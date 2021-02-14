-- Top test bench
-- 2021-01-30, wf


library ieee;
use ieee.std_logic_1164.all;
use work.vienna_scope_pkg.all;  

entity top_tb is
end top_tb;

architecture behavioral of top_tb is

    constant C_ADC_INTERLEAVED_CH : integer := 4;
    constant C_MISO_WIDTH         : integer := 1;
    -- top port
    signal s_reset_i              : std_logic := '0'; 
    signal s_adc_ch1_clk0_i       : std_logic := '0';
    signal s_adc_ch1_clk2_i       : std_logic := '0';
    signal s_adc_ch1_d_i          : slv8_array_t(0 to C_ADC_INTERLEAVED_CH-1);
    signal s_adc_ch2_d_i          : slv8_array_t(0 to C_ADC_INTERLEAVED_CH-1);
    signal s_spi_csn_i            : std_logic := '1';
    signal s_spi_sck_i            : std_logic := '0';
    signal s_spi_mosi_i           : std_logic;
    signal s_spi_miso_o           : std_logic_vector(C_MISO_WIDTH-1 downto 0);
    signal s_led_o                : std_logic;
    signal s_dac_clkp_o           : std_logic;
    signal s_dac_clkn_o           : std_logic;
    signal s_dac_o                : std_logic_vector(7 downto 0);
    --------------------------------------------------------------
    signal data_wr_0              : slv8_array_t(0 to 2);
    signal data_wr_1              : slv8_array_t(0 to 2);
    signal data_rd_0              : slv8_array_t(0 to 2);
    signal data_rd_1              : slv8_array_t(0 to 2);
begin

    s_reset_i <= '1',
                 '0' after 100 ns;
    s_adc_ch1_clk0_i   <= not s_adc_ch1_clk0_i  after 25 ns;  -- 20 MHz clock

    data_wr_0(0)    <= C_SPI_CMD_WR;
    data_wr_0(1)    <= X"03";           -- 5 bits: s_led_clk_div
    data_wr_0(2)    <= X"00";

    data_wr_1(0)    <= C_SPI_CMD_WR;
    data_wr_1(1)    <= X"02";           -- 2 bits: s_led_mode
    data_wr_1(2)    <= X"03";

    data_rd_0(0)    <= C_SPI_CMD_RD;
    data_rd_0(1)    <= X"01";           -- version
    data_rd_0(2)    <= X"00";           -- don't care - this is just for master to clock data in

    data_rd_1(0)    <= C_SPI_CMD_RD;
    data_rd_1(1)    <= X"50";           -- indirect read
    data_rd_1(2)    <= X"00";           -- don't care - this is just for master to clock data in

    p_stimulus : process
    begin
    
        wait for 1 us;
        s_spi_csn_i     <= '0';
        wait for 25 ns;

        -- for k in 0 to 2 loop
        --     for i in 0 to 7 loop
        --         s_spi_sck_i <= '0';
        --         wait for 25 ns;
        --         s_spi_mosi_i     <= data_wr_0(k)(7-i);
        --         wait for 25 ns;
        --         s_spi_sck_i <= '1';
        --         wait for 50 ns;
        --         s_spi_sck_i <= '0';
        --     end loop;
        -- end loop;

        wait for 1 us;

        for k in 0 to 2 loop
            for i in 0 to 7 loop
                s_spi_sck_i <= '0';
                wait for 25 ns;
                s_spi_mosi_i     <= data_wr_1(k)(7-i);
                wait for 25 ns;
                s_spi_sck_i <= '1';
                wait for 50 ns;
                s_spi_sck_i <= '0';
            end loop;
        end loop;

        wait for 1 us;

        for k in 0 to 2 loop
            for i in 0 to 7 loop
                s_spi_sck_i <= '0';
                wait for 25 ns;
                s_spi_mosi_i     <= data_rd_0(k)(7-i);
                wait for 25 ns;
                s_spi_sck_i <= '1';
                wait for 50 ns;
                s_spi_sck_i <= '0';
            end loop;
        end loop;

        wait for 1 us;

        for k in 0 to 2 loop
            for i in 0 to 7 loop
                s_spi_sck_i <= '0';
                wait for 25 ns;
                s_spi_mosi_i     <= data_rd_1(k)(7-i);
                wait for 25 ns;
                s_spi_sck_i <= '1';
                wait for 50 ns;
                s_spi_sck_i <= '0';
            end loop;
        end loop;

        wait for 100 ns;
        s_spi_csn_i           <= '1';
        wait for 100 us;
        

    end process p_stimulus;

    i_dut : entity work.top
        generic map (
            G_ADC_INTERLEAVED_CH   => C_ADC_INTERLEAVED_CH,
            G_MISO_WIDTH           => C_MISO_WIDTH
        )
        port map (
            reset_i                => s_reset_i,
            adc_ch1_clk0_i         => s_adc_ch1_clk0_i,
            adc_ch1_clk2_i         => s_adc_ch1_clk2_i,
            adc_ch1_d_i            => s_adc_ch1_d_i,
            adc_ch2_d_i            => s_adc_ch2_d_i,
            spi_csn_i              => s_spi_csn_i,
            spi_sck_i              => s_spi_sck_i,
            spi_mosi_i             => s_spi_mosi_i,
            spi_miso_o             => s_spi_miso_o,
            led_o                  => s_led_o,
            dac_clkp_o             => s_dac_clkp_o,
            dac_clkn_o             => s_dac_clkn_o,
            dac_o                  => s_dac_o
        );

end behavioral;
