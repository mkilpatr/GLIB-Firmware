--
--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 
--
--   To use any of the example code shown below, uncomment the lines and modify as necessary
--
library ieee;
use ieee.std_logic_1164.all;
--use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

--! Custom libraries and packages: 
use work.fmc_package.all; 


--! user packages
--! IPHC PKG
--! dualTBM_emulator
use work.pkg_dualTBM_emulator.all; 


package pkg_glib_pix_emul is


--	---------------********************************attribute************************************----------------
--	attribute register_duplication									: string;
--	attribute incremental_synthesis									: string;
--	attribute init															: string;
--	attribute tig															: string;
--	attribute keep_hierarchy 											: string;
-- attribute keep                  									: string;  
--	attribute iob 															: string;  
--	attribute loc                   									: string;
--	attribute pullup                									: string;
--	attribute iostandard            									: string;
--	attribute clock_dedicated_route 									: string;	
--	---------------******************************END attribute**********************************----------------	


	--=======================================--
	-- ARCHI GENE
	--=======================================--

	--===========--
   -- Constants --
   --===========--
	constant TBM_EMUL_NB		 											: positive := 1;--24;--1; --[1:48]
	
-- see pkg_dualTBM_emulator
--	constant TBM_CH_NB	 												: positive := 2; 
--	constant chA 															: integer := 0; --see pkg_dualTBM_emulator
--	constant chB 															: integer := 1;	
--	constant ROC0 															: integer := 0;
--	constant ROC1 															: integer := 1;	
--	constant ROC2 															: integer := 2;
--	constant ROC3 															: integer := 3;	
--	constant ROC4 															: integer := 4;
--	constant ROC5 															: integer := 5;	
--	constant ROC6 															: integer := 6;
--	constant ROC7 															: integer := 7;
	--===================--
   -- Types declaration --
   --===================--
	type array_TBM_EMUL_NBxTBM_CH_NBx1b 							is array(TBM_EMUL_NB-1 downto 0) of array_TBM_CH_NBx1b;
	type array_TBM_EMUL_NBxTBM_CH_NBx3b 							is array(TBM_EMUL_NB-1 downto 0) of array_TBM_CH_NBx3b;
	type array_TBM_EMUL_NBxTBM_CH_NBx4b 							is array(TBM_EMUL_NB-1 downto 0) of array_TBM_CH_NBx4b;	
	type array_TBM_EMUL_NBxTBM_CH_NBx6b 							is array(TBM_EMUL_NB-1 downto 0) of array_TBM_CH_NBx6b;	
	type array_TBM_EMUL_NBxTBM_CH_NBx8b 							is array(TBM_EMUL_NB-1 downto 0) of array_TBM_CH_NBx8b;
	type array_TBM_EMUL_NBxTBM_CH_NBx9b 							is array(TBM_EMUL_NB-1 downto 0) of array_TBM_CH_NBx9b;
	--
	type array_TBM_EMUL_NBxTBM_CH_NBxROC_NB_MAXx4b				is array(TBM_EMUL_NB-1 downto 0) of array_TBM_CH_NBxROC_NB_MAXx4b;
	type array_TBM_EMUL_NBxTBM_CH_NBxROC_NB_MAXx6b				is array(TBM_EMUL_NB-1 downto 0) of array_TBM_CH_NBxROC_NB_MAXx6b;
	type array_TBM_EMUL_NBxTBM_CH_NBxROC_NB_MAXx8b				is array(TBM_EMUL_NB-1 downto 0) of array_TBM_CH_NBxROC_NB_MAXx8b;
	type array_TBM_EMUL_NBxTBM_CH_NBxROC_NB_MAXx9b				is array(TBM_EMUL_NB-1 downto 0) of array_TBM_CH_NBxROC_NB_MAXx9b;
	--
	type array_TBM_EMUL_NBx8b											is array(TBM_EMUL_NB-1 downto 0) of std_logic_vector(7 downto 0);		
	type array_TBM_EMUL_NBx2b											is array(TBM_EMUL_NB-1 downto 0) of std_logic_vector(1 downto 0);	

   type array_Nx2b 									    				is array(natural range <>) of std_logic_vector(1 downto 0);
	--=======================================--
	-- VERSIONING
	--=======================================--
	-->From IPHC
	--ASCII CODES
	constant USER_IPHC_ASCII_WORD_01									: std_logic_vector(31 downto 0)	:= x"50_49_58_20"; -- 'P I X  '	
	constant USER_IPHC_ASCII_WORD_02									: std_logic_vector(31 downto 0)	:= x"45_4D_55_4C"; -- 'E M U L '		
	--FW VER
	constant USER_IPHC_FW_VER_YEAR									: integer range 0 to 99 			:= 15; 	--7b
	constant USER_IPHC_FW_VER_MONTH									: integer range 0 to 12 			:= 08;	--4b
	constant USER_IPHC_FW_VER_DAY  									: integer range 0 to 31 			:= 17;	--5b
	constant USER_IPHC_ARCHI_VER_NB  								: integer range 0 to 2**8-1 		:= 1;		--8b	
	--x"01" : 1 TBM output 
	constant USER_IPHC_FW_VER_NB  									: integer range 0 to 2**8-1 		:= 1;		--8b	
	


	--=======================================--
	-- ARCHITECTURE - CONSTANTS
	--=======================================--
	--> Fixed
	constant fmc1_j2 														: integer := 0; --J2
	constant fmc2_j1 														: integer := 1; --J1
	--> To define	
	constant fmc1_j2_type 												: string := "fmcfitel";	 	--"unused", "fmc8sfp", "fmcdio", "fmcfitel"  ---- TWN 2/23/2016 (was "fmc8sfp")
	constant fmc2_j1_type 												: string := "fmcdio"; 		--"unused", "fmc8sfp", "fmcdio",
--	constant ctrl_mode													: string := "by_fmc1_j2"; 	--"by_fmc1_j2" "by_fmc2_j1"

	
	-- fmc_la_settings:
	-------------------	
	function func_fmc_la_settings										( 		fmc_type_i : string  
																					 ) return fmc_la_io_settings_array;	--see fmc_package.vhd

--	constant fmc1_j2_la_io_settings									: fmc_la_io_settings_array := func_fmc_la_settings(fmc1_j2_type);
--	constant fmc2_j1_la_io_settings									: fmc_la_io_settings_array := func_fmc_la_settings(fmc2_j1_type);	
	
	
	--==========================================================--
	-- PARAMETERS LIST - I/O REGISTERS STORED INTO A MEMORY MAP --
	--==========================================================--
	constant glib_pix_emul_param_width 								: natural := 6; --2^6 = 64 x 32bit-words	
	constant glib_pix_emul_param_depth 								: natural := 2**(glib_pix_emul_param_width); --2^6 = 64 x 32b-words	
	type glib_pix_emul_param_type 									is array (glib_pix_emul_param_depth-1 downto 0) of std_logic_vector(31 downto 0);	
	constant RD_PARAM_NB													: integer	:= 16;
	constant RD_PARAM_ADDR_0 											: integer 	:= 0;
	constant WR_PARAM_ADDR_0 											: integer 	:= RD_PARAM_ADDR_0 + RD_PARAM_NB;	
	signal glib_pix_emul_param_i 										: glib_pix_emul_param_type;	
	signal glib_pix_emul_param_o 										: glib_pix_emul_param_type;	
	signal glib_pix_emul_param_o_resync_40M						: glib_pix_emul_param_type;

	--

	--=========================--
	-- FMC IO TYPE DECLARATION --
	--=========================--
	type fmc_from_fabric_to_pin_array_type 						is array (0 to 1) of fmc_from_fabric_to_pin_type; 	--see fmc_package
	type fmc_from_pin_to_fabric_array_type 						is array (0 to 1) of fmc_from_pin_to_fabric_type;	--see fmc_package		
--	signal fmc_from_fabric_to_pin_array 							: fmc_from_fabric_to_pin_array_type;
--	signal fmc_from_pin_to_fabric_array 							: fmc_from_pin_to_fabric_array_type;


	--====================================--
	-- FMC IO SETTINGS - SEVERAL CHOOICES --
	--====================================--
	--==========--
   -- FMC DIO5 --
   --==========--
	constant fmc_la_io_settings_fmcdio_constants:fmc_la_io_settings_array:=
	(
--CHOICE : "lvds" / "cmos" - "in__" / "out_" / "i_o_" / "ckin"
--=============================--
--    std     dir_p   dir_n	
--=============================--
		"lvds", "in__", "in__",		--FMC2_LA00		--		OUT(4) 	--> LEMO_4 MODE IN 	+ OE_N(4) DISABLED	 
		"cmos", "out_", "out_",		--FMC2_LA01		--		_p : LED_TOP / _n : LED_BOT
		"cmos", "in__", "in__",		--FMC2_LA02		-- 	
		"lvds", "in__", "in__",		--FMC2_LA03		--		OUT(3) 	--> LEMO_3 MODE IN 	+ OE_N(3) DISABLED	 	
		"lvds", "out_", "out_",		--FMC2_LA04		--		IN(4) 	--> LEMO_4 MODE OUT 	+ OE_N(4) VALID	  
		"cmos", "out_", "out_",		--FMC2_LA05		--		_p : OE_N(4) / _n = TERM_EN(2)	 
		"cmos", "in__", "out_",		--FMC2_LA06		--		_n = TERM_EN(1)	 
		"lvds", "out_", "out_",		--FMC2_LA07		--		IN(3) 	--> LEMO_3 MODE OUT 	+ OE_N(3) VALID	 
		"lvds", "out_", "out_",		--FMC2_LA08		--		IN(2) 	--> LEMO_2 MODE OUT 	+ OE_N(2) VALID 	 
		"cmos", "out_", "out_",		--FMC2_LA09		--		_p = TERM_EN(3) / _n = TERM_EN(4)
		"cmos", "in__", "in__",		--FMC2_LA10		--	
		"cmos", "out_", "in__",		--FMC2_LA11		--		_p : OE_N(3)	 
		"cmos", "in__", "in__",		--FMC2_LA12		--		
		"cmos", "in__", "in__",		--FMC2_LA13		--	 
		"cmos", "in__", "in__",		--FMC2_LA14		--	
		"cmos", "in__", "out_",		--FMC2_LA15		--		_n : OE_N(2)	
		"lvds", "in__", "in__",		--FMC2_LA16		--		OUT(2) 	--> LEMO_2 MODE IN 	+ OE_N(2) DISABLED	 		
		"cmos", "in__", "in__",		--FMC2_LA17		-- 	
		"cmos", "in__", "in__",		--FMC2_LA18		--		
		"cmos", "in__", "in__",		--FMC2_LA19		--	 		 
		"lvds", "in__", "in__",		--FMC2_LA20		--		OUT(1) 	--> LEMO_1 MODE IN 	+ OE_N(1) DISABLED					
		"cmos", "in__", "in__",		--FMC2_LA21		--		 
		"cmos", "in__", "in__",		--FMC2_LA22		--		
		"cmos", "in__", "i_o_",		--FMC2_LA23		--		_n : ONEWIRE		
		"cmos", "in__", "out_",		--FMC2_LA24		--		_n : OE_N(1)		
		"cmos", "in__", "in__",		--FMC2_LA25		--		 
		"cmos", "in__", "in__",		--FMC2_LA26		--		
		"cmos", "in__", "in__",		--FMC2_LA27		--		 
		"lvds", "out_", "out_",		--FMC2_LA28		--		IN(1) 	--> LEMO_1 MODE OUT 	+ OE_N(1) VALID		
		"lvds", "out_", "out_",		--FMC2_LA29		--		IN(0)		--> LEMO_0 MODE OUT 	+ OE_N(0) VALID
		"cmos", "out_", "out_",		--FMC2_LA30		--		_p : OE_N(0) / _n = TERM_EN(0)
		"cmos", "in__", "in__",		--FMC2_LA31		--		
		"cmos", "in__", "in__",		--FMC2_LA32		--		
		"lvds", "in__", "in__"		--FMC2_LA33		--		OUT(0) 	--> LEMO_0 MODE IN 	+ OE_N(0) DISABLED				
	);


	--===========--
   -- FMC FITEL --     CHANGED LINES 208 THRU 231 TO OUTPUTS - TWN 2/23/2016 -
   --===========--
	constant fmc_la_io_settings_fmcfitel_constants:fmc_la_io_settings_array:=
	(
--CHOICE : "lvds" / "cmos" - "in__" / "out_" / "i_o_" / "ckin"
--=============================--
--    std     dir_p   dir_n	
--=============================--
		"cmos", "out_", "i_o_",		--FMC2_LA00		--		_p : FRR2_SCL_VADJ	/	_n :  FRR2_SDA_VADJ
		"cmos", "out_", "out_",		--FMC2_LA01		--		_p : FRR2_NINT_VADJ	/	_n :  FRR2_RST_VADJ		
		"cmos", "out_", "i_o_",		--FMC2_LA02		--		_p : FRR1_SCL_VADJ	/	_n :  FRR1_SDA_VADJ 	
		"cmos", "out_", "out_",		--FMC2_LA03		--		_p : FRR1_NINT_VADJ	/	_n :  FRR1_RST_VADJ			 	
		"cmos", "out_", "out_",		--FMC2_LA04		--		_p : LED1_N_VADJ		/	_n :  LED2_N_VADJ			  
		"cmos", "out_", "out_",		--FMC2_LA05		--		_p : LED3_N_VADJ		/	_n :  LED4_N_VADJ		 
		"lvds", "out_", "out_",		--FMC2_LA06		--		LS_RX(1)(7)			 
		"lvds", "out_", "out_",		--FMC2_LA07		--		LS_RX(1)(8)			 
		"lvds", "out_", "out_",		--FMC2_LA08		--		LS_RX(1)(9)			 
		"lvds", "out_", "out_",		--FMC2_LA09		--		LS_RX(1)(10)		
		"lvds", "out_", "out_",		--FMC2_LA10		--		LS_RX(1)(11)	
		"lvds", "out_", "out_",		--FMC2_LA11		--		LS_RX(1)(12)		
		"lvds", "out_", "out_",		--FMC2_LA12		--		LS_RX(1)(1)		
		"lvds", "out_", "out_",		--FMC2_LA13		--		LS_RX(1)(2)	 
		"lvds", "out_", "out_",		--FMC2_LA14		--		LS_RX(1)(3)	
		"lvds", "out_", "out_",		--FMC2_LA15		--		LS_RX(1)(4)		
		"lvds", "out_", "out_",		--FMC2_LA16		--		LS_RX(1)(5)				 		
		"lvds", "out_", "out_",		--FMC2_LA17		--		LS_RX(1)(6) 	
		"lvds", "out_", "out_",		--FMC2_LA18		--		LS_RX(2)(7)		
		"lvds", "out_", "out_",		--FMC2_LA19		--		LS_RX(2)(8)	 		 
		"lvds", "out_", "out_",		--FMC2_LA20		--		LS_RX(2)(9)								
		"lvds", "out_", "out_",		--FMC2_LA21		--		LS_RX(2)(10)		 
		"lvds", "out_", "out_",		--FMC2_LA22		--		LS_RX(2)(11)			
		"lvds", "out_", "out_",		--FMC2_LA23		--		LS_RX(2)(12)				
		"lvds", "out_", "out_",		--FMC2_LA24		--		LS_RX(2)(1)				
		"lvds", "out_", "out_",		--FMC2_LA25		--		LS_RX(2)(2)			 
		"lvds", "out_", "out_",		--FMC2_LA26		--		LS_RX(2)(3)		
		"lvds", "out_", "out_",		--FMC2_LA27		--		LS_RX(2)(4)		 
		"lvds", "out_", "out_",		--FMC2_LA28		--		LS_RX(2)(5)				
		"lvds", "out_", "out_",		--FMC2_LA29		--		LS_RX(2)(6)			
		"lvds", "in__", "in__",		--FMC2_LA30		--		
		"lvds", "in__", "in__",		--FMC2_LA31		--		
		"lvds", "in__", "in__",		--FMC2_LA32		--		
		"lvds", "in__", "in__"		--FMC2_LA33		--						
	);


	--==========--
   -- FMC DIO5 -- 
   --==========--
	constant fmc_la_io_settings_fmc_dtx4_cha_constants : fmc_la_io_settings_array:=
	(
--CHOICE : "lvds" / "cmos" - "in__" / "out_" / "i_o_" / "ckin"
--=============================--
--    std     dir_p   dir_n	
--=============================--
		"lvds", "out_", "out_",		--FMC2_LA00		--	LEMO1 OUT	 
		"lvds", "out_", "out_",		--FMC2_LA01		--	LEMO2 OUT			
		"lvds", "out_", "out_",		--FMC2_LA02		--	LEMO3 OUT		 	
		"lvds", "out_", "out_",		--FMC2_LA03		--	LEMO4 OUT					 	
		"cmos", "in__", "in__",		--FMC2_LA04		--			  
		"cmos", "in__", "in__",		--FMC2_LA05		--			 
		"cmos", "in__", "in__",		--FMC2_LA06		--			 
		"cmos", "in__", "in__",		--FMC2_LA07		--			 
		"cmos", "in__", "in__",		--FMC2_LA08		--		 	 
		"cmos", "in__", "in__",		--FMC2_LA09		--		
		"cmos", "in__", "in__",		--FMC2_LA10		--	
		"cmos", "in__", "in__",		--FMC2_LA11		--			 
		"cmos", "in__", "in__",		--FMC2_LA12		--		
		"cmos", "in__", "in__",		--FMC2_LA13		--	 
		"cmos", "in__", "in__",		--FMC2_LA14		--	
		"cmos", "in__", "in__",		--FMC2_LA15		--			
		"cmos", "in__", "in__",		--FMC2_LA16		--			 		
		"cmos", "in__", "in__",		--FMC2_LA17		-- 	
		"cmos", "in__", "in__",		--FMC2_LA18		--		
		"cmos", "in__", "in__",		--FMC2_LA19		--	 		 
		"cmos", "in__", "in__",		--FMC2_LA20		--							
		"cmos", "in__", "in__",		--FMC2_LA21		--		 
		"cmos", "in__", "in__",		--FMC2_LA22		--		
		"cmos", "in__", "in__",		--FMC2_LA23		--			
		"cmos", "in__", "in__",		--FMC2_LA24		--				
		"cmos", "in__", "in__",		--FMC2_LA25		--		 
		"cmos", "in__", "in__",		--FMC2_LA26		--		
		"cmos", "in__", "in__",		--FMC2_LA27		--		 
		"cmos", "in__", "in__",		--FMC2_LA28		--				
		"cmos", "in__", "in__",		--FMC2_LA29		--		
		"cmos", "in__", "in__",		--FMC2_LA30		--		
		"cmos", "in__", "in__",		--FMC2_LA31		--		
		"cmos", "in__", "in__",		--FMC2_LA32		--		
		"cmos", "in__", "in__"		--FMC2_LA33		--						
	);


	--==========--
   -- FMC_8SFP -- 
   --==========--
	constant fmc_la_io_settings_fmc8sfp_constants : fmc_la_io_settings_array:= 
	(
--CHOICE : "lvds" / "cmos" - "in__" / "out_" / "i_o_" / "ckin"
--=============================--
--    std     dir_p   dir_n	
--=============================--
		"lvds", "in__", "in__",		--FMC2_LA00		-- 
		"lvds", "in__", "in__",		--FMC2_LA01		--		RX_A 
		"lvds", "out_", "out_",		--FMC2_LA02		--		TX_A 
		"lvds", "in__", "in__",		--FMC2_LA03		--		RX_B 	
		"lvds", "out_", "out_",		--FMC2_LA04		--		TX_B	  
		"lvds", "in__", "in__",		--FMC2_LA05		--		RX_C		 
		"lvds", "out_", "out_",		--FMC2_LA06		--		TX_C		 
		"lvds", "in__", "in__",		--FMC2_LA07		--		RX_D		 
		"lvds", "out_", "out_",		--FMC2_LA08		--		TX_D		 
		"lvds", "in__", "in__",		--FMC2_LA09		--		RX_E		
		"lvds", "out_", "out_",		--FMC2_LA10		--		TX_E		
		"lvds", "in__", "in__",		--FMC2_LA11		--		RX_F		 
		"lvds", "out_", "out_",		--FMC2_LA12		--		TX_F			
		"lvds", "in__", "in__",		--FMC2_LA13		--		RX_G		 
		"lvds", "out_", "out_",		--FMC2_LA14		--		TX_G		
		"lvds", "in__", "in__",		--FMC2_LA15		--		RX_H		
		"lvds", "out_", "out_",		--FMC2_LA16		--		TX_H					
		"lvds", "in__", "in__",		--FMC2_LA17		--				
		"lvds", "in__", "in__",		--FMC2_LA18		--			
		"lvds", "in__", "in__",		--FMC2_LA19		--				 
		"lvds", "in__", "in__",		--FMC2_LA20		--			
		"lvds", "in__", "in__",		--FMC2_LA21		--			 
		"lvds", "in__", "in__",		--FMC2_LA22		--			
		"lvds", "in__", "in__",		--FMC2_LA23		--			
		"lvds", "in__", "in__",		--FMC2_LA24		--			
		"lvds", "in__", "in__",		--FMC2_LA25		--			 
		"lvds", "in__", "in__",		--FMC2_LA26		--			
		"lvds", "in__", "in__",		--FMC2_LA27		--			 
		"lvds", "in__", "in__",		--FMC2_LA28		--			
		"lvds", "in__", "in__",		--FMC2_LA29		--			
		"lvds", "in__", "in__",		--FMC2_LA30		--			
		"lvds", "in__", "in__",		--FMC2_LA31		--			
		"cmos", "out_", "i_o_",		--FMC2_LA32		-- 	_p : SCL 	/ _n : SDA			
		"cmos", "out_", "in__"		--FMC2_LA33		-- 	_p : RST_N 	/ _n : INT_N 			
	); 
end pkg_glib_pix_emul;

package body pkg_glib_pix_emul is


	-- fmc_la_settings:
	-------------------	
	function func_fmc_la_settings(fmc_type_i : string)
	return fmc_la_io_settings_array is
		variable fmc_la_io_settings	: fmc_la_io_settings_array := fmc_la_io_settings_defaults;
	begin
--		case fmc_type_i is
--			when "fmcfitel" 		=> fmc_la_io_settings 	:= fmc_la_io_settings_fmcfitel_constants;
--			when "fmc8sfp" 		=> fmc_la_io_settings 	:= fmc_la_io_settings_fmc8sfp_constants;
--			when "unused" 			=> fmc_la_io_settings 	:= fmc_la_io_settings_defaults;
--			when "fmcdio" 			=> fmc_la_io_settings 	:= fmc_la_io_settings_fmcdio_constants;			
--			--...
--			when others 			=> fmc_la_io_settings 	:= fmc_la_io_settings_defaults;
--		end case;		

		if 	fmc_type_i = "fmcfitel" then
			fmc_la_io_settings 	:= fmc_la_io_settings_fmcfitel_constants;
		elsif fmc_type_i = "fmc8sfp" then
			fmc_la_io_settings 	:= fmc_la_io_settings_fmc8sfp_constants; 
		elsif fmc_type_i = "unused" then
			fmc_la_io_settings 	:= fmc_la_io_settings_defaults; 
		elsif fmc_type_i = "fmcdio" then
			fmc_la_io_settings 	:= fmc_la_io_settings_fmcdio_constants; 
		else
			fmc_la_io_settings 	:= fmc_la_io_settings_defaults;
		end if;
		--
		return fmc_la_io_settings;
	end;

end pkg_glib_pix_emul;
