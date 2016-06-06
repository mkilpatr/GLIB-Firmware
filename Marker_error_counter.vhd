----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:01:55 05/27/2016 
-- Design Name: 
-- Module Name:    Marker_error_counter - Behavioral 
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

entity Marker_error_counter is

port(

		Marker_error						: in std_logic_vector(1 downto 0);
		Marker_zero							: out std_logic;
		Marker_zero_buffer				: out std_logic;
		Marker_reset_dummy				: in std_logic;
		Marker_reset_buffer				: out std_logic;
		--Marker_reset_ROC					: in std_logic;
		fabric_clk							: in std_logic;
		Marker_Clk							: in std_logic_vector(7 downto 0);
		L1Accept								: in std_logic
);

end Marker_error_counter;

architecture Behavioral of Marker_error_counter is

		signal Marker_count_init 		: unsigned(7 downto 0) := (others => '0');
		signal Marker_zero_init			: std_logic := '0';
		
begin


	 process(fabric_clk) 
	 begin
	 
	 if rising_edge(fabric_clk) then
		if Marker_error = "00" then
			if Marker_Clk /= "00000000" then
				Marker_count_init				<= unsigned(Marker_Clk);
			else
				Marker_count_init				<= "01100100";
			end if;
			
			Marker_zero_init				<= '0';
		else
			if Marker_reset_dummy = '1' then
				if Marker_Clk /= "00000000" then
					Marker_count_init				<= unsigned(Marker_Clk);
				else
					Marker_count_init				<= "01100100";
				end if;
				
				Marker_zero_init			<= '0';
			else
				if Marker_count_init /= "00000000" AND L1Accept = '1' then 
					Marker_count_init 		<= Marker_count_init - 1;
				elsif Marker_count_init	= "00000000" then
					Marker_zero_init			<= '1';
				end if;
			end if;
		end if;
	end if;
	
	end process;
	
	Marker_zero								<= Marker_zero_init;
	Marker_zero_buffer					<= Marker_zero_init;
	Marker_reset_buffer					<= Marker_reset_dummy;
	
	
end Behavioral;



