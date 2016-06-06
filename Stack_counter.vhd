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
--use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity Stack_counter is

port(
	
		Stack_count					: out std_logic_vector(5 downto 0);
		TOKEN 						: in std_logic;
		fabric_clk	    			: in std_logic;
      reset	         			: in std_logic;
		L1Accept						: in std_logic;
		ROC_Constant				: in std_logic;
		ROC_Clk						: in std_logic_vector(7 downto 0);
		ROC_Timer					: out std_logic;
		Stack_ROC					: out std_logic_vector(5 downto 0);
		ROC_Timer_Buffer			: out std_logic;
		ROC_Stack_Dummy			: in std_logic;
		ROC_NTP						: out std_logic;
		TBM_Constant				: in std_logic;
		TBM_8							: out std_logic;
		Stack_count_full			: out std_logic;
		Stack_ROC_zero				: out std_logic_vector(5 downto 0)
		
);
end Stack_counter;

architecture Behavioral of Stack_counter is

		Signal Stack_count_init 		: unsigned(5 downto 0) := (others => '0');
		signal Stack_ROC_zero_init		: unsigned(5 downto 0) := (others => '0');
		signal Stack_full_init			: std_logic := '0';
		signal ROC_Clk_init 				: integer := 0;
		signal ROC_count_8				: integer := 8;
		signal ROC_Timer_init			: std_logic := '0';
		signal Stack_ROC_init			: unsigned(5 downto 0) := (others => '0');
		signal ROC_Clk_const				: integer := 0;
		signal ROC_NTP_init				: std_logic := '0';
		signal TBM_Clk_init				: unsigned(2 downto 0) := "101";
		signal TBM_8_init					: std_logic := '0';
		
		
begin


	 process(fabric_clk) 
	 begin
	 
	 if rising_edge(fabric_clk) then
		if (reset = '1') then
			Stack_count_init 				<= (others => '0');
		elsif Stack_count_init = "100000" then
			Stack_full_init				<= '1';
		else
			if L1Accept = '1' then 
				Stack_count_init 			<= stack_count_init + 1;
			elsif TOKEN = '1' AND stack_count_init /= "000000" then
				Stack_count_init 			<= stack_count_init - 1;
			end if;
			
			Stack_full_init				<= '0';
		end if;
	end if;
	
	if TBM_Constant = '1' then
		if rising_edge(fabric_clk) then
			if TBM_Clk_init /= "000" then
				TBM_Clk_init 				<= TBM_Clk_init - 1;
			else
				TBM_8_init					<= '1';
			end if;
		end if;
	else
		TBM_Clk_init						<= "101";
		TBM_8_init							<= '0';
	end if;
	
	if ROC_Constant = '1' then
		if rising_edge(fabric_clk) then 
			if ROC_Clk_init >= To_integer(unsigned(ROC_Clk)) AND L1Accept = '1' then
				Stack_ROC_init				<= Stack_ROC_init + 1;
			end if;
			
			if ROC_Clk_init = To_integer(unsigned(ROC_Clk)) then
				Stack_ROC_zero_init		<= Stack_count_init;
			end if;
			
			if Stack_ROC_init /= "000000" AND ROC_Stack_Dummy = '1' then
				Stack_ROC_init				<= Stack_ROC_init - 1;
			end if;
			
			if ROC_Clk_init = ROC_Clk_const AND TBM_Constant /= '1' then 
				ROC_NTP_init				<= '1';
			else
				ROC_NTP_init				<= '0';
			end if;
			
			if ROC_Clk_init = 0 then
				ROC_Timer_init				<= '1';
			elsif ROC_CLK_init /= 0 then
				ROC_Clk_init 				<= ROC_Clk_init - 1;
			end if;				
		end if;
	else
		ROC_Clk_init	 					<= To_integer(unsigned(ROC_Clk)) + ROC_count_8;
		ROC_Timer_init						<= '0';
		ROC_NTP_init						<= '0';
		ROC_Clk_const						<= To_integer(unsigned(ROC_Clk));
		Stack_ROC_init						<= (others => '0');
		Stack_ROC_zero_init				<= (others => '0');
	end if;
	
	end process;
	
	Stack_count 							<= std_logic_vector(Stack_count_init);
	Stack_count_full						<= Stack_full_init;
	Stack_ROC_zero							<= std_logic_vector(Stack_ROC_zero_init);
	ROC_Timer								<= ROC_Timer_init;
	ROC_Timer_Buffer						<= ROC_Timer_init;
	Stack_ROC								<= std_logic_vector(Stack_ROC_init);
	ROC_NTP									<= ROC_NTP_init;
	TBM_8										<= TBM_8_init;
	
end Behavioral;

