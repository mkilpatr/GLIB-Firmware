--=================================================================================================--
--==================================== Module Information =========================================--
--=================================================================================================--
--                                                                                         
-- Company:                 	IPHC Laboratory (CNRS/Strasbourg)                                                         
-- Engineer:                	Laurent CHARLES (lcharles@iphc.cnrs.fr) 
--                                                                                                  
-- Project Name:            	FEC / CMS Tracker Upgrade (VME -> uTCA technology)                                                               
-- Module Name:             	user_logic.vhd                                       
--                                                                                                  
-- Language:               	VHDL'93                                                                  
--                                                                                                    
-- Target Device:           	Device agnostic                                                         
-- Tool version: 				   ISE14.6                                                                    
--                                                                                                    
-- Version:                 	0.1                                                                      
--
-- Description:             	* Integration of the FEC
-- 
-- Versions history:        	DATE         VERSION   	AUTHOR            DESCRIPTION
--
--                          	20/11/2014   0.1       	LCHARLES          - First .vhd file 
--                                                                  
--
-- Additional Comments:                                                                             
--                                                                                                    
--=================================================================================================--
--=================================================================================================--
-- Matt Added summary of changes to Strasbourg Pixel Emulation 
-- Evaldas Jruska made all of the TTC_decoder connections that were necessary for this project.
--====================================================================================================
--If you change the XPOINT1 configuration during runtime by writing to the control register, then the board will crash, 
--so what I did is just to modify the system_core.vhd and hardcode the xpoint1_s30 <= '1' and xpoint1_s31 <= '1'. 
--This is done so the simulated TTC signal from the AMC13 is routed to the correct ports on the GLIB.
--You can then pick up the clock signal from xpoint1_clk3_p and xpoint1_clk3_n in your user_logic_basic.vhd:
--    add or uncomment these lines in your port() section
--      xpoint1_clk3_p : in std_logic;
--      xpoint1_clk3_n : in std_logic;
--   uncomment and a bit modify a few lines in your user_fabric_clk.ucf file so they look like this:
--     NET "xpoint1_clk3_p"                                            LOC = A10                                                                        ; # IO_L1P_GC_34               
--     NET "xpoint1_clk3_n"                                            LOC = B10                                                                        ; # IO_L1N_GC_34                       
--     NET "xpoint1_clk3_p"                                            TNM_NET = "xpoint1_clk3_p"                                                       ;
--     NET "xpoint1_clk3_n"                                            TNM_NET = "xpoint1_clk3_n"                                                       ;
--     TIMESPEC TS_xpoint1_clk3_p =                    PERIOD "xpoint1_clk3_p" 24.95 ns HIGH 50 % INPUT_JITTER 100 ps                              
--     TIMESPEC TS_xpoint1_clk3_n =                    PERIOD "xpoint1_clk3_n" TS_xpoint1_clk3_p PHASE 12.475 ns HIGH 50 %                ;
--
--For the data make sure you have these lines uncommented in the system.ucf (though I think they are available by default):
--  NET "amc_port_rx_p[*]" LOC = ####;
--  NET "amc_port_rx_n[*]" LOC = ####;
--also make sure you have them in your port() section of the user_logic_basic.vhd:
--   amc_port_rx_p               : in std_logic_vector(1 to 15);
--   amc_port_rx_n               : in std_logic_vector(1 to 15);
--
--At this point you can instantiate the TTC decoder module that we got I believe from HCAL (Jared knows the details) like this:
--(attached TTC_decoder.vhd). Correct variable have been added to the user architecture and fed through the ipbut link_tracking to 
--be counted. If you look at link_tracking.vhd you will see three counters have been added to count L1As, Orbits, and bunches and 
--they can be read by reading registers 0x4004000 & (0,1,2). The signals from the TTC_decoder and some bits from the counter have 
--been sent to the fmc1_j2 HA00-HA07 and LA18 ports. I had to add the user_fmc1_io_conf_package.vhd so that the pins could be changed to
--out. Also changed fmc1_j2_map: entity work.fmc_io_buffers to fmc_la_io_settings => fmc1_la_io_settings_constants. These signals are 
--easily viewed with an oscilloscope.


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
--! xilinx packages
library unisim;
use unisim.vcomponents.all;
--! system packages
library work;
use work.system_flash_sram_package.all;
use work.system_pcie_package.all;
use work.system_package.all;
use work.wb_package.all;
use work.ipbus.all;

--! Custom libraries and packages: 
use work.fmc_package.all; 


--! user packages
--! IPHC PKG
use work.user_package.all;
use work.user_version_package.all;
use work.pkg_dualTBM_emulator.all; 
use work.pkg_glib_pix_emul.all;
use work.user_fmc1_io_conf_package.all;

entity user_logic is
port
(
	--================================--
	-- USER MGT REFCLKs
	--================================--
   -- BANK_112(Q0):  
   clk125_1_p	                        : in	  std_logic;  		    
   clk125_1_n	                        : in	  std_logic;  		  
   cdce_out0_p	                        : in	  std_logic;  		  
   cdce_out0_n	                        : in	  std_logic; 		  
   -- BANK_113(Q1):                 
   fmc2_clk0_m2c_xpoint2_p	            : in	  std_logic;
   fmc2_clk0_m2c_xpoint2_n	            : in	  std_logic;
   cdce_out1_p	                        : in	  std_logic;       
   cdce_out1_n	                        : in	  std_logic;         
   -- BANK_114(Q2):                 
   pcie_clk_p	                        : in	  std_logic; 			  
   pcie_clk_n	                        : in	  std_logic;			  
   cdce_out2_p  	                     : in	  std_logic;			  
   cdce_out2_n  	                     : in	  std_logic;			  
   -- BANK_115(Q3):                 
   clk125_2_i                          : in	  std_logic;		      
   fmc1_gbtclk1_m2c_p	               : in	  std_logic;     
   fmc1_gbtclk1_m2c_n	               : in	  std_logic;     
   -- BANK_116(Q4):                 
   fmc1_gbtclk0_m2c_p	               : in	  std_logic;	  
   fmc1_gbtclk0_m2c_n	               : in	  std_logic;	  
   cdce_out3_p	                        : in	  std_logic;		  
   cdce_out3_n	                        : in	  std_logic;		    
   --================================--
	-- USER FABRIC CLOCKS
	--================================--
   xpoint1_clk3_p	                     : in	  std_logic;		   
   xpoint1_clk3_n	                     : in	  std_logic;
   ------------------------------------  
   cdce_out4_p                         : in	  std_logic;                
   cdce_out4_n                         : in	  std_logic;              
   ------------------------------------
   amc_tclkb_o					            : out	  std_logic;
   ------------------------------------      
   fmc1_clk0_m2c_xpoint2_p	            : in	  std_logic;
   fmc1_clk0_m2c_xpoint2_n	            : in	  std_logic;
   fmc1_clk1_m2c_p		               : in	  std_logic;	
   fmc1_clk1_m2c_n		               : in	  std_logic;	
   fmc1_clk2_bidir_p		               : in	  std_logic;	
   fmc1_clk2_bidir_n		               : in	  std_logic;	
   fmc1_clk3_bidir_p		               : in	  std_logic;	
   fmc1_clk3_bidir_n		               : in	  std_logic;	
   ------------------------------------
   fmc2_clk1_m2c_p	                  : in	  std_logic;		
   fmc2_clk1_m2c_n	                  : in	  std_logic;		
	--================================--
	-- GBT PHASE MONITORING MGT REFCLK
	--================================--
   cdce_out0_gtxe1_o                   : out   std_logic;  		  
   cdce_out3_gtxe1_o                   : out   std_logic;  
	--================================--
	-- AMC PORTS
	--================================--
   amc_port_tx_p				            : out	  std_logic_vector(1 to 15);
	amc_port_tx_n				            : out	  std_logic_vector(1 to 15);
	amc_port_rx_p				            : in	  std_logic_vector(1 to 15);
	amc_port_rx_n				            : in	  std_logic_vector(1 to 15);
	------------------------------------
	amc_port_tx_out			            : out	  std_logic_vector(17 to 20);	
	amc_port_tx_in				            : in	  std_logic_vector(17 to 20);		
	amc_port_tx_de				            : out	  std_logic_vector(17 to 20);	
	amc_port_rx_out			            : out	  std_logic_vector(17 to 20);	
	amc_port_rx_in				            : in	  std_logic_vector(17 to 20);	
	amc_port_rx_de				            : out	  std_logic_vector(17 to 20);	
	--================================--
	-- SFP QUAD
	--================================--
	sfp_tx_p						            : out	  std_logic_vector(1 to 4);
	sfp_tx_n						            : out	  std_logic_vector(1 to 4);
	sfp_rx_p						            : in	  std_logic_vector(1 to 4);
	sfp_rx_n						            : in	  std_logic_vector(1 to 4);
	sfp_mod_abs					            : in	  std_logic_vector(1 to 4);		
	sfp_rxlos					            : in	  std_logic_vector(1 to 4);		
	sfp_txfault					            : in	  std_logic_vector(1 to 4);				
	--================================--
	-- FMC1
	--================================--
	fmc1_tx_p					            : out	  std_logic_vector(1 to 4);
	fmc1_tx_n                           : out	  std_logic_vector(1 to 4);
	fmc1_rx_p                           : in	  std_logic_vector(1 to 4);
	fmc1_rx_n                           : in	  std_logic_vector(1 to 4);
	------------------------------------
	fmc1_io_pin					            : inout fmc_io_pin_type;
	------------------------------------
	fmc1_clk_c2m_p				            : out	  std_logic_vector(0 to 1);
	fmc1_clk_c2m_n				            : out	  std_logic_vector(0 to 1);
	fmc1_present_l				            : in	  std_logic;
	--================================--
	-- FMC2
	--================================--
	fmc2_io_pin					            : inout fmc_io_pin_type;
	------------------------------------
	fmc2_clk_c2m_p				            : out	  std_logic_vector(0 to 1);
	fmc2_clk_c2m_n				            : out	  std_logic_vector(0 to 1);
	fmc2_present_l				            : in	  std_logic;
   --================================--      
	-- SYSTEM GBE   
	--================================--      
   sys_eth_amc_p1_tx_p		            : in	  std_logic;	
   sys_eth_amc_p1_tx_n		            : in	  std_logic;	
   sys_eth_amc_p1_rx_p		            : out	  std_logic;	
   sys_eth_amc_p1_rx_n		            : out	  std_logic;	
	------------------------------------
	user_mac_syncacqstatus_i            : in	  std_logic_vector(0 to 3);
	user_mac_serdes_locked_i            : in	  std_logic_vector(0 to 3);
	--================================--   										
	-- SYSTEM PCIe				   												
	--================================--   
   sys_pcie_mgt_refclk_o	            : out	  std_logic;	  
   user_sys_pcie_dma_clk_i             : in	  std_logic;	  
   ------------------------------------
	sys_pcie_amc_tx_p		               : in	  std_logic_vector(0 to 3);    
   sys_pcie_amc_tx_n		               : in	  std_logic_vector(0 to 3);    
   sys_pcie_amc_rx_p		               : out	  std_logic_vector(0 to 3);    
   sys_pcie_amc_rx_n		               : out	  std_logic_vector(0 to 3);    
   ------------------------------------
	user_sys_pcie_slv_o	               : out   R_slv_to_ezdma2;									   	
	user_sys_pcie_slv_i	               : in    R_slv_from_ezdma2; 	   						    
	user_sys_pcie_dma_o                 : out   R_userDma_to_ezdma2_array  (1 to 7);		   					
	user_sys_pcie_dma_i                 : in 	  R_userDma_from_ezdma2_array(1 to 7);		   	
	user_sys_pcie_int_o 	               : out   R_int_to_ezdma2;									   	
	user_sys_pcie_int_i 	               : in    R_int_from_ezdma2; 								    
	user_sys_pcie_cfg_i 	               : in	  R_cfg_from_ezdma2; 								   	
	--================================--
	-- SRAMs
	--================================--
	user_sram_control_o		            : out	  userSramControlR_array(1 to 2);
	user_sram_addr_o			            : out	  array_2x21bit;
	user_sram_wdata_o			            : out	  array_2x36bit;
	user_sram_rdata_i			            : in 	  array_2x36bit;
	------------------------------------
   sram1_bwa                           : out	  std_logic;  
   sram1_bwb                           : out	  std_logic;  
   sram1_bwc                           : out	  std_logic;  
   sram1_bwd                           : out	  std_logic;  
   sram2_bwa                           : out	  std_logic;  
   sram2_bwb                           : out	  std_logic;  
   sram2_bwc                           : out	  std_logic;  
   sram2_bwd                           : out	  std_logic;    
   --================================--               
	-- CLK CIRCUITRY              
	--================================--    
   fpga_clkout_o	  			            : out	  std_logic;	
   ------------------------------------
   sec_clk_o		                     : out	  std_logic;	
	------------------------------------
	user_cdce_locked_i			         : in	  std_logic;
	user_cdce_sync_done_i					: in	  std_logic;
	user_cdce_sel_o			            : out	  std_logic;
	user_cdce_sync_o			            : out	  std_logic;
	--================================--  
	-- USER BUS  
	--================================--       
	wb_miso_o				               : out	  wb_miso_bus_array(0 to number_of_wb_slaves-1);
	wb_mosi_i				               : in 	  wb_mosi_bus_array(0 to number_of_wb_slaves-1);
	------------------------------------
	ipb_clk_i				               : in 	  std_logic;
	ipb_miso_o			                  : out	  ipb_rbus_array(0 to number_of_ipb_slaves-1);
	ipb_mosi_i			                  : in 	  ipb_wbus_array(0 to number_of_ipb_slaves-1);   
   --================================--
	-- VARIOUS
	--================================--
   reset_i						            : in	  std_logic;	    
	user_clk125_i                  		: in	  std_logic;       
   user_clk200_i                  		: in	  std_logic;       
   ------------------------------------   
   sn			                           : in    std_logic_vector(7 downto 0);	   
   ------------------------------------   
   amc_slot_i									: in    std_logic_vector( 3 downto 0);
	mac_addr_o 					            : out   std_logic_vector(47 downto 0);
   ip_addr_o					            : out   std_logic_vector(31 downto 0);
   ------------------------------------	
   user_v6_led_o                       : out	  std_logic_vector(1 to 2);
   ------------------------------------		
	user_fpga_scl_o				         : out	  std_logic;	
	user_fpga_sda_o				         : out	  std_logic;		   	
	user_fpga_sda_i				         : in	  std_logic;
	cnt_ttc_trigger							: in	  std_logic_vector(31 downto 0);
	cnt_ttc_Orbit								: in    std_logic_vector(31 downto 0);
	cnt_ttc_Bunches							: in    std_logic_vector(31 downto 0)
);                         	
end user_logic;
							
architecture user_logic_arch of user_logic is                    	


   --@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@--
   --@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@--
   --@@@@@@@@ PLACE YOUR DECLARATIONS BELOW THIS COMMENT @@@@@@@@@--
   --@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@--
   --@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@--


	-- Global signals

    signal gtx_clk              : std_logic := '0';

    -- External signals

    signal ext_sbit             : std_logic := '0';

    -- GTX signals

    signal rx_error             : std_logic_vector(3 downto 0) := (others => '0');
    signal rx_kchar             : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_data              : std_logic_vector(63 downto 0) := (others => '0');
    signal tx_kchar             : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_data              : std_logic_vector(63 downto 0) := (others => '0');

    -- Registers requests
    
    signal request_write_0      : array32(127 downto 0) := (others => (others => '0'));
    signal request_tri_0        : std_logic_vector(127 downto 0);
    
    signal request_write        : array32(127 downto 0) := (others => (others => '0'));
    signal request_tri          : std_logic_vector(127 downto 0) := (others => '0');
    signal request_read         : array32(127 downto 0) := (others => (others => '0'));

    -- Trigger

    signal empty_trigger_fifo   : std_logic := '0';
    signal sbit_configuration   : std_logic_vector(2 downto 0) := (others => '0');
    signal ttc_trigger          : std_logic := '0';
    
    -- TTC
    signal l1_led               : std_logic := '0';
    signal bc0_led              : std_logic := '0';
	 
	 -- TTC
    signal bcntres              : std_logic := '0';
    signal evcntres             : std_logic := '0';
    signal sinerrstr            : std_logic := '0';
    signal dberrstr             : std_logic := '0';
    signal brcst                : std_logic_vector(5 downto 0) := (others => '0');
    signal brcststr             : std_logic := '0';
    signal l1accept             : std_logic := '0';
    signal tcc_clock            : std_logic := '0';
	 signal ttcready				  : std_logic := '0';
	 signal ttc_data_out			  : std_logic := '0';
	 signal ctrl_reg				  : array_32x32bit;
	 signal L1A_count				  : std_logic_vector(31 downto 0) := (others => '0');
	 signal Orbit_count          : std_logic_vector(31 downto 0) := (others => '0');
	 signal Bunch_count			  : std_logic_vector(31 downto 0) := (others => '0');
	 

	--==================================== Attributes =====================================--
   
   -- Comment: The "keep" constant is used to avoid that ISE changes the name of 
   --          the signals to be analysed
   attribute keep                  								: string;  
	attribute iob 														: string;  
	attribute loc                   								: string;
	attribute pullup                								: string;
	attribute iostandard            								: string;
	attribute clock_dedicated_route 								: string;	

   --=============================================================================================================================================--
	-- FMC I/O --
   --=============================================================================================================================================--
	signal fmc1_from_pin_to_fabric								: fmc_from_pin_to_fabric_type;
	signal fmc1_from_fabric_to_pin								: fmc_from_fabric_to_pin_type;
	
	signal fmc2_from_pin_to_fabric								: fmc_from_pin_to_fabric_type;
	signal fmc2_from_fabric_to_pin								: fmc_from_fabric_to_pin_type;

	signal fmc_from_fabric_to_pin_array 						: fmc_from_fabric_to_pin_array_type; --see pkg_glib_pix_emul.vhd
	signal fmc_from_pin_to_fabric_array 						: fmc_from_pin_to_fabric_array_type;
	attribute iob of fmc_from_fabric_to_pin_array     		: signal is "true";
	--=============================================================================================================================================--
	-- END FMC IO -- 
   --=============================================================================================================================================--


   --=============================================================================================================================================--
	-- FMC8SFP I2C CTRL -- 
   --=============================================================================================================================================--
	--Manager 
	signal fmc_8sfp_i2c_ctrl_settings							: std_logic_vector(31 downto 0):=(others=>'0');	
	signal fmc_8sfp_i2c_ctrl_command								: std_logic_vector(31 downto 0):=(others=>'0');		
	signal fmc_8sfp_i2c_ctrl_reply								: std_logic_vector(31 downto 0):=(others=>'0');		
	signal fmc_8sfp_i2c_ctrl_done 								: std_logic:='0';
	--tmp
	signal fmc_8sfp_i2c_ctrl_busy 								: std_logic:='0';
	--PHY
	signal fmc_8sfp_i2c_ctrl_scl 									: std_logic:='1';
	signal fmc_8sfp_i2c_ctrl_scl_oe_l 							: std_logic:='1';
	signal fmc_8sfp_i2c_ctrl_sda_i 								: std_logic:='1';
	signal fmc_8sfp_i2c_ctrl_sda_o	 							: std_logic:='1';
	signal fmc_8sfp_i2c_ctrl_sda_oe_l 							: std_logic:='1';	
	--
	attribute keep of fmc_8sfp_i2c_ctrl_scl     				: signal is "true";
	attribute keep of fmc_8sfp_i2c_ctrl_scl_oe_l  			: signal is "true";
	attribute keep of fmc_8sfp_i2c_ctrl_sda_i     			: signal is "true";
	attribute keep of fmc_8sfp_i2c_ctrl_sda_o     			: signal is "true";
	attribute keep of fmc_8sfp_i2c_ctrl_sda_oe_l   			: signal is "true";
   --=============================================================================================================================================--
	-- END FMC8SFP I2C CTRL -- 
   --=============================================================================================================================================--



   --=============================================================================================================================================--
	-- I/O Registers Mapping / Parameters List --
   --=============================================================================================================================================--
	signal glib_pix_emul_param_i 									: glib_pix_emul_param_type;	
	signal glib_pix_emul_param_o 									: glib_pix_emul_param_type;	
	signal glib_pix_emul_param_o_resync_clk_40_0				: glib_pix_emul_param_type;
--	signal glib_pix_emul_param_o_resync_wr_clk				: glib_pix_emul_param_type;
--	signal glib_pix_emul_param_o_resync_rd_clk				: glib_pix_emul_param_type;
	--
	signal SW_TRIGGER_SEL 											: std_logic:='0';
	signal SW_CMD_START 												: std_logic:='0';		
	signal SW_CONFIG_OK 												: std_logic:='0';
	signal SW_INT_TRIGGER_FREQ_SEL 								: std_logic_vector(3 downto 0):=(others=>'0');		
	--
	signal SW_STANDALONE_MODE 										: std_logic := '0'; --'0' : enabled (internal clock & trigger) / '1' : disabled (link with pixfed / external clock & trigger)
	signal SW_TBM_EMUL_TYPE											: std_logic_vector(3 downto 0) := (others => '0'); --0 : v1 / 1 : v2
	signal SW_TBM_EMUL_NB											: std_logic_vector(5 downto 0) := (others => '0'); --[1:48]
	signal SW_SAME_CONFIG_ALL_EMUL								: std_logic := '0'; --'0' : no / '1' : yes (independant); by def
   --=============================================================================================================================================--
	-- END I/O Registers Mapping / Parameters List --
   --=============================================================================================================================================--



   --=============================================================================================================================================--
	-- CLOCKING -- 
   --=============================================================================================================================================--
	--> xpoint1_clk3 (internal 40-MHz crystal oscillator):
	------------------------------------------------------
	signal xpoint1_clk3_ibufgds 									: std_logic := '0';
	signal xpoint1_clk3_bufg 										: std_logic := '0';
	--> cdce_out4:
	-------------- 	
	signal cdce_out4_ibufgds 										: std_logic := '0';
	signal cdce_out4_bufg 											: std_logic := '0';	
	--> CDCE CTRL:
	-------------- 
	signal sec_clk														: std_logic := '0';
	signal user_cdce_sync											: std_logic := '1'; --DIS / by def.	
	signal user_cdce_sel												: std_logic := '1'; --clk1 by def	
	attribute keep of user_cdce_sync								: signal is "true"; 	
	attribute keep of user_cdce_sel								: signal is "true"; 
	type	cdce_states 												is (	idle, s1, s2, s3 );
	signal cdce_state 												: cdce_states;	
	--> MMCM:
	---------
	signal clk_40_0 													: std_logic := '0';
	signal clk_400_0 													: std_logic := '0';	
	signal clk_400_45 												: std_logic := '0';	
	signal clk_400_90 												: std_logic := '0';	
	signal clk_400_135 												: std_logic := '0';	
	signal clk_320_0 													: std_logic := '0';	
	signal clk_160_0 													: std_logic := '0';	
	signal clk_80_0 													: std_logic := '0';	
	signal clk_200_0 													: std_logic := '0';		
	signal clk_120_0 													: std_logic := '0';			
	signal mmcm1_lock													: std_logic := '0';  
	signal mmcm2_lock													: std_logic := '0';
	signal mmcm_lock													: std_logic := '0';
	--=============================================================================================================================================--
	-- END CLOCKING -- 
   --=============================================================================================================================================--



	



	
	
   --=============================================================================================================================================--
	-- CHIPSCOPE -- 
   --=============================================================================================================================================--	
	signal CONTROL0 													: std_logic_vector(35 downto 0)		:=(others=>'0');
	signal CLK_ILA_TEST 												: std_logic									:='0';
	signal ILA_TRIG0 													: std_logic_vector(7 downto 0) 		:=(others => '0');
	signal ILA_TRIG1 													: std_logic_vector(35 downto 0) 		:=(others => '0');
	signal ILA_TRIG2 													: std_logic_vector(35 downto 0) 		:=(others => '0');
	signal ILA_TRIG3 													: std_logic_vector(35 downto 0) 		:=(others => '0');
	signal ILA_TRIG4 													: std_logic_vector(35 downto 0) 		:=(others => '0');
	signal ILA_TRIG5 													: std_logic_vector(1 downto 0) 		:=(others => '0');
	signal ILA_TRIG6 													: std_logic_vector(35 downto 0) 		:=(others => '0');
	signal ILA_TRIG7 													: std_logic_vector(0 to 0) 			:=(others => '0');
	signal ILA_TRIG8 													: std_logic_vector(20 downto 0) 		:=(others => '0');
	signal ILA_TRIG9 													: std_logic_vector(31 downto 0) 		:=(others => '0');
	signal ILA_TRIG10 												: std_logic_vector(0 to 0) 			:=(others => '0');
	signal ILA_TRIG11 												: std_logic_vector(20 downto 0) 		:=(others => '0');
	signal ILA_TRIG12 												: std_logic_vector(31 downto 0) 		:=(others => '0');
   --=============================================================================================================================================--
	-- END CHIPSCOPE -- 
   --=============================================================================================================================================--	




   --=============================================================================================================================================--
	-- EXTERNAL CTRL: CLOCK, TRIGGER & RESET -- 
   --=============================================================================================================================================--	
	--External signals
	signal rx_clk_in 													: std_logic := '0';
	signal rx_trig_in 												: std_logic := '0';
	signal rx_reset_in 												: std_logic := '1';	
	attribute keep of rx_clk_in									: signal is "true"; 
	attribute keep of rx_trig_in									: signal is "true"; 	
	attribute keep of rx_reset_in									: signal is "true";
	--buffer
	signal rx_clk_in_bufg											: std_logic := '0'; 
	--attribute clock_dedicated_route of fmc2_io_pin.la_p : signal is "false";
	--NET "fmc2_la_p<33>" CLOCK_DEDICATED_ROUTE = FALSE; -> if bufg	
	--
	signal rx_trig_in_del 											: std_logic_vector(2 downto 0):=(others=>'0');
	signal rx_trig_in_pulse											: std_logic := '0'; 	
	--
	signal rx_reset_in_del 											: std_logic_vector(2 downto 0):=(others=>'0');	
	signal rx_reset_in_pulse										: std_logic := '1'; 	
   --=============================================================================================================================================--
	-- END EXTERNAL CTRL: CLOCK, TRIGGER & RESET -- 
   --=============================================================================================================================================--		
	
	
   --=============================================================================================================================================--
	-- PIXEL EMULATOR -- --
   --=============================================================================================================================================--
	--Constants & Types declaration: see pkg_glib_pix_emul 
	--
	signal tbm_ch_start												: array_TBM_EMUL_NBx2b;
	--
	signal tbm_emul_v1_hit_nb_ROC_mode							: array_TBM_EMUL_NBxTBM_CH_NBx4b;
	signal tbm_emul_v1_matrix_mode								: array_TBM_EMUL_NBxTBM_CH_NBx4b;
	signal tbm_emul_v1_hit_data_mode								: array_TBM_EMUL_NBxTBM_CH_NBx4b;
	--
	signal tbm_emul_v1_ROC_nb										: array_TBM_EMUL_NBxTBM_CH_NBx4b;
	--
	signal tbm_emul_v1_hit_nb										: array_TBM_EMUL_NBxTBM_CH_NBxROC_NB_MAXx4b;	
	
	signal tbm_emul_v1_reset										: std_logic;
	signal PKAM_Reset_v1												: std_logic_vector(7 downto 0) := (others => '0');
	signal PKAM_Constant												: std_logic_vector(7 downto 0) := (others => '0');
	signal PKAM_Enable												: std_logic := '0';
	signal PKAM_Buffer												: std_logic := '0';
	signal ROC_Timer_Buffer											: std_logic := '0';
	signal ROC_Clk														: std_logic_vector(7 downto 0) := (others => '0');
	--
	signal tbm_emul_v1_dcol											: array_TBM_EMUL_NBxTBM_CH_NBxROC_NB_MAXx6b;
	signal tbm_emul_v1_row											: array_TBM_EMUL_NBxTBM_CH_NBxROC_NB_MAXx9b;
	signal tbm_emul_v1_hit											: array_TBM_EMUL_NBxTBM_CH_NBxROC_NB_MAXx8b;
	signal tbm_emul_v1_header_flag								: array_TBM_EMUL_NBxTBM_CH_NBx8b;
	signal tbm_emul_v1_trailer_flag1								: array_TBM_EMUL_NBxTBM_CH_NBx8b;
	signal tbm_emul_v1_trailer_flag2								: array_TBM_EMUL_NBxTBM_CH_NBx8b;	
	signal tbm_chB_delaying											: array_TBM_EMUL_NBx8b;
	--
	signal tx_tbm_sdout												: std_logic_vector(TBM_EMUL_NB-1 downto 0) := (others=>'0');
	signal tbm_chA_word4b_sync40M									: std_logic_vector(3 downto 0) := (others => '0');
	signal tbm_chB_word4b_sync40M									: std_logic_vector(3 downto 0) := (others => '0');
	signal tbm_chA_word4b_sync80M									: std_logic_vector(3 downto 0) := (others => '0');
	signal tbm_chB_word4b_sync80M									: std_logic_vector(3 downto 0) := (others => '0');
	signal tx_symb4b													: std_logic_vector(3 downto 0) := (others => '0');
	signal tx_symb5b													: std_logic_vector(4 downto 0) := (others => '0');
   --=============================================================================================================================================--
	-- END PIXEL EMULATOR -- --
   --=============================================================================================================================================--	


	signal int_trigger												: std_logic:='0';
	signal user_reset													: std_logic:='1';	


	
--@@@@@@@@@@@@@@@@@@@@@@--   
--@@@@@@@@@@@@@@@@@@@@@@--   
--@@@@@@@@@@@@@@@@@@@@@@--
begin-- ARCHITECTURE
--@@@@@@@@@@@@@@@@@@@@@@--                              
--@@@@@@@@@@@@@@@@@@@@@@--
--@@@@@@@@@@@@@@@@@@@@@@--
 
   
   --#############################--
   --## GLIB IP & MAC ADDRESSES ##--
   --#############################--
   
   ip_addr_o				               <= x"c0a801a"     & amc_slot_i;  -- 192.168.1.[160:175] changed xc0a800a to xc0a801a
	--ip_addr_o				               <= x"00000000";
   mac_addr_o 				               <= x"080030F100a" & amc_slot_i;  -- 08:00:30:F1:00:0[A0:AF] 
  
  
   --@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@--
   --@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@--
   --@@@@@@@@@@@@ PLACE YOUR LOGIC BELOW THIS COMMENT @@@@@@@@@@@@--
   --@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@--
   --@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@--


	user_v6_led_o(1) <= l1_led;
   user_v6_led_o(2) <= bc0_led;
	

    --fmc1_io_pin.la_p(10) <= ext_sbit;

    --================================--
    -- GTX
    --================================--

    gtx_wrapper_inst : entity work.gtx_wrapper
    port map(
        gtx_clk_o       => gtx_clk,
        reset_i         => reset_i,
        rx_error_o      => rx_error,
        rx_kchar_o      => rx_kchar,
        rx_data_o       => rx_data,
        rx_n_i          => sfp_rx_n,
        rx_p_i          => sfp_rx_p,
        tx_kchar_i      => tx_kchar,
        tx_data_i       => tx_data,
        tx_n_o          => sfp_tx_n,
        tx_p_o          => sfp_tx_p,
        gtp_refclk_n_i  => cdce_out1_n,
        gtp_refclk_p_i  => cdce_out1_p
    );

    --================================--
    -- Tracking links
    --================================--

    link_tracking_0_inst : entity work.link_tracking
    port map(
        gtx_clk_i       => gtx_clk,
        --ttc_clk_p_i     => xpoint1_clk3_p,
        --ttc_clk_n_i     => xpoint1_clk3_n,
		  ipb_clk_i       => ipb_clk_i,
        reset_i         => reset_i,
        rx_error_i      => rx_error(0),
        rx_kchar_i      => rx_kchar(1 downto 0),
        rx_data_i       => rx_data(15 downto 0),
        tx_kchar_o      => tx_kchar(1 downto 0),
        tx_data_o       => tx_data(15 downto 0),
--        ipb_vi2c_i      => ipb_mosi_i(ipb_vi2c_0),
--        ipb_vi2c_o      => ipb_miso_o(ipb_vi2c_0),
--        ipb_track_i     => ipb_mosi_i(ipb_track_0),
--        ipb_track_o     => ipb_miso_o(ipb_track_0),
--        ipb_regs_i      => ipb_mosi_i(ipb_regs_0),
--        ipb_regs_o      => ipb_miso_o(ipb_regs_0),
        ipb_info_i      => ipb_mosi_i(ipb_info_0),
        ipb_info_o      => ipb_miso_o(ipb_info_0),
        request_write_o => request_write_0,
        request_tri_o   => request_tri_0,
        request_read_i  => request_read,
        trigger_i       => ttc_trigger,
		  l1accept			=> l1accept,
		  EvCntRes			=> EvCntRes,
		  BCntRes			=> BCntRes,
		  L1A_count			=> L1A_count,
		  Orbit_count		=> Orbit_count,
		  Bunch_count		=> Bunch_count,
		  xpoint1_clk3_bufg => xpoint1_clk3_bufg
    );
    
    requests: for I in 0 to 127 generate
    begin
        request_tri(I) <= request_tri_0(I);
        request_write(I) <= request_write_0(I) when request_tri_0(I) = '1';
    end generate;    
	 
    
    --================================--
    -- TTC/TTT signal handling 	
    -- from ngFEC_logic.vhd (HCAL)
    --================================--
    
    TTC_decode: entity work.TTC_decoder
	port map ( 
				TTC_CLK_p => xpoint1_clk3_p,
				 TTC_CLK_n => xpoint1_clk3_n,
				 TTC_rst => reset_i,--ctrl_reg(0)(31),-- asynchronous reset after TTC_CLK_p/TTC_CLK_n frequency changed
				 TTC_data_p => amc_port_rx_p(3),
				 TTC_data_n => amc_port_rx_n(3),
				 TTC_CLK_out => xpoint1_clk3_bufg,
				 TTCready  => TTCready,
				 L1Accept  => L1Accept,
				 BCntRes  => BCntRes,
				 EvCntRes  => EvCntRes,
				 SinErrStr  => SinErrStr,
				 DbErrStr  => DbErrStr,
				 BrcstStr => BrcstStr,
				 Brcst => Brcst,
				 TTCDataOut => TTC_data_out
				 );
				 
				 
	  -- blink a led on the clock (slowed down)
    process(xpoint1_clk3_bufg)
        variable i : integer := 0;
    begin
        if (rising_edge(xpoint1_clk3_bufg)) then
            if (i < 2_500_000) then
                bc0_led <= '0'; -- this is not really BC0 signal, just the clock
            else
                bc0_led <= '1';
            end if;
            
            if (i = 5_000_000) then
                i := 0;
            else
                i := i + 1;
            end if;
        end if;
    end process;
    
    -- blink a LED on L1A (here you can also easily implement an L1A counter and a reset)
    process(xpoint1_clk3_bufg)
        variable i : integer := 0;
    begin
        if (rising_edge(xpoint1_clk3_bufg)) then
            if (i > 0) then
                l1_led <= '1';
            else
                l1_led <= '0';
            end if;
            
            if (l1accept = '1') then
                i := 400_000;
            elsif (i > 0) then
                i := i - 1;
            else
                i := 0;
            end if;
        end if;
    end process;
	 
	 clock_bridge_trigger_inst : entity work.clock_bridge_simple
    port map(
        reset_i     => '0',
        m_clk_i     => xpoint1_clk3_bufg,
        m_en_i      => l1accept,
        s_clk_i     => gtx_clk,
        s_en_o      => ttc_trigger
    );
	 
    --================================--
    -- Register mapping
    --================================--

    -- Empty trigger fifo

    empty_trigger_fifo <= request_tri(0);

    -- S Bits configuration : 0 -- read / write _ Controls the Sbits to send to the TDC

    sbit_configuration_reg : entity work.reg port map(fabric_clk_i => ipb_clk_i, reset_i => reset_i, wbus_i => request_write(1), wbus_t => request_tri(1), rbus_o => request_read(1));
    sbit_configuration <= request_read(1)(2 downto 0);
    

   --=============================================================================================================================================--
	-- FMC2_J1 I/O Mapping --
   --=============================================================================================================================================--

	--==================================
	fmc2_j1_map: entity work.fmc_io_buffers
	--==================================
	generic map
	(
		fmc_la_io_settings		=> func_fmc_la_settings(fmc2_j1_type), --fmc2_j1_la_io_settings, --see pkg_glib_pix_emul
		fmc_ha_io_settings		=> fmc_ha_io_settings_defaults, 			--see fmc_package
		fmc_hb_io_settings		=> fmc_hb_io_settings_defaults
	)
	port map
	(
		fmc_io_pin					=> fmc2_io_pin,
		fmc_from_fabric_to_pin	=> fmc_from_fabric_to_pin_array(fmc2_j1),
		fmc_from_pin_to_fabric	=> fmc_from_pin_to_fabric_array(fmc2_j1)
	);
	--==================================


	fmc2_j1_fmcdio_used_gen	: if fmc2_j1_type = "fmcdio" generate
		--> test 
--		--LEMO_0_OUT <= LA(29)
--		fmc_from_fabric_to_pin_array(fmc2_j1).la_lvds(29)			<= rx_clk_in;		
--		--LEMO_1_OUT <= LA(28)
--		fmc_from_fabric_to_pin_array(fmc2_j1).la_lvds(28)			<= clk_40_0;	
--		--LEMO_2_OUT <= LA(08)
--		fmc_from_fabric_to_pin_array(fmc2_j1).la_lvds(08)			<= cdce_out4_ibufgds;	 
--		--LEMO_3_OUT <= LA(07)
--		fmc_from_fabric_to_pin_array(fmc2_j1).la_lvds(07)			<= ipb_clk_i; 
--		--LEMO_4_OUT <= LA(04)	
--		fmc_from_fabric_to_pin_array(fmc2_j1).la_lvds(04)			<= '0';			
		-->
		--LEMO_0_OUT <= LA(29)
		fmc_from_fabric_to_pin_array(fmc2_j1).la_lvds(29)			<= clk_40_0;			
		--LEMO_1_OUT <= LA(28)
		fmc_from_fabric_to_pin_array(fmc2_j1).la_lvds(28)			<= rx_reset_in_pulse; --rx_reset_in / rx_reset_in_pulse
		--LEMO_2_OUT <= LA(08)
		fmc_from_fabric_to_pin_array(fmc2_j1).la_lvds(08)			<= rx_trig_in_pulse; --rx_trig_in / rx_trig_in_pulse
		--LEMO_3_OUT <= LA(07)
		fmc_from_fabric_to_pin_array(fmc2_j1).la_lvds(07)			<= '0';--tx_tbm_sdout(0)	
		--LEMO_4_OUT <= LA(04)	
		fmc_from_fabric_to_pin_array(fmc2_j1).la_lvds(04)			<= '0';		

		
		--OE_L from OBUF!!!
		fmc_from_fabric_to_pin_array(fmc2_j1).la_lvds_oe_l(29) 	<= '0';
		fmc_from_fabric_to_pin_array(fmc2_j1).la_lvds_oe_l(28) 	<= '0';
		fmc_from_fabric_to_pin_array(fmc2_j1).la_lvds_oe_l(08) 	<= '0';	
		fmc_from_fabric_to_pin_array(fmc2_j1).la_lvds_oe_l(07) 	<= '0';
		fmc_from_fabric_to_pin_array(fmc2_j1).la_lvds_oe_l(04) 	<= '0';	
		
		--OE_N_0 => LA_P(30)
		fmc_from_fabric_to_pin_array(fmc2_j1).la_cmos_p(30)		<= '0'; --or PULLDOWN + HZ 
		fmc_from_fabric_to_pin_array(fmc2_j1).la_cmos_p_oe_l(30)	<= '0';		
		--OE_N_1 => LA_N(24)	
		fmc_from_fabric_to_pin_array(fmc2_j1).la_cmos_n(24)		<= '0'; --or PULLDOWN + HZ 
		fmc_from_fabric_to_pin_array(fmc2_j1).la_cmos_n_oe_l(24)	<= '0';
		--OE_N_2 => LA_N(15)
		fmc_from_fabric_to_pin_array(fmc2_j1).la_cmos_n(15)		<= '0'; --or PULLDOWN + HZ 
		fmc_from_fabric_to_pin_array(fmc2_j1).la_cmos_n_oe_l(15)	<= '0';	
		--OE_N_3 => LA_P(11)
		fmc_from_fabric_to_pin_array(fmc2_j1).la_cmos_p(11)		<= '0'; --or PULLDOWN + HZ 
		fmc_from_fabric_to_pin_array(fmc2_j1).la_cmos_p_oe_l(11)	<= '0';
		--OE_N_4 => LA_P(5)	
		fmc_from_fabric_to_pin_array(fmc2_j1).la_cmos_p(05)		<= '0'; --or PULLDOWN + HZ 
		fmc_from_fabric_to_pin_array(fmc2_j1).la_cmos_p_oe_l(05)	<= '0';
		
		--TERM_EN_0 => LA_N(30)
		fmc_from_fabric_to_pin_array(fmc2_j1).la_cmos_n(30)		<= '0';  
		fmc_from_fabric_to_pin_array(fmc2_j1).la_cmos_n_oe_l(30)	<= '0';
		--TERM_EN_1 => LA_N(06)
		fmc_from_fabric_to_pin_array(fmc2_j1).la_cmos_n(06)		<= '0'; 
		fmc_from_fabric_to_pin_array(fmc2_j1).la_cmos_n_oe_l(06)	<= '0';
		--TERM_EN_2 => LA_N(05)
		fmc_from_fabric_to_pin_array(fmc2_j1).la_cmos_n(05)		<= '0'; 
		fmc_from_fabric_to_pin_array(fmc2_j1).la_cmos_n_oe_l(05)	<= '0';	
		--TERM_EN_3 => LA_P(09)
		fmc_from_fabric_to_pin_array(fmc2_j1).la_cmos_p(09)		<= '0'; 
		fmc_from_fabric_to_pin_array(fmc2_j1).la_cmos_p_oe_l(09)	<= '0';
		--TERM_EN_4 => LA_N(09)
		fmc_from_fabric_to_pin_array(fmc2_j1).la_cmos_n(09)		<= '0'; 
		fmc_from_fabric_to_pin_array(fmc2_j1).la_cmos_n_oe_l(09)	<= '0';	
		
		
	end generate;


   --=============================================================================================================================================--
	-- END FMC2_J1 I/O Mapping --
   --=============================================================================================================================================--


   --=============================================================================================================================================--
	-- FMC1_J2 I/O Mapping --
   --=============================================================================================================================================--

	--==================================
	fmc1_j2_map: entity work.fmc_io_buffers
	--==================================
	generic map
	(
		fmc_la_io_settings		=> func_fmc_la_settings(fmc1_j2_type), --fmc1_j2_la_io_settings, --see pkg_glib_pix_emul
		fmc_ha_io_settings		=> fmc1_ha_io_settings_constants, 			--see fmc_package
		fmc_hb_io_settings		=> fmc_hb_io_settings_defaults
	)
	port map
	(
		fmc_io_pin					=> fmc1_io_pin,
		fmc_from_fabric_to_pin	=> fmc_from_fabric_to_pin_array(fmc1_j2),
		fmc_from_pin_to_fabric	=> fmc_from_pin_to_fabric_array(fmc1_j2)
	);
	--==================================

--	fmc1_j2_fmcdio_used_gen	: if fmc1_j2_type = "fmcdio" generate --ctrl
--	end generate;

--Matt Added TTC mapping
		---------------------------------------------------------------------------------
		--TTC_CLK => LA18_CC
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_lvds_oe_l(17)	<= '0';
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_lvds(17) <= xpoint1_clk3_bufg;
		
		--TTC_DATA => HA00_CC/TTC_CLK
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_p_oe_l(00)	<= '0';
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_p(00) <= TTC_data_out ;
		
		--SinErrStr => HA01_p
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_p_oe_l(01)	<= '0';
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_p(01) <= SinErrStr;
		--DbSinErr => HA01_n
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_n_oe_l(01)	<= '0';
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_n(01) <= DbErrStr;
		
		--L1A => HA02_p
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_p_oe_l(02)	<= '0';
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_p(02) <= L1Accept;
		
		--BcntRes = HA03_p
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_p_oe_l(03)	<= '0';
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_p(03) <= BCntRes;
		
		--EvCntRes = HA03_n
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_n_oe_l(03)	<= '0';
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_n(03) <= EvCntRes;
		
		--Total_Reset => HA04_p
		--fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_p_oe_l(04)	<= '0';
		--fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_p(04) <= Test_Reset;
		
		--ttcready => HA04_n
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_n_oe_l(04)	<= '0';
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_n(04) <= PKAM_Enable;
		
		--Brcst => HA05_p
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_p_oe_l(05)	<= '0';
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_p(05) <= PKAM_Buffer; --Brcst(0);
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_n_oe_l(05)	<= '0';
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_n(05) <= ROC_Timer_Buffer; --Brcst(1);
		
		--Brcst => HA06
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_p_oe_l(06)	<= '0';
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_p(06) <= Brcst(2);
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_n_oe_l(06)	<= '0';
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_n(06) <= Brcst(3);
		
		--Brcst => HA07
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_p_oe_l(07)	<= '0';
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_p(07) <= Brcst(4);
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_n_oe_l(07)	<= '0';
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_n(07) <= Brcst(5);
		
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_p_oe_l(08)	<= '0';
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_p(08) <= brcststr;
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_n_oe_l(08)	<= '0';
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_n(08) <= clk_80_0;
		
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_p_oe_l(09)	<= '0';
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_p(09) <= clk_200_0;
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_n_oe_l(09)	<= '0';
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_n(09) <= clk_400_0;
		
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_p_oe_l(10)	<= '0';
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_p(10) <= clk_400_45;
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_n_oe_l(10)	<= '0';
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_n(10) <= clk_400_90;
		
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_p_oe_l(11) 		<= '0';
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_p(11)		 		<= tbm_chA_word4b_sync40M(0);
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_n_oe_l(11) 		<= '0';
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_n(11)		 		<= tbm_chA_word4b_sync40M(1);
			
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_p_oe_l(12) 		<= '0';
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_p(12)		 		<= tbm_chA_word4b_sync40M(2);
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_n_oe_l(12) 		<= '0';
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_n(12)		 		<= tbm_chA_word4b_sync40M(3);
			
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_p_oe_l(13) 		<= '0';
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_p(13) 				<= tbm_chB_word4b_sync40M(0);
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_n_oe_l(13) 		<= '0';
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_n(13) 				<= tbm_chB_word4b_sync40M(1);
		
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_p_oe_l(14) 		<= '0';
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_p(14) 				<= tbm_chB_word4b_sync40M(2);
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_n_oe_l(14) 		<= '0';
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_n(14) 				<= tbm_chB_word4b_sync40M(3);
			
--		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_p_oe_l(15)		<= '0';
--		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_p(15) 	<= Test_Reset;
--		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_n_oe_l(15)		<= '0';
--		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_n(15) 	<= Test2_Reset;
--		
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_p_oe_l(16)		<= '0';
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_p(16) 	<= tx_symb5b(2);
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_n_oe_l(16)		<= '0';
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_n(16) 	<= tx_symb5b(3);
		
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_p_oe_l(18)		<= '0';
		fmc_from_fabric_to_pin_array(fmc1_j2).ha_cmos_p(18) 	<= tx_symb5b(4);
		

	io_fmc1_j2_fmc8sfp_used_gen : if fmc1_j2_type = "fmc8sfp" generate 
		-->IN / RX / CTRL
			--from A
			rx_clk_in							<= xpoint1_clk3_bufg; 		--fmc_from_pin_to_fabric_array(fmc1_j2).la_lvds(1);			
			--from B
			rx_trig_in 							<= L1Accept; 					--fmc_from_pin_to_fabric_array(fmc1_j2).la_lvds(3);			
			--from C
			rx_reset_in							<= BCntRes;					--fmc_from_pin_to_fabric_array(fmc1_j2).la_lvds(5);
			

		-->OUT / TX / TBM Data
			--> Debug / sync test
--			--to A
--			fmc_from_fabric_to_pin_array(fmc1_j2).la_lvds(2) 			<= rx_clk_in; 		
--			fmc_from_fabric_to_pin_array(fmc1_j2).la_lvds_oe_l(2) 	<= '0';--EN		
--			--to B
--			fmc_from_fabric_to_pin_array(fmc1_j2).la_lvds(4) 			<= clk_40_0;		
--			fmc_from_fabric_to_pin_array(fmc1_j2).la_lvds_oe_l(4) 	<= '0';--EN	
			--> Normal
--			--to A
			process
			begin
			wait until rising_edge(clk_400_0);
				fmc_from_fabric_to_pin_array(fmc1_j2).la_lvds(2) 		<= tx_tbm_sdout(0);	
			end process;
			fmc_from_fabric_to_pin_array(fmc1_j2).la_lvds_oe_l(2) 	<= '0';--EN		
			--to B
			process
			begin
			wait until rising_edge(clk_400_0);
				fmc_from_fabric_to_pin_array(fmc1_j2).la_lvds(4) 		<= tx_tbm_sdout(0);		
			end process;
			fmc_from_fabric_to_pin_array(fmc1_j2).la_lvds_oe_l(4) 	<= '0';--EN
--			--
			--to C
			process
			begin
			wait until rising_edge(clk_400_0);
				fmc_from_fabric_to_pin_array(fmc1_j2).la_lvds(6) 		<= tx_tbm_sdout(0);		
			end process;
			fmc_from_fabric_to_pin_array(fmc1_j2).la_lvds_oe_l(6) 	<= '0';--EN	
			--to D
			process
			begin
			wait until rising_edge(clk_400_0);
				fmc_from_fabric_to_pin_array(fmc1_j2).la_lvds(8) 		<= tx_tbm_sdout(0);		
			end process;
			fmc_from_fabric_to_pin_array(fmc1_j2).la_lvds_oe_l(8) 	<= '0';--EN	
			--to E
			process
			begin
			wait until rising_edge(clk_400_0);
				fmc_from_fabric_to_pin_array(fmc1_j2).la_lvds(10) 		<= tx_tbm_sdout(0);		
			end process;
			fmc_from_fabric_to_pin_array(fmc1_j2).la_lvds_oe_l(10) 	<= '0';--EN	
			--to F
			process
			begin
			wait until rising_edge(clk_400_0);
				fmc_from_fabric_to_pin_array(fmc1_j2).la_lvds(12) 		<= tx_tbm_sdout(0);		
			end process;
			fmc_from_fabric_to_pin_array(fmc1_j2).la_lvds_oe_l(12) 	<= '0';--EN	
			--to G
			process
			begin
			wait until rising_edge(clk_400_0);
				fmc_from_fabric_to_pin_array(fmc1_j2).la_lvds(14) 		<= tx_tbm_sdout(0);		
			end process;
			fmc_from_fabric_to_pin_array(fmc1_j2).la_lvds_oe_l(14) 	<= '0';--EN	
			--to H
			process
			begin
			wait until rising_edge(clk_400_0);
				fmc_from_fabric_to_pin_array(fmc1_j2).la_lvds(16) 		<= tx_tbm_sdout(0);		
			end process;	
			fmc_from_fabric_to_pin_array(fmc1_j2).la_lvds_oe_l(16) 	<= '0';--EN				
	end generate;


	
	io_fmc1_j2_i2c_fmc8sfp_gen : if fmc1_j2_type = "fmc8sfp" generate
		--SCL
		fmc_from_fabric_to_pin_array(fmc1_j2).la_cmos_p(32) 			<= fmc_8sfp_i2c_ctrl_scl;
		--SCL_OE_L
		fmc_from_fabric_to_pin_array(fmc1_j2).la_cmos_p_oe_l(32)		<= fmc_8sfp_i2c_ctrl_scl_oe_l; --'0'; 
		--SDA_I
		fmc_8sfp_i2c_ctrl_sda_i													<= fmc_from_pin_to_fabric_array(fmc1_j2).la_cmos_n(32);		
		--fmc_8sfp_i2c_ctrl_sda_i													<= '1'; --not used
		--SDA_O
		fmc_from_fabric_to_pin_array(fmc1_j2).la_cmos_n(32) 			<= fmc_8sfp_i2c_ctrl_sda_o;
		--SDA_OE_L	
		fmc_from_fabric_to_pin_array(fmc1_j2).la_cmos_n_oe_l(32)		<= fmc_8sfp_i2c_ctrl_sda_oe_l;

		--RST_N - active low
		fmc_from_fabric_to_pin_array(fmc1_j2).la_cmos_p(33) 			<= not reset_i; --aclr_n(0); 
		fmc_from_fabric_to_pin_array(fmc1_j2).la_cmos_p_oe_l(33) 	<= '0';
	end generate;
	

	io_fmc2_j1_i2c_fmc8sfp_gen : if fmc2_j1_type = "fmc8sfp" generate
		--SCL
		fmc_from_fabric_to_pin_array(fmc2_j1).la_cmos_p(32) 			<= fmc_8sfp_i2c_ctrl_scl;
		--SCL_OE_L
		fmc_from_fabric_to_pin_array(fmc2_j1).la_cmos_p_oe_l(32)		<= fmc_8sfp_i2c_ctrl_scl_oe_l; --'0'; 
		--SDA_I
		--fmc_8sfp_i2c_ctrl_sda_i													<= fmc_from_pin_to_fabric_array(fmc2_j1).la_cmos_n(32);		
		--fmc_8sfp_i2c_ctrl_sda_i													<= '1'; --not used
		--SDA_O
		fmc_from_fabric_to_pin_array(fmc2_j1).la_cmos_n(32) 			<= fmc_8sfp_i2c_ctrl_sda_o;
		--SDA_OE_L	
		fmc_from_fabric_to_pin_array(fmc2_j1).la_cmos_n_oe_l(32)		<= fmc_8sfp_i2c_ctrl_sda_oe_l;

		--RST_N - active low
		fmc_from_fabric_to_pin_array(fmc2_j1).la_cmos_p(33) 			<= not reset_i; --aclr_n(0); 
		fmc_from_fabric_to_pin_array(fmc2_j1).la_cmos_p_oe_l(33) 	<= '0';
	end generate;



	fmc8sfp_i2c_ctrl_gen : if fmc1_j2_type = "fmc8sfp" or fmc2_j1_type = "fmc8sfp" generate
		--=====================--
		-- FMC8SFP I2C CONTROL -- 
		--=====================--
		fmc_8sfp_i2c_manager_inst: entity work.fmc_8sfp_i2c_manager 
		PORT MAP(
			clk_i 						=> ipb_clk_i, 	--xpoint1_clk3_bufg,
			reset_n_i 					=> not reset_i, --active low
			i2c_ctrl_reply_i 			=> fmc_8sfp_i2c_ctrl_reply,
			i2c_ctrl_done_i	 		=> fmc_8sfp_i2c_ctrl_done,
			i2c_ctrl_settings_o 		=> fmc_8sfp_i2c_ctrl_settings,
			i2c_ctrl_command_o 		=> fmc_8sfp_i2c_ctrl_command,
			i2c_access_busy_o 		=> fmc_8sfp_i2c_ctrl_busy
		);

		--===================================--
		fmc_8sfp_i2c_ctrl_inst: entity work.i2c_master_core_v2
		--===================================--
		port map
		(
			clk							=> ipb_clk_i, --xpoint1_clk3_bufg	 							
			reset							=> reset_i, --active high
			settings						=> fmc_8sfp_i2c_ctrl_settings(12 downto 0),	
			command						=> fmc_8sfp_i2c_ctrl_command,
			reply							=> fmc_8sfp_i2c_ctrl_reply,
			------------
			done_o						=> fmc_8sfp_i2c_ctrl_done, --one-pulse
			busy_o						=> open,
			
			scl_i(0)						=> 'Z',	
			scl_i(1)						=> 'Z',
			--
			scl_o(0)						=> fmc_8sfp_i2c_ctrl_scl, 
			scl_o(1)						=> open,
			--
			sda_i(0)						=> fmc_8sfp_i2c_ctrl_sda_i,
			sda_i(1)						=> 'Z',
			--
			sda_o(0)						=> fmc_8sfp_i2c_ctrl_sda_o, 
			sda_o(1)						=> open,
			--
			scl_oe_l(0)					=> fmc_8sfp_i2c_ctrl_scl_oe_l,
			scl_oe_l(1)					=> open,		
			--
			sda_oe_l(0)					=> fmc_8sfp_i2c_ctrl_sda_oe_l,
			sda_oe_l(1)					=> open		
		);
	end generate;


	
   --=============================================================================================================================================--
	-- END FMC1_J2 I/O Mapping --
   --=============================================================================================================================================-




	



   --=============================================================================================================================================--
	-- I/O Registers Mapping / Parameters List --
   --=============================================================================================================================================--
	--========================--
	glib_pix_emul_param_inst: entity work.glib_pix_emul_param 
	--========================--
	port map 
		(
			wb_mosi	=> wb_mosi_i(user_wb_glib_pix_emul_param), -- constant user_wb_glib_pix_emul_param : see user_package.vhd and user_addr_decode.vhd 
			wb_miso 	=> wb_miso_o(user_wb_glib_pix_emul_param),	
			regs_o 	=> glib_pix_emul_param_o, 
			regs_i 	=> glib_pix_emul_param_i
		);
	--========================--	


	--==============================--
	-- PARAM CTRL - Rd/Wr => resync --
	--==============================--
	process 
	begin
		wait until rising_edge(clk_40_0);
			glib_pix_emul_param_o_resync_clk_40_0 <= glib_pix_emul_param_o;
	end process;
	--===========================--




	--==========================================--
	-- PARAM FLAGS & STATUS / Rd only => resync --
	--==========================================--
	process 
	begin
		wait until rising_edge(wb_mosi_i(user_wb_glib_pix_emul_param).wb_clk);
			--> USER ASCII CODES (stored into user_glib_fec_package.vhd)
			glib_pix_emul_param_i(RD_PARAM_ADDR_0 + 00) 							<= USER_IPHC_ASCII_WORD_01;	
			glib_pix_emul_param_i(RD_PARAM_ADDR_0 + 01) 							<= USER_IPHC_ASCII_WORD_02;	
			--> USER IPHC FIRMWARE VERSION
			glib_pix_emul_param_i(RD_PARAM_ADDR_0 + 02) 							<= std_logic_vector(to_unsigned(USER_IPHC_FW_VER_YEAR  ,7)) &
																								std_logic_vector(to_unsigned(USER_IPHC_FW_VER_MONTH ,4)) &
																								std_logic_vector(to_unsigned(USER_IPHC_FW_VER_DAY   ,5)) &
																								std_logic_vector(to_unsigned(USER_IPHC_ARCHI_VER_NB ,8)) &																	
																								std_logic_vector(to_unsigned(USER_IPHC_FW_VER_NB    ,8));

			
	
			--> ACQ PARAMETERS
	

			glib_pix_emul_param_i(RD_PARAM_ADDR_0 + 03)							<= std_logic_vector(to_unsigned(0,28)) & mmcm2_lock & mmcm1_lock & user_cdce_sync & user_cdce_sel;



			--> OTHERS				
	end process;


	--=======================================--
	-- PARAM CTRL & CMD / Rd/Wr
	--=======================================--
----	process 
----	begin
----		wait until rising_edge(wb_mosi_i(user_wb_glib_pix_emul_param).wb_clk);
			
						
	--=======================================--
	-- PARAM CTRL & CMD / Rd/Wr
	--=======================================--
	--toto 												<= glib_pix_emul_param_o_resync_clk_40_0(WR_PARAM_ADDR_0+00);
	SW_CONFIG_OK 										<= glib_pix_emul_param_o_resync_clk_40_0(WR_PARAM_ADDR_0 + 00)(0);
	SW_CMD_START 										<= glib_pix_emul_param_o_resync_clk_40_0(WR_PARAM_ADDR_0 + 00)(1);
	SW_TRIGGER_SEL 									<= glib_pix_emul_param_o_resync_clk_40_0(WR_PARAM_ADDR_0 + 00)(2);
	SW_INT_TRIGGER_FREQ_SEL 						<= glib_pix_emul_param_o_resync_clk_40_0(WR_PARAM_ADDR_0 + 00)(7 downto 4);
	SW_STANDALONE_MODE								<= glib_pix_emul_param_o_resync_clk_40_0(WR_PARAM_ADDR_0 + 00)(8);
	SW_TBM_EMUL_TYPE 									<= glib_pix_emul_param_o_resync_clk_40_0(WR_PARAM_ADDR_0 + 00)(15 downto 12);--4b	
	SW_TBM_EMUL_NB 									<= glib_pix_emul_param_o_resync_clk_40_0(WR_PARAM_ADDR_0 + 00)(21 downto 16); --6b	
	SW_SAME_CONFIG_ALL_EMUL							<= glib_pix_emul_param_o_resync_clk_40_0(WR_PARAM_ADDR_0 + 00)(25); --or by def if SW_TBM_EMUL_NB > 1
	
	--01 : reserved

	--==============--
   -- EMUL CONTROL --
   --==============--	
	--TBM0
	tbm_emul_v1_ROC_nb(0)(chA)						<= glib_pix_emul_param_o_resync_clk_40_0(WR_PARAM_ADDR_0 + 02)(3 downto 0);--4-bit
	tbm_emul_v1_ROC_nb(0)(chB)						<= glib_pix_emul_param_o_resync_clk_40_0(WR_PARAM_ADDR_0 + 02)(7 downto 4);--4-bit		
	--
	tbm_emul_v1_hit_nb_ROC_mode(0)(chA)			<= glib_pix_emul_param_o_resync_clk_40_0(WR_PARAM_ADDR_0 + 02)(11 downto 8);--4-bit
	tbm_emul_v1_hit_nb_ROC_mode(0)(chB)			<= glib_pix_emul_param_o_resync_clk_40_0(WR_PARAM_ADDR_0 + 02)(15 downto 12);--4-bit
	--
	tbm_emul_v1_matrix_mode(0)(chA)				<= glib_pix_emul_param_o_resync_clk_40_0(WR_PARAM_ADDR_0 + 02)(19 downto 16);--4-bit
	tbm_emul_v1_matrix_mode(0)(chB)				<= glib_pix_emul_param_o_resync_clk_40_0(WR_PARAM_ADDR_0 + 02)(23 downto 20);--4-bit		
	--
	tbm_emul_v1_hit_data_mode(0)(chA)			<= glib_pix_emul_param_o_resync_clk_40_0(WR_PARAM_ADDR_0 + 02)(27 downto 24);--4-bit
	tbm_emul_v1_hit_data_mode(0)(chB)			<= glib_pix_emul_param_o_resync_clk_40_0(WR_PARAM_ADDR_0 + 02)(31 downto 28);--4-bit		

--	--
--	tbm_emul_v1_ROC_nb(0)(chA)						<= std_logic_vector(to_unsigned(8,4));--4-bit
--	tbm_emul_v1_ROC_nb(0)(chB)						<= std_logic_vector(to_unsigned(8,4));--4-bit
--	--
--	tbm_emul_v1_hit_nb_ROC_mode(0)(chA)			<= std_logic_vector(to_unsigned(0,4));--4-bit
--	tbm_emul_v1_hit_nb_ROC_mode(0)(chB)			<= std_logic_vector(to_unsigned(0,4));--4-bit	
--	--
--	tbm_emul_v1_matrix_mode(0)(chA)				<= std_logic_vector(to_unsigned(0,4));--4-bit
--	tbm_emul_v1_matrix_mode(0)(chB)				<= std_logic_vector(to_unsigned(0,4));--4-bit		
--	--
--	tbm_emul_v1_hit_data_mode(0)(chA)			<= std_logic_vector(to_unsigned(0,4));--4-bit
--	tbm_emul_v1_hit_data_mode(0)(chB)			<= std_logic_vector(to_unsigned(0,4));--4-bit


	--
	tbm_emul_v1_header_flag(0)(chA)				<= glib_pix_emul_param_o_resync_clk_40_0(WR_PARAM_ADDR_0 + 03)(7 downto 0);	--8-bit
	tbm_emul_v1_header_flag(0)(chB)				<= glib_pix_emul_param_o_resync_clk_40_0(WR_PARAM_ADDR_0 + 04)(7 downto 0);	--8-bit	
	--
	tbm_emul_v1_trailer_flag1(0)(chA)			<= glib_pix_emul_param_o_resync_clk_40_0(WR_PARAM_ADDR_0 + 03)(15 downto 8);	--8-bit
	tbm_emul_v1_trailer_flag1(0)(chB)			<= glib_pix_emul_param_o_resync_clk_40_0(WR_PARAM_ADDR_0 + 04)(15 downto 8);	--8-bit
	--
	tbm_emul_v1_trailer_flag2(0)(chA)			<= glib_pix_emul_param_o_resync_clk_40_0(WR_PARAM_ADDR_0 + 03)(23 downto 16);	--8-bit
	tbm_emul_v1_trailer_flag2(0)(chB)			<= glib_pix_emul_param_o_resync_clk_40_0(WR_PARAM_ADDR_0 + 04)(23 downto 16);	--8-bit
	
--	Stack_count(chA)(5 downto 0)					<= glib_pix_emul_param_o_resync_clk_40_0(WR_PARAM_ADDR_0 + 03)(21 downto 16);
--	Stack_count(chB)(5 downto 0)					<= glib_pix_emul_param_o_resync_clk_40_0(WR_PARAM_ADDR_0 + 04)(21 downto 16);
	
	tbm_chB_delaying(0)								<= glib_pix_emul_param_o_resync_clk_40_0(WR_PARAM_ADDR_0 + 03)(31 downto 24);	--8-bit	
	--tbm_chB_delaying(0)								<= std_logic_vector(to_unsigned(0,8));--8-bit	
	
	--
	data_roc_gen : for i_roc in 0 to 7 generate  --> Over-range !!!
		data_ch_gen : for i_ch in 0 to 1 generate
			--
			tbm_emul_v1_hit(0)(i_ch)(i_roc)		<= glib_pix_emul_param_o_resync_clk_40_0(WR_PARAM_ADDR_0 + 05 + (2*i_roc + i_ch))(7 downto 0);	--8-bit
			--
			tbm_emul_v1_dcol(0)(i_ch)(i_roc)		<= glib_pix_emul_param_o_resync_clk_40_0(WR_PARAM_ADDR_0 + 05 + (2*i_roc + i_ch))(13 downto 8);	--6-bit
			--
			tbm_emul_v1_row(0)(i_ch)(i_roc)		<= glib_pix_emul_param_o_resync_clk_40_0(WR_PARAM_ADDR_0 + 05 + (2*i_roc + i_ch))(24 downto 16);--9-bit
		
		end generate;
	end generate;
	
	tbm_emul_v1_hit_nb(0)(0)(0)				<= glib_pix_emul_param_o_resync_clk_40_0(WR_PARAM_ADDR_0 + 21 )(3 downto 0);--4-bit
	tbm_emul_v1_hit_nb(0)(0)(1)				<= glib_pix_emul_param_o_resync_clk_40_0(WR_PARAM_ADDR_0 + 21 )(7 downto 4);--4-bit
	tbm_emul_v1_hit_nb(0)(0)(2)				<= glib_pix_emul_param_o_resync_clk_40_0(WR_PARAM_ADDR_0 + 21 )(11 downto 8);--4-bit
	tbm_emul_v1_hit_nb(0)(0)(3)				<= glib_pix_emul_param_o_resync_clk_40_0(WR_PARAM_ADDR_0 + 21 )(15 downto 12);--4-bit
	tbm_emul_v1_hit_nb(0)(0)(4)				<= glib_pix_emul_param_o_resync_clk_40_0(WR_PARAM_ADDR_0 + 21 )(19 downto 16);--4-bit
	tbm_emul_v1_hit_nb(0)(0)(5)				<= glib_pix_emul_param_o_resync_clk_40_0(WR_PARAM_ADDR_0 + 21 )(23 downto 20);--4-bit
	tbm_emul_v1_hit_nb(0)(0)(6)				<= glib_pix_emul_param_o_resync_clk_40_0(WR_PARAM_ADDR_0 + 21 )(27 downto 24);--4-bit
	tbm_emul_v1_hit_nb(0)(0)(7)				<= glib_pix_emul_param_o_resync_clk_40_0(WR_PARAM_ADDR_0 + 21 )(31 downto 28);--4-bit
		
	tbm_emul_v1_hit_nb(0)(1)(0)				<= glib_pix_emul_param_o_resync_clk_40_0(WR_PARAM_ADDR_0 + 22 )(3 downto 0);--4-bit
	tbm_emul_v1_hit_nb(0)(1)(1)				<= glib_pix_emul_param_o_resync_clk_40_0(WR_PARAM_ADDR_0 + 22 )(7 downto 4);--4-bit
	tbm_emul_v1_hit_nb(0)(1)(2)				<= glib_pix_emul_param_o_resync_clk_40_0(WR_PARAM_ADDR_0 + 22 )(11 downto 8);--4-bit
	tbm_emul_v1_hit_nb(0)(1)(3)				<= glib_pix_emul_param_o_resync_clk_40_0(WR_PARAM_ADDR_0 + 22 )(15 downto 12);--4-bit
	tbm_emul_v1_hit_nb(0)(1)(4)				<= glib_pix_emul_param_o_resync_clk_40_0(WR_PARAM_ADDR_0 + 22 )(19 downto 16);--4-bit
	tbm_emul_v1_hit_nb(0)(1)(5)				<= glib_pix_emul_param_o_resync_clk_40_0(WR_PARAM_ADDR_0 + 22 )(23 downto 20);--4-bit
	tbm_emul_v1_hit_nb(0)(1)(6)				<= glib_pix_emul_param_o_resync_clk_40_0(WR_PARAM_ADDR_0 + 22 )(27 downto 24);--4-bit
	tbm_emul_v1_hit_nb(0)(1)(7)				<= glib_pix_emul_param_o_resync_clk_40_0(WR_PARAM_ADDR_0 + 22 )(31 downto 28);--4-bit
	
	tbm_emul_v1_reset								<= glib_pix_emul_param_o_resync_clk_40_0(WR_PARAM_ADDR_0 + 23 )(0);
	PKAM_Reset_v1									<= glib_pix_emul_param_o_resync_clk_40_0(WR_PARAM_ADDR_0 + 24 )(7 downto 0);--8 bit
	PKAM_Constant									<= glib_pix_emul_param_o_resync_clk_40_0(WR_PARAM_ADDR_0 + 24 )(15 downto 8);--5 bit
	PKAM_Enable										<= glib_pix_emul_param_o_resync_clk_40_0(WR_PARAM_ADDR_0 + 24 )(16);--1 bit
	ROC_Clk											<= glib_pix_emul_param_o_resync_clk_40_0(WR_PARAM_ADDR_0 + 25 )(7 downto 0); --8 bit
	

			

--	data_roc_gen : for i_roc in 0 to 7 generate
--		data_ch_gen : for i_ch in 0 to 1 generate
--			tbm_emul_v1_dcol(0)(i_ch)(i_roc)		<= std_logic_vector(to_unsigned(1,3)) & std_logic_vector(to_unsigned(2,3));--6-bit			
--			tbm_emul_v1_row(0)(i_ch)(i_roc)		<= std_logic_vector(to_unsigned(1,3)) & std_logic_vector(to_unsigned(2,3)) & std_logic_vector(to_unsigned(3,3));		
--			tbm_emul_v1_hit(0)(i_ch)(i_roc)		<= std_logic_vector(to_unsigned(65,8));--8-bit
--		end generate;
--	end generate;	

		



   --=============================================================================================================================================--
	-- END S/W I/O Registers Mapping --
   --=============================================================================================================================================--





   --=============================================================================================================================================--
	-- CLOCKING & CLOCK BUFFERS --
   --=============================================================================================================================================--
   --> from xpoint1_clk3 (internal 40-MHz crystal oscillator):
	-----------------------------------------------------------
--	mmcm_40_400_inst : entity work.mmcm_40_400
--	port map
--	(		 -- Clock in ports
--			 CLK_IN1_P 		=> xpoint1_clk3_p,
--			 CLK_IN1_N 		=> xpoint1_clk3_n,
--			 -- Clock out ports
--			 CLK_OUT1	 	=> clk_400_0,
--			 -- Status and control signals
--			 RESET  			=> '0',
--			 LOCKED 			=> open
--	 );

--   -- Fabric clock (40MHz) :
--   -------------------------       
--   xpoint1_clk3_ibufgds_inst: IBUFGDS
--      generic map (
--         IBUF_LOW_PWR                           => FALSE,
--         IOSTANDARD                             => "LVDS_25")
--      port map (                 
--         O                                      => xpoint1_clk3_ibufgds,
--         I                                      => XPOINT1_CLK3_P,
--         IB                                     => XPOINT1_CLK3_N
--      );
--   
--   xpoint1_clk3_bufg_inst: bufg               
--      port map (              
--         O                                      => xpoint1_clk3_bufg,
--         I                                      => xpoint1_clk3_ibufgds 
--      );   

  

   --> from PIXFED + CDCE through CDCE_CLK2_IN + cdce_out4 (320MHz):
   -----------------------------------------------------------------   
	--================--
   -- RX INPUT CLOCK --
   --================-- 
	rx_clk_in_bufg_inst: bufg               
      port map (              
         O					=> rx_clk_in_bufg, 
         I					=> rx_clk_in  --40-MHz from PIXFED
      ); 
	--===================--
   -- CDCE CLK2 SETTING --
   --===================--
	sec_clk_o				<= rx_clk_in_bufg; --rx_clk_in / rx_clk_in_bufg	
--	--
--	sec_clk_o_obuf:obuf 
--	generic map
--	(
--		drive       		=> 12,
--		iostandard  		=> "lvcmos25",
--		slew        		=> "slow"
--	)
--	port map
--	(
--		i 						=> sec_clk, 
--		o 						=> sec_clk_o
--	);
--	
--	sec_clk_oddr_inst : ODDR 
--	generic map(
--		DDR_CLK_EDGE 	=> "OPPOSITE_EDGE", 	-- "OPPOSITE_EDGE" or "SAME_EDGE" 
--		INIT 				=> '0',   				-- Initial value for Q port ('1' or '0')
--		SRTYPE 			=> "SYNC") 				-- Reset Type ("ASYNC" or "SYNC")
--	port map (
--		-- 1-bit DDR output
--		Q 					=> sec_clk_o,				
--		-- 1-bit clock input
--		C 					=> rx_clk_in_bufg,    																		
--		-- 1-bit clock enable input
--		CE 				=> '1',  																				
--		-- 1-bit data input (positive edge)
--		D1 				=> '0',   																				
--		-- 1-bit data input (negative edge)
--		D2 				=> '1',   																				
--		-- 1-bit reset input
--		R 					=> '0',   																				
--		-- 1-bit set input
--		S 					=> '0'     				
--	);	
	--====================--
   -- CDCE CLK SWITCHING --
   --====================--	
	user_cdce_sel_o 			<= '0';	 	-- clk2 	
	user_cdce_sync_o 			<= '1'; 		-- DIS by def
--	user_cdce_sel_o 			<= user_cdce_sel;	 -- clk2 by def 	
--	user_cdce_sync_o 			<= user_cdce_sync; -- DIS by def
--	--
--	process
--	variable cnt : integer range 0 to 15 := 15;
--	begin
--		--
--		if rising_edge(ipb_clk_i) then
--			--
--			case cdce_state is
--				--
--				when idle =>
--					if mmcm1_lock = '1' and mmcm2_lock = '1' and reset_i = '0' then --normalement lock sur rx_clk_in
--						user_cdce_sel  		<= '0'; -- clk2
--						cdce_state 				<= s1;
--					else
--						user_cdce_sync  		<= '1'; -- DIS by def		
--						user_cdce_sel  		<= '1'; -- clk1 by def
--						cnt						:= 15;						
--					end if;
--				--
--				when s1 =>	
--					if cnt = 0 then
--						cdce_state 				<= s2;						
--					else
--						cnt 						:= cnt - 1;
--					end if;
--				--
--				when s2 =>			
--					user_cdce_sync  			<= '0'; -- EN
--					cdce_state 					<= s3;					
--				--
--				when s3 =>			
--					user_cdce_sync  			<= '1'; -- DIS
--				--
--				when others => 
--					null;
--			--
--			end case;
--		--
--		end if;
--	end process;
	--=========--
   -- BUFFERS --
   --=========--
	cdce_out4_ibufgds_ibufgds_inst: IBUFGDS
	generic map 
	(
		IBUF_LOW_PWR		=> FALSE,
		IOSTANDARD        => "LVDS_25"
	)
	port map 
	(                 
		O 						=> cdce_out4_ibufgds,
		I 						=> cdce_out4_p,
		IB 					=> cdce_out4_n
    );

   --========--
   -- MMCM 1 -- 
   --========-- 
	mmcm1_320in_inst : entity work.mmcm1_320in
	port map
		(		
			-- Clock in ports
			 CLK_IN1 		=> xpoint1_clk3_bufg, --cdce_out4_ibufgds,
			 -- Clock out ports
			 CLK_OUT1 		=> clk_400_0,
			 CLK_OUT2 		=> clk_400_45,
			 CLK_OUT3 		=> clk_400_90,
			 CLK_OUT4 		=> clk_400_135,
			 CLK_OUT5 		=> clk_200_0,
			 --if added in ipcore
			 CLK_OUT6 		=> clk_80_0,
			 CLK_OUT7 		=> clk_40_0,
			 -- Status and control signals
			 RESET  			=> '0',
			 LOCKED 			=> mmcm1_lock
		);
	mmcm_lock <= mmcm1_lock;
--   --========--
--   -- MMCM 2 -- 
--   --========-- 
--	mmcm2_320in_inst : entity work.mmcm2_320in
--	port map
--		(		
--			-- Clock in ports
--			 CLK_IN1 		=> cdce_out4_ibufgds,
--			 -- Clock out ports
--			 CLK_OUT1 		=> clk_320_0,
--			 CLK_OUT2 		=> clk_160_0,
--			 CLK_OUT3 		=> clk_80_0,
--			 CLK_OUT4 		=> clk_40_0,
--			 CLK_OUT5		=> clk_120_0,
--			 -- Status and control signals
--			 RESET  			=> '0',
--			 LOCKED 			=> mmcm2_lock
--		);
--
--	mmcm_lock <= mmcm1_lock and mmcm2_lock;

   --=============================================================================================================================================--
	-- END CLOCKING --
   --=============================================================================================================================================--



   --=============================================================================================================================================--
	-- SMA INSPECTION --
   --=============================================================================================================================================--
	fpga_clkout_o 			<= clk_40_0; --int_trigger;--tbm_fifo_wr_en(0,0); --clk_40_0;
   --=============================================================================================================================================--
	-- END SMA INSPECTION --
   --=============================================================================================================================================--



	user_reset 				<= reset_i or not SW_CONFIG_OK;
	

	
--	---------------********************************TRIGGER************************************----------------
--	--===============================================================================================--
--	process --internal trigger
--	--===============================================================================================--	
--	variable int_trigger_counter : integer range 0 to 40e6:=0; 
--	begin
--		wait until rising_edge(clk_40_0); --40M
--			if  user_reset = '1' or int_trigger = '1' then --reset_from_or_gate / SW_CONFIG_OK / reset_i
--				int_trigger_counter 	:= 0;
--				int_trigger 			<= '0';
--			else
--				int_trigger_counter := int_trigger_counter + 1;
--				--
--				if 	unsigned(SW_INT_TRIGGER_FREQ_SEL) = 0 		and int_trigger_counter = 40e6  		then 	int_trigger <= '1'; --1Hz
--				elsif unsigned(SW_INT_TRIGGER_FREQ_SEL) = 1 		and int_trigger_counter = 20e6  		then 	int_trigger <= '1'; --2Hz 
--				elsif unsigned(SW_INT_TRIGGER_FREQ_SEL) = 2 		and int_trigger_counter = 10e6  		then 	int_trigger <= '1'; --4Hz
--				elsif unsigned(SW_INT_TRIGGER_FREQ_SEL) = 3 		and int_trigger_counter = 5e6  		then 	int_trigger <= '1'; --8Hz
--				elsif unsigned(SW_INT_TRIGGER_FREQ_SEL) = 4 		and int_trigger_counter = 2500000  	then 	int_trigger <= '1'; --16Hz
--				elsif unsigned(SW_INT_TRIGGER_FREQ_SEL) = 5 		and int_trigger_counter = 1250000 	then 	int_trigger <= '1'; --32Hz
--				elsif unsigned(SW_INT_TRIGGER_FREQ_SEL) = 6 		and int_trigger_counter = 625000		then 	int_trigger <= '1'; --64Hz
--				elsif unsigned(SW_INT_TRIGGER_FREQ_SEL) = 7 		and int_trigger_counter = 312500		then 	int_trigger <= '1'; --128Hz
--				elsif unsigned(SW_INT_TRIGGER_FREQ_SEL) = 8 		and int_trigger_counter = 156250		then 	int_trigger <= '1'; --256Hz
--				elsif unsigned(SW_INT_TRIGGER_FREQ_SEL) = 9 		and int_trigger_counter = 78125		then 	int_trigger <= '1'; --512Hz
--				elsif unsigned(SW_INT_TRIGGER_FREQ_SEL) = 10 	and int_trigger_counter = 39062  	then 	int_trigger <= '1'; --1024Hz
--				elsif unsigned(SW_INT_TRIGGER_FREQ_SEL) = 11 	and int_trigger_counter = 19531  	then 	int_trigger <= '1'; --2048Hz
--				elsif unsigned(SW_INT_TRIGGER_FREQ_SEL) = 12 	and int_trigger_counter = 9766  		then 	int_trigger <= '1'; --4096Hz	
--				elsif unsigned(SW_INT_TRIGGER_FREQ_SEL) = 13 	and int_trigger_counter = 4883  		then 	int_trigger <= '1'; --8192Hz
--				elsif unsigned(SW_INT_TRIGGER_FREQ_SEL) = 14 	and int_trigger_counter = 2441  		then 	int_trigger <= '1'; --16384Hz
--				elsif unsigned(SW_INT_TRIGGER_FREQ_SEL) = 15 	and int_trigger_counter = 1221  		then 	int_trigger <= '1'; --32768Hz					
--				else 																								
--					int_trigger <= '0';
--				end if; 
--				--
--			end if;
--	end process;			
--	--===============================================================================================--		


	
   --=============================================================================================================================================--
	-- Reset and Trigger from PIXFED --
   --=============================================================================================================================================--
	--> Trigger:
	------------
	process
	begin
	wait until rising_edge(clk_40_0);
		rx_trig_in_del(0) 		<= rx_trig_in;
		rx_trig_in_del(1) 		<= rx_trig_in_del(0);
		rx_trig_in_del(2) 		<= rx_trig_in_del(1);
	end process;
	--
	process (mmcm_lock, clk_40_0)
	begin
		if mmcm_lock = '0' then
			rx_trig_in_pulse 		<= '0';
		elsif rising_edge(clk_40_0) then
			rx_trig_in_pulse  	<= rx_trig_in_del(2) xnor rx_trig_in_del(1); --NRZ_INV
		end if;
	end process;
	

	--> Reset:
	----------
	process
	begin
	wait until rising_edge(clk_40_0);
		rx_reset_in_del(0) 		<= rx_reset_in;
		rx_reset_in_del(1) 		<= rx_reset_in_del(0);
		rx_reset_in_del(2) 		<= rx_reset_in_del(1);
	end process;	
	--
	process (mmcm_lock, clk_40_0)
	begin
		if mmcm_lock = '0' then
			rx_reset_in_pulse 	<= '0'; 
		elsif rising_edge(clk_40_0) then
			rx_reset_in_pulse  	<= rx_reset_in_del(2) xnor rx_reset_in_del(1); --NRZ_INV
		end if;
	end process;
   --=============================================================================================================================================--
	-- END Reset and Trigger from PIXFED --
   --=============================================================================================================================================--	


	
   --=============================================================================================================================================--
	-- PIXEL EMULATOR -- --
   --=============================================================================================================================================--
	
	i_dualTBM_gen : for i in 0 to TBM_EMUL_NB - 1 generate
		dualTBM_emulator_inst : entity work.dualTBM_emulator
		generic map (
					EMUL_VERSION							=>  "V1"			-- V1 : by FSM
																					-- V2 : by Memory (not yet)
																					-- V3 : after interleaving 	/ 	test with interleaved data emulating "7FC" defined in hard
																					-- V4 : before interleaving 	/ 	test with "7FC" defined in hard
						)
		port map(
					clk_40_0_i 								=> clk_40_0,
					clk_80_0_i 								=> clk_80_0,
					clk_400_0_i 							=> clk_400_0,
					TTC_data_out							=> TTC_data_out,
					Brcst										=> Brcst,
					brcststr									=> brcststr,
					PKAM_Reset								=> PKAM_Reset_v1,
					PKAM_Enable								=> PKAM_Enable,
					PKAM_Constant							=> PKAM_Constant,
					PKAM_Buffer								=> PKAM_Buffer,
					ROC_Timer_Buffer						=> ROC_Timer_Buffer,
					ROC_Clk									=> ROC_Clk,
					--
					sclr_i 									=> tbm_emul_v1_reset,--BCntRes,--rx_reset_in_pulse, --active-high
					--
					trigger_i 								=> L1Accept,--rx_trig_in_pulse, --int_trigger,
					trigger_en_i 							=> '1',
					L1A_count								=> L1A_count,
					EvCntRes									=> EvCntRes,
					--
					tbm_ch_start_i	 						=> "11",--"01", --tbm_ch_start(i),  --(0)=chA (1)=chB
					--v1 param
					tbm_emul_v1_hit_nb_ROC_mode_i		=> tbm_emul_v1_hit_nb_ROC_mode(i),--"0000" : 0 / "1111" : 15
					tbm_emul_v1_matrix_mode_i 			=> tbm_emul_v1_matrix_mode(i),
					tbm_emul_v1_hit_data_mode_i		=> tbm_emul_v1_hit_data_mode(i),					
					--
					tbm_emul_v1_ROC_nb_i					=> tbm_emul_v1_ROC_nb(i), --[0:8] with 1<=>1
					--
					tbm_emul_v1_hit_nb_i					=> tbm_emul_v1_hit_nb(i),
					--
					tbm_emul_v1_dcol_i					=> tbm_emul_v1_dcol(i),--2 words in base-6, translation from bin to this format made in s/w	
					tbm_emul_v1_row_i						=> tbm_emul_v1_row(i),--3 words in base-6, translation from bin to this format made in s/w	
					tbm_emul_v1_hit_i						=> tbm_emul_v1_hit(i),		
					tbm_emul_v1_header_flag_i			=> tbm_emul_v1_header_flag(i),
					tbm_emul_v1_trailer_flag1_i 		=> tbm_emul_v1_trailer_flag1(i),
					tbm_emul_v1_trailer_flag2_i		=> tbm_emul_v1_trailer_flag2(i),
					--
					tbm_chB_delaying_i					=> tbm_chB_delaying(i), --[0-255 clk40 cycles]
					--v2 param
					tbm_chA_loop_nb_i						=> (others =>'0'),	
					tbm_chB_loop_nb_i						=> (others =>'0'),				
					--storage memory
					tbm_chA_mem_data_i					=> (others =>'0'),	
					tbm_chB_mem_data_i					=> (others =>'0'),	
					tbm_chA_mem_addr_o					=> open,	
					tbm_chB_mem_addr_o					=> open,					
					tbm_chA_mem_rd_en_o 					=> open,	
					tbm_chB_mem_rd_en_o 					=> open,	
					--INSPEC
					--initial channels
					tbm_chA_word4b_sync40M_o  			=> tbm_chA_word4b_sync40M, --open,	
					tbm_chB_word4b_sync40M_o  			=> tbm_chB_word4b_sync40M, --open,	
					tbm_chA_word4b_sync80M_o  			=> tbm_chA_word4b_sync80M, --open,	
					tbm_chB_word4b_sync80M_o  			=> tbm_chB_word4b_sync80M, --open,			
					--4b/5b encoding
					tx_symb4b_o								=> tx_symb4b, --open,	
					tx_symb5b_o								=> tx_symb5b, --open,			
					--OUT
					tx_sdout_o 								=> tx_tbm_sdout(i)
		);
	end generate;
   --=============================================================================================================================================--
	-- END PIXEL EMULATOR --
   --=============================================================================================================================================--

end user_logic_arch;