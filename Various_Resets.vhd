----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:34:28 01/05/2016 
-- Design Name: 
-- Module Name:    Various_Resets - Behavioral 
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Various_Resets is
port(
		Brcst							: in std_logic_vector(5 downto 0);
		brcststr						: in std_logic;
		TBM_Reset					: out std_logic;
		ROC_Reset					: out std_logic;
		fabric_clk					: in std_logic
);
end Various_Resets;

architecture Behavioral of Various_Resets is

	signal TBM_Dummy				: std_logic := '0';
	signal ROC_Dummy				: std_logic := '0';

begin

	process(fabric_clk) 
	begin
	if rising_edge(fabric_clk) then
		if Brcst = "000101" then           --TBM Reset set to the 101 command in broadcast this is equal to 0x1
			TBM_Dummy		<= brcststr;
			ROC_Dummy		<= '0';
		else
			TBM_Dummy		<= '0';
		end if;
		
		if Brcst = "000111" then			  --ROC Reset set to 111 this is equal to sending 0x1F in BGO commands
			ROC_Dummy		<= brcststr;
			TBM_Dummy		<= '0';
		else
			ROC_Dummy		<= '0';
		end if;

	end if;
	
	end process;

	TBM_Reset		<= TBM_Dummy;
	ROC_Reset		<= ROC_Dummy;

end Behavioral;

