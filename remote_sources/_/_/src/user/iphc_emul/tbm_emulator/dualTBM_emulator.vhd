--=================================================================================================--
--==================================== Module Information =========================================--
--=================================================================================================--
--                                                                                         
-- Institute:                 IPHC Laboratory (CNRS/Strasbourg)                                                         
-- Engineer:                	Laurent CHARLES (lcharles@iphc.cnrs.fr) 
--                                                                                                  
-- Project Name:            	PIXFED / CMS Pixel Upgrade Phase I (VME -> uTCA technology)                                                               
-- Module Name:             	dualTBM_emulator.vhd                                       
--                                                                                                  
-- Language:               	VHDL'93                                                                  
--                                                                                                    
-- Target Device:           	Device agnostic                                                         
-- Tool version: 				   ISE14.6                                                                    
--                                                                                                    
-- Version:                 	0.2                                                                      
--
-- Description:             	* This logic block performs
--												--> Emulation of channels A/B from a dual-TBM
--												--> Encoding + Serialization
--												--> Linked with the package "pkg_dualTBM_emulator.vhd"
--
-- 
-- Versions history:        	DATE         VERSION   	AUTHOR            DESCRIPTION
--
--                          	2015/04/09   0.1       	LCHARLES          - First .vhd file 
--                          	2015/08/14   0.2       	LCHARLES          - several modes added
--  																							-                         	                                                                  
--
-- Additional Comments:                                                                             
--                                                                                                    
--=================================================================================================--
--=================================================================================================--


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

--! user packages
use work.pkg_dualTBM_emulator.all; 

entity dualTBM_emulator is
generic (
				EMUL_VERSION							: string := "V1";	-- V1 : by FSM
																					-- V2 : by Memory
																					-- V3 : after interleaving 	/ 	test with interleaved data emulating "7FC" defined in hard
																					-- V4 : before interleaving 	/ 	test with "7FC" defined in hard
				CHAN_B_DELAY							: string := "no" --"yes" or "no"
			);
port (	
				clk_40_0_i 								: in std_logic;
				clk_80_0_i 								: in std_logic;
				clk_400_0_i								: in std_logic;
				sclr_i 									: in std_logic;
				TTC_data_out							: in std_logic;
				Brcst										: in std_logic_vector(5 downto 0);
				brcststr									: in std_logic;
				PKAM_Reset								: in std_logic_vector(7 downto 0);
				PKAM_Constant							: in std_logic_vector(7 downto 0);
				PKAM_Enable								: in std_logic;
				PKAM_Buffer								: out std_logic;
				Event_Enable							: out std_logic;
				ROC_Timer_Buffer						: out std_logic;
				ROC_Clk									: in std_logic_vector(7 downto 0);
				--common
				trigger_i								: in std_logic;
				trigger_en_i							: in std_logic; --pause_trigger_i : pause/resume to wait new data set					
				tbm_ch_start_i							: in std_logic_vector(1 downto 0); --(0)=chA (1)=chB	
				--v1 param
				tbm_emul_v1_hit_nb_ROC_mode_i		: in array_TBM_CH_NBx4b;
				tbm_emul_v1_matrix_mode_i 			: in array_TBM_CH_NBx4b;
				tbm_emul_v1_hit_data_mode_i		: in array_TBM_CH_NBx4b;					
				--
				tbm_emul_v1_ROC_nb_i					: in array_TBM_CH_NBx4b; --[0:8] with 1<=>1
				--
				tbm_emul_v1_hit_nb_i					: in array_TBM_CH_NBxROC_NB_MAXx4b; --"0000" : 0 / "1111" : 15
				--
				tbm_emul_v1_dcol_i					: in array_TBM_CH_NBxROC_NB_MAXx6b;--2 words in base-6, translation from bin to this format performed s/w side
				tbm_emul_v1_row_i						: in array_TBM_CH_NBxROC_NB_MAXx9b;--3 words in base-6, translation from bin to this format performed s/w side	
				tbm_emul_v1_hit_i						: in array_TBM_CH_NBxROC_NB_MAXx8b;		
				tbm_emul_v1_header_flag_i			: in array_TBM_CH_NBx8b;
				tbm_emul_v1_trailer_flag1_i 		: in array_TBM_CH_NBx8b;
				tbm_emul_v1_trailer_flag2_i		: in array_TBM_CH_NBx8b;
				--
				tbm_chB_delaying_i					: in std_logic_vector(7 downto 0); --[0-255 clk40 cycles]

				L1A_count								: in std_logic_vector(31 downto 0);
				EvCntRes									: in std_logic;
				
				--v2 param
				tbm_chA_loop_nb_i						: in  std_logic_vector(15 downto 0);	
				tbm_chB_loop_nb_i						: in  std_logic_vector(15 downto 0);				
				--storage memory
				tbm_chA_mem_data_i					: in std_logic_vector(31 downto 0);
				tbm_chB_mem_data_i					: in std_logic_vector(31 downto 0);
				tbm_chA_mem_addr_o					: out std_logic_vector(15 downto 0);
				tbm_chB_mem_addr_o					: out std_logic_vector(15 downto 0);				
				tbm_chA_mem_rd_en_o 					: out std_logic;
				tbm_chB_mem_rd_en_o 					: out std_logic;	
				--INSPEC
				--initial channels
				tbm_chA_word4b_sync40M_o  			: out std_logic_vector(3 downto 0);
				tbm_chB_word4b_sync40M_o  			: out std_logic_vector(3 downto 0);
				tbm_chA_word4b_sync80M_o  			: out std_logic_vector(3 downto 0);
				tbm_chB_word4b_sync80M_o  			: out std_logic_vector(3 downto 0);			
				--4b/5b encoding
				tx_symb4b_o								: out std_logic_vector(3 downto 0);
				tx_symb5b_o								: out std_logic_vector(4 downto 0);			
				--OUT
				tx_sdout_o 								: out std_logic
		);
end dualTBM_emulator;

architecture Behavioral of dualTBM_emulator is

	type array_2x1b								is array(1 downto 0) of std_logic; 
	type array_2x4b 								is array(1 downto 0) of std_logic_vector(3 downto 0);
	type array_2x8b 								is array(1 downto 0) of std_logic_vector(7 downto 0); 	
	type array_2x16b								is array(1 downto 0) of std_logic_vector(15 downto 0);   
	type array_2x32b								is array(1 downto 0) of std_logic_vector(31 downto 0);   
	type array_16x8b 								is array(15 downto 0) of std_logic_vector(7 downto 0);
	--
	type array_2xarray_2x4b						is array(1 downto 0) of array_2x4b; 	
	--
--	constant chA 									: integer := 0;
--	constant chB 									: integer := 1;	
--	constant ROC0 									: integer := 0;
--	constant ROC1 									: integer := 1;	
--	constant ROC2 									: integer := 2;
--	constant ROC3 									: integer := 3;	
--	constant ROC4 									: integer := 4;
--	constant ROC5 									: integer := 5;	
--	constant ROC6 									: integer := 6;
--	constant ROC7 									: integer := 7;

	--
	signal tbm_ch_word4b 						: array_2x4b := (others => x"F"); 
	signal tbm_ch_word4b_tmp					: array_2x4b := (others => x"F"); 
	signal tbm_ch_word4b_sync80M				: array_2xarray_2x4b := (others => (others => x"F")); 
	--after interleaving
	signal mux_tbm_ch_word8b 					: std_logic_vector(7 downto 0):=x"AA";
	signal mux_tbm_ch_word8b_sync80M 		: array_2x8b := (others => x"AA");	
	
	signal tx_enc_tmp 							: std_logic:= '1';
	signal div2_sync80M 							: std_logic:= '0';	
	
	signal symb4b_current 						: std_logic_vector(3 downto 0) := x"A";	
	signal symb4b_next 							: std_logic_vector(3 downto 0) := x"A";

	signal tx_symb4b 								: std_logic_vector(3 downto 0) := x"A"; 
 

 

	
	signal tbm_ch_mem_rd_en						: array_2x1b 	:= (others => '0'); 
	signal tbm_ch_mem_addr						: array_2x16b 	:= (others => (others => '0'));
	signal tbm_ch_mem_data						: array_2x32b 	:= (others => (others => '0'));
	signal tbm_ch_loop_nb						: array_2x16b 	:= (others => (others => '0'));
	
	--emul

	signal mux_tbm_ch_word8b_emul				: array_16x8b := (others => x"AA");			


	signal tbm_ch_word4b_to_resync80M 		: std_logic_vector(7 downto 0) := x"FF";
	signal tbm_ch_word4b_resync80M 			: std_logic_vector(7 downto 0) := x"FF";

		
begin


	--==============================================================================================================================================--
	-- OUTPUTS --
	--==============================================================================================================================================--
	tbm_chA_word4b_sync80M_o 					<= tbm_ch_word4b_sync80M(1)(chA); --double resync / 80M <=> 1 delay / 40M
	tbm_chB_word4b_sync80M_o 					<= tbm_ch_word4b_sync80M(1)(chB);
	--delay compensationin (word4b 40M & 80M in phase / useful for sim or inspection)
	process
	begin
		wait until rising_edge(clk_80_0_i);
			tbm_chA_word4b_sync40M_o			<= tbm_ch_word4b(chA);
			tbm_chB_word4b_sync40M_o			<= tbm_ch_word4b(chB);			
	end process;
	--
	tbm_chA_mem_addr_o							<= tbm_ch_mem_addr(chA);
	tbm_chB_mem_addr_o							<= tbm_ch_mem_addr(chB);	
	--
	tbm_chA_mem_rd_en_o							<= tbm_ch_mem_rd_en(chA);
	tbm_chB_mem_rd_en_o							<= tbm_ch_mem_rd_en(chB);		


	--==============================================================================================================================================--
	-- INPUTS --
	--==============================================================================================================================================--
	tbm_ch_loop_nb(chA)							<= tbm_chA_loop_nb_i;
	tbm_ch_loop_nb(chB)							<= tbm_chB_loop_nb_i;
	--
	tbm_ch_mem_data(chA)							<= tbm_chA_mem_data_i;
	tbm_ch_mem_data(chB)							<= tbm_chB_mem_data_i;	
	

	--==============================================================================================================================================--
	-- EMUL_VERSION = "V2" --
	--==============================================================================================================================================--
--	emul_version_V2_gen : if EMUL_VERSION = "V2" generate
--		-- ChA
--		tbm_ch_gen_v2_inst_chA: entity work.tbm_ch_gen_v2 
--		PORT MAP (
--				 clk_i 								=> clk_40_0_i, --40-MHz
--				 sclr_i 								=> sclr_i, --active-high
--				 start_i 							=> tbm_ch_start_i(chA), --one-pulse
--				 mem_rd_en_o 						=> tbm_ch_mem_rd_en(chA),
--				 mem_addr_o 						=> tbm_ch_mem_addr(chA),
--				 mem_data_i 						=> tbm_ch_mem_data(chA),
--				 symb4b_o 							=> tbm_ch_word4b(chA),
--				 loop_nb_i 							=> tbm_ch_loop_nb(chA)
--			  );
--
--		-- ChB
--		tbm_ch_gen_v2_inst_chB: entity work.tbm_ch_gen_v2 
--		PORT MAP (
--				 clk_i 								=> clk_40_0_i, --40-MHz
--				 sclr_i 								=> sclr_i, --active-high
--				 start_i 							=> tbm_ch_start_i(chB), --one-pulse
--				 mem_rd_en_o 						=> mem_rd_en(chB),
--				 mem_addr_o 						=> mem_addr(chB),
--				 mem_data_i 						=> mem_data(chB),
--				 symb4b_o 							=> tbm_ch_word4b(chB),
--				 loop_nb_i 							=> loop_nb(chB)
--			  );
--
----		tbm_ch_word4b(chB) <= tbm_ch_word4b(chA);
--	end generate;
	
	
	

	--==============================================================================================================================================--
	-- EMUL_VERSION = "V1" --
	--==============================================================================================================================================--	
	emul_version_V1_gen : if EMUL_VERSION = "V1" generate
		--> chA:
		--------
		tbm_ch_gen_v1_inst_chA: entity work.tbm_ch_gen_v1 
		PORT MAP (
						clk_i 						=> clk_40_0_i,
						sclr_i 						=> sclr_i,
						start_i 						=> tbm_ch_start_i(chA), --one-pulse,
						TTC_data_out				=> TTC_data_out,
						Brcst							=> Brcst,
						brcststr						=> brcststr,
						PKAM_Reset					=> PKAM_Reset,
						PKAM_Constant				=> PKAM_Constant,
						PKAM_Enable					=> PKAM_Enable,
						PKAM_Buffer					=> PKAM_Buffer,
						Event_Enable				=> Event_Enable,
						ROC_Timer_Buffer			=> ROC_Timer_Buffer,
						ROC_Clk						=> ROC_Clk,
						--
						trigger_i					=> trigger_i,
						trigger_en_i				=> trigger_en_i, --pause_trigger_i : pause/resume to wait new data set         
						--
						ch_word4b_o 				=> tbm_ch_word4b_tmp(chA),
						--param
						hit_nb_ROC_mode_i			=> tbm_emul_v1_hit_nb_ROC_mode_i(chA),
						matrix_mode_i 				=> tbm_emul_v1_matrix_mode_i(chA),
						hit_data_mode_i			=> tbm_emul_v1_hit_data_mode_i(chA),
						--
						ROC_nb_i 					=> tbm_emul_v1_ROC_nb_i(chA), --[0:8] with 1<=>1	
						--
						hit_nb_ROCn0_i				=> tbm_emul_v1_hit_nb_i(chA)(ROC0),--"0000" : 0 / "1111" : 15
						hit_nb_ROCn1_i				=> tbm_emul_v1_hit_nb_i(chA)(ROC1),
						hit_nb_ROCn2_i				=> tbm_emul_v1_hit_nb_i(chA)(ROC2),
						hit_nb_ROCn3_i				=> tbm_emul_v1_hit_nb_i(chA)(ROC3),
						hit_nb_ROCn4_i				=> tbm_emul_v1_hit_nb_i(chA)(ROC4),
						hit_nb_ROCn5_i				=> tbm_emul_v1_hit_nb_i(chA)(ROC5),
						hit_nb_ROCn6_i				=> tbm_emul_v1_hit_nb_i(chA)(ROC6),
						hit_nb_ROCn7_i				=> tbm_emul_v1_hit_nb_i(chA)(ROC7),						
						--
						dcol_ROCn0_i 				=> tbm_emul_v1_dcol_i(chA)(ROC0),
						dcol_ROCn1_i 				=> tbm_emul_v1_dcol_i(chA)(ROC1),
						dcol_ROCn2_i 				=> tbm_emul_v1_dcol_i(chA)(ROC2),
						dcol_ROCn3_i 				=> tbm_emul_v1_dcol_i(chA)(ROC3),
						dcol_ROCn4_i 				=> tbm_emul_v1_dcol_i(chA)(ROC4),
						dcol_ROCn5_i 				=> tbm_emul_v1_dcol_i(chA)(ROC5),
						dcol_ROCn6_i 				=> tbm_emul_v1_dcol_i(chA)(ROC6),
						dcol_ROCn7_i 				=> tbm_emul_v1_dcol_i(chA)(ROC7),
						--
						row_ROCn0_i 				=> tbm_emul_v1_row_i(chA)(ROC0),
						row_ROCn1_i 				=> tbm_emul_v1_row_i(chA)(ROC1),
						row_ROCn2_i 				=> tbm_emul_v1_row_i(chA)(ROC2),
						row_ROCn3_i 				=> tbm_emul_v1_row_i(chA)(ROC3),
						row_ROCn4_i 				=> tbm_emul_v1_row_i(chA)(ROC4),
						row_ROCn5_i 				=> tbm_emul_v1_row_i(chA)(ROC5),
						row_ROCn6_i 				=> tbm_emul_v1_row_i(chA)(ROC6),
						row_ROCn7_i 				=> tbm_emul_v1_row_i(chA)(ROC7),
						--
						hit_ROCn0_i 				=> tbm_emul_v1_hit_i(chA)(ROC0),
						hit_ROCn1_i 				=> tbm_emul_v1_hit_i(chA)(ROC1),
						hit_ROCn2_i 				=> tbm_emul_v1_hit_i(chA)(ROC2),
						hit_ROCn3_i 				=> tbm_emul_v1_hit_i(chA)(ROC3),
						hit_ROCn4_i 				=> tbm_emul_v1_hit_i(chA)(ROC4),
						hit_ROCn5_i 				=> tbm_emul_v1_hit_i(chA)(ROC5),
						hit_ROCn6_i 				=> tbm_emul_v1_hit_i(chA)(ROC6),
						hit_ROCn7_i 				=> tbm_emul_v1_hit_i(chA)(ROC7),
						--
						header_flag_i				=> tbm_emul_v1_header_flag_i(chA), 			-- = [DataID(1:0) - D(5:0)]
						trailer_flag1_i			=> tbm_emul_v1_trailer_flag1_i(chA), 		-- = [NoTokPass - ResetTBM - ResetROC - SyncErr - SyncTrig - ClrTrigCntr - CalTrig - StackFumm]					
						trailer_flag2_i			=> tbm_emul_v1_trailer_flag2_i(chA), 		-- = [StackFull - PkamReset - Stack_Count(5:0)]					
						L1A_count					=> L1A_count,
						EvCntRes						=> EvCntRes
			  );
			  

		--> chB:
		--------
		tbm_ch_gen_v1_inst_chB: entity work.tbm_ch_gen_v1 
		PORT MAP (
						clk_i 						=> clk_40_0_i,
						sclr_i 						=> sclr_i,
						start_i 						=> tbm_ch_start_i(chB), --one-pulse,
						TTC_data_out				=> TTC_data_out,
						Brcst							=> Brcst,
						brcststr						=> brcststr,
						PKAM_Reset					=> PKAM_Reset,
						PKAM_Constant				=> PKAM_Constant,
						PKAM_Enable					=> PKAM_Enable,
						ROC_Clk						=> ROC_Clk,
						--
						trigger_i					=> trigger_i,
						trigger_en_i				=> trigger_en_i, --pause_trigger_i : pause/resume to wait new data set         
						--
						ch_word4b_o 				=> tbm_ch_word4b_tmp(chB),
						--param
						hit_nb_ROC_mode_i			=> tbm_emul_v1_hit_nb_ROC_mode_i(chB),
						matrix_mode_i 				=> tbm_emul_v1_matrix_mode_i(chB),
						hit_data_mode_i			=> tbm_emul_v1_hit_data_mode_i(chB),
						--
						L1A_count					=> L1A_count,
						
						ROC_nb_i 					=> tbm_emul_v1_ROC_nb_i(chB), --[0:8] with 1<=>1	
						--
						hit_nb_ROCn0_i				=> tbm_emul_v1_hit_nb_i(chB)(ROC0),--"0000" : 0 / "1111" : 15
						hit_nb_ROCn1_i				=> tbm_emul_v1_hit_nb_i(chB)(ROC1),
						hit_nb_ROCn2_i				=> tbm_emul_v1_hit_nb_i(chB)(ROC2),
						hit_nb_ROCn3_i				=> tbm_emul_v1_hit_nb_i(chB)(ROC3),
						hit_nb_ROCn4_i				=> tbm_emul_v1_hit_nb_i(chB)(ROC4),
						hit_nb_ROCn5_i				=> tbm_emul_v1_hit_nb_i(chB)(ROC5),
						hit_nb_ROCn6_i				=> tbm_emul_v1_hit_nb_i(chB)(ROC6),
						hit_nb_ROCn7_i				=> tbm_emul_v1_hit_nb_i(chB)(ROC7),						
						--
						dcol_ROCn0_i 				=> tbm_emul_v1_dcol_i(chB)(ROC0),
						dcol_ROCn1_i 				=> tbm_emul_v1_dcol_i(chB)(ROC1),
						dcol_ROCn2_i 				=> tbm_emul_v1_dcol_i(chB)(ROC2),
						dcol_ROCn3_i 				=> tbm_emul_v1_dcol_i(chB)(ROC3),
						dcol_ROCn4_i 				=> tbm_emul_v1_dcol_i(chB)(ROC4),
						dcol_ROCn5_i 				=> tbm_emul_v1_dcol_i(chB)(ROC5),
						dcol_ROCn6_i 				=> tbm_emul_v1_dcol_i(chB)(ROC6),
						dcol_ROCn7_i 				=> tbm_emul_v1_dcol_i(chB)(ROC7),
						--
						row_ROCn0_i 				=> tbm_emul_v1_row_i(chB)(ROC0),
						row_ROCn1_i 				=> tbm_emul_v1_row_i(chB)(ROC1),
						row_ROCn2_i 				=> tbm_emul_v1_row_i(chB)(ROC2),
						row_ROCn3_i 				=> tbm_emul_v1_row_i(chB)(ROC3),
						row_ROCn4_i 				=> tbm_emul_v1_row_i(chB)(ROC4),
						row_ROCn5_i 				=> tbm_emul_v1_row_i(chB)(ROC5),
						row_ROCn6_i 				=> tbm_emul_v1_row_i(chB)(ROC6),
						row_ROCn7_i 				=> tbm_emul_v1_row_i(chB)(ROC7),
						--
						hit_ROCn0_i 				=> tbm_emul_v1_hit_i(chB)(ROC0),
						hit_ROCn1_i 				=> tbm_emul_v1_hit_i(chB)(ROC1),
						hit_ROCn2_i 				=> tbm_emul_v1_hit_i(chB)(ROC2),
						hit_ROCn3_i 				=> tbm_emul_v1_hit_i(chB)(ROC3),
						hit_ROCn4_i 				=> tbm_emul_v1_hit_i(chB)(ROC4),
						hit_ROCn5_i 				=> tbm_emul_v1_hit_i(chB)(ROC5),
						hit_ROCn6_i 				=> tbm_emul_v1_hit_i(chB)(ROC6),
						hit_ROCn7_i 				=> tbm_emul_v1_hit_i(chB)(ROC7),
						--
						header_flag_i				=> tbm_emul_v1_header_flag_i(chB), 			-- = [StackFull - PkamReset - StackCount(5:0)]
						trailer_flag1_i			=> tbm_emul_v1_trailer_flag1_i(chB), 		-- = [NoTokPass - ResetTBM - ResetROC - SyncErr - SyncTrig - ClrTrigCntr - CalTrig - StackFumm]					
						trailer_flag2_i			=> tbm_emul_v1_trailer_flag2_i(chB), 		-- = [DataID(1:0) - D(5:0)]		
						EvCntRes						=> EvCntRes
			  );


	end generate;	


	--==============================================================================================================================================--
	-- EMUL_VERSION = "V4" --
	--==============================================================================================================================================--	
	emul_version_V4_gen : if EMUL_VERSION = "V4" generate
		--MSB=chA / LSB=chB
		mux_tbm_ch_word8b_emul(15) 			<= x"ff";
		mux_tbm_ch_word8b_emul(14) 			<= x"ff";
		mux_tbm_ch_word8b_emul(13) 			<= x"ff";
		mux_tbm_ch_word8b_emul(12) 			<= x"ff";
		mux_tbm_ch_word8b_emul(11) 			<= x"ff";
		mux_tbm_ch_word8b_emul(10) 			<= x"ff";
		mux_tbm_ch_word8b_emul(09) 			<= x"ff";
		mux_tbm_ch_word8b_emul(08) 			<= x"ff";
	--	--chA
	--	mux_tbm_ch_word8b_emul(07) 			<= x"7f";	
	--	mux_tbm_ch_word8b_emul(06) 			<= x"ff";
	--	mux_tbm_ch_word8b_emul(05) 			<= x"cf";
	--	--
	--	--chB
	--	mux_tbm_ch_word8b_emul(07) 			<= x"f7";	
	--	mux_tbm_ch_word8b_emul(06) 			<= x"ff";
	--	mux_tbm_ch_word8b_emul(05) 			<= x"fc";
	--	--
		--chA&B
		mux_tbm_ch_word8b_emul(07) 			<= x"77";	
		mux_tbm_ch_word8b_emul(06) 			<= x"ff";
		mux_tbm_ch_word8b_emul(05) 			<= x"cc";
		--	
		mux_tbm_ch_word8b_emul(04) 			<= x"ff";
		mux_tbm_ch_word8b_emul(03) 			<= x"ff";
		mux_tbm_ch_word8b_emul(02) 			<= x"ff";
		mux_tbm_ch_word8b_emul(01) 			<= x"ff";
		mux_tbm_ch_word8b_emul(00) 			<= x"ff";

		--================================--	
		process  --cnt process
		--================================--	
		variable cnt : integer range 0 to 15 := 0;
		begin
			wait until rising_edge(clk_40_0_i);
				--
				if cnt = 0 and trigger_i = '1' then
					cnt := 15;
				elsif cnt = 0 then
					null;
				else
					cnt := cnt - 1;
				end if;
				--------------------------
				-- Channels affectation --
				--------------------------
					tbm_ch_word4b_tmp(chA)			<= mux_tbm_ch_word8b_emul(cnt)(7 downto 4);	
					tbm_ch_word4b_tmp(chB)			<= mux_tbm_ch_word8b_emul(cnt)(3 downto 0);
					
		end process;
		--================================--
	end generate;


	--==============================================================================================================================================--
	-- TBM Channels A & B - A bus of 4-bit for each channel --
	--==============================================================================================================================================--
	--> without a delaying added on chB:
	------------------------------------
	CHAN_B_DELAY_NO_gen : if CHAN_B_DELAY = "no" generate
		
		begin
			tbm_ch_word4b 								<= tbm_ch_word4b_tmp;
	end generate;

	--> with a delaying added on chB:
	---------------------------------
	CHAN_B_DELAY_YES_gen : if CHAN_B_DELAY = "yes" generate
	--
	begin
		tbm_ch_word4b(chA) 							<= tbm_ch_word4b_tmp(chA);

	--
	--================================--
	channelB_varDelay_inst : entity work.channelB_varDelay
	--================================--	
	PORT MAP (	clk 								=> clk_40_0_i,
					a	 								=> tbm_chB_delaying_i, --8b
					d									=> tbm_ch_word4b_tmp(chB),--4b
					q     							=> tbm_ch_word4b(chB)--4b
				);
	--================================--
	end generate;



	--==============================================================================================================================================--
	-- MUX / Interleaving of channels A & B --
	--==============================================================================================================================================--
	--> interleaves 2 bus of 4-bit / out data frame is then on 8-bit:
	-----------------------------------------------------------------
	process	
	begin
		wait until rising_edge(clk_40_0_i);
			--nibbleA
			mux_tbm_ch_word8b(7) 				<= 		tbm_ch_word4b(chA)(3);
			mux_tbm_ch_word8b(6) 				<= not 	tbm_ch_word4b(chB)(3);
			mux_tbm_ch_word8b(5) 				<= 		tbm_ch_word4b(chA)(2);
			mux_tbm_ch_word8b(4) 				<= not 	tbm_ch_word4b(chB)(2);
			--nibbleB
			mux_tbm_ch_word8b(3) 				<= 		tbm_ch_word4b(chA)(1);
			mux_tbm_ch_word8b(2) 				<= not 	tbm_ch_word4b(chB)(1);
			mux_tbm_ch_word8b(1) 				<= 		tbm_ch_word4b(chA)(0);
			mux_tbm_ch_word8b(0) 				<= not 	tbm_ch_word4b(chB)(0);		
	end process;
	


	--==============================================================================================================================================--
	-- div2 generation / 80M --
	--==============================================================================================================================================--
	process
	begin
		wait until rising_edge(clk_80_0_i);
			--div2
			div2_sync80M 							<= not div2_sync80M;			
	end process;

	
	--==============================================================================================================================================--
	-- latch/div2 + resync/80M --
	--==============================================================================================================================================--
	process
	begin
		wait until rising_edge(clk_80_0_i);
			--latch + resync
			if div2_sync80M = '0' then
				mux_tbm_ch_word8b_sync80M(0) 	<= mux_tbm_ch_word8b; 
				mux_tbm_ch_word8b_sync80M(1) 	<= mux_tbm_ch_word8b_sync80M(0); --not necessary
			end if;
			--
	end process;

				


	--==============================================================================================================================================--
	-- MUX / outputting of successive 4-bit symbols --
	--==============================================================================================================================================--		
	emul_version_notV3_gen : if EMUL_VERSION /= "V3" generate	
		process	
		begin
			wait until rising_edge(clk_80_0_i);
				--
				if div2_sync80M = '1' then
					tx_symb4b 						<= mux_tbm_ch_word8b_sync80M(1)(7 downto 4); --most-significant first
				else
					tx_symb4b 						<= mux_tbm_ch_word8b_sync80M(1)(3 downto 0); --then less-significant
				end if;
				--
		end process;
	end generate;  --> end emul_version_notV3_gen

	emul_version_V3_gen : if EMUL_VERSION = "V3" generate
		--emulV3
		mux_tbm_ch_word8b_emul(15) 			<= x"aa";
		mux_tbm_ch_word8b_emul(14) 			<= x"aa";
		mux_tbm_ch_word8b_emul(13) 			<= x"aa";
		mux_tbm_ch_word8b_emul(12) 			<= x"aa";
		mux_tbm_ch_word8b_emul(11) 			<= x"aa";
		mux_tbm_ch_word8b_emul(10) 			<= x"aa";
		mux_tbm_ch_word8b_emul(09) 			<= x"aa";
		mux_tbm_ch_word8b_emul(08) 			<= x"aa";
--		--7FC => chA
--		mux_tbm_ch_word8b_emul(07) 			<= x"2a";	
--		mux_tbm_ch_word8b_emul(06) 			<= x"aa";
--		mux_tbm_ch_word8b_emul(05) 			<= x"a0";
--		--
--		--7FC => chB
--		mux_tbm_ch_word8b_emul(07) 			<= x"ea";	
--		mux_tbm_ch_word8b_emul(06) 			<= x"aa";
--		mux_tbm_ch_word8b_emul(05) 			<= x"af";
--		--
		--7FC => chA & chB
		mux_tbm_ch_word8b_emul(07) 			<= x"6a";	
		mux_tbm_ch_word8b_emul(06) 			<= x"aa";
		mux_tbm_ch_word8b_emul(05) 			<= x"a5";
		--
		mux_tbm_ch_word8b_emul(04) 			<= x"aa";
		mux_tbm_ch_word8b_emul(03) 			<= x"aa";
		mux_tbm_ch_word8b_emul(02) 			<= x"aa";
		mux_tbm_ch_word8b_emul(01) 			<= x"aa";
		mux_tbm_ch_word8b_emul(00) 			<= x"aa";
		
		--
		process
		variable cnt : integer range 0 to 15 := 0;
		begin
			wait until rising_edge(clk_80_0_i);
				if div2_sync80M = '1' then
					tx_symb4b 						<= mux_tbm_ch_word8b_emul(cnt)(7 downto 4);
				else
					tx_symb4b 						<= mux_tbm_ch_word8b_emul(cnt)(3 downto 0);
				end if;
				if div2_sync80M = '0' then 
					if cnt = 0 and trigger_i = '1' then
						cnt 							:= 15;
					elsif cnt = 0 then
						null;
					else
						cnt 							:= cnt - 1;
					end if;
				end if;
		end process;
		--
	end generate;  --> end emul_version_V3_gen



	--==============================================================================================================================================--
	-- Encoding + Serialising --
	--==============================================================================================================================================--
   encoder4b5bNRZI_serialiser_inst: entity work.encoder4b5bNRZI_serialiser 
	PORT MAP (
          clk_80_0_i 							=> clk_80_0_i,
          clk_400_0_i 							=> clk_400_0_i,
          sclr_i 									=> sclr_i,
          symb4b_i 								=> tx_symb4b,
          symb4b_o 								=> tx_symb4b_o,
          symb5b_o 								=> tx_symb5b_o,
          tx_serial_dout_o 					=> tx_sdout_o
        );





	
----	--before
----	--delaying chB/chA
----	--> off
----	tbm_ch_word4b <= tbm_ch_word4b_tmp;
------	--> on
------	tbm_ch_word4b(chA) <= tbm_ch_word4b_tmp(chA);
------	--
------	--===============================================================================================--	
------	channelB_varDelay_inst : entity work.channelB_varDelay
------	--===============================================================================================--	
------	PORT MAP (	clk 			=> clk_40_0_i,
------					a	 			=> tbm_chB_delaying_i, --8b
------					d				=> tbm_ch_word4b_tmp(chB),--4b
------					q     		=> tbm_ch_word4b(chB)--4b
------				);
------	--===============================================================================================--	
--
--
--	----------------------------
--	-- Resync from 40M to 80M --
--	----------------------------
--	tbm_ch_word4b_to_resync80M 		<= tbm_ch_word4b_tmp(chA) & tbm_ch_word4b_tmp(chB);
--	--===============================================================================================--
--	resync_from_40M_to_80M_chA_and_B: entity work.clk_domain_bridge --between 1 to 127-bits
--	--===============================================================================================--
--	generic map (n => 8)
--	port map 
--	(
--		wrclk_i								=> clk_40_0_i,
--		rdclk_i								=> clk_80_0_i, 
--		wdata_i								=> tbm_ch_word4b_to_resync80M,
--		rdata_o								=> tbm_ch_word4b_resync80M
--	); 
--
--	tbm_ch_word4b(chA) 					<= tbm_ch_word4b_resync80M(7 downto 4);
--	tbm_ch_word4b(chB)					<= tbm_ch_word4b_resync80M(3 downto 0);
--
--
--
--
--	--resync tbm_ch_word4b/80M
--	process
--	begin
--		wait until rising_edge(clk_80_0_i);
--			--chA&B
--			tbm_ch_word4b_sync80M(0)		<= tbm_ch_word4b;
--			tbm_ch_word4b_sync80M(1)		<= tbm_ch_word4b_sync80M(0);			
--			--
--	end process;	
--
--
--	---------------------------------
--	-- MUX / channels interleaving --
--	---------------------------------
--	--> interleaves 2 bus of 4-bit / out data frame is then on 8-bit
--	----------------------------------------------------------------
--	--================================--	
--	process
--	--================================--	
--	begin
----		wait until rising_edge(clk_40_0_i);
--		wait until rising_edge(clk_80_0_i);
--			--nibbleA
--			mux_tbm_ch_word8b(7) <= 		tbm_ch_word4b(chA)(3);
--			mux_tbm_ch_word8b(6) <= not 	tbm_ch_word4b(chB)(3);
--			mux_tbm_ch_word8b(5) <= 		tbm_ch_word4b(chA)(2);
--			mux_tbm_ch_word8b(4) <= not 	tbm_ch_word4b(chB)(2);
--			--nibbleB
--			mux_tbm_ch_word8b(3) <= 		tbm_ch_word4b(chA)(1);
--			mux_tbm_ch_word8b(2) <= not 	tbm_ch_word4b(chB)(1);
--			mux_tbm_ch_word8b(1) <= 		tbm_ch_word4b(chA)(0);
--			mux_tbm_ch_word8b(0) <= not 	tbm_ch_word4b(chB)(0);		
--	end process;
--	--================================--

--	--resync/80M + latch/div2
--	process
--	begin
--		wait until rising_edge(clk_80_0_i);
--			mux_tbm_ch_word8b_sync80M(0) 		<= mux_tbm_ch_word8b; --not necessary
--			--latch
--			if div2_sync80M = '0' then
--				mux_tbm_ch_word8b_sync80M(1) 	<= mux_tbm_ch_word8b_sync80M(0); 
--			end if;
--			--
--	end process;



end Behavioral;

