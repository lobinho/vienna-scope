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
    generic(
        G_ADC_INTERLEAVED_CH         : integer := 4;
        G_MISO_WIDTH                 : integer := 1
    );
    port (
        -- Reset could be in future jtag pin used as gpio,
        -- in the meantime drive with e.g. Pin138 - Rpi MISOD3
        reset_i                      : in  std_logic;

        --ADC
        adc_ch1_clk0_i               : in  std_logic;
        adc_ch1_clk2_i               : in  std_logic;
        -- + 2 * 4 * 8 data lines
        adc_ch1_d_i                  : in slv8_array_t(0 to G_ADC_INTERLEAVED_CH-1);
        adc_ch2_d_i                  : in slv8_array_t(0 to G_ADC_INTERLEAVED_CH-1);

        -- SPI (can be extended with parallel MISO)
        spi_csn_i                    : in  std_logic;
        spi_sck_i                    : in  std_logic;
        spi_mosi_i                   : in  std_logic;
        spi_miso_o                   : out std_logic_vector(G_MISO_WIDTH-1 downto 0);

        -- LED (green)
        led_o                        : out std_logic;

        -- DAC
        dac_clkp_o                   : out std_logic;
        dac_clkn_o                   : out std_logic;
        dac_o                        : out std_logic_vector(7 downto 0)
    );
end top;

architecture rtl of top is
    constant C_MAJOR_VERSION         : std_logic_vector(3 downto 0) := X"0";
    constant C_MINOR_VERSION         : std_logic_vector(3 downto 0) := X"1";
    constant C_DC                    : std_logic_vector(2 downto 0) := "000";
    constant C_SAWTOOTH              : std_logic_vector(2 downto 0) := "001";
    constant C_TRIANGLE              : std_logic_vector(2 downto 0) := "010";
    constant C_SQUARE                : std_logic_vector(2 downto 0) := "011";
    constant C_SINE                  : std_logic_vector(2 downto 0) := "100";

    signal s_clk_sys                 : std_logic;

    signal s_clk_counter             : std_logic_vector(31 downto 0);
    signal s_led_clk_div             : std_logic_vector( 4 downto 0);

    signal s_awg_count_clock         : std_logic;

    signal s_adc_ch1_d               : slv8_array_t(0 to G_ADC_INTERLEAVED_CH-1);
    signal s_adc_ch2_d               : slv8_array_t(0 to G_ADC_INTERLEAVED_CH-1);
    signal s_adc_ch1_data            : std_logic_vector(31 downto 0);
    signal s_adc_ch2_data            : std_logic_vector(31 downto 0);

    signal s_fifo_wr_clk             : std_logic;
    signal s_fifo_rd_clk             : std_logic;
    signal s_fifo_ch1_wr_en          : std_logic;
    signal s_fifo_ch1_rd_en          : std_logic;
    signal s_fifo_ch1_reset          : std_logic;
    signal s_fifo_ch1_rpreset        : std_logic;
    signal s_fifo_ch1_rd             : std_logic_vector(31 downto 0);
    signal s_fifo_ch1_empty          : std_logic;
    signal s_fifo_ch1_almost_empty   : std_logic;
    signal s_fifo_ch1_full           : std_logic;
    signal s_fifo_ch1_almost_full    : std_logic;
    signal s_fifo_ch2_wr_en          : std_logic;
    signal s_fifo_ch2_rd_en          : std_logic;
    signal s_fifo_ch2_reset          : std_logic;
    signal s_fifo_ch2_rpreset        : std_logic;
    signal s_fifo_ch2_rd             : std_logic_vector(31 downto 0);
    signal s_fifo_ch2_empty          : std_logic;
    signal s_fifo_ch2_almost_empty   : std_logic;
    signal s_fifo_ch2_full           : std_logic;
    signal s_fifo_ch2_almost_full    : std_logic;

    signal s_fifo_read_state         : fifo_rd_state_t;
    signal s_fifo_source             : std_logic_vector(1 downto 0);

    signal s_fifo_rd                 : std_logic_vector(31 downto 0);
    signal s_fifo_address            : std_logic_vector(1 downto 0);

    signal s_adc_clk_shifter         : slv8_array_t(0 to 1);
    signal s_adc_clk_re              : std_logic_vector(1 downto 0);
    signal s_adc_clk_counter         : unsigned8_array_t(0 to 1);

    signal s_dac_awg_out             : std_logic_vector(7 downto 0);
    signal s_dac_awg                 : slv8_array_t(0 to 4);
    signal s_awg_shape               : std_logic_vector(2  downto 0);
    signal s_awg_amplitude           : std_logic_vector(7  downto 0);
    signal s_awg_offset              : std_logic_vector(7  downto 0);
    signal s_awg_period              : std_logic_vector(23 downto 0);
    signal s_awg_clk_stop            : std_logic;
    signal s_awg_clk_div             : std_logic_vector(3  downto 0);

    signal s_spi_data_tx_valid       : std_logic;
    signal s_spi_data_tx             : slv8_array_t(0 to G_MISO_WIDTH-1);
    signal s_spi_loopback            : std_logic;
    signal s_spi_data_rx             : std_logic_vector(7 downto 0);
    signal s_spi_data_rx_valid       : std_logic;
    signal s_spi_busy                : std_logic;
    signal s_spi_com_error           : std_logic;

    signal s_com_address             : std_logic_vector(7 downto 0);
    signal s_com_write_data          : std_logic_vector(7 downto 0);
    signal s_com_read_strobe_rq      : std_logic;
    signal s_com_read_strobe         : std_logic;
    signal s_com_write_strobe        : std_logic;
    signal s_com_state               : com_state_t;

    attribute NOM_FREQ               : string;
    attribute NOM_FREQ of i_rc_oscillator : label is "53.20";

    -- attribute syn_keep               : boolean;
    -- attribute syn_keep of s_version  : signal is true;
begin
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

    i_clk_count : entity work.clk_count
        port map(
            clk_i       => s_clk_sys,
            reset_i     => reset_i,
            enable_i    => '1',
            count_o     => s_clk_counter
        );
    led_o        <=     std_logic(s_clk_counter(to_integer(unsigned(s_led_clk_div))));
    dac_clkp_o   <=     std_logic(s_clk_counter(to_integer(unsigned(s_awg_clk_div)))) when s_awg_clk_stop = '0' else '0';
    dac_clkn_o   <= not std_logic(s_clk_counter(to_integer(unsigned(s_awg_clk_div)))) when s_awg_clk_stop = '0' else '0';

    p_adc_clk : process (reset_i, s_clk_sys)
    begin
        if reset_i = '1' then
            for i in 0 to 1 loop
                s_adc_clk_shifter(i) <= (others => '0');
                s_adc_clk_re(i)      <= '0';
                s_adc_clk_counter(i) <= to_unsigned(0, s_adc_clk_counter(i)'length);
            end loop;
        elsif rising_edge(s_clk_sys) then
            s_adc_clk_shifter(0) <= X"0" & s_adc_clk_shifter(0)(2 downto 0) & adc_ch1_clk0_i;
            s_adc_clk_shifter(1) <= X"0" & s_adc_clk_shifter(1)(2 downto 0) & adc_ch1_clk2_i;
            for i in 0 to 1 loop
                s_adc_clk_re(i)          <= s_adc_clk_shifter(i)(3) and not s_adc_clk_shifter(i)(2);
                if s_adc_clk_re(i) = '1' then
                    s_adc_clk_counter(i) <= s_adc_clk_counter(i) + 1;
                end if;
            end loop;
        end if;
    end process;

    -- Currently only ch1_d(0) is really used. Other phase relations and ch2 are TODO.
    p_adc : process (reset_i, s_clk_sys)
    begin
        if reset_i = '1' then
            for i in 0 to G_ADC_INTERLEAVED_CH-1 loop
                s_adc_ch1_d(i)   <= (others => '0');
                s_adc_ch2_d(i)   <= (others => '0');
            end loop;
        elsif rising_edge(s_clk_sys) then
            --if adc_ch1_clk0_i = '1' then
            if s_adc_clk_re(0) = '1' then
                s_adc_ch1_d(0)   <=  adc_ch1_d_i(0);
                s_adc_ch1_d(2)   <=  adc_ch1_d_i(2);

            end if;
            --if adc_ch1_clk2_i = '1' then
            if s_adc_clk_re(1) = '1' then
                s_adc_ch1_d(1)   <=  adc_ch1_d_i(1);
                s_adc_ch1_d(3)   <=  adc_ch1_d_i(3);
                
            end if;
        end if;
    end process;
    -- for testing purposes feed fifo with awg or registered external adc clock
    s_adc_ch1_data(7  downto 0)   <= s_adc_ch1_d(0)           when s_fifo_source = "00" else
                                     s_dac_awg_out            when s_fifo_source = "01" else
                                     s_adc_clk_shifter(0)(3) & "0000000"  when s_fifo_source = "10" else
                                     s_dac_awg_out;
    s_adc_ch1_data(15 downto 8)   <= s_adc_ch1_d(1);
    s_adc_ch1_data(23 downto 16)  <= s_adc_ch1_d(2);
    s_adc_ch1_data(31 downto 24)  <= s_adc_ch1_d(3);

    s_adc_ch2_data(7  downto 0)   <= s_adc_ch2_d(0)           when s_fifo_source = "00" else
                                     s_dac_awg_out            when s_fifo_source = "01" else
                                     s_adc_clk_shifter(1)(3) & "0000000" when s_fifo_source = "10" else
                                     s_dac_awg_out;
    s_adc_ch2_data(15 downto 8)   <= s_adc_ch2_d(1);
    s_adc_ch2_data(23 downto 16)  <= s_adc_ch2_d(2);
    s_adc_ch2_data(31 downto 24)  <= s_adc_ch2_d(3);

    s_fifo_wr_clk <= s_clk_sys;
    s_fifo_rd_clk <= s_clk_sys;

    i_fifo_ch1 : entity work.adc_fifo
        port map (
            Data                => s_adc_ch1_data,
            WrClock             => s_fifo_wr_clk,
            RdClock             => s_fifo_rd_clk,
            WrEn                => s_fifo_ch1_wr_en,
            RdEn                => s_fifo_ch1_rd_en,
            Reset               => s_fifo_ch1_reset,
            RPReset             => s_fifo_ch1_rpreset,
            Q                   => s_fifo_ch1_rd,
            Empty               => s_fifo_ch1_empty,
            Full                => s_fifo_ch1_full,
            AlmostEmpty         => s_fifo_ch1_almost_empty,
            AlmostFull          => s_fifo_ch1_almost_full
    );
    i_fifo_ch2 : entity work.adc_fifo
        port map (
            Data                => s_adc_ch2_data,
            WrClock             => s_fifo_wr_clk,
            RdClock             => s_fifo_rd_clk,
            WrEn                => s_fifo_ch2_wr_en,
            RdEn                => s_fifo_ch2_rd_en,
            Reset               => s_fifo_ch2_reset,
            RPReset             => s_fifo_ch2_rpreset,
            Q                   => s_fifo_ch2_rd,
            Empty               => s_fifo_ch2_empty,
            Full                => s_fifo_ch2_full,
            AlmostEmpty         => s_fifo_ch2_almost_empty,
            AlmostFull          => s_fifo_ch2_almost_full
    );

    i_awg : entity work.awg
        port map(
            clk_i               => s_clk_sys,
            reset_i             => reset_i,
            amplitude_i         => s_awg_amplitude,
            offset_i            => s_awg_offset,
            period_i            => s_awg_period,
            dc_o                => s_dac_awg(0),
            sawtooth_o          => s_dac_awg(1),
            triangle_o          => s_dac_awg(2),
            square_o            => s_dac_awg(3),
            sine_o              => s_dac_awg(4)
        );
    s_dac_awg_out <= s_dac_awg(0) when (s_awg_shape = C_DC)       else
                     s_dac_awg(1) when (s_awg_shape = C_SAWTOOTH) else
                     s_dac_awg(2) when (s_awg_shape = C_TRIANGLE) else
                     s_dac_awg(3) when (s_awg_shape = C_SQUARE)   else
                     s_dac_awg(4); -- when (s_awg_shape = C_SINE)
    dac_o <= s_dac_awg_out;
    s_awg_count_clock <= '1' when unsigned(s_dac_awg(3)) > unsigned(s_awg_offset) else '0';

    i_spi : entity work.spi_slave
        generic map (
            G_MISO_WIDTH        => G_MISO_WIDTH
        )
        port map (
            clk_i               => s_clk_sys,
            reset_i             => reset_i,
            sck_i               => spi_sck_i,
            csn_i               => spi_csn_i,
            mosi_i              => spi_mosi_i,
            miso_o              => spi_miso_o,
            data_tx_valid_i     => s_spi_data_tx_valid,
            data_tx_i           => s_spi_data_tx,
            loopback_i          => s_spi_loopback,
            data_rx_o           => s_spi_data_rx,
            data_rx_valid_o     => s_spi_data_rx_valid,
            busy_o              => s_spi_busy,
            com_error_o         => s_spi_com_error
    );

    i_com_decode : entity work.spi_decode
        port map (
            clk_i             => s_clk_sys,
            reset_i           => reset_i,
            data_rx_i         => s_spi_data_rx,
            data_rx_strobe_i  => s_spi_data_rx_valid,
            address_o         => s_com_address,
            write_data_o      => s_com_write_data,
            read_strobe_o     => s_com_read_strobe_rq,
            write_strobe_o    => s_com_write_strobe,
            state_o           => s_com_state
        );
    -- MISO = MOSI unless we provide requested data to read back: WAIT_FOR_DATA_RD
    s_spi_loopback <= '0' when s_com_state = WAIT_FOR_DATA_RD else '1';

    -- Forward read requests directly unless when reading indirectly from FIFO for ADCs
    -- s_com_address is assumed unchanged within one cycle of pipeline as it is updated only
    -- after 8 clocks - plenty of time
    p_com_read_control : process (s_clk_sys, reset_i)
    begin
        if reset_i = '1' then
            s_com_read_strobe  <= '0';
            s_fifo_ch1_rd_en   <= '0';
            s_fifo_ch2_rd_en   <= '0';
            s_fifo_read_state <= DIRECT_READ_RQ;
        elsif rising_edge(s_clk_sys) then
            s_com_read_strobe <= '0';
            s_fifo_ch1_rd_en  <= '0';
            s_fifo_ch2_rd_en  <= '0';
            case s_fifo_read_state is
                when DIRECT_READ_RQ =>
                    if s_com_read_strobe_rq = '1' and s_com_address = X"50" then
                        -- indirect read from FIFO for adc channel
                        -- start reading fifo - this has one clock latency without output register
                        -- assume that FIFO was actually full before - this shall be done
                        -- by user who shall read out
                        case s_fifo_address is
                            when "00" =>
                                s_fifo_ch1_rd_en  <= '1';
                                s_fifo_ch2_rd_en  <= '0';
                            when "01" =>
                                s_fifo_ch1_rd_en  <= '0';
                                s_fifo_ch2_rd_en  <= '1';
                            when others =>
                                s_fifo_ch1_rd_en  <= '0';
                                s_fifo_ch2_rd_en  <= '0';
                        end case;
                        s_fifo_read_state <= WAIT_FOR_FIFO_0;
                    else
                        s_com_read_strobe <= '1';
                    end if;
                when WAIT_FOR_FIFO_0 =>
                    s_fifo_ch1_rd_en  <= '0';
                    s_fifo_ch2_rd_en  <= '0';
                    s_fifo_read_state <= WAIT_FOR_FIFO_1;
                when WAIT_FOR_FIFO_1 =>
                    s_com_read_strobe <= '1';
                    case s_fifo_address is
                        when "00" =>
                            s_fifo_rd <= s_fifo_ch1_rd;
                        when "01" =>
                            s_fifo_rd <= s_fifo_ch2_rd;
                        when "10" =>
                            s_fifo_rd <= X"DEADDEAD";
                        when others =>
                            s_fifo_rd <= X"DEADBEEE";
                    end case;
                    s_fifo_read_state <= DIRECT_READ_RQ;
                when others =>
                    s_fifo_read_state <= DIRECT_READ_RQ;
            end case;
        end if;
    end process;

    p_com_requests : process (s_clk_sys, reset_i)
    begin
        if reset_i = '1' then
            s_led_clk_div       <= "11000";     -- 24
            s_awg_shape         <= C_SQUARE;
            s_awg_amplitude     <= X"0A";
            s_awg_offset        <= X"7F";
            s_awg_period        <= X"000100";
            s_awg_clk_stop      <= '1';
            s_awg_clk_div       <= "1000";

            s_spi_data_tx_valid <= '0';
            for i in 0 to G_MISO_WIDTH-1 loop
                s_spi_data_tx(i) <= (others => '0');
            end loop;

            s_fifo_source       <= (others => '0');
            s_fifo_ch1_wr_en    <= '0';
            s_fifo_ch1_reset    <= '1';
            s_fifo_ch1_rpreset  <= '1';
            s_fifo_ch2_wr_en    <= '0';
            s_fifo_ch2_reset    <= '1';
            s_fifo_ch2_rpreset  <= '1';
            s_fifo_address      <= (others => '0');
        elsif rising_edge(s_clk_sys) then
            s_spi_data_tx_valid     <= '0';
            if s_com_read_strobe = '1' then
                s_spi_data_tx_valid     <= '1';

                s_spi_data_tx(0)        <= (others => '0');
                case s_com_address is
                    when X"01" =>
                        s_spi_data_tx(0)    <= C_MAJOR_VERSION & C_MINOR_VERSION;
                    when X"02" =>
                        s_spi_data_tx(0)    <= X"FF";
                    when X"03" =>
                        s_spi_data_tx(0)(4 downto 0) <= s_led_clk_div;
                    when X"0E" =>
                        s_spi_data_tx(0)    <= std_logic_vector(s_adc_clk_counter(0));
                    when X"0F" =>
                        s_spi_data_tx(0)    <= std_logic_vector(s_adc_clk_counter(1));   
                    when X"20" =>
                        s_spi_data_tx(0)    <= X"0" & '0' & s_awg_shape;
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
                        s_spi_data_tx(0)    <= "000" & s_awg_clk_stop & s_awg_clk_div;
                    when X"50" =>
                        -- indirect read from FIFO finished and ready at this point
                        s_spi_data_tx(0)    <= s_fifo_rd(7 downto 0);
                        -- TODO: other channels can use further MISO lines
                    when X"51" =>
                        s_spi_data_tx(0)    <= "00" & s_fifo_source & "00" & s_fifo_address(1 downto 0);
                    when X"52" =>
                        s_spi_data_tx(0)    <= "000" & s_fifo_ch2_wr_en & "000" & s_fifo_ch1_wr_en;
                    when X"53" =>
                        s_spi_data_tx(0)    <= "00" & s_fifo_ch2_rpreset & s_fifo_ch2_reset & "00" & s_fifo_ch1_rpreset & s_fifo_ch1_reset;
                    when X"54" =>
                        s_spi_data_tx(0)    <= s_fifo_ch2_almost_empty & s_fifo_ch2_empty & s_fifo_ch2_almost_full & s_fifo_ch2_full
                                             & s_fifo_ch1_almost_empty & s_fifo_ch1_empty & s_fifo_ch1_almost_full & s_fifo_ch1_full;
                    when others => 
                        s_spi_data_tx_valid <= '0';
                end case;
            end if;
            if s_com_write_strobe = '1' then
                case s_com_address is
                    when X"02" =>
                    
                    when X"03" =>
                        s_led_clk_div                <= s_com_write_data(4 downto 0);
                    -- X"0E" to X"0F" is reserved
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
                        s_awg_clk_stop               <= s_com_write_data(4);
                    -- X"50" is read only
                    when X"51" =>
                        s_fifo_address               <= s_com_write_data(1 downto 0);
                        s_fifo_source                <= s_com_write_data(5 downto 4);
                    when X"52" =>
                        s_fifo_ch1_wr_en             <= s_com_write_data(0);
                        s_fifo_ch2_wr_en             <= s_com_write_data(4);
                    when X"53" =>
                        s_fifo_ch1_reset             <= s_com_write_data(0);
                        s_fifo_ch1_rpreset           <= s_com_write_data(1);
                        s_fifo_ch2_reset             <= s_com_write_data(4);
                        s_fifo_ch2_rpreset           <= s_com_write_data(5);
                    -- X"54" is read only
                    when others => 
                        
                end case;
            end if;

        end if;
    end process;

end rtl;
