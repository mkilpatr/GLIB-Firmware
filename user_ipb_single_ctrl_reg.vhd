--=================================================================================================--
--==================================== Module Information =========================================--
--=================================================================================================--
-- TWN 3/11/2016  Excerpted from:               : to a single 32 bit control resister.
                                                                                       
-- Company:                 	IPHC Laboratory (CNRS/Strasbourg)                                                         
-- Engineer:                	Laurent CHARLES (lcharles@iphc.cnrs.fr) 
--                                                                                                  
-- Project Name:            	PIXFED / CMS Pixel Upgrade Phase I (VME -> uTCA technology)                                                               
-- Module Name:             	iphc_ipb_ctrl_regs.vhd                                       
--                                                                                                  
-- Language:               	VHDL'93                                                                  
--                                                                                                    
-- Target Device:           	Device agnostic                                                         
-- Tool version: 				   ISE14.6                                                                    
--                                                                                                    
-- Version:                 	0.1                                                                      
--
-- Description:           		* Ipbus Control Register reserved for IPHC
--										* Function as several parameters (see pkg_pixfed.vhd)
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
use work.system_package.all;

--! user packages

--! IPHC packages
--use work.pkg_pixfed.all;

entity user_ipb_single_ctrl_reg is
port
(
	clk					: in 	std_logic;
	reset					: in 	std_logic;
	ipb_mosi_i			: in 	ipb_wbus;
	ipb_miso_o			: out ipb_rbus;
	------------------
	--From s/w to user_logic (Ctrl & Cmd)
	regs_o				: out	std_logic_vector(31 downto 0)
);
	
end user_ipb_single_ctrl_reg;

architecture rtl of user_ipb_single_ctrl_reg is

   --========================= Signals Declaration ==========================--

	signal regs						: std_logic_vector(31 downto 0);	

	signal ack						: std_logic := '0';

	attribute keep					: boolean;
	attribute keep of ack		: signal is true;


--===========================================================================--
-----        --===================================================--
begin      --================== Architecture Body ==================-- 
-----        --===================================================--
--===========================================================================--
   
   --============================= User Logic ===============================--

	--=============================--
	-- io mapping
	--=============================--
	--> To user_logic: 
	------------------
	regs_o 	<= regs;


	--=============================--
	process(reset, clk)
	--=============================--
	begin
	if reset='1' then
--		regs 	 						<= (others=> (others=>'0'));
		regs							<= (others=> '0');
		ack 	 						<= '0';
	elsif rising_edge(clk) then
		-- write: From s/w to temp reg		
		if ipb_mosi_i.ipb_strobe='1' and ipb_mosi_i.ipb_write='1' then
				regs     			<= ipb_mosi_i.ipb_wdata;
		end if;
		-- read: From temp reg to s/w 
		ipb_miso_o.ipb_rdata 	<= regs;
		-- ack
		ack 							<= ipb_mosi_i.ipb_strobe and not ack;


	end if;
	end process;
	
	ipb_miso_o.ipb_ack 			<= ack;
	ipb_miso_o.ipb_err 			<= '0';


end rtl;