library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter is
port(
    
    fabric_clk_i    : in std_logic;
    reset_i         : in std_logic;
    
    en_i            : in std_logic;
	 --disen_i			  : in std_logic;
    data_o          : out std_logic_vector(31 downto 0)
    
);
end counter;

architecture Behavioral of counter is
    
    signal counter  : unsigned(31 downto 0) := (others => '0');
    
begin

    process(fabric_clk_i)
    begin

        if (rising_edge(fabric_clk_i)) then
        
            if (reset_i = '1') then
            
                counter <= (others => '0');
                
            else
            
                if (en_i = '1') then
                
                    counter <= counter + 1;
                    
                end if;	  
                
            end if;
        
        end if;
    
    end process;
                
    data_o <= std_logic_vector(counter);

end Behavioral;
