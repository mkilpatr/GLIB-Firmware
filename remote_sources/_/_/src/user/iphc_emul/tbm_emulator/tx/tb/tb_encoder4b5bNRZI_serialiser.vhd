--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   16:04:41 01/09/2015
-- Design Name:   
-- Module Name:   C:/VHDL/CMS/ISE14.6/PixFED/TEST_IPHC/vhdl/src/user/iphc_readout/TBM_emulator/tx/tb/tb_encoder4b5bNRZI_serialiser.vhd
-- Project Name:  glib_v3_pixfed
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: encoder4b5bNRZI_serialiser
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
 
ENTITY tb_encoder4b5bNRZI_serialiser IS
END tb_encoder4b5bNRZI_serialiser;
 
ARCHITECTURE behavior OF tb_encoder4b5bNRZI_serialiser IS 
 

    

   --Inputs
   signal clk_80_0_i : std_logic := '0';
   signal clk_400_0_i : std_logic := '0';
   signal sclr_i : std_logic := '1';
   signal symb4b_i : std_logic_vector(3 downto 0) := x"A";

 	--Outputs
   signal symb4b_o : std_logic_vector(3 downto 0);
   signal symb5b_o : std_logic_vector(4 downto 0);
   signal tx_serial_dout_o : std_logic;

   -- Clock period definitions
   constant clk_80_0_i_period 	: time := 40 ns;
   constant clk_400_0_i_period 	: time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   encoder4b5bNRZI_serialiser_inst: entity work.encoder4b5bNRZI_serialiser 
	PORT MAP (
          clk_80_0_i 			=> clk_80_0_i,
          clk_400_0_i 			=> clk_400_0_i,
          sclr_i 					=> sclr_i,
          symb4b_i 				=> symb4b_i,
          symb4b_o 				=> symb4b_o,
          symb5b_o 				=> symb5b_o,
          tx_serial_dout_o 	=> tx_serial_dout_o
        );

   -- Clock process definitions
   clk_80_0_i_process :process
   begin
		clk_80_0_i <= '0';
		wait for clk_80_0_i_period/2;
		clk_80_0_i <= '1';
		wait for clk_80_0_i_period/2;
   end process;
 
   clk_400_0_i_process :process
   begin
		clk_400_0_i <= '0';
		wait for clk_400_0_i_period/2;
		clk_400_0_i <= '1';
		wait for clk_400_0_i_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      sclr_i 			<= '1';
      symb4b_i 		<= x"A";		
		wait for 113 ns;	
      sclr_i 			<= '0';


      wait for clk_80_0_i_period*10;
 
      wait for clk_80_0_i_period*1;
      symb4b_i 		<= x"3"; 
      wait for clk_80_0_i_period*1;
      symb4b_i 		<= x"A"; 		
      wait for clk_80_0_i_period*1;
      symb4b_i 		<= x"8"; 		
	   wait for clk_80_0_i_period*1;
      symb4b_i 		<= x"2"; 	
	   wait for clk_80_0_i_period*1;
      symb4b_i 		<= x"A"; 
      wait;
   end process;

END;
