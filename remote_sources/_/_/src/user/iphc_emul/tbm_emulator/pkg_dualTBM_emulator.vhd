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
 
--! user packages


package pkg_dualTBM_emulator is




	--=======================--
   -- Constants declaration --
   --=======================--
	constant TBM_CH_NB	 															: positive := 2; 	
	constant ROC_NB_MAX	 															: positive := 8; --by channel!!!
	--
	constant chA 																		: integer := 0;
	constant chB 																		: integer := 1;	
	constant ROC0 																		: integer := 0;
	constant ROC1 																		: integer := 1;	
	constant ROC2 																		: integer := 2;
	constant ROC3 																		: integer := 3;	
	constant ROC4 																		: integer := 4;
	constant ROC5 																		: integer := 5;	
	constant ROC6 																		: integer := 6;
	constant ROC7 																		: integer := 7;
	
	--===================--
   -- Types declaration --
   --===================--
	type array_TBM_CH_NBx1b 														is array(TBM_CH_NB-1 downto 0) of std_logic;
	type array_2xarray_TBM_CH_NBx1b												is array(1 downto 0) of array_TBM_CH_NBx1b;
	type array_TBM_CH_NBx3b 														is array(TBM_CH_NB-1 downto 0) of std_logic_vector(2 downto 0);
	type array_TBM_CH_NBx4b 														is array(TBM_CH_NB-1 downto 0) of std_logic_vector(3 downto 0);	
	type array_TBM_CH_NBx6b 														is array(TBM_CH_NB-1 downto 0) of std_logic_vector(5 downto 0);	
	type array_TBM_CH_NBx8b 														is array(TBM_CH_NB-1 downto 0) of std_logic_vector(7 downto 0);
	type array_TBM_CH_NBx9b 														is array(TBM_CH_NB-1 downto 0) of std_logic_vector(8 downto 0);

	type array_ROC_NB_MAXx4b 														is array(ROC_NB_MAX-1 downto 0) of std_logic_vector(3 downto 0);
	type array_ROC_NB_MAXx6b 														is array(ROC_NB_MAX-1 downto 0) of std_logic_vector(5 downto 0);	
	type array_ROC_NB_MAXx8b 														is array(ROC_NB_MAX-1 downto 0) of std_logic_vector(7 downto 0);
	type array_ROC_NB_MAXx9b 														is array(ROC_NB_MAX-1 downto 0) of std_logic_vector(8 downto 0);

	type array_TBM_CH_NBxROC_NB_MAXx4b											is array(TBM_CH_NB-1 downto 0) of array_ROC_NB_MAXx4b;	
	type array_TBM_CH_NBxROC_NB_MAXx6b											is array(TBM_CH_NB-1 downto 0) of array_ROC_NB_MAXx6b;
	type array_TBM_CH_NBxROC_NB_MAXx8b											is array(TBM_CH_NB-1 downto 0) of array_ROC_NB_MAXx8b;
	type array_TBM_CH_NBxROC_NB_MAXx9b											is array(TBM_CH_NB-1 downto 0) of array_ROC_NB_MAXx9b;
	

end pkg_dualTBM_emulator;

package body pkg_dualTBM_emulator is
end pkg_dualTBM_emulator;
