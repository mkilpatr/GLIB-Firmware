--
-- This entity takes care of crossing clock-domains for one strobe and a data bus
--

library ieee;
use ieee.std_logic_1164.all;

entity clock_bridge_simple is
port(

    reset_i     : in std_logic;
    
    m_clk_i     : in std_logic;
    m_en_i      : in std_logic;
    
    s_clk_i     : in std_logic;
    s_en_o      : out std_logic
    
);
end clock_bridge_simple;

architecture behavioral of clock_bridge_simple is

    -- Status registers
    signal strobe   : std_logic := '0';
    signal ack      : std_logic := '0';
    
begin

    -- Input clock
    process(m_clk_i)
    begin
    
        -- Work only at the rising edge
        if (rising_edge(m_clk_i)) then
        
            -- Reset signal
            if (reset_i = '1') then
            
                strobe <= '0';
                
            else
            
                -- Ready to send data
                if (strobe = '0' and ack = '0') then
            
                    -- Detect an input strobe
                    if (m_en_i = '1') then
                    
                        strobe <= '1';
                        
                    end if;
                    
                elsif (strobe = '1' and ack = '1') then
                
                    strobe <= '0';
                    
                end if;
                
            end if;
            
        end if;
        
    end process;
    
    -- Output clock
    process(s_clk_i)
    begin
    
        -- Work only at the rising edge
        if (rising_edge(s_clk_i)) then
        
            -- Reset signal
            if (reset_i = '1') then
            
                s_en_o <= '0';
                
                ack <= '0';
                
            else   
            
                -- Check if a strobe is waiting
                if (strobe = '1' and ack = '0') then
                
                    -- If so, set an output strobe
                    s_en_o <= '1';
                    
                    -- Change the status
                    ack <= '1';
                    
                -- Otherwhise
                elsif (strobe = '0' and ack = '1') then
                
                    -- Reset the strobe
                    s_en_o <= '0';
                    
                    -- Reset the acknowledgement
                    ack <= '0';
                
                else
                
                    s_en_o <= '0';
                    
                end if;
                
            end if;
            
        end if;
        
    end process;    

end behavioral;