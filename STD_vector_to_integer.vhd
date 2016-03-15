----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:08:23 12/04/2015 
-- Design Name: 
-- Module Name:    STD_vector_to_integer - Behavioral 
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
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity STD_vector_to_integer is
    Port ( 
				fabric_clk					: in std_logic;
				Stack_count 				: in std_logic_vector(5 downto 0);
				Stack_count_integer 		: out integer
			  );
end STD_vector_to_integer;

architecture Behavioral of STD_vector_to_integer is

begin
	process(fabric_clk) 
	begin
		if rising_edge(fabric_clk) then
			stack_count_integer <= to_integer(signed(stack_count));
		end if;
	end process;
end Behavioral;

