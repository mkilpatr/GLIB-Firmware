library ieee;
use ieee.std_logic_1164.all;

library work;
use work.user_package.all;

entity reg is
port(

    fabric_clk_i    : in std_logic;
    reset_i         : in std_logic;

    wbus_i          : in std_logic_vector(31 downto 0);
    wbus_t          : in std_logic;
    rbus_o          : out std_logic_vector(31 downto 0)

);
end reg;

architecture Behavioral of reg is
begin

    process(fabric_clk_i)

        variable reg  : std_logic_vector(31 downto 0) := (others => '0');
    
    begin

        if (rising_edge(fabric_clk_i)) then

            if (reset_i = '1') then

                reg := (others => '0');

            else
            
                if (wbus_t = '1') then

                    reg := wbus_i;

                end if;

            end if;
    
            rbus_o <= reg;

        end if;

    end process;

end Behavioral;
