--=================================================================================================--
--==================================== Module Information =========================================--
--=================================================================================================--
--                                                                                         
-- Institute:                 IPHC Laboratory (CNRS/Strasbourg)                                                         
-- Engineer:                	Laurent CHARLES (lcharles@iphc.cnrs.fr) 
--                                                                                                  
-- Project Name:            	PIXFED / CMS Pixel Upgrade Phase I (VME -> uTCA technology)                                                               
-- Module Name:             	encoder4b5bNRZI_serialiser.vhd                                       
--                                                                                                  
-- Language:               	VHDL'93                                                                  
--                                                                                                    
-- Target Device:           	Device agnostic                                                         
-- Tool version: 				   ISE14.6                                                                    
--                                                                                                    
-- Version:                 	0.2                                                                      
--
-- Description:             	* This logic block performs
--												--> 4b/5b encoding + special framing for symb4b = x"A" (see doc from Ed Bartz)
--												--> NRZI encoding
--												--> Serialization
--
-- 
-- Versions history:        	DATE         VERSION   	AUTHOR            DESCRIPTION
--
--                          	2014/01/09   0.1       	LCHARLES          - First .vhd file 
--                          	2015/08/11   0.2       	LCHARLES          - correction Latch + resync from 80M -> 400M                                                                 
--																								-
-- Additional Comments:                                                                             
--                                                                                                    
--=================================================================================================--
--=================================================================================================--


-- IEEE VHDL standard library:
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Xilinx devices library:
-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;


entity encoder4b5bNRZI_serialiser is
port (	
			--==================--
			-- Resets and Clock --
			--==================--
			clk_80_0_i 								: in std_logic;
			clk_400_0_i 							: in std_logic;
			sclr_i									: in std_logic; 
			--====================================--
			-- 4-bit data word from FSM to encode --
			--====================================--				
			symb4b_i									: in std_logic_vector(3 downto 0);
			--=======================--
			-- Symbols in same phase --
			--=======================--			
			-- used for verif
			symb4b_o									: out std_logic_vector(3 downto 0); -- => symb4b_i delayed to be in phase with symb5b_o
			symb5b_o									: out std_logic_vector(4 downto 0);
			--=====================--
			-- Serial Data Outputs --
			--=====================--	
			tx_serial_dout_o						: out std_logic

		);
end encoder4b5bNRZI_serialiser;

architecture Behavioral of encoder4b5bNRZI_serialiser is

   --========================= Signal Declarations ==========================--

	--4b/5b enconding
	signal symb4b									: std_logic_vector(3 downto 0) 	:= x"A";
	signal symb4b_next							: std_logic_vector(3 downto 0) 	:= x"A";  
	constant symb5b_Idle 						: std_logic_vector(4 downto 0) 	:= "10000"; --for init and framing
	signal symb5b									: std_logic_vector(4 downto 0) 	:= symb5b_Idle;	

	--modulo 5 down-counter + div5
	signal modulo5_cnt							: integer range 0 to 4:=4;
	signal div5_del								: std_logic_vector(4 downto 0) 	:= (others => '0');
	
	--resync
	type array_2x5bit								is array(1 downto 0) of std_logic_vector(4 downto 0);
	signal symb5b_resync400						: array_2x5bit 						:= (others => symb5b_Idle);

	--serial data
	signal tx_serial_dout						: std_logic								:='0';

	--sim
	signal sdata_no_nrzi							: std_logic								:='0'; 
	

	
   --========================================================================--   
 
--===========================================================================--
-----        --===================================================--
begin      --================== Architecture Body ==================-- 
-----        --===================================================--
--===========================================================================--
   
   --============================= User Logic ===============================--


	--============--
	-- OUTPUTTING --
	--============--	
	--> symbols in phase
	process
	begin
		wait until rising_edge(clk_80_0_i);		
			symb4b_next				<= symb4b_i;
			symb4b	 				<= symb4b_next;			
			symb4b_o					<= symb4b;
	end process;
	--		
	symb5b_o 						<= symb5b;
	--
	process
	begin
		wait until rising_edge(clk_400_0_i);	
			tx_serial_dout_o 		<= tx_serial_dout; --FF to be placed into one IOB
	end process;


	--================--
	-- 4b/5b encoding --
	--================--	
	--> from symb4b to symb5b
	process
	begin
		wait until rising_edge(clk_80_0_i);
			--
			if sclr_i = '1' then	--init		
				symb5b 				<= "10000"; 	--symb5b_Idle
			--
			else
				--
				if			symb4b = x"0" then
						symb5b 		<= "11110";
				elsif		symb4b = x"1" then
						symb5b 		<= "01001";
				elsif		symb4b = x"2" then
						symb5b 		<= "10100";
				elsif		symb4b = x"3" then
						symb5b 		<= "10101";
				elsif		symb4b = x"4" then
						symb5b 		<= "01010";
				elsif		symb4b = x"5" then
						symb5b 		<= "01011";
				elsif		symb4b = x"6" then
						symb5b 		<= "01110";
				elsif		symb4b = x"7" then
						symb5b 		<= "01111";
				elsif		symb4b = x"8" then
						symb5b 		<= "10010";
				elsif		symb4b = x"9" then
						symb5b 		<= "10011";
				--SPECIAL FRAMING
--				elsif		symb4b = x"A" then
--						symb5b 		<= "10110";							
				elsif		symb4b = x"A" then
					--
					if 	symb4b_next = x"1" or symb4b_next = x"4" or symb4b_next = x"5" or symb4b_next = x"6" or symb4b_next = x"7" then	
						symb5b 		<= "10110"; -- Normal	
					else
						symb5b 		<= "10000"; -- Framing
					end if;
					--
				--
				elsif		symb4b = x"B" then
						symb5b 		<= "10111";
				elsif		symb4b = x"C" then
						symb5b 		<= "11010";
				elsif		symb4b = x"D" then
						symb5b 		<= "11011";
				elsif		symb4b = x"E" then
						symb5b 		<= "11100";						
				elsif		symb4b = x"F" then
						symb5b 		<= "11101";
				end if;	
				--
			end if;						
			--		
	end process;



	--=========================================--
	-- Modulo 5 down-counter + div5 generation --
	--=========================================--	
	process
	begin
		wait until rising_edge(clk_400_0_i); 
			if modulo5_cnt = 0 then
				modulo5_cnt 			<= 4; --MSB first, Left-Shifting
				div5_del(0)				<= '1';
			else
				modulo5_cnt 			<= modulo5_cnt - 1; --from [4:0]
				div5_del(0)				<= '0';
			end if;
			--
			div5_del_loop : for i in 0 to 3 loop
				div5_del(i+1) 			<= div5_del(i);
			end loop;
			--
	end process;	

	--=================================--
	-- Latch + resync from 80M -> 400M --
	--=================================--	
	process
	begin
		wait until rising_edge(clk_400_0_i); 
			if div5_del(4) = '1' then
				symb5b_resync400(0)  <= symb5b;
			end if;
	end process;


	--===============================--
	-- NRZI encoding + serialization --
	--===============================--	
	process
	begin
		wait until rising_edge(clk_400_0_i); 
			if symb5b_resync400(0)(modulo5_cnt) = '1' then 
				tx_serial_dout 		<= not tx_serial_dout;
			end if;
	end process;


	--================--
	-- For simulation --
	--================--	
	sdata_no_nrzi 						<= symb5b_resync400(0)(modulo5_cnt);







--	--before:
--	---------
----	--double resync
----	process
----	begin
----		wait until rising_edge(clk_400_0_i); 
----			symb5b_resync400(0) 		<= symb5b;
----			symb5b_resync400(1) 		<= symb5b_resync400(0);
----	end process;	
--	
--	--new1:
--	-------
--	--===============================================================================================--
--	resync_symb5_from_80M_to_400M: entity work.clk_domain_bridge --between 1 to 127-bits
--	--===============================================================================================--
--	generic map (n => 5)
--	port map 
--	(
--		wrclk_i								=> clk_80_0_i,
--		rdclk_i								=> clk_400_0_i, 
--		wdata_i								=> symb5b,
--		rdata_o								=> symb5b_resync400(0)
--	); 	
--	process
--	begin
--		wait until rising_edge(clk_400_0_i); 
--			symb5b_resync400(1) 		<= symb5b_resync400(0);
--	end process;	
--	---end new-----------------------------------------------------------------------------------------------------	
--	
--
--	--modulo 5 down-counter used as 
--	process
--	begin
--		wait until rising_edge(clk_400_0_i); 
--			if modulo5_cnt = 0 then
--				modulo5_cnt 			<= 4; --MSB first, Left-Shifting
--			else
--				modulo5_cnt 			<= modulo5_cnt - 1; --from [4:0]
--			end if;
--	end process;
--	
--	--NRZI + serialiser
--	process
--	begin
--		wait until rising_edge(clk_400_0_i); 
--			if symb5b_resync400(1)(modulo5_cnt) = '1' then 
--				tx_serial_dout 		<= not tx_serial_dout;
--			end if;
--	end process;
--
--	--sim
--	sdata_no_nrzi <= symb5b_resync400(1)(modulo5_cnt);


	
	

	
	
end Behavioral;

