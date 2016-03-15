--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   16:36:17 01/12/2015
-- Design Name:   
-- Module Name:   C:/VHDL/CMS/ISE14.6/PixFED/TEST_IPHC/vhdl/src/user/iphc_readout/TBM_emulator/tb/tb_tbm_ch_gen_v1.vhd
-- Project Name:  glib_v3_pixfed
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: tbm_ch_gen_v1
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
 
ENTITY tb_tbm_ch_gen_v1 IS
END tb_tbm_ch_gen_v1;
 
ARCHITECTURE behavior OF tb_tbm_ch_gen_v1 IS 
 

    

   --Inputs
   signal clk_i 								: std_logic := '0';
   signal sclr_i 								: std_logic := '0';
   signal start_i 							: std_logic := '0';
   signal trigger_i 							: std_logic := '0';	
   signal trigger_en_i 						: std_logic := '0';		
--   signal gen_mode_i 						: std_logic_vector(3 downto 0) := (others => '0');
--   signal ROC_nb_i 							: std_logic_vector(2 downto 0) := (others => '0');
--   signal ROC_hit_en_i 						: std_logic_vector(7 downto 0) := (others => '0');


	--param
	--HIT_NB_ROC_MODE
	--"0000" : fixed (predefined values updated from s/w) 
	--"0001" : cnt from [0:15]; incremented for each new frame (not yet)
	--"0010" : pseudo-random (not yet)					
   signal hit_nb_ROC_mode_i				: std_logic_vector(3 downto 0);
	--MATRIX_MODE [dcol-row]
	--"0000" : fixed (predefined values updated from s/w) 
	--"0001" : cnt; but if several hits/roc => same value; incremented for each new frame; common for all ROC & Hit/ROC
	--"0010" : pseudo-random (not yet)
   signal matrix_mode_i						: std_logic_vector(3 downto 0); 
	--HIT_DATA_MODE
	--MATRIX_MODE [dcol-row]
	--"0000" : fixed (predefined values updated from s/w) 
	--"0001" : cnt (not yet)
	--"0010" : pseudo-random (not yet)					
   signal hit_data_mode_i					: std_logic_vector(3 downto 0);
	--
   signal ROC_nb_i							: std_logic_vector(3 downto 0); --[0:8] with 1<=>1	

   signal hit_nb_ROCn0_i					: std_logic_vector(3 downto 0) := (others => '0'); --"0000" : 0 / "1111" : 15
   signal hit_nb_ROCn1_i					: std_logic_vector(3 downto 0) := (others => '0');
   signal hit_nb_ROCn2_i					: std_logic_vector(3 downto 0) := (others => '0');
   signal hit_nb_ROCn3_i					: std_logic_vector(3 downto 0) := (others => '0');
   signal hit_nb_ROCn4_i					: std_logic_vector(3 downto 0) := (others => '0');
   signal hit_nb_ROCn5_i					: std_logic_vector(3 downto 0) := (others => '0');
   signal hit_nb_ROCn6_i					: std_logic_vector(3 downto 0) := (others => '0');
   signal hit_nb_ROCn7_i					: std_logic_vector(3 downto 0) := (others => '0');
   --
	signal dcol_ROCn0_i 						: std_logic_vector(5 downto 0) := (others => '0');
   signal dcol_ROCn1_i 						: std_logic_vector(5 downto 0) := (others => '0');
   signal dcol_ROCn2_i 						: std_logic_vector(5 downto 0) := (others => '0');
   signal dcol_ROCn3_i 						: std_logic_vector(5 downto 0) := (others => '0');
   signal dcol_ROCn4_i 						: std_logic_vector(5 downto 0) := (others => '0');
   signal dcol_ROCn5_i 						: std_logic_vector(5 downto 0) := (others => '0');
   signal dcol_ROCn6_i 						: std_logic_vector(5 downto 0) := (others => '0');
   signal dcol_ROCn7_i 						: std_logic_vector(5 downto 0) := (others => '0');
   --
	signal row_ROCn0_i 						: std_logic_vector(8 downto 0) := (others => '0');
   signal row_ROCn1_i 						: std_logic_vector(8 downto 0) := (others => '0');
   signal row_ROCn2_i 						: std_logic_vector(8 downto 0) := (others => '0');
   signal row_ROCn3_i	 					: std_logic_vector(8 downto 0) := (others => '0');
   signal row_ROCn4_i 						: std_logic_vector(8 downto 0) := (others => '0');
   signal row_ROCn5_i 						: std_logic_vector(8 downto 0) := (others => '0');
   signal row_ROCn6_i 						: std_logic_vector(8 downto 0) := (others => '0');
   signal row_ROCn7_i 						: std_logic_vector(8 downto 0) := (others => '0');
   signal hit_ROCn0_i 						: std_logic_vector(7 downto 0) := (others => '0');
   signal hit_ROCn1_i 						: std_logic_vector(7 downto 0) := (others => '0');
   signal hit_ROCn2_i 						: std_logic_vector(7 downto 0) := (others => '0');
   signal hit_ROCn3_i 						: std_logic_vector(7 downto 0) := (others => '0');
   signal hit_ROCn4_i 						: std_logic_vector(7 downto 0) := (others => '0');
   signal hit_ROCn5_i 						: std_logic_vector(7 downto 0) := (others => '0');
   signal hit_ROCn6_i 						: std_logic_vector(7 downto 0) := (others => '0');
   signal hit_ROCn7_i 						: std_logic_vector(7 downto 0) := (others => '0');
	--
   signal header_flag_i						: std_logic_vector(7 downto 0) := (others => '0'); -- = [StackFull - PkamReset - StackCount(5:0)]
   signal trailer_flag1_i					: std_logic_vector(7 downto 0) := (others => '0'); -- = [NoTokPass - ResetTBM - ResetROC - SyncErr - SyncTrig - ClrTrigCntr - CalTrig - StackFumm]					
   signal trailer_flag2_i					: std_logic_vector(7 downto 0) := (others => '0'); -- = [DataID(1:0) - D(5:0)]	

 	--Outputs
   signal ch_word4b_o 						: std_logic_vector(3 downto 0);
	signal l1a_count							: std_logic_vector(31 downto 0);
	signal EvCntRes							: std_logic;


   -- Clock period definitions
   constant clk_i_period 					: time := 10 ns;
	
	
	
--	constant CMD0 								: std_logic_vector(gen_mode_i'range) := std_logic_vector(to_unsigned(0,gen_mode_i'length));
--	constant CMD1 								: std_logic_vector(gen_mode_i'range) := std_logic_vector(to_unsigned(1,gen_mode_i'length));	
--	constant CMD2 								: std_logic_vector(gen_mode_i'range) := std_logic_vector(to_unsigned(2,gen_mode_i'length));	
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   tbm_ch_gen_v1_uut: entity work.tbm_ch_gen_v1 
	PORT MAP (
					clk_i 						=> clk_i,
					sclr_i 						=> sclr_i,
					start_i 						=> start_i,
					--
					trigger_i					=> trigger_i,
					trigger_en_i				=> trigger_en_i, --pause_trigger_i : pause/resume to wait new data set         
					--
					ch_word4b_o 				=> ch_word4b_o,
					--param
--					gen_mode_i 					=> gen_mode_i,
--					ROC_nb_i 					=> ROC_nb_i,
--					ROC_hit_en_i 				=> ROC_hit_en_i,
					l1a_count					=> l1A_count,
					EvCntRes						=> EvCntRes,


					--param
					--HIT_NB_ROC_MODE
					--"0000" : fixed (predefined values updated from s/w) 
					--"0001" : cnt from [0:15]; incremented for each new frame (not yet)
					--"0010" : pseudo-random (not yet)					
					hit_nb_ROC_mode_i			=> hit_nb_ROC_mode_i,
					--MATRIX_MODE [dcol-row]
					--"0000" : fixed (predefined values updated from s/w) 
					--"0001" : cnt; but if several hits/roc => same value; incremented for each new frame; common for all ROC & Hit/ROC
					--"0010" : pseudo-random (not yet)
					matrix_mode_i				=> matrix_mode_i, 
					--HIT_DATA_MODE
					--MATRIX_MODE [dcol-row]
					--"0000" : fixed (predefined values updated from s/w) 
					--"0001" : cnt (not yet)
					--"0010" : pseudo-random (not yet)					
					hit_data_mode_i			=> hit_data_mode_i,
					--
					ROC_nb_i						=> ROC_nb_i,  --[0:8] with 1<=>1	
					--
					hit_nb_ROCn0_i				=> hit_nb_ROCn0_i,--"0000" : 0 / "1111" : 15
					hit_nb_ROCn1_i				=> hit_nb_ROCn1_i,
					hit_nb_ROCn2_i				=> hit_nb_ROCn2_i,
					hit_nb_ROCn3_i				=> hit_nb_ROCn3_i,
					hit_nb_ROCn4_i				=> hit_nb_ROCn4_i,
					hit_nb_ROCn5_i				=> hit_nb_ROCn5_i,
					hit_nb_ROCn6_i				=> hit_nb_ROCn6_i,
					hit_nb_ROCn7_i				=> hit_nb_ROCn7_i,
					--
					dcol_ROCn0_i 				=> dcol_ROCn0_i,
					dcol_ROCn1_i 				=> dcol_ROCn1_i,
					dcol_ROCn2_i 				=> dcol_ROCn2_i,
					dcol_ROCn3_i 				=> dcol_ROCn3_i,
					dcol_ROCn4_i 				=> dcol_ROCn4_i,
					dcol_ROCn5_i 				=> dcol_ROCn5_i,
					dcol_ROCn6_i 				=> dcol_ROCn6_i,
					dcol_ROCn7_i 				=> dcol_ROCn7_i,
					--
					row_ROCn0_i 				=> row_ROCn0_i,
					row_ROCn1_i 				=> row_ROCn1_i,
					row_ROCn2_i 				=> row_ROCn2_i,
					row_ROCn3_i 				=> row_ROCn3_i,
					row_ROCn4_i 				=> row_ROCn4_i,
					row_ROCn5_i 				=> row_ROCn5_i,
					row_ROCn6_i 				=> row_ROCn6_i,
					row_ROCn7_i 				=> row_ROCn7_i,
					--
					hit_ROCn0_i 				=> hit_ROCn0_i,
					hit_ROCn1_i 				=> hit_ROCn1_i,
					hit_ROCn2_i 				=> hit_ROCn2_i,
					hit_ROCn3_i 				=> hit_ROCn3_i,
					hit_ROCn4_i 				=> hit_ROCn4_i,
					hit_ROCn5_i 				=> hit_ROCn5_i,
					hit_ROCn6_i 				=> hit_ROCn6_i,
					hit_ROCn7_i 				=> hit_ROCn7_i,
					--
					header_flag_i				=> header_flag_i, 	-- = [StackFull - PkamReset - StackCount(5:0)]
					trailer_flag1_i			=> trailer_flag1_i, 	-- = [NoTokPass - ResetTBM - ResetROC - SyncErr - SyncTrig - ClrTrigCntr - CalTrig - StackFumm]					
					trailer_flag2_i			=> trailer_flag2_i 	-- = [DataID(1:0) - D(5:0)]					
					
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
		l1a_count				<= "00000000000000000000000000000010";
      sclr_i					<= '1';
		EvCntRes					<= '0';
		--
		trigger_i				<= '1';
		trigger_en_i			<= '1';		
		--
--		gen_mode_i				<= CMD1;	
--		ROC_nb_i					<= std_logic_vector(to_unsigned(7,ROC_nb_i'length)); --[0:7]	
--		--ROC_hit_en_i 			<= "11111111";
--		ROC_hit_en_i 			<= "01010101";

		--HIT_NB_ROC_MODE
		--"0000" : fixed (predefined values updated from s/w) 
		--"0001" : cnt from [0:15]; incremented for each new frame (not yet)
		--"0010" : pseudo-random (not yet)					
		hit_nb_ROC_mode_i			<= std_logic_vector(to_unsigned(0,hit_nb_ROC_mode_i'length));
		--MATRIX_MODE [dcol-row]
		--"0000" : fixed (predefined values updated from s/w) 
		--"0001" : cnt; but if several hits/roc => same value; incremented for each new frame; common for all ROC & Hit/ROC
		--"0010" : pseudo-random (not yet)
		matrix_mode_i				<= std_logic_vector(to_unsigned(1,matrix_mode_i'length)); 
		--HIT_DATA_MODE
		--MATRIX_MODE [dcol-row]
		--"0000" : fixed (predefined values updated from s/w) 
		--"0001" : cnt (not yet)
		--"0010" : pseudo-random (not yet)					
		hit_data_mode_i			<= std_logic_vector(to_unsigned(0,hit_data_mode_i'length));
		--
		ROC_nb_i						<= std_logic_vector(to_unsigned(4,ROC_nb_i'length));  --[0:8] with 1<=>1	
		--
		hit_nb_ROCn0_i				<= std_logic_vector(to_unsigned(1,hit_nb_ROCn0_i'length));  --"0000" : 0 / "1111" : 15
		hit_nb_ROCn1_i				<= std_logic_vector(to_unsigned(0,hit_nb_ROCn0_i'length));
		hit_nb_ROCn2_i				<= std_logic_vector(to_unsigned(0,hit_nb_ROCn0_i'length));
		hit_nb_ROCn3_i				<= std_logic_vector(to_unsigned(0,hit_nb_ROCn0_i'length));
		hit_nb_ROCn4_i				<= std_logic_vector(to_unsigned(0,hit_nb_ROCn0_i'length));
		hit_nb_ROCn5_i				<= std_logic_vector(to_unsigned(0,hit_nb_ROCn0_i'length));
		hit_nb_ROCn6_i				<= std_logic_vector(to_unsigned(0,hit_nb_ROCn0_i'length));
		hit_nb_ROCn7_i				<= std_logic_vector(to_unsigned(0,hit_nb_ROCn0_i'length));		
		--dcol
		dcol_ROCn0_i			<= "001" & "000";
		dcol_ROCn1_i			<= "001" & "001";
		dcol_ROCn2_i			<= "001" & "010";
		dcol_ROCn3_i			<= "001" & "011";
		dcol_ROCn4_i			<= "001" & "100";
		dcol_ROCn5_i			<= "001" & "101";
		dcol_ROCn6_i			<= "010" & "000";
		dcol_ROCn7_i			<= "010" & "001";
		--row
		row_ROCn0_i				<= "001" & "001" & "000";
		row_ROCn1_i				<= "001" & "001" & "001";
		row_ROCn2_i				<= "001" & "001" & "010";
		row_ROCn3_i				<= "001" & "001" & "011";
		row_ROCn4_i				<= "001" & "001" & "100";
		row_ROCn5_i				<= "001" & "001" & "101";
		row_ROCn6_i				<= "010" & "001" & "000";
		row_ROCn7_i				<= "010" & "001" & "001";
		--hit
		hit_ROCn0_i				<= std_logic_vector(to_unsigned(127,hit_ROCn0_i'length));
		hit_ROCn1_i				<= std_logic_vector(to_unsigned(127,hit_ROCn1_i'length));
		hit_ROCn2_i				<= std_logic_vector(to_unsigned(127,hit_ROCn2_i'length));
		hit_ROCn3_i				<= std_logic_vector(to_unsigned(127,hit_ROCn3_i'length));
		hit_ROCn4_i				<= std_logic_vector(to_unsigned(127,hit_ROCn4_i'length));
		hit_ROCn5_i				<= std_logic_vector(to_unsigned(127,hit_ROCn5_i'length));
		hit_ROCn6_i				<= std_logic_vector(to_unsigned(127,hit_ROCn6_i'length));		
		hit_ROCn7_i				<= std_logic_vector(to_unsigned(127,hit_ROCn7_i'length));
		
      wait for clk_i_period*10.2;	
      sclr_i					<= '0';
      wait for clk_i_period*1;
		start_i					<= '1';
      wait for clk_i_period*10;
		start_i					<= '1';		
      -- insert stimulus here 

      wait;
   end process;

END;
