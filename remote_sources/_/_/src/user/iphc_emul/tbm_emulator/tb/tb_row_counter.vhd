--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   11:51:21 01/12/2015
-- Design Name:   
-- Module Name:   C:/VHDL/CMS/ISE14.6/PixFED/TEST_IPHC/vhdl/src/user/iphc_readout/TBM_emulator/tb/tb_row_counter.vhd
-- Project Name:  glib_v3_pixfed
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: row_counter
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
--USE ieee.numeric_std.ALL;
 
ENTITY tb_row_counter IS
END tb_row_counter;
 
ARCHITECTURE behavior OF tb_row_counter IS 
 

    

   --Inputs
   signal clk_i 						: std_logic := '0';
   signal sclr_i 						: std_logic := '0';
   signal row_cnt_en_i 				: std_logic := '0';

 	--Outputs
   signal row_cnt_o	 				: std_logic_vector(8 downto 0);

   -- Clock period definitions
   constant clk_i_period 			: time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   row_counter_inst : entity work.row_counter 
	PORT MAP (
				 clk_i 				=> clk_i,
				 sclr_i 				=> sclr_i,
				 row_cnt_en_i 		=> row_cnt_en_i,
				 row_cnt_o 			=> row_cnt_o
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
		row_cnt_en_i <= '1';

      wait;
   end process;

END;
