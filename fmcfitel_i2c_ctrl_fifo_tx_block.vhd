--=================================================================================================--
--==================================== Module Information =========================================--
--=================================================================================================--
--                                                                                         
-- Company:                 	IPHC Laboratory (CNRS/Strasbourg)                                                         
-- Engineer:                	Laurent CHARLES (lcharles@iphc.cnrs.fr) 
--                                                                                                  
-- Project Name:            	PIXFED / CMS Pixel Upgrade Phase I (VME -> uTCA technology)                                                               
-- Module Name:             	fmcfitel_i2c_ctrl_fifo_tx_block.vhd                                       
--                                                                                                  
-- Language:               	VHDL'93                                                                  
--                                                                                                    
-- Target Device:           	Device agnostic                                                         
-- Tool version: 				   ISE14.6                                                                    
--                                                                                                    
-- Version:                 	0.1                                                                      
--
-- Description:           		* FIFO TX - Write access controlled by ipbus / Reads access controlled by internal f/w
--										* Used as temporary memory containing the I2C transactions - Format FMCFITEL
--										* Allows the I2C slow control of all the FMCFITEL Optical Receivers by packet
--										* Indexing (fmcNb) + Indexing (fmcfitelNb)
--
-- Versions history:        	DATE         VERSION   	AUTHOR            DESCRIPTION
--
--                          	2015/09/01   0.1       	LCHARLES          - First .vhd file 
--                                                                  
--
-- Additional Comments:                                                                             
--                                                                                                    
--=================================================================================================--
--=================================================================================================--

library ieee;
use ieee.std_logic_1164.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use ieee.numeric_std.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

--! system packages
use work.ipbus.all;

--! user packages

entity fmcfitel_i2c_ctrl_fifo_tx_block is
port (
		--===============--
		-- ipb interface --
		--===============--	
      ipb_clk_i							: in std_logic;    
		clk_i									: in std_logic;
		reset_i								: in std_logic; --active high,
		--
		ipb_mosi_i							: in ipb_wbus;  --see ipbus_package  
		ipb_miso_o							: out ipb_rbus;
		--==================--
		-- fabric interface --
		--==================--
		fifo_empty_o						: out std_logic; 
		fifo_rd_en_i             		: in std_logic;
		fifo_valid_o						: out std_logic;
		fifo_rd_data_o           		: out std_logic_vector(31 downto 0)
		);
end fmcfitel_i2c_ctrl_fifo_tx_block;

architecture Behavioral of fmcfitel_i2c_ctrl_fifo_tx_block is

   --========================= Signals Declaration ==========================--
	
	signal sel								: integer := 0;
	signal ack								: std_logic := '0';


	attribute keep							: boolean;
	attribute keep of ack				: signal is true;


	signal wr_en							: std_logic := '0';
	signal rd_en							: std_logic := '0';
	signal valid							: std_logic := '0';
	signal empty							: std_logic := '1';
	signal full								: std_logic := '0';      
	signal wr_data							: std_logic_vector(31 downto 0) := (others => '0');
	signal rd_data							: std_logic_vector(31 downto 0) := (others => '0');

     
   --========================================================================--   
 
--===========================================================================--
-----        --===================================================--
begin      --================== Architecture Body ==================-- 
-----        --===================================================--
--===========================================================================--
   
   --============================= User Logic ===============================--

	--=========================--
	-- io mapping
	--==========================--         
	fifo_empty_o						<= empty;
	rd_en									<= fifo_rd_en_i;
	fifo_valid_o						<= valid;
	fifo_rd_data_o						<= rd_data;


	--
--	ipb_miso_o.ipb_rdata				<= (others=>'0');   These 3 were already "--"  TWN 3/11/2016
--	ipb_miso_o.ipb_ack				<= ack;
--	ipb_miso_o.ipb_err				<= '0';
       

	--=========================--
	-- wr_en / ipb_clk_i  wb_clk
	--==========================--         
	wr_en									<= ack and ipb_mosi_i.ipb_write;    
		      


	--============================--
	-- wr_data / ipb_clk_i
	--============================--               
	wr_data 								<= ipb_mosi_i.ipb_wdata;				
	
       
	--=========================--
	-- ack / ipb_clk_i
	--==========================--         
	process
	begin
	wait until rising_edge(ipb_clk_i);				

		--
		if reset_i = '1' then
			ack							<= '0';
		else
			ack							<= ipb_mosi_i.ipb_strobe and not ack;      

		end if;
		--
	end process;




	--===============================================================================================--
	fifo_tx_inst: entity work.fifo_tx --normal mode
	--===============================================================================================--
	port map  
	(
			wr_clk				=> ipb_clk_i,       -- TWN 3/11/2016
			rd_clk				=> clk_i,
--			clk					=> clk_i,    
			rst					=> reset_i,
			din					=> wr_data,
			wr_en					=> wr_en,
			rd_en					=> rd_en,
			dout					=> rd_data,
			full					=> open,
			empty					=> empty,
			valid					=> valid
	);
	--===============================================================================================--





end Behavioral;

