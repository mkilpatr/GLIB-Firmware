library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use work.ipbus.all;
use work.user_package.all;

package user_addr_decode is

	function user_wb_addr_sel (signal addr : in std_logic_vector(31 downto 0)) return integer;
	function user_ipb_addr_sel(signal addr : in std_logic_vector(31 downto 0)) return integer;

end user_addr_decode;

package body user_addr_decode is

	function user_ipb_addr_sel(signal addr : in std_logic_vector(31 downto 0)) return integer is
		variable sel : integer;
	begin
		--              addr, "00------------------------------" is reserved (system ipbus fabric)
		if    std_match(addr, "01000000000000000000000000------") then  	sel := user_ipb_stat_regs;
		elsif std_match(addr, "01000000000000000000000001------") then  	sel := user_ipb_ctrl_regs;	
		--elsif std_match(addr, "01000000000000000000000100000000") then		sel := user_ipb_timer; -- xx
		--              addr, "1-------------------------------" is reserved (wishbone fabric)
	
		
		--elsif std_match(addr, "010000000000000100000-----------") then sel := ipb_vi2c_0;   -- 0x4001XXYY     0 <= XX <= 7    8 <= XX <= 15  16 <= XX <= 23
      --elsif std_match(addr, "0100000000000010000000000000----") then sel := ipb_track_0;  -- 0x4002000X  
      --elsif std_match(addr, "0100000000000011000000000-------") then sel := ipb_regs_0;   -- 0x400300XX  
		elsif std_match(addr, "010000000000010000000000--------") then sel := ipb_info_0;   -- 0x400400XX
--
--
--Added decoding for FITEL i2c FIFOs  TWN 3/1/2016:
------
		elsif std_match(addr, "01000000000100000000000000000000") then sel := fmcfitel_i2c_ctrl_fifo_tx_sel;    --  0x40100000
		elsif std_match(addr, "01000000000100000000000000000001") then sel := fmcfitel_i2c_ctrl_fifo_rx_sel;    --  0x40100001 

		else         
				sel := 99;
		end if;
		
		return sel;
	end user_ipb_addr_sel;


   function user_wb_addr_sel(signal addr : in std_logic_vector(31 downto 0)) return integer is
		variable sel : integer;
   begin
		--              addr, "00------------------------------" is reserved (system ipbus fabric)
		--              addr, "01------------------------------" is reserved (user ipbus fabric)

		if		std_match(addr, "100000000000000000000000--------") then  	sel := user_wb_glib_pix_emul_param; 	--see user_package.vhd / just 32 @ are reserved

		---->BASE_ADDR = x"80000000"
		
		elsif std_match(addr, "100100000000000000000000--------") then  	sel := user_wb_regs; --0x900000XX
		
		else
			sel := 99;
		end if;
		
		return sel;
	end user_wb_addr_sel; 

end user_addr_decode;


