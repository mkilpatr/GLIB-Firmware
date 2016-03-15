--=================================================================================================--
--==================================== Module Information =========================================--
--=================================================================================================--
--                                                                                         
-- Company:                 	CERN                                                         
-- Engineer:                	Laurent CHARLES (lcharles@iphc.cnrs.fr) 
--                                                                                                  
-- Project Name:            	FEC / CMS Tracker Upgrade (VME -> uTCA technology)                                                               
-- Module Name:             	I2Cmaster.vhd                                       
--                                                                                                  
-- Language:               	VHDL'93                                                                  
--                                                                                                    
-- Target Device:           	Device agnostic                                                         
-- Tool version: 				   ISE14.6                                                                    
--                                                                                                    
-- Version:                 	0.2                                                                      
--
-- Description:             	* The I2C master. It supports the standard 7-bit addressing and the custom "RAL" addressing mode 
-- 
-- Versions history:        	DATE         VERSION   	AUTHOR            DESCRIPTION
--
--                          	******   0.1       	P.Vichoudis          - First .vhd file (from GLIB3 SVN Repository)
--                          	******   0.2       	LCHARLES          	- done flag added                                                                
--
-- Additional Comments:                                                                             
--                                                                                                    
--=================================================================================================--
--=================================================================================================--




library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library unisim;
use unisim.vcomponents.all;

entity i2c_master_core_v2 is
port
(
	clk			: in  	std_logic;
	reset			: in  	std_logic;
	--- i2c registers ------------
	settings		: in  	std_logic_vector(12 downto 0);
	command		: in  	std_logic_vector(31 downto 0);
	reply			: out 	std_logic_vector(31 downto 0);
	------------------------------
	--- flag	--------------------
	done_o		: out		std_logic; --one-pulse 
	busy_o		: out		std_logic;
	------------------------------	
	scl_i			: in		std_logic_vector(1 downto 0);					
	scl_o			: out		std_logic_vector(1 downto 0);					
	sda_i			: in		std_logic_vector(1 downto 0);
	sda_o			: out		std_logic_vector(1 downto 0);
	--new
	sda_oe_l		: out		std_logic_vector(1 downto 0);
	scl_oe_l		: out		std_logic_vector(1 downto 0)

); 			
end i2c_master_core_v2;


--===========================================
-- note: the response is latched when ctrl_done=1
--===========================================
architecture hierarchy of i2c_master_core_v2 is

signal startclk								:std_logic;
signal execstart								:std_logic;
signal execstop								:std_logic;
signal execwr									:std_logic;
signal execgetack								:std_logic;
signal execrd									:std_logic;
signal execsendack							:std_logic;
signal bytetowrite							:std_logic_vector(7 downto 0);
signal byteread								:std_logic_vector(7 downto 0);	
signal bytereaddv								:std_logic;	
signal completed								:std_logic;
signal failed									:std_logic;
 
BEGIN


--===========================================
u1: entity work.i2c_bitwise_v2
--===========================================
port map
(
	clk				=> CLK,
	reset				=> RESET,
	------------------------------
	--=== settings ==--
	------------------------------
	enable			=> SETTINGS(11),
	i2c_bus_select	=> SETTINGS(10),
	clkprescaler	=> SETTINGS(9 downto 0),
	------------------------------
	--== interface w/ i2cdata ==--
	------------------------------
	startclk_ext	=> startclk,
	execstart_ext	=> execstart,
	execstop_ext	=> execstop,
	execwr_ext		=> execwr,
	execgetack_ext	=> execgetack,
	execrd_ext		=> execrd,
	execsendack_ext=> execsendack,
	bytetowrite_ext=> bytetowrite,
	completed		=> completed,
	failed			=> failed,
	byteread			=> byteread,
	bytereaddv		=> bytereaddv,
	------------------------------
	--== physical interface   ==--
	------------------------------
	scl_o				=> scl_o,
	scl_i				=> scl_i,
	sda_o				=> sda_o,				
	sda_i				=> sda_i,				
	--new
	sda_oe_l			=> sda_oe_l,
	scl_oe_l			=> scl_oe_l

); 			
--===========================================



--===========================================
u2: entity work.i2c_ctrl_v2
--===========================================
port map
(
	clk				=> CLK,
	reset				=> RESET,
	------------------------------
	--=== settings ==--
	------------------------------
	enable			=> SETTINGS(11),
	clkprescaler	=> SETTINGS(9 downto 0),
	------------------------------
	--=== command  ==--
	------------------------------
	executestrobe	=> COMMAND(31),
	extmode			=> COMMAND(25), --16bit data
	ralmode			=> COMMAND(24),
	writetoslave	=> COMMAND(23),
	slaveaddress	=> '0'&  COMMAND(22 downto 16),
	slaveregister	=> COMMAND(15 downto 8 ),
	datatoslave		=> COMMAND( 7 downto 0 ),
	------------------------------
	--== interface w/ i2cdata ==--
	------------------------------
	startclk			=> startclk,
	execstart		=> execstart,
	execstop			=> execstop,
	execwr			=> execwr,
	execgetack		=> execgetack,
	execrd			=> execrd,
	execsendack		=> execsendack,
	bytetowrite		=> bytetowrite,
	byteread			=> byteread,
	bytereaddv		=> bytereaddv,
	completed		=> completed,
	failed			=> failed,
	------------------------------
	done_o			=> done_o,
	busy_o			=> busy_o,
	reply_o			=> REPLY
); 
--===========================================





END hierarchy;
