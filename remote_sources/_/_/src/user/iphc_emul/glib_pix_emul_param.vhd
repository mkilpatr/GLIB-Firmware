--=================================================================================================--
--==================================== Module Information =========================================--
--=================================================================================================--
--                                                                                         
-- Institute:                 IPHC Laboratory (CNRS/Strasbourg)                                                         
-- Engineer:                	Laurent CHARLES (lcharles@iphc.cnrs.fr) 
--                                                                                                  
-- Project Name:            	PIXFED / CMS Tracker Upgrade Phase 1 (VME -> uTCA technology)                                                               
-- Module Name:             	glib_pix_emul_param.vhd                                       
--                                                                                                  
-- Language:               	VHDL'93                                                                  
--                                                                                                    
-- Target Device:           	Device agnostic                                                         
-- Tool version: 				   ISE14.6                                                                    
--                                                                                                    
-- Version:                 	0.1                                                                      
--
-- Description:             	* MEMORY MAP for I/O registers  
-- 
-- Versions history:        	DATE         VERSION   	AUTHOR            DESCRIPTION
--
--                          	17/12/2014   0.1       	LCHARLES          - First .vhd file 
--                                                                  
--
-- Additional Comments:                                                                             
--                                                                                                    
--=================================================================================================--
--=================================================================================================--

--! xilinx packages
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
--! system packages
use work.system_package.all;
use work.wb_package.all;
--! user packages
use work.user_package.all;
use work.user_addr_decode.all;
--! IPHC PKG
use work.pkg_glib_pix_emul.all;


	
	
	
entity glib_pix_emul_param is
--	generic(	glib_pix_emul_param_width : natural := 5); --2**5=32
port
(
	wb_mosi			: in  wb_mosi_bus;
	wb_miso			: out wb_miso_bus;
	---------------
	--From s/w to user_logic (Ctrl & Cmd)
	regs_o			: out glib_pix_emul_param_type;
	--From user_logic to s/w (Flags & Status)	
	regs_i			: in  glib_pix_emul_param_type
	 );
end glib_pix_emul_param;




architecture rtl of glib_pix_emul_param is


	signal regs						: glib_pix_emul_param_type;	

	signal sel						: integer range 0 to glib_pix_emul_param_depth-1; 
	signal ack						: std_logic;

	attribute keep					: boolean;
	attribute keep 				of ack: signal is true;
	attribute keep 				of sel: signal is true;

	signal regs_16_25to24_del1	: std_logic_vector(1 downto 0) := (others => '0');
	signal regs_16_25to24_del2	: std_logic_vector(1 downto 0) := (others => '0');	
	
	begin

	--=============================--
	-- IO mapping
	--=============================--

	--==========================================--
	--> To user_logic 
	--==========================================--
	regs_o 	<= 	regs;


	--==================================================--
	--> From user_logic (Flags & Status / Rd only)
	--==================================================--
	status_flags_gen : for i in 0 to RD_PARAM_NB-1 generate
		regs(i)	<= regs_i(i);
	end generate;


	--=============================--
	-- SEL
	--=============================--
	sel <= to_integer(unsigned(wb_mosi.wb_adr(glib_pix_emul_param_width-1 downto 0))) when glib_pix_emul_param_width>0 else 0;




	--=============================--
	process(wb_mosi.wb_rst, wb_mosi.wb_clk)
	--=============================--
	begin
	if wb_mosi.wb_rst='1' then
		ack 		<= '0';
		-- def val, ex:
		--regs(22)(1) <= '1'; --CLK40_ODDR_RISING_VAL = '1' by def
	elsif rising_edge(wb_mosi.wb_clk) then
		
		-- From s/w to temp reg
		if wb_mosi.wb_stb='1' and wb_mosi.wb_we='1' then
			case sel is	
				
				--------------------------------------
				-- 0 to 15 Rd only / Flags & Status --
				--------------------------------------		
--				when	0 			=> regs(00)	<= wb_mosi.wb_dat;	
--				when	1 			=> regs(01)	<= wb_mosi.wb_dat;	
--				when	2 			=> regs(02)	<= wb_mosi.wb_dat;				
--				when	3 			=> regs(03)	<= wb_mosi.wb_dat;	
-- 			when	4 			=> regs(04)	<= wb_mosi.wb_dat;	
--				when	5 			=> regs(05)	<= wb_mosi.wb_dat;  -- Bits as in FC7 for "to_sw_fmcfitel_i2c_ctrl_cmd_ack" and "fmcfitel_i2c_ctrl_fifo_rx_empty"  TWN 3/10/2016
--				when	6 			=> regs(06)	<= wb_mosi.wb_dat;	  
--				when	7 			=> regs(07)	<= wb_mosi.wb_dat;				
--				when	8 			=> regs(08)	<= wb_mosi.wb_dat;
--				when	9 			=> regs(09)	<= wb_mosi.wb_dat;				
--				when	10			=> regs(10) <= wb_mosi.wb_dat;	
--				when	11			=> regs(11) <= wb_mosi.wb_dat;
--				when	12			=> regs(12) <= wb_mosi.wb_dat;				
--				when	13			=> regs(13) <= wb_mosi.wb_dat;	
--				when	14			=> regs(14) <= wb_mosi.wb_dat;
--				when	15			=> regs(15) <= wb_mosi.wb_dat;				
				
				---------------------------------
				-- 16 to 31 Rd/Wr / Ctrl & Cmd --
				---------------------------------				
				 --when 16 to 31 or if sel >= PARAM_RD_ONLY_NB then regs(sel) <= wb_mosi.wb_dat;
				when	16			=> regs(16) <= wb_mosi.wb_dat;
				when	17			=> regs(17) <= wb_mosi.wb_dat;   -- for "from_sw_fmcfitel_i2c_ctrl_.....",  bits as in FC7,  TWN 3/10/2016
				when	18			=> regs(18) <= wb_mosi.wb_dat;				
				when	19			=> regs(19) <= wb_mosi.wb_dat;
				when	20			=> regs(20) <= wb_mosi.wb_dat;	
				when	21			=> regs(21) <= wb_mosi.wb_dat;
				when	22			=> regs(22) <= wb_mosi.wb_dat;
				when	23			=> regs(23) <= wb_mosi.wb_dat;				
				when	24			=> regs(24) <= wb_mosi.wb_dat;	
				when	25			=> regs(25) <= wb_mosi.wb_dat;
				when	26			=> regs(26) <= wb_mosi.wb_dat;				
				when	27			=> regs(27) <= wb_mosi.wb_dat;				
				when	28			=> regs(28) <= wb_mosi.wb_dat;	
				when	29			=> regs(29) <= wb_mosi.wb_dat;	
				when	30			=> regs(30) <= wb_mosi.wb_dat;	
				when	31			=> regs(31) <= wb_mosi.wb_dat;	
				when	32			=> regs(32) <= wb_mosi.wb_dat;	
				when	33			=> regs(33) <= wb_mosi.wb_dat;
				when	34			=> regs(34) <= wb_mosi.wb_dat;	
				when	35			=> regs(35) <= wb_mosi.wb_dat;				
				when	36			=> regs(36) <= wb_mosi.wb_dat;	
				when	37			=> regs(37) <= wb_mosi.wb_dat;
				when	38			=> regs(38) <= wb_mosi.wb_dat;	
				when	39			=> regs(39) <= wb_mosi.wb_dat;				
				when	40			=> regs(40) <= wb_mosi.wb_dat;
				when	41			=> regs(41) <= wb_mosi.wb_dat;				
				when	42			=> regs(42) <= wb_mosi.wb_dat;
				when	43			=> regs(43) <= wb_mosi.wb_dat;
				when	44			=> regs(44) <= wb_mosi.wb_dat;				
				when	45			=> regs(45) <= wb_mosi.wb_dat;
				when	46			=> regs(46) <= wb_mosi.wb_dat;
				when	47			=> regs(47) <= wb_mosi.wb_dat;				
				when	48			=> regs(48) <= wb_mosi.wb_dat;
				when	49			=> regs(49) <= wb_mosi.wb_dat;
				when	50			=> regs(50) <= wb_mosi.wb_dat;
				when	51			=> regs(51) <= wb_mosi.wb_dat;				
				when	52			=> regs(52) <= wb_mosi.wb_dat;
				when	53			=> regs(53) <= wb_mosi.wb_dat;
				when	54			=> regs(54) <= wb_mosi.wb_dat;				
				when	55			=> regs(55) <= wb_mosi.wb_dat;
				when	56			=> regs(56) <= wb_mosi.wb_dat;
				when	57			=> regs(57) <= wb_mosi.wb_dat;				
				when	58			=> regs(58) <= wb_mosi.wb_dat;
				when	59			=> regs(59) <= wb_mosi.wb_dat;
				when	60			=> regs(60) <= wb_mosi.wb_dat;
				when	61			=> regs(61) <= wb_mosi.wb_dat;				
				when	62			=> regs(62) <= wb_mosi.wb_dat;
				when	63			=> regs(63) <= wb_mosi.wb_dat;				
				when others 	=> 
			end case;	
		end if;

		-- From temp reg to s/w 
		wb_miso.wb_dat <= regs(sel);
		-- ack control	
		ack <= wb_mosi.wb_stb and (not ack);
		-- autoclear -----
--		if wb_mosi.wb_stb='0' then
--			regs(18)(1) <= '0'; 
--		end if;


--		-- autoclear -----
--		regs_16_25to24_del1 			<= regs(16)(25 downto 24);
--		regs_16_25to24_del2 			<= regs_16_25to24_del1;
--		if regs_16_25to24_del2(1) = '1' then
--			regs(16)(25)				<= '0';
--		end if;
--		if regs_16_25to24_del2(0) = '1' then
--			regs(16)(24)				<= '0';
--		end if;
		

--		-- From temp reg to s/w 	
--		case sel is	
--			--------------------------------------
--			-- 0 to 15 Rd only / Flags & Status --
--			--------------------------------------	
--			when	0 			=> wb_miso.wb_dat	<= regs(sel);	
--			when	1 			=> wb_miso.wb_dat	<= regs(sel);	
--			when	2 			=> wb_miso.wb_dat	<= regs(sel);				
--			when	3 			=> wb_miso.wb_dat	<= regs(sel);	
--			when	4 			=> wb_miso.wb_dat	<= regs(sel);	
--			when	5 			=> wb_miso.wb_dat	<= regs(sel);
--			when	6 			=> wb_miso.wb_dat	<= regs(sel);	
--			when	7 			=> wb_miso.wb_dat	<= regs(sel);				
--			when	8 			=> wb_miso.wb_dat	<= regs(sel);
--			when	9 			=> wb_miso.wb_dat	<= regs(sel);				
--			when	10			=> wb_miso.wb_dat <= regs(sel);	
--			when	11			=> wb_miso.wb_dat <= regs(sel);
--			when	12			=> wb_miso.wb_dat <= regs(sel);				
--			when	13			=> wb_miso.wb_dat <= regs(sel);	
--			when	14			=> wb_miso.wb_dat <= regs(sel);
--			when	15			=> wb_miso.wb_dat <= regs(sel);				
--			---------------------------------
--			-- 16 to 31 Rd/Wr / Ctrl & Cmd --
--			---------------------------------				
--			when	16			=> wb_miso.wb_dat(25 downto 24) 	<= regs_i(sel)(25 downto 24);
--									wb_miso.wb_dat(20 downto 0)	<= regs(sel)(20 downto 0);
--			when	17			=> wb_miso.wb_dat <= regs(sel);
--			when	18			=> wb_miso.wb_dat <= regs(sel);				
--			when	19			=> wb_miso.wb_dat <= regs(sel);
--			when	20			=> wb_miso.wb_dat <= regs(sel);	
--			when	21			=> wb_miso.wb_dat <= regs(sel);
--			when	22			=> wb_miso.wb_dat <= regs(sel);
--			when	23			=> wb_miso.wb_dat <= regs(sel);				
--			when	24			=> wb_miso.wb_dat <= regs(sel);	
--			when	25			=> wb_miso.wb_dat <= regs(sel);
--			when	26			=> wb_miso.wb_dat <= regs(sel);				
--			when	27			=> wb_miso.wb_dat <= regs(sel);				
--			when	28			=> wb_miso.wb_dat <= regs(sel);	
--			when	29			=> wb_miso.wb_dat <= regs(sel);	
--			when	30			=> wb_miso.wb_dat <= regs(sel);	
--			when	31			=> wb_miso.wb_dat <= regs(sel);	
--			when others 	=> 
--		end case;		
	
	
	end if;
	end process;
		

	wb_miso.wb_ack  <= ack;
	wb_miso.wb_err  <= '0';	
	








end rtl;