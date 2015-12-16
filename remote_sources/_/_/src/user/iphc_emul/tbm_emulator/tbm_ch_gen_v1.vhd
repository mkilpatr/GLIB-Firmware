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
					--
					start_i 							: in   std_logic;
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
					--stack
					--Stack_count						: inout std_logic_vector(5 downto 0)
					
		  );
		  
end tbm_ch_gen_v1;

architecture Behavioral of tbm_ch_gen_v1 is

	type t_state is ( 			idle,
										TH1,
										TH2,
										TH3,
										TH4, 	--send_EVn1
										TH5,	--send_EVn2
										TH6,	--send_Stack1
										TH7, 	--send_Stack2
										RH0,
										TT1,
										TT2,
										TT3,
										TT4,	--send_TR_WORDn1
										TT5,	--send_TR_WORDn2
										TT6,	--send_TR_WORDn3
										TT7, 	--send_TR_WORDn4
										stack1,
										stack2
								);
	signal s_state 							: t_state;



	--signal stack								: std_logic_vector(5 downto 0) := (others=>'0');
	signal event_cnt 							: unsigned(7 downto 0) := (others=>'0');
	signal ROC_cnt 							: integer range 0 to 15 := 0; --4b
	signal ROC_index 							: integer range 0 to 7 := 0; --3b
	
	signal ROC_cnt_end 						: std_logic:='0';		
	

	type array_8x6bit 						is array (0 to 7) of std_logic_vector(5 downto 0); 
	type array_8x9bit 						is array (0 to 7) of std_logic_vector(8 downto 0); 
	type array_8x8bit 						is array (0 to 7) of std_logic_vector(7 downto 0);
	type array_8x4bit_unsigned				is array (0 to 7) of unsigned(3 downto 0);	
	type array_8x4bit							is array (0 to 7) of std_logic_vector(3 downto 0);
	
	signal read_pixelData_en				: std_logic := '0';

	constant ch_word4b_Idle					: std_logic_vector(3 downto 0) := x"F"; 	
	signal ch_word4b							: std_logic_vector(3 downto 0) := ch_word4b_Idle;
	constant ch_word4b_TBM_Idle			: std_logic_vector(3 downto 0) := x"F"; 
	signal ch_word4b_TBM						: std_logic_vector(3 downto 0) := ch_word4b_TBM_Idle;
	constant ch_word4b_ROC_Idle			: std_logic_vector(3 downto 0) := x"F"; 	
	signal ch_word4b_ROC						: std_logic_vector(3 downto 0) := ch_word4b_ROC_Idle;
	
	signal buffer_EvCnt						: std_logic_vector(7 downto 0);
	signal stack_count_integer				: integer := 0;
	signal Dummy_constant					: std_logic := '0';
	signal L1A_constant						: std_logic_vector(7 downto 0) := (others => '0');
	signal Stack_count			  			: std_logic_vector(5 downto 0) := (others => '0');
	signal TOKEN_OUT							: std_logic := '0';
	signal TOKEN_IN							: std_logic := '0';
	
begin

	--============--
	-- OUTPUTTING --
	--============--
	
	ch_word4b_o	<= ch_word4b_TBM AND ch_word4b_ROC;
	
	
	
	Stack_count_integer_inst : entity work.STD_vector_to_integer
	 port map(
			fabric_clk					=> clk_i,
			stack_count 				=> stack_count,
			Stack_count_integer 		=> stack_count_integer
	 );
	 
	 Stack_counter: entity work.Stack_counter
	 port map (
				
				TOKEN 						=> Dummy_constant,
				fabric_clk	 				=> clk_i,
				stack_count					=> stack_count,
				L1Accept						=> trigger_i,
				reset							=> sclr_i
--				Stack_count_integer		=> Stack_count_integer
	 );
	 
	 
	 ROC_ch_gen_v1_inst: entity work.ROC_ch_gen_v1
		port map(
						clk_i 						=> clk_i,
						sclr_i 						=> sclr_i,
						start_i 						=> start_i, --one-pulse,
						--
						trigger_i					=> trigger_i,
						trigger_en_i				=> trigger_en_i, --pause_trigger_i : pause/resume to wait new data set         
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
		if sclr_i = '1' then
			ch_word4b_TBM 							<= ch_word4b_TBM_Idle; 
			--event_cnt								<= (others=>'0');
			ROC_cnt									<= 15;
			ROC_index								<= 0;			
			read_pixelData_en						<= '0';
			TOKEN_OUT								<= '0';
			s_state 									<= idle;
		else
		--
			--
			case s_state is
				-------------------------------------------------------------------------
				when idle =>	--start + wait trigger			
					ch_word4b_TBM 					<= ch_word4b_TBM_Idle;
					ROC_cnt							<= to_integer(unsigned(ROC_nb_i));
					ROC_index						<= 0;
					TOKEN_OUT						<= '0';
					--hit_cnt							<= to_integer(unsigned(hit_nb_ROCn(0)));
					--
					if start_i = '1' and trigger_i = '1' and trigger_en_i = '1' then
						if stack_count_integer = 1 then
							L1A_constant				<= L1A_count(7 downto 0);
						end if;
						s_state 						<= TH1;
					end if;				
				
				-------------------------------------------------------------------------
				when TH1 =>
					Dummy_constant					<= '0';
					ch_word4b_TBM 					<= x"7"; 
					s_state 							<= TH2;
				
				-------------------------------------------------------------------------
				when TH2 =>
					ch_word4b_TBM					<= x"F"; 
					s_state 							<= TH3; 
				
				-------------------------------------------------------------------------
				when TH3 =>
					ch_word4b_TBM					<= x"C"; 
						if (stack_count_integer > 1) then
							buffer_EvCnt <= L1A_constant + '1'; --std_logic_vector(to_unsigned(to_integer(unsigned(L1A_constant)) + 1, 8));
							s_state						<= Stack1;
						else
							s_state 						<= TH4;
						end if;
						
				-------------------------------------------------------------------------
				when Stack1 =>
					ch_word4b_TBM					<= buffer_EvCnt(7 downto 4);
					s_state							<= Stack2;
				
				-------------------------------------------------------------------------
				when Stack2 =>
					ch_word4b_TBM					<= buffer_EvCnt(3 downto 0);
					s_state							<= TH6;
				
				-------------------------------------------------------------------------
				when TH4 =>
					ch_word4b_TBM					<= L1A_count(7 downto 4);
					s_state 							<= TH5; 
					
				-------------------------------------------------------------------------
				when TH5 =>
					ch_word4b_TBM					<= L1A_count(3 downto 0); 
					s_state 							<= TH6; 
					
				-------------------------------------------------------------------------
				when TH6 =>
					ch_word4b_TBM					<= header_flag_i(7 downto 4);
					s_state 							<= TH7; 
				
				-------------------------------------------------------------------------
				when TH7 =>
					ch_word4b_TBM 					<= header_flag_i(3 downto 0);					
					--
					if ROC_nb_i = std_logic_vector(to_unsigned(0,ROC_nb_i'length)) then
						s_state 						<= TT1;
					else
						--read_pixelData_en			<= '1';
						--s_state 						<= idle;
						ch_word4b_TBM 				<= ch_word4b_TBM_Idle; 
						TOKEN_OUT					<= '1';
						s_state						<= TT1;
					end if;
					
				-------------------------------------------------------------------------
				when TT1 =>
					if TOKEN_IN = '1' then
						TOKEN_OUT						<= '0';
						Dummy_constant					<= '1';
						ch_word4b_TBM					<= x"7";
						s_state 							<= TT2;
					end if;
				
				-------------------------------------------------------------------------
				when TT2 =>
					ch_word4b_TBM					<= x"F"; 
					Dummy_constant					<= '0';
					s_state 							<= TT3; 
				
				-------------------------------------------------------------------------
				when TT3 =>
					ch_word4b_TBM					<= x"E";
					s_state							<= TT4;
					
				-------------------------------------------------------------------------
				when TT4 =>
					--ch_word4b 						<= "0000"; 
					ch_word4b_TBM					<= trailer_flag1_i(7 downto 4); 					
					s_state 							<= TT5; 
				
				-------------------------------------------------------------------------
				when TT5 =>
					--ch_word4b 						<= "0000"; 
					ch_word4b_TBM					<= trailer_flag1_i(3 downto 0); 	
					s_state 							<= TT6; 
				
				-------------------------------------------------------------------------
				when TT6 =>
					--ch_word4b 						<= "0000"; 
					ch_word4b_TBM					<= "00" & Stack_count(5 downto 4); --trailer_flag2_i(7 downto 4); 						
					s_state 							<= TT7; 
				
				-------------------------------------------------------------------------
				when TT7 =>
					--ch_word4b 						<= "0011"; 
					ch_word4b_TBM					<= Stack_count(3 downto 0);--trailer_flag2_i(3 downto 0); 						
					
					if Stack_count_integer /= 0 then
						s_state						<= TH1;
					else
						s_state 						<= Idle;
					end if;
				
				-------------------------------------------------------------------------
				when others => 
					null;
					
				
			end case;
	end if;
end process;



end Behavioral;

