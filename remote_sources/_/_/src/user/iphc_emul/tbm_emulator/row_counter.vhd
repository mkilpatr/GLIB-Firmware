----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:37:00 01/12/2015 
-- Design Name: 
-- Module Name:    row_counter - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity row_counter is
port (
			clk_i								: in std_logic;
			sclr_i							: in std_logic;	
			row_cnt_en_i					: in std_logic;
			row_cnt_o						: out std_logic_vector(8 downto 0);
			row_cnt_end_o					: out std_logic
		);
end row_counter;

architecture Behavioral of row_counter is

	signal row_cnt_part1					: unsigned(2 downto 0) := (others => '0'); --LSB
	signal row_cnt_part2					: unsigned(2 downto 0) := (others => '0'); --Middle
	signal row_cnt_part3					: unsigned(2 downto 0) := (others => '0'); --MSB
	
	signal row_cnt_end					: std_logic:='0';
	

begin


	row_cnt_o 					<= std_logic_vector(row_cnt_part3 & row_cnt_part2 & row_cnt_part1);
	row_cnt_end_o 				<= row_cnt_end;

	--case [0:159]
	row_cnt_end 				<= '1' when ( row_cnt_part3 = to_unsigned(4,3) and row_cnt_part2 = to_unsigned(2,3) and  row_cnt_part1 = to_unsigned(3,3) ) else '0';
	--case [1:160]
	--row_cnt_end 				<= '1' when ( row_cnt_part3 = to_unsigned(4,3) and row_cnt_part2 = to_unsigned(2,3) and  row_cnt_part1 = to_unsigned(4,3) ) else '0';
	
	
	
	process
	begin
		wait until rising_edge(clk_i);
			--
			if 	sclr_i = '1' then
				--case [0:159]
				row_cnt_part1 				<= to_unsigned(0,3);
				--case [1:160]
				--row_cnt_part1 			<= to_unsigned(1,3);				
			--
			elsif row_cnt_en_i = '1' then
				--
				if 	row_cnt_end = '1' then
					row_cnt_part1 			<= to_unsigned(0,3);
				--	
				elsif	row_cnt_part1 = to_unsigned(5,3) then
					row_cnt_part1 			<= to_unsigned(0,3);
				--
				else				
					row_cnt_part1			<= row_cnt_part1 + "01";			
				--
				end if;
			--
			end if;
	end process;


	process
	begin
		wait until rising_edge(clk_i);
			--
			if 	sclr_i = '1' then
				row_cnt_part2 				<= to_unsigned(0,3);
			--
			elsif row_cnt_en_i = '1' then
				--
				if 	row_cnt_end = '1' then
					row_cnt_part2 			<= to_unsigned(0,3);
				--
				elsif row_cnt_part2 = to_unsigned(5,3) and row_cnt_part1 = to_unsigned(5,3) then
					row_cnt_part2 			<= to_unsigned(0,3);				
				--
				elsif	row_cnt_part1 = to_unsigned(5,3) then			
					row_cnt_part2			<= row_cnt_part2 + "01";			
				--
				end if;
			--
			end if;
	end process;


	process
	begin
		wait until rising_edge(clk_i);
			--
			if 	sclr_i = '1' then
				row_cnt_part3 				<= to_unsigned(0,3);
			--
			elsif row_cnt_en_i = '1' then
				--
				if 	row_cnt_end = '1' then
					row_cnt_part3 			<= to_unsigned(0,3);
				--
				elsif	row_cnt_part2 = to_unsigned(5,3) and row_cnt_part1 = to_unsigned(5,3) then			
					row_cnt_part3			<= row_cnt_part3 + "01";			
				--
				end if;
			--
			end if;
	end process;

end Behavioral;

