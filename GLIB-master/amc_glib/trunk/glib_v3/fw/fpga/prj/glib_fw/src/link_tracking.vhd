library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.ipbus.all;
use work.system_package.all;
use work.user_package.all;

entity link_tracking is
port(

    gtx_clk_i       : in std_logic;
    ipb_clk_i       : in std_logic;
    reset_i         : in std_logic;
    
    rx_error_i      : in std_logic;
    rx_kchar_i      : in std_logic_vector(1 downto 0);
    rx_data_i       : in std_logic_vector(15 downto 0);
    
    tx_kchar_o      : out std_logic_vector(1 downto 0);
    tx_data_o       : out std_logic_vector(15 downto 0);
    
--	ipb_vi2c_i      : in ipb_wbus;
--	ipb_vi2c_o      : out ipb_rbus;
--    
--	ipb_track_i     : in ipb_wbus;
--	ipb_track_o     : out ipb_rbus;
--    
--	ipb_regs_i      : in ipb_wbus;
--	ipb_regs_o      : out ipb_rbus;
--    
	ipb_info_i      : in ipb_wbus;
	ipb_info_o      : out ipb_rbus;

    -- Global requets
  
    request_write_o : out array32(127 downto 0);
    request_tri_o   : out std_logic_vector(127 downto 0);
    request_read_i  : in array32(127 downto 0);
    
    -- Trigger
    
    trigger_i       : in std_logic;
	 l1accept		  : in std_logic;
	 xpoint1_clk3_bufg: in std_logic;
	 EvCntRes		  : in std_logic;
	 BCntRes			  : in std_logic;
	 
	 L1A_count		  : out std_logic_vector(31 downto 0);
	 Orbit_count	  : out std_logic_vector(31 downto 0);
	 Bunch_count	  : out std_logic_vector(31 downto 0)
    
);
end link_tracking;

architecture Behavioral of link_tracking is

    -- VFAT2 signals
    
    signal vi2c_tx_en               : std_logic := '0';
    signal vi2c_tx_data             : std_logic_vector(31 downto 0) := (others => '0');
    signal vi2c_rx_en               : std_logic := '0';
    signal vi2c_rx_data             : std_logic_vector(31 downto 0) := (others => '0');
    
    -- Track data
    
    signal track_rx_en              : std_logic := '0';
    signal track_rx_data            : std_logic_vector(223 downto 0) := (others => '0');
    signal track_fifo_reset         : std_logic := '0';
    signal track_fifo_count         : std_logic_vector(11 downto 0) := (others => '0');
         
    -- Registers signals
    
    signal regs_tx_en               : std_logic := '0';
    signal regs_tx_data             : std_logic_vector(47 downto 0) := (others => '0');
    signal regs_rx_en               : std_logic := '0';
    signal regs_rx_data             : std_logic_vector(47 downto 0) := (others => '0');
    
    signal regs_tx_en_trig          : std_logic := '0';
    signal regs_tx_en_ipbus         : std_logic := '0';
    signal regs_tx_data_ipbus       : std_logic_vector(47 downto 0) := (others => '0');
    
    -- Info signals

    signal regs_req_write           : array32(255 downto 0) := (others => (others => '0'));
    signal regs_req_tri             : std_logic_vector(255 downto 0);
    signal regs_req_read            : array32(255 downto 0) := (others => (others => '0'));

    -- Local requests

    signal request_write            : array32(127 downto 0) := (others => (others => '0'));
    signal request_tri              : std_logic_vector(127 downto 0);
    signal request_read             : array32(127 downto 0) := (others => (others => '0'));

    -- Counters

--    signal rx_error_counter         : std_logic_vector(31 downto 0) := (others => '0');
--    signal vi2c_rx_counter          : std_logic_vector(31 downto 0) := (others => '0');
--    signal vi2c_tx_counter          : std_logic_vector(31 downto 0) := (others => '0');
--    signal regs_rx_counter          : std_logic_vector(31 downto 0) := (others => '0');
--    signal regs_tx_counter          : std_logic_vector(31 downto 0) := (others => '0');
	
	 signal cnt_ttc_trigger				: std_logic_vector(31 downto 0) := (others => '0');
	 signal cnt_ttc_bunches				: std_logic_vector(31 downto 0) := (others => '0');
	 signal cnt_ttc_Orbit				: std_logic_vector(31 downto 0) := (others => '0');

--    signal rx_error_counter_reset   : std_logic := '0';
--    signal vi2c_rx_counter_reset    : std_logic := '0';
--    signal vi2c_tx_counter_reset    : std_logic := '0';
--    signal regs_rx_counter_reset    : std_logic := '0';
--    signal regs_tx_counter_reset    : std_logic := '0';
	 
	 signal Bunch_enable_const			: std_logic := '1';
    
    signal trigger_config           : std_logic_vector(1 downto 0) := (others => '0');
    
begin

    --================================--
    -- GTX
    --================================--

    gtx_tx_mux_inst : entity work.gtx_tx_mux
    port map(
        gtx_clk_i   => gtx_clk_i,
        reset_i     => reset_i,
        vi2c_en_i   => vi2c_tx_en,
        vi2c_data_i => vi2c_tx_data,
        regs_en_i   => regs_tx_en,
        regs_data_i => regs_tx_data,
        tx_kchar_o  => tx_kchar_o,
        tx_data_o   => tx_data_o  
    );
    
    regs_tx_en <= regs_tx_en_ipbus when trigger_config = "00" else
                  regs_tx_en_trig when trigger_config = "01" else
                  (regs_tx_en_trig or regs_tx_en_ipbus);
    
    regs_tx_data <= x"000000004043" when regs_tx_en_trig = '1' else regs_tx_data_ipbus;
    
    regs_tx_en_trig <= trigger_i;
    
    gtx_rx_mux_inst : entity work.gtx_rx_mux
    port map(
        gtx_clk_i       => gtx_clk_i,
        reset_i         => reset_i,
        vi2c_en_o       => vi2c_rx_en,
        vi2c_data_o     => vi2c_rx_data,
        track_en_o      => track_rx_en,
        track_data_o    => track_rx_data,
        regs_en_o       => regs_rx_en,
        regs_data_o     => regs_rx_data,
        rx_kchar_i      => rx_kchar_i,
        rx_data_i       => rx_data_i
    );
	 
    
--    --================================--
--    -- VFAT2 I2C
--    --================================--
--    
--    ipb_vi2c_inst : entity work.ipb_vi2c
--    port map(
--        ipb_clk_i       => ipb_clk_i,
--        gtx_clk_i       => gtx_clk_i,
--        reset_i         => reset_i,
--        ipb_mosi_i      => ipb_vi2c_i,
--        ipb_miso_o      => ipb_vi2c_o,
--        tx_en_o         => vi2c_tx_en,
--        tx_data_o       => vi2c_tx_data,
--        rx_en_i         => vi2c_rx_en,
--        rx_data_i       => vi2c_rx_data
--    );
--    
--    --================================--
--    -- Tracking data
--    --================================--
--    
--    ipb_tracking_inst : entity work.ipb_tracking
--    port map(
--        ipb_clk_i       => ipb_clk_i,
--        gtx_clk_i       => gtx_clk_i,
--        reset_i         => reset_i,
--        ipb_mosi_i      => ipb_track_i,
--        ipb_miso_o      => ipb_track_o,
--        rx_en_i         => track_rx_en,
--        rx_data_i       => track_rx_data,
--        fifo_reset_i    => track_fifo_reset,
--        fifo_count_o    => track_fifo_count
--    );
--
--    --================================--
--    -- Registers
--    --================================--
--    
--    ipb_registers_inst : entity work.ipb_registers
--    port map(
--        ipb_clk_i       => ipb_clk_i,
--        gtx_clk_i       => gtx_clk_i,
--        reset_i         => reset_i,
--        ipb_mosi_i      => ipb_regs_i,
--        ipb_miso_o      => ipb_regs_o,
--        tx_en_o         => regs_tx_en_ipbus,
--        tx_data_o       => regs_tx_data_ipbus,
--        rx_en_i         => regs_rx_en,
--        rx_data_i       => regs_rx_data
--    );

    --================================--
    -- Info
    --================================--
    
    ipb_info_inst : entity work.ipb_info
    port map(
        ipb_clk_i   => ipb_clk_i,
        reset_i     => reset_i,
        ipb_mosi_i  => ipb_info_i,
        ipb_miso_o  => ipb_info_o,
        wbus_o      => regs_req_write,
        wbus_t      => regs_req_tri,
        rbus_i      => regs_req_read
    );
    
    regs_req_read <= request_read_i & request_read;    -- Global & Local
    
    request_write_o <= regs_req_write(255 downto 128);   -- Global mapping
    request_tri_o <= regs_req_tri(255 downto 128);
    
    request_write <= regs_req_write(127 downto 0);       -- Local mapping
    request_tri <= regs_req_tri(127 downto 0);

    --================================--
    -- Counters
    --================================--
    
--    rx_error_counter_inst : entity work.counter port map(fabric_clk_i => gtx_clk_i, reset_i => rx_error_counter_reset, en_i => rx_error_i, data_o => rx_error_counter);
--    vi2c_rx_counter_inst : entity work.counter port map(fabric_clk_i => gtx_clk_i, reset_i => vi2c_rx_counter_reset, en_i => vi2c_rx_en, data_o => vi2c_rx_counter);
--    vi2c_tx_counter_inst : entity work.counter port map(fabric_clk_i => gtx_clk_i, reset_i => vi2c_tx_counter_reset, en_i => vi2c_tx_en, data_o => vi2c_tx_counter);
--    regs_rx_counter_inst : entity work.counter port map(fabric_clk_i => gtx_clk_i, reset_i => regs_rx_counter_reset, en_i => regs_rx_en, data_o => regs_rx_counter);
--    regs_tx_counter_inst : entity work.counter port map(fabric_clk_i => gtx_clk_i, reset_i => regs_tx_counter_reset, en_i => regs_tx_en, data_o => regs_tx_counter);

	 ttc_trigger_counter : entity work.counter port map(fabric_clk_i => xpoint1_clk3_bufg, reset_i => EvCntRes, en_i => l1accept, data_o => cnt_ttc_trigger);
	 ttc_Orbit_counter : entity work.counter port map(fabric_clk_i => xpoint1_clk3_bufg, reset_i => EvCntRes, en_i => BCntRes, data_o => cnt_ttc_Orbit);
	 ttc_Bunch_counter : entity work.counter port map(fabric_clk_i => xpoint1_clk3_bufg, reset_i => BCntRes, en_i => Bunch_enable_const, data_o => cnt_ttc_Bunches);
	 
	 L1A_count <= cnt_ttc_trigger;
	 Orbit_count <= cnt_ttc_orbit;
	 bunch_count <= cnt_ttc_bunches;


	 
	 --================================--
    -- Request & register mapping
    --================================--
    
    -- Counters : 4 downto 0
    
--    request_read(0) <= rx_error_counter;
--    
--    request_read(1) <= vi2c_rx_counter;
--    
--    request_read(2) <= vi2c_tx_counter;
--    
--    request_read(3) <= regs_rx_counter;
--    
--    request_read(4) <= regs_tx_counter;
--    
--    -- Counters reset : 9 downto 5
--    
--    rx_error_counter_reset <= request_tri(5);
--    
--    vi2c_rx_counter_reset <= request_tri(6);
--    
--    vi2c_tx_counter_reset <= request_tri(7);
--    
--    regs_rx_counter_reset <= request_tri(8);
--    
--    regs_tx_counter_reset <= request_tri(9);
    
    -- Firmware date : 10
    
--    request_read(10) <= request_read_i(2); -- Mapped for backwards compatibility
--    
--    -- Tracking fifo : 12 downto 11
--    
--    request_read(11) <= x"00000" & track_fifo_count; -- Occupancy
--    
--    track_fifo_reset <= request_tri(12); -- Reset
	 
	 --cnt_reset <= request_tri(13);
	 
    request_read(0) <= cnt_ttc_trigger;
	 
	 request_read(1) <= cnt_ttc_Orbit;
	 
	 request_read(2) <= cnt_ttc_bunches;
	 
--    Others : 127 downto 3
--    
--    trigger_configuration_reg : entity work.reg port map(fabric_clk_i => ipb_clk_i, reset_i => reset_i, wbus_i => request_write(3), wbus_t => request_tri(3), rbus_o => request_read(3));
--    trigger_config <= request_read(3)(1 downto 0); 

end Behavioral;