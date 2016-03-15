----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:15:46 01/12/2015 
-- Design Name: 
-- Module Name:    dcol_counter - Behavioral 
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

entity dcol_counter is
port (
			clk_i									: in std_logic;
			sclr_i								: in std_logic;	
			dcol_cnt_en_i						: in std_logic;
			dcol_cnt_o							: out std_logic_vector(5 downto 0);
			dcol_cnt_end_o						: out std_logic
		);		
end dcol_counter;

architecture Behavioral of dcol_counter is

	signal dcol_cnt_part1					: unsigned(2 downto 0) := (others => '0'); --LSB
	signal dcol_cnt_part2					: unsigned(2 downto 0) := (others => '0'); --MSB

	signal dcol_cnt_end						: std_logic:='0';

begin

	dcol_cnt_o 						<= std_logic_vector(dcol_cnt_part2 & dcol_cnt_part1);
	dcol_cnt_end_o 				<= dcol_cnt_end;

	--case [0:25]
	dcol_cnt_end 					<= '1' when ( dcol_cnt_part2 = to_unsigned(4,3) and dcol_cnt_part1 = to_unsigned(1,3) ) else '0';
	--case [1:26]
	--dcol_cnt_end 				<= '1' when ( dcol_cnt_part2 = to_unsigned(4,3) and dcol_cnt_part1 = to_unsigned(2,3) ) else '0';
	
	process
	begin
		wait until rising_edge(clk_i);
			--
			if 	sclr_i = '1' then
				--case [0:25]
				dcol_cnt_part1 			<= to_unsigned(0,3);
				--case [1:26]
				--dcol_cnt_part1 			<= to_unsigned(0,3);				
			--
			elsif dcol_cnt_en_i = '1' then
				--
				if dcol_cnt_end = '1' then
					dcol_cnt_part1 		<= to_unsigned(0,3);
				--
				elsif	dcol_cnt_part1 = to_unsigned(5,3) then
					dcol_cnt_part1 		<= to_unsigned(0,3);
				--
				else				
					dcol_cnt_part1			<= dcol_cnt_part1 + "01";			
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
				dcol_cnt_part2 			<= to_unsigned(0,3);
			--
			elsif dcol_cnt_en_i = '1' then
				--
				if dcol_cnt_end = '1' then				
					dcol_cnt_part2 		<= to_unsigned(0,3);
				--
				elsif	dcol_cnt_part1 = to_unsigned(5,3) then
					dcol_cnt_part2			<= dcol_cnt_part2 + "01";		
				--
				end if;
			--
			end if;
	end process;



end Behavioral;

