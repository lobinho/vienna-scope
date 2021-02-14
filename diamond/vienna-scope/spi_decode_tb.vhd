-- SPI decode test bench
-- 2021-01-24, wf


library ieee;
use ieee.std_logic_1164.all;
use work.vienna_scope_pkg.all;

entity spi_decode_tb is
end spi_decode_tb;

architecture behavioral of spi_decode_tb is
    signal s_clk              : std_logic := '0';
    signal s_reset            : std_logic;

    signal s_data_rx_i        : std_logic_vector(7 downto 0);
    signal s_data_rx_strobe_i : std_logic := '0';
    signal s_address_o        : std_logic_vector(7 downto 0);
    signal s_write_data_o     : std_logic_vector(7 downto 0);
    signal s_read_strobe_o    : std_logic;
    signal s_write_strobe_o   : std_logic;

begin
    s_clk   <= not s_clk  after 5 ns;  -- 100 MHz clock
    s_reset <= '1',
               '0' after 10 ns;

    p_stimulus : process
    begin
        wait for 2 ns;

        -- read from 0x20
        s_data_rx_i        <= C_SPI_CMD_RD;
        wait for 1 us;
        s_data_rx_strobe_i <= '1';
        wait for 10 ns;
        s_data_rx_strobe_i <= '0';

        wait for 1 us;
        s_data_rx_i        <= X"20";
        wait for 1 us;
        s_data_rx_strobe_i <= '1';
        wait for 10 ns;
        s_data_rx_strobe_i <= '0';
        wait for 1 us;

        -- write 0xAA to 0x30
        s_data_rx_i        <= C_SPI_CMD_WR;
        wait for 1 us;
        s_data_rx_strobe_i <= '1';
        wait for 10 ns;
        s_data_rx_strobe_i <= '0';

        wait for 1 us;
        s_data_rx_i        <= X"30";
        wait for 1 us;
        s_data_rx_strobe_i <= '1';
        wait for 10 ns;
        s_data_rx_strobe_i <= '0';

        wait for 1 us;
        s_data_rx_i        <= X"AA";
        wait for 1 us;
        s_data_rx_strobe_i <= '1';
        wait for 10 ns;
        s_data_rx_strobe_i <= '0';
        wait for 1 us;

        -- illegal command
        s_data_rx_i        <= X"FF";
        wait for 1 us;
        s_data_rx_strobe_i <= '1';
        wait for 10 ns;
        s_data_rx_strobe_i <= '0';
        wait for 1 us;

    end process p_stimulus;

    i_dut : entity work.spi_decode
        port map (
            clk_i             => s_clk,
            reset_i           => s_reset,
            data_rx_i         => s_data_rx_i,
            data_rx_strobe_i  => s_data_rx_strobe_i,
            address_o         => s_address_o,
            write_data_o      => s_write_data_o,
            read_strobe_o     => s_read_strobe_o,
            write_strobe_o    => s_write_strobe_o,
            state_o           => open
        );



end behavioral;
