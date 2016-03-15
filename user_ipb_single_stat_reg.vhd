--=================================================================================================--
--==================================== Module Information =========================================--
--=================================================================================================--
--                                                                                         
-- Company:                 	IPHC Laboratory (CNRS/Strasbourg)                                                         
-- Engineer:                	Laurent CHARLES (lcharles@iphc.cnrs.fr) 
--                                                                                                  
-- Project Name:            	PIXFED / CMS Pixel Upgrade Phase I (VME -> uTCA technology)                                                               
-- Module Name:             	iphc_ipb_stat_regs.vhd                                       
--                                                                                                  
-- Language:               	VHDL'93                                                                  
--                                                                                                    
-- Target Device:           	Device agnostic                                                         
-- Tool version: 				   ISE14.6                                                                    
--                                                                                                    
-- Version:                 	0.1                                                                      
--
-- Description:           		* Ipbus Status Register reserved for IPHC
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
---use work.pkg_pixfed.all;



entity user_ipb_single_stat_reg is
port
(
	clk					: in 	std_logic;
	reset					: in 	std_logic;
	ipb_mosi_i			: in 	ipb_wbus;
	ipb_miso_o			: out ipb_rbus;
	--
	--From user_logic to s/w (Flags & Status)	
	regs_i				: in  std_logic_vector(31 downto 0)
);
	
end user_ipb_single_stat_reg;

architecture rtl of user_ipb_single_stat_reg is

   --========================= Signals Declaration ==========================--

	signal regs						: std_logic_vector(31 downto 0);

	signal ack						: std_logic := '0';

	attribute keep					: boolean;
	attribute keep of ack		: signal is true;

   --========================================================================--   
 
--===========================================================================--
-----        --===================================================--
begin      --================== Architecture Body ==================-- 
-----        --===================================================--
--===========================================================================--
   
   --============================= User Logic ===============================--

	--=============================--
	-- io mapping
	--=============================--
	--> From user_logic (Flags & Status / Rd only):
	-----------------------------------------------
	regs 		<= regs_i;


	--=============================--
	process(reset, clk)
	--=============================--
	begin
	if reset='1' then
		ack 	 						<= '0';
	elsif rising_edge(clk) then
		-- read: From temp reg to s/w 
		ipb_miso_o.ipb_rdata 	<= regs;
		-- ack
		ack 							<= ipb_mosi_i.ipb_strobe and not ack;

	end if;
	end process;
	
	ipb_miso_o.ipb_ack 			<= ack;
	ipb_miso_o.ipb_err 			<= '0';

end rtl;