--=================================================================================================--
--==================================== Module Information =========================================--
--=================================================================================================--
--                                                                                         
-- Institute:                 IPHC Laboratory (CNRS/Strasbourg)                                                         
-- Engineer:                	Laurent CHARLES (lcharles@iphc.cnrs.fr) 
--                                                                                                  
-- Project Name:            	PIXFED / CMS Pixel Upgrade Phase I (VME -> uTCA technology)                                                               
-- Module Name:             	tbm_ch_gen_v1.vhd                                       
--                                                                                                  
-- Language:               	VHDL'93                                                                  
--                                                                                                    
-- Target Device:           	Device agnostic                                                         
-- Tool version: 				   ISE14.6                                                                    
--                                                                                                    
-- Version:                 	0.1                                                                      
--
-- Description:             	* TBM frame generator (only-one channel) by FSM 
--
-- 
-- Versions history:        	DATE         VERSION   	AUTHOR            DESCRIPTION
--
--                          	2015/04/01   0.1       	LCHARLES          - First .vhd file 
-- 																							- Possible to test juste TH-TT if ROC_nb_i = 0                                                                 
--
-- Additional Comments:                                                                             
--                                                                                                    
--=================================================================================================--
--=================================================================================================--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
use work.ipbus.all;
use work.user_package.all;

entity tbm_ch_gen_v1 is
port (			clk_i 							: in   std_logic;
					sclr_i 							: in   std_logic;
					TTC_data_out					: in std_logic;
					--
					start_i 							: in   std_logic;
					Brcst								: in std_logic_vector(5 downto 0);
					brcststr							: in std_logic;
					PKAM_Reset						: in std_logic_vector(7 downto 0);
					PKAM_Constant					: in std_logic_vector(7 downto 0);
					PKAM_Enable						: in std_logic;
					PKAM_Buffer						: out std_logic;
					--PKAM_zero_Buffer				: out std_logic;
					ROC_Timer_Buffer				: out std_logic;				
					ROC_Clk							: in std_logic_vector(7 downto 0);
					--
					trigger_i						: in std_logic;
					trigger_en_i					: in std_logic; --pause_trigger_i : pause/resume to wait new data set		
					--
					ch_word4b_o 					: out  std_logic_vector(3 downto 0 );
					--param
					--HIT_NB_ROC_MODE
					--"0000" : fixed (predefined values updated from s/w) 
					--"0001" : cnt from [0:15]; incremented for each new frame (not yet)
					--"0010" : pseudo-random (not yet)					
					hit_nb_ROC_mode_i				: in std_logic_vector(3 downto 0);
					--MATRIX_MODE [dcol-row]
					--"0000" : fixed (predefined values updated from s/w) 
					--"0001" : cnt; but if several hits/roc => same value; incremented for each new frame; common for all ROC & Hit/ROC
					--"0010" : pseudo-random (not yet)
					matrix_mode_i					: in std_logic_vector(3 downto 0); 
					--HIT_DATA_MODE
					--MATRIX_MODE [dcol-row]
					--"0000" : fixed (predefined values updated from s/w) 
					--"0001" : cnt (not yet)
					--"0010" : pseudo-random (not yet)					
					hit_data_mode_i				: in std_logic_vector(3 downto 0);
					--
					ROC_nb_i							: in std_logic_vector(3 downto 0); --[0:8] with 1<=>1	
					--hitNbByROC
					hit_nb_ROCn0_i					: in std_logic_vector(3 downto 0); --"0000" : 0 / "1111" : 15
					hit_nb_ROCn1_i					: in std_logic_vector(3 downto 0);
					hit_nb_ROCn2_i					: in std_logic_vector(3 downto 0);
					hit_nb_ROCn3_i					: in std_logic_vector(3 downto 0);
					hit_nb_ROCn4_i					: in std_logic_vector(3 downto 0);
					hit_nb_ROCn5_i					: in std_logic_vector(3 downto 0);
					hit_nb_ROCn6_i					: in std_logic_vector(3 downto 0);
					hit_nb_ROCn7_i					: in std_logic_vector(3 downto 0);
					--dcol if constant => base-6 format
					dcol_ROCn0_i					: in std_logic_vector(5 downto 0);
					dcol_ROCn1_i					: in std_logic_vector(5 downto 0);
					dcol_ROCn2_i					: in std_logic_vector(5 downto 0);
					dcol_ROCn3_i					: in std_logic_vector(5 downto 0);
					dcol_ROCn4_i					: in std_logic_vector(5 downto 0);
					dcol_ROCn5_i					: in std_logic_vector(5 downto 0);
					dcol_ROCn6_i					: in std_logic_vector(5 downto 0);
					dcol_ROCn7_i					: in std_logic_vector(5 downto 0);					
					--row if constant => base-6 format
					row_ROCn0_i						: in std_logic_vector(8 downto 0);
					row_ROCn1_i						: in std_logic_vector(8 downto 0);
					row_ROCn2_i						: in std_logic_vector(8 downto 0);
					row_ROCn3_i						: in std_logic_vector(8 downto 0);
					row_ROCn4_i						: in std_logic_vector(8 downto 0);
					row_ROCn5_i						: in std_logic_vector(8 downto 0);
					row_ROCn6_i						: in std_logic_vector(8 downto 0);
					row_ROCn7_i						: in std_logic_vector(8 downto 0);	
					--hit if constant => base-6 format
					hit_ROCn0_i						: in std_logic_vector(7 downto 0);
					hit_ROCn1_i						: in std_logic_vector(7 downto 0);
					hit_ROCn2_i						: in std_logic_vector(7 downto 0);
					hit_ROCn3_i						: in std_logic_vector(7 downto 0);
					hit_ROCn4_i						: in std_logic_vector(7 downto 0);
					hit_ROCn5_i						: in std_logic_vector(7 downto 0);
					hit_ROCn6_i						: in std_logic_vector(7 downto 0);
					hit_ROCn7_i						: in std_logic_vector(7 downto 0);
					--
					header_flag_i					: in std_logic_vector(7 downto 0); 	-- = [StackFull - PkamReset - StackCount(5:0)]
					trailer_flag1_i				: in std_logic_vector(7 downto 0); 	-- = [NoTokPass - ResetTBM - ResetROC - SyncErr - SyncTrig - ClrTrigCntr - CalTrig - StackFumm]					
					trailer_flag2_i				: in std_logic_vector(7 downto 0); 	-- = [DataID(1:0) - D(5:0)]
					--
					L1A_count						: in std_logic_vector(31 downto 0);
					EvCntRes							: in std_logic					
		  );
		  
end tbm_ch_gen_v1;

architecture Behavioral of tbm_ch_gen_v1 is

	type t_state is ( 			idle,
										TH1,
										TH2,
										TH3,
										TH4, 	--send_EVn1
										TH5,	--send_EVn2
										TH4_TBM,  --send_TBM_Evn1
										TH5_TBM,  --send_TBM_Evn2
										TH6,	--send_TH_WORDn3
										TH7, 	--send_TH_WORDn4
										TT1,
										TT2,
										TT3,
										TT4,	--send_TR_WORDn1
										TT5,	--send_TR_WORDn2
										TT6,	--send_Stack1
										TT7, 	--send_Stack2
										stack1,
										stack2,
										stack1_TBM,
										stack2_TBM
								);
	signal s_state 							: t_state;	
	
	type array_8x6bit 						is array (0 to 7) of std_logic_vector(5 downto 0); 
	type array_8x9bit 						is array (0 to 7) of std_logic_vector(8 downto 0); 
	type array_8x8bit 						is array (0 to 7) of std_logic_vector(7 downto 0);
	type array_8x4bit_unsigned				is array (0 to 7) of unsigned(3 downto 0);	
	type array_8x4bit							is array (0 to 7) of std_logic_vector(3 downto 0);
	
	--signal read_pixelData_en				: std_logic := '0';

	constant ch_word4b_Idle					: std_logic_vector(3 downto 0) := x"F"; 	
	signal ch_word4b							: std_logic_vector(3 downto 0) := ch_word4b_Idle;
	constant ch_word4b_TBM_Idle			: std_logic_vector(3 downto 0) := x"F"; 
	signal ch_word4b_TBM						: std_logic_vector(3 downto 0) := ch_word4b_TBM_Idle;
	constant ch_word4b_ROC_Idle			: std_logic_vector(3 downto 0) := x"F"; 	
	signal ch_word4b_ROC						: std_logic_vector(3 downto 0) := ch_word4b_ROC_Idle;
	
	signal Dummy_constant					: std_logic := '0';
	signal L1A_Stack_Evn						: std_logic_vector(7 downto 0) := (others => '0');
	signal Stack_count			  			: std_logic_vector(5 downto 0) := (others => '0');
	signal TOKEN_OUT							: std_logic := '0';
	signal TOKEN_IN							: std_logic := '0';
	
	signal Do_stack							: std_logic := '0';
	signal No_Token_Pass						: std_logic := '0';
	signal TBM_Evn_Count						: std_logic_vector(7 downto 0) := (others => '0');
	signal TBM_stack_Evn						: std_logic_vector(7 downto 0) := (others => '0');
	signal Total_Reset						: std_logic := '0';
	signal TBM_Reset							: std_logic := '0';
	signal ROC_Reset							: std_logic := '0';
	signal TBM_dummy_reset					: std_logic := '0';
	
	signal ROC_dummy_reset					: std_logic := '0';
	signal ROC_Constant						: std_logic := '0';
	signal ROC_Timer							: std_logic := '0';
	signal Stack_ROC							: std_logic_vector(5 downto 0) := (others => '0');
	signal ROC_Stack_Dummy					: std_logic	:= '0';
	
	signal PKAM									: std_logic := '0';
	signal PKAM_zero							: std_logic := '0';
	signal PKAM_zero_Buffer					: std_logic := '0';
	signal PKAM_Token							: std_logic := '0';
	signal PKAM_dummy_reset					: std_logic := '0';
	signal state								: integer 	:= 0;
	
	
begin

	--============--
	-- OUTPUTTING --
	--============--
	
	ch_word4b_o	<= ch_word4b_TBM AND ch_word4b_ROC;
	Total_Reset	<= TBM_Reset OR ROC_Reset;
	 
	 Stack_counter: entity work.Stack_counter
	 port map (
				
				TOKEN 						=> Dummy_Constant,
				fabric_clk	 				=> clk_i,
				stack_count					=> stack_count,
				L1Accept						=> trigger_i,
				reset							=> TBM_Reset,
				ROC_Constant				=> ROC_Constant,
				ROC_Clk						=> ROC_Clk,
				ROC_Timer					=> ROC_Timer,
				Stack_ROC					=> Stack_ROC,
				ROC_Timer_Buffer			=> ROC_Timer_Buffer,
				ROC_Stack_Dummy			=> ROC_Stack_Dummy
	 );
	 
	 PKAM_Reset_file : entity work.PKAM_Reset
	 port map(
				fabric_clk	 				=> clk_i,
				stack_count					=> stack_count,
				PKAM_Reset					=> PKAM_Reset,
				PKAM_Constant				=> PKAM_Constant,
				PKAM_Token					=> PKAM_Token,
				PKAM							=> PKAM,
				PKAM_zero					=> PKAM_zero,
				PKAM_Enable					=> PKAM_Enable,
				PKAM_Buffer					=> PKAM_Buffer,
				PKAM_zero_Buffer			=> PKAM_zero_Buffer
	 );
	 
	Various_Resets: entity work.Various_Resets
	port map(
				fabric_clk					=> clk_i,
				Brcst							=> Brcst,
				brcststr						=> brcststr,
				TBM_Reset					=> TBM_Reset,
				ROC_Reset					=> ROC_Reset
	);
	 
	 
	 ROC_ch_gen_v1_inst: entity work.ROC_ch_gen_v1
		port map(
				clk_i 						=> clk_i,
				sclr_i						=> Total_Reset,
				--
				trigger_i					=> trigger_i,
				trigger_en_i				=> trigger_en_i, --pause_trigger_i : pause/resume to wait new data set 
				TBM_Reset					=> TBM_Reset,
				ROC_Reset					=> ROC_Reset,
				Total_Reset					=> Total_Reset,
				ROC_Constant				=> ROC_Constant,
				PKAM							=> PKAM,
				PKAM_zero					=> PKAM_zero,
				No_Token_Pass				=> No_Token_Pass,
				--
				ch_word4b_ROC 				=> ch_word4b_ROC,
				--param
				hit_nb_ROC_mode_i			=> hit_nb_ROC_mode_i,
				matrix_mode_i 				=> matrix_mode_i ,
				hit_data_mode_i			=> hit_data_mode_i,						
				--
				ROC_nb_i 					=> ROC_nb_i , --[0:8] with 1<=>1	
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
						
				TOKEN_ROC_IN				=> TOKEN_OUT,
				TOKEN_ROC_OUT				=> TOKEN_IN
		);
	 

	--=======================--
	-- FSM - Frame Generator --
	--=======================--	
	process
	begin
	wait until rising_edge(clk_i);	-- rising clock edge
		--
		if ROC_Reset = '1' then 
			ROC_Constant							<= '1';
			ROC_dummy_Reset						<= '1';
			No_Token_Pass							<= '1';
			TOKEN_OUT								<= '0';
		elsif ROC_Timer = '1' then
			ROC_Constant							<= '0';
		elsif TBM_Reset = '1' then 
			TBM_Evn_Count							<= (others => '0');
			TBM_dummy_reset 						<= '1';
			TOKEN_OUT								<= '0';
		elsif PKAM = '1' AND PKAM_zero = '0' AND stack_count /= "000000" then
			ch_word4b_TBM 							<= ch_word4b_TBM_Idle;
			TOKEN_OUT								<= '0';
			PKAM_dummy_reset						<= '1';
			s_state									<= TT1;
		else
			--
			case s_state is
				-------------------------------------------------------------------------
				when idle =>	--start + wait trigger			
					state								<= 0;
					ch_word4b_TBM 					<= ch_word4b_TBM_Idle;
					TOKEN_OUT						<= '0';
					PKAM_Token						<= '0';
					Do_stack							<= '0';
					No_Token_Pass					<= '0';
					
					if start_i = '1' and trigger_i = '1' and trigger_en_i = '1' and PKAM /= '1' then
						L1A_stack_Evn				<= L1A_count(7 downto 0);
						s_state 						<= TH1;
					end if;				
				
				-------------------------------------------------------------------------
				when TH1 =>
					state								<= 8;
					Dummy_constant					<= '0';
					ROC_Stack_Dummy				<= '0';
					ch_word4b_TBM 					<= x"7"; 
					TBM_Evn_Count					<= std_logic_vector(unsigned(TBM_Evn_Count) + 1);
					s_state 							<= TH2;
				
				-------------------------------------------------------------------------
				when TH2 =>					
					state								<= 8;
					ch_word4b_TBM					<= x"F"; 
					if Do_stack = '0' then
						TBM_stack_Evn				<= TBM_Evn_Count(7 downto 0);
					end if;
					s_state 							<= TH3; 
				
				-------------------------------------------------------------------------
				when TH3 =>
					state								<= 8;
					ch_word4b_TBM					<= x"C"; 
					if Do_stack = '1' then
						TBM_Stack_Evn 				<= std_logic_vector(unsigned(TBM_stack_Evn) + 1); 
						s_state						<= Stack1_TBM;
					else
						s_state						<= TH4_TBM;							
					end if;
						
				-------------------------------------------------------------------------
				when Stack1_TBM =>
					state								<= 8;
					ch_word4b_TBM					<= TBM_stack_Evn(7 downto 4);
					Do_stack							<= '0';
					s_state							<= Stack2_TBM;
				
				-------------------------------------------------------------------------
				when Stack2_TBM =>
					state								<= 8;
					ch_word4b_TBM					<= TBM_stack_Evn(3 downto 0);
					s_state							<= TH6;
				
				-------------------------------------------------------------------------
				when TH4_TBM =>
					state								<= 8;
					ch_word4b_TBM					<= TBM_Evn_count(7 downto 4);
					s_state 							<= TH5_TBM; 
					
				-------------------------------------------------------------------------
				when TH5_TBM =>					
					state								<= 8;
					ch_word4b_TBM					<= TBM_Evn_count(3 downto 0); 
					s_state 							<= TH6; 
					
				-------------------------------------------------------------------------
				when TH6 =>
					state								<= 8;
					ch_word4b_TBM					<= header_flag_i(7 downto 4);
					if Stack_count >= "010000" then  --is the stack >= 16
						No_Token_Pass				<= '1';
					else
						No_Token_Pass				<= '0';
					end if;
					
					s_state 							<= TH7; 
				
				-------------------------------------------------------------------------
				when TH7 =>
					state								<= 8;
					ch_word4b_TBM 					<= header_flag_i(3 downto 0);	
					
					if No_Token_Pass = '1' OR ROC_Dummy_Reset = '1' OR PKAM_zero = '1' then
						s_state 						<= TT1;
					else
						PKAM_Token					<= '1';
						TOKEN_OUT					<= '1';
						s_state						<= TT1;
					end if;
					
				-------------------------------------------------------------------------
				when TT1 =>
					state								<= 1;
					if PKAM_zero = '1' then
						No_Token_Pass				<= '1';
					end if;
					
					if TOKEN_IN = '1' OR No_Token_Pass = '1' OR ROC_dummy_Reset = '1' OR TBM_dummy_Reset = '1' OR PKAM_zero = '1' then
						TOKEN_OUT					<= '0';
						Dummy_constant				<= '1';
						ROC_Stack_Dummy			<= '1';
						ch_word4b_TBM				<= x"7";
						s_state 						<= TT2;
					else
						ch_word4b_TBM 				<= ch_word4b_TBM_Idle;
					end if;
				
				-------------------------------------------------------------------------
				when TT2 =>
					state								<= 2;
					ch_word4b_TBM					<= x"F";
					ROC_Stack_Dummy				<= '0';
					Dummy_constant					<= '0';
					s_state 							<= TT3; 
				
				-------------------------------------------------------------------------
				when TT3 =>
					state								<= 3;
					ch_word4b_TBM					<= x"E";
					s_state							<= TT4;
					
				-------------------------------------------------------------------------
				when TT4 =>					
					state								<= 4;
					ch_word4b_TBM					<= No_Token_Pass & TBM_dummy_reset & ROC_dummy_Reset & '0';
					s_state 							<= TT5; 
				
				-------------------------------------------------------------------------
				when TT5 =>
					state								<= 5;
					ch_word4b_TBM					<= "0000";--trailer_flag1_i(3 downto 0); 	
					s_state 							<= TT6; 
				
				-------------------------------------------------------------------------
				when TT6 =>
					state								<= 6;
					if Stack_ROC = "000000" then
						ch_word4b_TBM				<= "0" & PKAM_Dummy_Reset & Stack_count(5 downto 4); 	
					else
						ch_word4b_TBM				<= "0" & PKAM_Dummy_Reset & Stack_ROC(5 downto 4); 	
					end if;
					s_state 							<= TT7; 
				
				-------------------------------------------------------------------------
				when TT7 =>
					state								<= 7;
					TBM_dummy_reset				<= '0';
					if Stack_ROC = "000000" then
						ch_word4b_TBM					<= Stack_count(3 downto 0);
					else
						ch_word4b_TBM					<= Stack_ROC(3 downto 0);
					end if;

					if PKAM_zero = '0' then
						PKAM_Token					<= '0';
						PKAM_Dummy_Reset			<= '0';
					end if;					
					
					if Stack_count /= "000000" OR Stack_ROC /= "000000" then
						Do_stack						<= '1';
						s_state						<= TH1;
					else
						No_Token_Pass				<= '0';
						ROC_Dummy_Reset			<= '0';
						s_state 						<= Idle;
					end if;
				
				-------------------------------------------------------------------------
				when others => 
					null;
					
				
			end case;
	end if;
end process;
end Behavioral;
