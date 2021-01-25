-- SPI slave test bench
-- 2021-01-23, wf


library ieee;
use ieee.std_logic_1164.all;
use work.vienna_scope_pkg.all;

entity spi_slave_tb is
end spi_slave_tb;

architecture behavioral of spi_slave_tb is

    signal s_clk              : std_logic := '0';
    signal s_reset            : std_logic;

    signal s_sck_i            : std_logic := '0';
    signal s_csn_i            : std_logic := '1';
    signal s_mosi_i           : std_logic := '0';
    signal s_miso_o           : std_logic_vector(0 downto 0);
    signal s_data_tx_valid_i  : std_logic := '0';
    signal s_data_tx_i        : svl8_array_t(0 downto 0);
    signal s_data_rx_o        : std_logic_vector(7 downto 0);
    signal s_data_rx_valid_o  : std_logic;
    signal s_busy_o           : std_logic;
    signal s_com_error_o      : std_logic;

begin
    s_clk   <= not s_clk  after 5 ns;  -- 100 MHz clock
    s_reset <= '1',
               '0' after 10 ns;

    s_sck_i <= not s_sck_i  after 50 ns;  -- 10 MHz SPI clock

    p_stimulus : process
    begin
        s_data_tx_i(0) <= (others => '0');
        wait for 1 us;

        -- 0x55
        s_data_tx_i(0) <= "01010101";
        wait for 2 us;
        s_data_tx_valid_i <= '1';

        wait for 2 us;
        s_csn_i     <= '0';
        wait for 300 ns;
        s_mosi_i    <= '1';
        wait for 500 ns;
        s_csn_i           <= '1';
        s_mosi_i          <= '0';
        s_data_tx_valid_i <= '0';


        wait for 1 us;
        -- 0xA9
        s_data_tx_i(0)    <= "10101001";
        s_data_tx_valid_i <= '1';

        wait for 1 us;
        s_csn_i     <= '0';
        wait for 25 ns;

        for i in 0 to 7 loop
            wait for 100 ns;
            s_mosi_i     <= not s_mosi_i;
        end loop;

        wait for 10 ns;
        s_csn_i           <= '1';
        s_data_tx_valid_i <= '0';
        
        wait for 2 us;
        -- 0x46
        s_data_tx_i(0)    <= "01000110";
        s_data_tx_valid_i <= '1';

        wait for 1 us;
        s_csn_i     <= '0';
        wait for 200 ns;
        
        -- deassert CS before finishing 8 bits - and wait for internal recovery
        s_csn_i           <= '1';
        s_data_tx_valid_i <= '0';

        wait for 10 us;

    end process p_stimulus;

    i_dut : entity work.spi_slave
        generic map (
            G_MISO_WIDTH        => 1
        )
        port map (
            clk_i               => s_clk,
            reset_i             => s_reset,
            sck_i               => s_sck_i,
            csn_i               => s_csn_i,
            mosi_i              => s_mosi_i,
            miso_o              => s_miso_o,
            data_tx_valid_i     => s_data_tx_valid_i,
            data_tx_i           => s_data_tx_i,
            data_rx_o           => s_data_rx_o,
            data_rx_valid_o     => s_data_rx_valid_o,
            busy_o              => s_busy_o,
            com_error_o         => s_com_error_o
        );

end behavioral;
