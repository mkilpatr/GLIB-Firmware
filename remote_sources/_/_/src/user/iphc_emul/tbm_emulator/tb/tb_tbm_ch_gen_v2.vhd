--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   10:29:04 01/16/2015
-- Design Name:   
-- Module Name:   C:/VHDL/CMS/ISE14.6/PixFED/TEST_IPHC/vhdl/src/user/iphc_readout/TBM_emulator/tb/tb_tbm_ch_gen_v2.vhd
-- Project Name:  glib_v3_pixfed
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: tbm_ch_gen_v2
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
 
ENTITY tb_tbm_ch_gen_v2 IS
END tb_tbm_ch_gen_v2;
 
ARCHITECTURE behavior OF tb_tbm_ch_gen_v2 IS 
 
    

   --Inputs
   signal clk_i 									: std_logic := '0';
   signal sclr_i 									: std_logic := '0';
   signal start_i 								: std_logic := '0';
   signal trigger_i 								: std_logic := '0';
   signal trigger_mode_i 						: std_logic := '0';	
   signal mem_data_i 							: std_logic_vector(31 downto 0) := (others => '0');
   signal loop_nb_i 								: std_logic_vector(15 downto 0) := (others => '0');

 	--Outputs
   signal mem_cs_o 								: std_logic;	
   signal mem_rd_en_o 							: std_logic;	
   signal mem_addr_o 							: std_logic_vector(15 downto 0);
   signal ch_word4b_o 							: std_logic_vector(3 downto 0);

   -- Clock period definitions
   constant clk_i_period 						: time := 10 ns;
	
	
	type mem_typ 									is array (65535 downto 0) of std_logic_vector(31 downto 0);
	signal mem 										: mem_typ := (others => (others => '0'));	
	
 
BEGIN
 

	--> possibility to take part of EndDataWord(15 downto 0)
 
--	mem(0) <= x"7"&x"7FC0100"; --T_H
--	mem(1) <= x"3"&x"7F80000";	--R_H
--	mem(2) <= x"6"&x"1234560"; --D	
--	mem(3) <= x"5"&x"7ff0000"; --T_T	
----	mem(4) <= x"f"&x"0000000";	--End	
--	mem(4) <= x"8"&x"0000002";	--Wait	
--	mem(5) <= x"f"&x"0000000";	--End	

--	mem(0) <= x"7"&x"FFFFFFA"; --T_H
--	mem(1) <= x"7"&x"7FC0100"; --T_H
--	mem(2) <= x"3"&x"7F80000";	--R_H
--	mem(3) <= x"6"&x"1234560"; --D	
--	mem(4) <= x"5"&x"7ff0000"; --T_T	
--	mem(5) <= x"8"&x"0000000";	--Wait	
--	mem(6) <= x"7"&x"AAAAAAA"; --MARKER
--	mem(7) <= x"f"&x"0000000";	--End	

	--TRAME1
	mem(0)  <= x"7"&x"FFFFFF1"; --T_H
	mem(1)  <= x"7"&x"7FC0100"; --T_H
	mem(2)  <= x"3"&x"7F80000"; --R_H
	mem(3)  <= x"6"&x"1234560"; --D	
	mem(4)  <= x"5"&x"7ff0000"; --T_T	
	mem(5)  <= x"8"&x"0000000"; --Wait	
	--TRAME2
	mem(6)  <= x"7"&x"FFFFFF2"; --T_H
	mem(7)  <= x"7"&x"7FC0200"; --T_H
	mem(8)  <= x"3"&x"7F80000"; --R_H
	mem(9)  <= x"6"&x"789abc0"; --D	
	mem(10) <= x"5"&x"7ff0000"; --T_T	
	mem(11) <= x"8"&x"0000000"; --Wait	
	--END
	mem(12) <= x"f"&x"0000000"; --End	
	



--	--wait first ok
--	mem(0) <= x"8"&x"0000010";	--Wait
--	mem(1) <= x"8"&x"0000010";	--Wait
--	mem(2) <= x"7"&x"7FC0100"; --T_H
--	mem(3) <= x"3"&x"7F80000";	--R_H
--	mem(4) <= x"6"&x"1234560"; --D	
--	mem(5) <= x"5"&x"7ff0000"; --T_T	
--	mem(6) <= x"8"&x"0000002";	--Wait	
--	mem(7) <= x"f"&x"0000000";	--End	

--	-->no double wait states!!!
--	mem(0) <= x"7"&x"7FC0100";
--	mem(1) <= x"3"&x"7F80000";
--	mem(2) <= x"6"&x"1234560";	
--	mem(3) <= x"5"&x"7ff0000";	
--	mem(4) <= x"8"&x"000000f";	
--	mem(5) <= x"8"&x"000000f";	
--	mem(6) <= x"f"&x"0000000";
	




	
	process
	begin
		wait until rising_edge(clk_i);
			if mem_rd_en_o = '1' then
				mem_data_i <= mem(to_integer(unsigned(mem_addr_o)));
			end if;
	end process;
	
	-- Instantiate the Unit Under Test (UUT)
   tbm_ch_gen_v2_uut: entity work.tbm_ch_gen_v2 
	PORT MAP (
					clk_i 						=> clk_i,
					sclr_i 						=> sclr_i,
					start_i 						=> start_i,
					trigger_i					=> trigger_i,
					trigger_mode_i				=>	trigger_mode_i,			 
					mem_cs_o						=> mem_cs_o,
					mem_rd_en_o 				=> mem_rd_en_o,
					mem_addr_o 					=> mem_addr_o,
					mem_data_i 					=> mem_data_i,
					ch_word4b_o 				=> ch_word4b_o,
					loop_nb_i 					=> loop_nb_i
        );

   -- Clock process definitions
   clk_i_process :process
   begin
		clk_i <= '0';
		wait for clk_i_period/2;
		clk_i <= '1';
		wait for clk_i_period/2;
   end process;
 

	loop_nb_i <= std_logic_vector(to_unsigned(2,loop_nb_i'length));

   -- Stimulus process
   stim_proc: process
   begin		
      sclr_i 				<= '1';
		trigger_mode_i		<= '1';
      wait for clk_i_period*5.2;
      sclr_i 				<= '0';
      -- insert stimulus here 
      wait for clk_i_period*2;
		start_i 				<= '1';		
      
		wait for clk_i_period*3;
		trigger_i 			<= '1';	
      wait for clk_i_period;
		trigger_i 			<= '0';



		wait for clk_i_period*80;
		trigger_i 			<= '1';	
      wait for clk_i_period;
		trigger_i 			<= '0';

		wait for clk_i_period*80;
		trigger_i 			<= '1';	
      wait for clk_i_period;
		trigger_i 			<= '0';

		
      wait;
   end process;

END;
