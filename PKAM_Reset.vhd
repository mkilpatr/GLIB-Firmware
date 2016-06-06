----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    22:16:09 02/02/2016 
-- Design Name: 
-- Module Name:    PKAM_Reset - Behavioral 
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

entity PKAM_Reset is

port(
	
		Stack_count					: in std_logic_vector(5 downto 0);
		fabric_clk	    			: in std_logic;
		PKAM_Reset					: in std_logic_vector(7 downto 0);
		PKAM_Constant				: in std_logic_vector(7 downto 0);
		PKAM_Token					: in std_logic;
		PKAM							: out std_logic;
		PKAM_zero					: out std_logic;
		PKAM_Enable					: in std_logic;
		PKAM_Buffer					: out std_logic;
		PKAM_zero_Buffer			: out std_logic
		
);
end PKAM_Reset;

architecture Behavioral of PKAM_Reset is

		signal PKAM_Multiple 			: integer := 256;
		signal PKAM_Count 				: integer := 8;
		signal PKAM_init 					: std_logic := '0';
		signal PKAM_zero_init			: std_logic := '0';
		signal Total_PKAM					: integer := 0;

begin

	process(fabric_clk) 
	begin

	if PKAM_Enable = '1' then
		if rising_edge(fabric_clk) then
			if PKAM_Token = '0' then
				PKAM_init			<= '0';
				PKAM_zero_init		<= '0';
				Total_PKAM			<= (To_integer(unsigned(PKAM_Reset)) * PKAM_Multiple) + To_integer(unsigned(PKAM_Constant)) + PKAM_Count;
			elsif Stack_count = "000000" then
				PKAM_zero_init		<= '0';
			else 
				if Total_PKAM = 8 then
					PKAM_init 		<= '1';
				end if;
				
				if Total_PKAM = 0 then
					PKAM_zero_init	<= '1';
				elsif Total_PKAM /= 0 then
					Total_PKAM 		<= Total_PKAM - 1;
				end if;
			end if;
		end if;
	else
		PKAM_init			<= '0';
		PKAM_zero_init		<= '0';
		Total_PKAM			<= (To_integer(unsigned(PKAM_Reset)) * PKAM_Multiple) + To_integer(unsigned(PKAM_Constant)) + PKAM_Count;
	end if;
	
	
	end process;
	
	PKAM						<= PKAM_init;
	PKAM_zero				<= PKAM_zero_init;
	PKAM_Buffer				<= PKAM_init;
	PKAM_zero_Buffer		<= PKAM_zero_init;

end Behavioral;