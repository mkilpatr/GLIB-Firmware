library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

library work;

entity gtx_wrapper is
port(

    gtx_clk_o       : out std_logic;
    reset_i         : in std_logic;
    
    rx_error_o      : out std_logic_vector(3 downto 0);
    tx_kchar_i      : in std_logic_vector(7 downto 0);
    tx_data_i       : in std_logic_vector(63 downto 0);
    
    rx_kchar_o      : out std_logic_vector(7 downto 0);
    rx_data_o       : out std_logic_vector(63 downto 0);
    
    rx_n_i          : in std_logic_vector(3 downto 0);
    rx_p_i          : in std_logic_vector(3 downto 0);
    tx_n_o          : out std_logic_vector(3 downto 0);
    tx_p_o          : out std_logic_vector(3 downto 0);

    gtp_refclk_n_i  : in std_logic;
    gtp_refclk_p_i  : in std_logic
    
);
end gtx_wrapper;

architecture Behavioral of gtx_wrapper is

    signal gtx_clk          : std_logic := '0';
   
    signal rx_disperr       : std_logic_vector(7 downto 0) := (others => '0'); 
    signal rx_notintable    : std_logic_vector(7 downto 0) := (others => '0');
    
    signal gtx0_mgtrefclkrx : std_logic_vector(1 downto 0) := (others => '0');
    signal gtx0_tx_out_clk  : std_logic := '0';   
    signal gtx0_tx_out_clk2 : std_logic := '0';   
    
begin
    
    gtx_clk_o <= gtx0_tx_out_clk2;
    
    --

    gtx_clk_inst : ibufds_gtxe1 port map( O => gtx_clk, ODIV2 => open, CEB => '0', I => gtp_refclk_p_i, IB => gtp_refclk_n_i);  
    
    --

    rx_error_o(0) <= rx_disperr(0) or rx_disperr(1) or rx_notintable(0) or rx_notintable(1);
    rx_error_o(1) <= rx_disperr(2) or rx_disperr(3) or rx_notintable(2) or rx_notintable(3);
    rx_error_o(2) <= rx_disperr(4) or rx_disperr(5) or rx_notintable(4) or rx_notintable(5);
    rx_error_o(3) <= rx_disperr(6) or rx_disperr(7) or rx_notintable(6) or rx_notintable(7);

    --

    gtx0_mgtrefclkrx <= '0' & gtx_clk;

    --

    tx_out_clk_bufg : bufg port map(I => gtx0_tx_out_clk, O => gtx0_tx_out_clk2);

    --

    gtx_0_inst : entity work.gtx_gtx
    generic map(
        GTX_SIM_GTXRESET_SPEEDUP    => 1,
        GTX_TX_CLK_SOURCE           => "RXPLL",
        GTX_POWER_SAVE              => "0000110100"
    )
    port map(
        RXCHARISK_OUT       => rx_kchar_o(1 downto 0),
        RXDISPERR_OUT       => rx_disperr(1 downto 0),
        RXNOTINTABLE_OUT    => rx_notintable(1 downto 0),
        RXBYTEISALIGNED_OUT => open,
        RXCOMMADET_OUT      => open,
        RXENMCOMMAALIGN_IN  => '1',
        RXENPCOMMAALIGN_IN  => '1',
        RXDATA_OUT          => rx_data_o(15 downto 0),
        RXRECCLK_OUT        => open,
        RXUSRCLK2_IN        => gtx0_tx_out_clk2,
        RXN_IN              => rx_n_i(0),
        RXP_IN              => rx_p_i(0),
        RXLOSSOFSYNC_OUT    => open,
        GTXRXRESET_IN       => reset_i,
        MGTREFCLKRX_IN      => gtx0_mgtrefclkrx,
        PLLRXRESET_IN       => reset_i,
        RXPLLLKDET_OUT      => open,
        RXRESETDONE_OUT     => open,
        TXCHARISK_IN        => tx_kchar_i(1 downto 0),
        TXDATA_IN           => tx_data_i(15 downto 0),
        TXOUTCLK_OUT        => gtx0_tx_out_clk,
        TXUSRCLK2_IN        => gtx0_tx_out_clk2,
        TXN_OUT             => tx_n_o(0),
        TXP_OUT             => tx_p_o(0),
        GTXTXRESET_IN       => reset_i,
        MGTREFCLKTX_IN      => gtx0_mgtrefclkrx,
        PLLTXRESET_IN       => reset_i,
        TXPLLLKDET_OUT      => open,
        TXRESETDONE_OUT     => open
    );   

    gtx_1_inst : entity work.gtx_gtx
    generic map(
        GTX_SIM_GTXRESET_SPEEDUP    => 1,
        GTX_TX_CLK_SOURCE           => "RXPLL",
        GTX_POWER_SAVE              => "0000110100"
    )
    port map(
        RXCHARISK_OUT       => rx_kchar_o(3 downto 2),
        RXDISPERR_OUT       => rx_disperr(3 downto 2),
        RXNOTINTABLE_OUT    => rx_notintable(3 downto 2),
        RXBYTEISALIGNED_OUT => open,
        RXCOMMADET_OUT      => open,
        RXENMCOMMAALIGN_IN  => '1',
        RXENPCOMMAALIGN_IN  => '1',
        RXDATA_OUT          => rx_data_o(31 downto 16),
        RXRECCLK_OUT        => open,
        RXUSRCLK2_IN        => gtx0_tx_out_clk2,
        RXN_IN              => rx_n_i(1),
        RXP_IN              => rx_p_i(1),
        RXLOSSOFSYNC_OUT    => open,
        GTXRXRESET_IN       => reset_i,
        MGTREFCLKRX_IN      => gtx0_mgtrefclkrx,
        PLLRXRESET_IN       => reset_i,
        RXPLLLKDET_OUT      => open,
        RXRESETDONE_OUT     => open,
        TXCHARISK_IN        => tx_kchar_i(3 downto 2),
        TXDATA_IN           => tx_data_i(31 downto 16),
        TXOUTCLK_OUT        => open,
        TXUSRCLK2_IN        => gtx0_tx_out_clk2,
        TXN_OUT             => tx_n_o(1),
        TXP_OUT             => tx_p_o(1),
        GTXTXRESET_IN       => reset_i,
        MGTREFCLKTX_IN      => gtx0_mgtrefclkrx,
        PLLTXRESET_IN       => reset_i,
        TXPLLLKDET_OUT      => open,
        TXRESETDONE_OUT     => open
    );   

    gtx_2_inst : entity work.gtx_gtx
    generic map(
        GTX_SIM_GTXRESET_SPEEDUP    => 1,
        GTX_TX_CLK_SOURCE           => "RXPLL",
        GTX_POWER_SAVE              => "0000110100"
    )
    port map(
        RXCHARISK_OUT       => rx_kchar_o(5 downto 4),
        RXDISPERR_OUT       => rx_disperr(5 downto 4),
        RXNOTINTABLE_OUT    => rx_notintable(5 downto 4),
        RXBYTEISALIGNED_OUT => open,
        RXCOMMADET_OUT      => open,
        RXENMCOMMAALIGN_IN  => '1',
        RXENPCOMMAALIGN_IN  => '1',
        RXDATA_OUT          => rx_data_o(47 downto 32),
        RXRECCLK_OUT        => open,
        RXUSRCLK2_IN        => gtx0_tx_out_clk2,
        RXN_IN              => rx_n_i(2),
        RXP_IN              => rx_p_i(2),
        RXLOSSOFSYNC_OUT    => open,
        GTXRXRESET_IN       => reset_i,
        MGTREFCLKRX_IN      => gtx0_mgtrefclkrx,
        PLLRXRESET_IN       => reset_i,
        RXPLLLKDET_OUT      => open,
        RXRESETDONE_OUT     => open,
        TXCHARISK_IN        => tx_kchar_i(5 downto 4),
        TXDATA_IN           => tx_data_i(47 downto 32),
        TXOUTCLK_OUT        => open,
        TXUSRCLK2_IN        => gtx0_tx_out_clk2,
        TXN_OUT             => tx_n_o(2),
        TXP_OUT             => tx_p_o(2),
        GTXTXRESET_IN       => reset_i,
        MGTREFCLKTX_IN      => gtx0_mgtrefclkrx,
        PLLTXRESET_IN       => reset_i,
        TXPLLLKDET_OUT      => open,
        TXRESETDONE_OUT     => open
    );   

    gtx_3_inst : entity work.gtx_gtx
    generic map(
        GTX_SIM_GTXRESET_SPEEDUP    => 1,
        GTX_TX_CLK_SOURCE           => "RXPLL",
        GTX_POWER_SAVE              => "0000110100"
    )
    port map(
        RXCHARISK_OUT       => rx_kchar_o(7 downto 6),
        RXDISPERR_OUT       => rx_disperr(7 downto 6),
        RXNOTINTABLE_OUT    => rx_notintable(7 downto 6),
        RXBYTEISALIGNED_OUT => open,
        RXCOMMADET_OUT      => open,
        RXENMCOMMAALIGN_IN  => '1',
        RXENPCOMMAALIGN_IN  => '1',
        RXDATA_OUT          => rx_data_o(63 downto 48),
        RXRECCLK_OUT        => open,
        RXUSRCLK2_IN        => gtx0_tx_out_clk2,
        RXN_IN              => rx_n_i(3),
        RXP_IN              => rx_p_i(3),
        RXLOSSOFSYNC_OUT    => open,
        GTXRXRESET_IN       => reset_i,
        MGTREFCLKRX_IN      => gtx0_mgtrefclkrx,
        PLLRXRESET_IN       => reset_i,
        RXPLLLKDET_OUT      => open,
        RXRESETDONE_OUT     => open,
        TXCHARISK_IN        => tx_kchar_i(7 downto 6),
        TXDATA_IN           => tx_data_i(63 downto 48),
        TXOUTCLK_OUT        => open,
        TXUSRCLK2_IN        => gtx0_tx_out_clk2,
        TXN_OUT             => tx_n_o(3),
        TXP_OUT             => tx_p_o(3),
        GTXTXRESET_IN       => reset_i,
        MGTREFCLKTX_IN      => gtx0_mgtrefclkrx,
        PLLTXRESET_IN       => reset_i,
        TXPLLLKDET_OUT      => open,
        TXRESETDONE_OUT     => open
    );   
    
end Behavioral;
