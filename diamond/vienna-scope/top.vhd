-- Vienna-Scope top module
-- 2021-01-26, wf

library machxo2;
library ieee;

use machxo2.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
use work.osc_pkg.all;
use work.vienna_scope_pkg.all;


entity top is
    port (
        --ADC
        adc_ch1_clk0_i               : in  std_logic;
        adc_ch1_clk2_i               : in  std_logic;
        -- + 2 * 4 * 8 data lines

        -- SPI (can be extended with parallel MISO)
        spi_csn_i                    : in  std_logic;
        spi_sck_i                    : in  std_logic;
        spi_mosi_i                   : in  std_logic;
        spi_miso_o                   : out std_logic;

        -- LED (green)
        led_o                        : out std_logic;

        -- DAC
        dac_clkp_o                   : out std_logic;
        dac_clkn_o                   : out std_logic;
        dac_o                        : out std_logic_vector(7 downto 0)
    );
end top;

architecture rtl of top is
    constant C_MISO_WIDTH            : integer                      := 1;
    constant C_DC                    : std_logic_vector(2 downto 0) := "000";
    constant C_SAWTOOTH              : std_logic_vector(2 downto 0) := "001";
    constant C_TRIANGLE              : std_logic_vector(2 downto 0) := "010";
    constant C_SQUARE                : std_logic_vector(2 downto 0) := "011";
    constant C_SINE                  : std_logic_vector(2 downto 0) := "100";

    signal s_clk_sys                 : std_logic;
    signal s_reset                   : std_logic;
    signal s_led_source              : std_logic;
    signal s_led_mode                : std_logic_vector(1 downto 0);
    signal s_led_speed               : std_logic;
    signal s_awg_count_clock         : std_logic;

    signal s_version                 : std_logic_vector(7 downto 0);

    signal s_dac_awg                 : svl8_array_t(0 to 4);
    signal s_awg_shape               : std_logic_vector(2  downto 0);
    signal s_awg_amplitude           : std_logic_vector(7  downto 0);
    signal s_awg_offset              : std_logic_vector(7  downto 0);
    signal s_awg_period              : std_logic_vector(23 downto 0);
    signal s_awg_clk_div             : std_logic_vector(3  downto 0);

    signal s_spi_data_tx_valid       : std_logic;
    signal s_spi_data_tx             : svl8_array_t(0 downto 0);
    signal s_spi_data_rx             : std_logic_vector(7 downto 0);
    signal s_spi_data_rx_valid       : std_logic;
    signal s_spi_busy                : std_logic;
    signal s_spi_com_error           : std_logic;

    signal s_com_address             : std_logic_vector(7 downto 0);
    signal s_com_write_data          : std_logic_vector(7 downto 0);
    signal s_com_read_strobe         : std_logic;
    signal s_com_write_strobe        : std_logic;

    -- attribute NOM_FREQ               : string;
    -- attribute NOM_FREQ of i_rc_oscillator : label is "53.20";
begin
    p_init : process (s_clk_sys)
    begin
        if(rising_edge(s_clk_sys)) then
            s_version           <= X"5A";
            s_reset             <= '0';
        end if;
    end process;
 
    i_rc_oscillator : OSCH
        -- synthesis translate_off
        generic map(
            NOM_FREQ => "53.20"
        )
        -- synthesis translate_on
        port map(
            STDBY       => '0',
            OSC         => s_clk_sys,
            SEDSTDBY    => open
        );

    i_led_blink : entity work.led
        port map(
            clk_i               => s_clk_sys,
            reset_i             => s_reset,
            source_i            => s_led_source,
            speed_i             => s_led_speed,
            led_o               => led_o
        );
    s_led_source <= s_clk_sys      when (s_led_mode="00") else
                    adc_ch1_clk0_i when (s_led_mode="01") else
                    adc_ch1_clk2_i when (s_led_mode="11") else
                    s_awg_count_clock;

    i_dac_clk : entity work.dac_clk
        port map(
            clk_i               => s_clk_sys,
            reset_i             => s_reset,
            clk_div_i           => s_awg_clk_div,
            dac_clkp_o          => dac_clkp_o,
            dac_clkn_o          => dac_clkn_o
        );

    i_awg : entity work.awg
        port map(
            clk_i               => s_clk_sys,
            reset_i             => s_reset,
            amplitude_i         => s_awg_amplitude,
            offset_i            => s_awg_offset,
            period_i            => s_awg_period,
            dc_o                => s_dac_awg(0),
            sawtooth_o          => s_dac_awg(1),
            triangle_o          => s_dac_awg(2),
            square_o            => s_dac_awg(3),
            sine_o              => s_dac_awg(4)
        );
    dac_o   <= s_dac_awg(0) when (s_awg_shape=C_DC)       else
               s_dac_awg(1) when (s_awg_shape=C_SAWTOOTH) else
               s_dac_awg(2) when (s_awg_shape=C_TRIANGLE) else
               s_dac_awg(3) when (s_awg_shape=C_SQUARE)   else
               s_dac_awg(4); -- when (s_awg_shape=C_SINE)
    s_awg_count_clock <= '1' when unsigned(s_dac_awg(3)) > unsigned(s_awg_offset) else '0';

    i_spi : entity work.spi_slave
        generic map (
            G_MISO_WIDTH        => C_MISO_WIDTH
        )
        port map (
            clk_i               => s_clk_sys,
            reset_i             => s_reset,
            sck_i               => spi_sck_i,
            csn_i               => spi_csn_i,
            mosi_i              => spi_mosi_i,
            miso_o(0)           => spi_miso_o,
            -- something like that miso_o(C_MISO_WIDTH-1 downto 0)  => open
            ----------------------------------
            data_tx_valid_i     => s_spi_data_tx_valid,
            data_tx_i           => s_spi_data_tx,
            data_rx_o           => s_spi_data_rx,
            data_rx_valid_o     => s_spi_data_rx_valid,
            busy_o              => s_spi_busy,
            com_error_o         => s_spi_com_error
    );

    i_com_decode : entity work.spi_decode
        port map (
            clk_i             => s_clk_sys,
            reset_i           => s_reset,
            data_rx_i         => s_spi_data_rx,
            data_rx_strobe_i  => s_spi_data_rx_valid,
            address_o         => s_com_address,
            write_data_o      => s_com_write_data,
            read_strobe_o     => s_com_read_strobe,
            write_strobe_o    => s_com_write_strobe
        );

    p_com_requests : process (s_clk_sys, s_reset)
    begin
        if s_reset = '1' then
            s_led_mode          <= (others => '0');
            s_led_speed         <= '1';

            -- Update these values:
            -- Multimeter mode: 
            -- s_awg_period <= X"205940";
            -- Osci mode - 1MHz div by 53 or even div by 5 for more than 10MHz:
            -- s_awg_period <= X"002968";
            s_awg_shape         <= C_SQUARE;
            s_awg_amplitude     <= X"0A";
            s_awg_offset        <= X"7F";
            s_awg_period        <= X"000100";
            s_awg_clk_div       <= "1000";

            s_spi_data_tx_valid     <= '0';
            s_spi_data_tx(0)        <= (others => '0');
        elsif rising_edge(s_clk_sys) then
            s_spi_data_tx_valid     <= '0';
            if s_com_read_strobe = '1' then
                s_spi_data_tx_valid     <= '1';
                case s_com_address is
                    when X"01" =>
                        s_spi_data_tx(0)    <= s_version;
                    when X"02" =>
                        s_spi_data_tx(0)(1 downto 0) <= s_led_mode;
                        s_spi_data_tx(0)(4) <= s_led_speed;
                    when X"20" =>
                        s_spi_data_tx(0)    <= "00000" & s_awg_shape;
                    when X"21" =>
                        s_spi_data_tx(0)    <= s_awg_amplitude;
                    when X"22" =>
                        s_spi_data_tx(0)    <= s_awg_offset;
                    when X"23" =>
                        s_spi_data_tx(0)    <= s_awg_period(7 downto 0);
                    when X"24" =>
                        s_spi_data_tx(0)    <= s_awg_period(15 downto 8);
                    when X"25" =>
                        s_spi_data_tx(0)    <= s_awg_period(23 downto 16);
                    when X"26" =>
                        -- s_spi_data_tx(0)    <= resize(s_awg_clk_div, s_spi_data_tx(0)'length);
                        s_spi_data_tx(0)    <= X"0" & s_awg_clk_div;
                    when others => 
                        s_spi_data_tx_valid <= '0';
                end case;
            end if;
            if s_com_write_strobe = '1' then
                case s_com_address is
                    when X"02" =>
                        s_led_mode                   <= s_com_write_data(1 downto 0);
                        s_led_speed                  <= s_com_write_data(4);
                    when X"20" =>
                        s_awg_shape                  <= s_com_write_data(2 downto 0);
                    when X"21" =>
                        s_awg_amplitude              <= s_com_write_data;
                    when X"22" =>
                        s_awg_offset                 <= s_com_write_data;
                    when X"23" =>
                        s_awg_period( 7 downto 0)    <= s_com_write_data;
                    when X"24" =>
                        s_awg_period(15 downto 8)    <= s_com_write_data;
                    when X"25" =>
                        s_awg_period(23 downto 16)   <= s_com_write_data;
                    when X"26" =>
                        s_awg_clk_div                <= s_com_write_data(3 downto 0);
                    when others => 
                        
                end case;
            end if;

        end if;
    end process;

end rtl;
