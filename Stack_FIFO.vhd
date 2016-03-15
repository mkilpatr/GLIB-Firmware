----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:02:55 03/03/2016 
-- Design Name: 
-- Module Name:    Stack_FIFO - Behavioral 
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

entity Stack_FIFO is
	Generic(
		constant DATA_WIDTH	: positive := 32;
		constant FIFO_DEPTH	: positive := 32
	);
	Port (
		CLK		: in std_logic;
		RST		: in std_logic;
		WriteEn	: in std_logic;
		DataIn	: in std_logic_vector(DATA_WIDTH -1 downto 0);
		ReadEn	: in std_logic;
		DataOut	: out std_logic_vector(DATA_WIDTH - 1 downto 0);
		Empty		: out std_logic;
		Full		: out std_logic
	);
end Stack_FIFO;

architecture Behavioral of Stack_FIFO is

begin

	-- Memory Pointer Process
	fif_proc : process(CLK)
		type FIFO_Memory is array (0 to FIFO_DEPTH - 1) of std_logic_vector(DATA_WIDTH - 1 downto 0);
		variable Memory :FIFO_Memory;
		
		variable Head : natural range 0 to FIFO_DEPTH - 1;
		variable Tail : natural range 0 to FIFO_DEPTH - 1;
		
		variable Looped : boolean;
		
	begin
		if rising_edge(CLK) then
			if RST = '1' then
				Head := 0;
				Tail := 0;
				
				Looped := false;
				
				Full 	<= '0';
				Empty <= '1';
			else 
				if (ReadEn = '1') then
					if ((Looped = true) or (Head /= Tail)) then
						--Update data output
						DataOut <= Memory(Tail);
						
						--Update Tail pointer as needed
						if (Tail = FIFO_DEPTH - 1) then
							Tail := 0;
							
							Looped := false;
						else 
							Tail := Tail + 1;
						end if;
						
					end if;
				end if;
				
				if (WriteEn = '1') then
					if ((Looped = false) or (Head /= Tail)) then
						--Write Data to Memory
						Memory(Head) := DataIn;
						
						-- Increment Head point as needed
						if (Head = FIFO_DEPTH - 1) then
							Head := 0;
							
							Looped := true;
						else
							Head := Head + 1;
						end if;
					end if;
				end if;
				
				-- Update Empty and Full flags
				if (Head = Tail) then
					if Looped then
						Full <= '1';
					else
						Empty <= '1';
					end if;
				else
					Empty <= '0';
					Full	<= '0';
				end if;
			end if;
		end if;
	end process;
				
end Behavioral;

