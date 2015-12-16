----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:27:44 12/03/2015 
-- Design Name: 
-- Module Name:    Stack_counter - Behavioral 
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
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity Stack_counter is

port(
	
		Stack_count					: out std_logic_vector(5 downto 0);
		TOKEN 						: in std_logic;
		fabric_clk	    			: in std_logic;
      reset	         			: in std_logic;
		L1Accept						: in std_logic
--		Stack_count_integer	 	: out  integer
		
);
end Stack_counter;

architecture Behavioral of Stack_counter is

		Signal Stack_count_init : unsigned(5 downto 0) := (others => '0');
--		signal stack_count_int : integer := 0;
		
begin
	 process(fabric_clk) 
	 begin
	 if rising_edge(fabric_clk) then
	 
		if (reset = '1') then
			
			Stack_count_init 		<= (others => '0');
--			Stack_count_int  		<= 0;

		else
			
			if L1Accept = '1' then 
			
				Stack_count_init <= stack_count_init + 1;
--				Stack_count_int  <= Stack_count_int + 1;
		
			elsif TOKEN = '1' then
		
				Stack_count_init <= stack_count_init - 1;
--				Stack_count_int  <= Stack_count_int - 1;

						
			end if;
	 
		end if;
		
	end if;
	
	end process;
	
	Stack_count <= std_logic_vector(Stack_count_init);
--	stack_count_integer <= stack_count_int;	

	
end Behavioral;

