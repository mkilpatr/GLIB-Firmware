--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   11:21:14 01/12/2015
-- Design Name:   
-- Module Name:   C:/VHDL/CMS/ISE14.6/PixFED/TEST_IPHC/vhdl/src/user/iphc_readout/tb/tb_dcol_counter.vhd
-- Project Name:  glib_v3_pixfed
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: dcol_counter
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE ieee.numeric_std.ALL;
 
ENTITY tb_dcol_counter IS
END tb_dcol_counter;
 
ARCHITECTURE behavior OF tb_dcol_counter IS 
 

   --Inputs
   signal clk_i 					: std_logic := '0';
   signal sclr_i 					: std_logic := '0';
   signal dcol_cnt_en_i 		: std_logic := '0';

 	--Outputs
   signal dcol_cnt_o 			: std_logic_vector(5 downto 0);

   -- Clock period definitions
   constant clk_i_period 		: time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   dcol_counter_inst: entity work.dcol_counter 
	PORT MAP (
				 clk_i 				=> clk_i,
				 sclr_i 				=> sclr_i,
				 dcol_cnt_en_i 	=> dcol_cnt_en_i,
				 dcol_cnt_o 		=> dcol_cnt_o
        );

   -- Clock process definitions
   clk_i_process :process
   begin
		clk_i <= '0';
		wait for clk_i_period/2;
		clk_i <= '1';
		wait for clk_i_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      sclr_i <= '1';
      wait for 114 ns;	
		sclr_i <= '0';
      wait for clk_i_period*2;		
		dcol_cnt_en_i <= '1';

      wait;
   end process;

END;
