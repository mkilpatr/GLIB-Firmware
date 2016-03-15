library ieee;
use ieee.std_logic_1164.all;
 
package user_package is

	--=== system options ========--
   constant sys_eth_p1_enable       : boolean  := false;   
   constant sys_pcie_enable         : boolean  := false;      
  
	--=== i2c master components ==--
	constant i2c_master_enable			: boolean  := true;
	constant auto_eeprom_read_enable	: boolean  := true;    

	--=== wishbone slaves ========--
	constant number_of_wb_slaves		: positive := 2 ;
	
	constant user_wb_glib_pix_emul_param	: integer  := 0 ;
	constant user_wb_regs				: integer  := 1 ;

--	constant user_wb_timer				: integer  := 1 ;    
	
	
	--=== ipb slaves =============--
	constant number_of_ipb_slaves		: positive := 6; --2 ;   TWN 3/8/2016  Was 4,  Change to 6

	
	constant ipb_vi2c_0                 : integer := 0;
   constant ipb_track_0                : integer := 1;
   constant ipb_regs_0                 : integer := 2;
   constant ipb_info_0                 : integer := 3;
	
   constant user_ipb_stat_regs 		: integer  := 0 ;
	constant user_ipb_ctrl_regs	   : integer  := 1 ;
	constant user_ipb_regs				: integer := 0 ;
	
	constant fmcfitel_i2c_ctrl_fifo_tx_sel	: integer  := 4 ;	 -- As in FC7 user_pkg  TWN 2/26/2016  -- ??? --
	constant fmcfitel_i2c_ctrl_fifo_rx_sel	: integer  := 5 ;	 -- As in FC7 user_pkg  TWN 2/26/2016  -- ??? --
		
	--Matt added package types
	
	--=== Package types ==========--
    
    constant def_gtp_idle       : std_logic_vector(7 downto 0) := x"00";  
    constant def_gtp_vi2c       : std_logic_vector(7 downto 0) := x"01";  
    constant def_gtp_tracks     : std_logic_vector(7 downto 0) := x"02";  
    constant def_gtp_regs       : std_logic_vector(7 downto 0) := x"03";  
    constant def_gtp_trigger    : std_logic_vector(7 downto 0) := x"04";  
	 
	 --Matt added
	 
	 constant def_gtx_idle               : std_logic_vector(7 downto 0) := x"00";  
    constant def_gtx_vi2c               : std_logic_vector(7 downto 0) := x"01";  
    constant def_gtx_tracks             : std_logic_vector(7 downto 0) := x"02";  
    constant def_gtx_regs               : std_logic_vector(7 downto 0) := x"03"; 
    constant def_gtx_trigger            : std_logic_vector(7 downto 0) := x"04"; 
    
    --=== Custom types ==========--
    
    type array192 is array(integer range <>) of std_logic_vector(191 downto 0);

    type array32 is array(integer range <>) of std_logic_vector(31 downto 0);
	 
	
end user_package;
   
package body user_package is
end user_package;