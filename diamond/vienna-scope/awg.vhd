-- Arbitrary Waveform generator module
-- 2021-01-22, wf

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_signed.all;
use ieee.numeric_std.all;
use work.vienna_scope_pkg.all;

entity awg is
port (
    clk_i             : in  std_logic;
    reset_i           : in  std_logic;
    amplitude_i       : in  std_logic_vector(7  downto 0);
    offset_i          : in  std_logic_vector(7  downto 0);
    period_i          : in  std_logic_vector(23 downto 0);

    dc_o              : out std_logic_vector(7  downto 0);
    sawtooth_o        : out std_logic_vector(7  downto 0);
    triangle_o        : out std_logic_vector(7  downto 0);
    square_o          : out std_logic_vector(7  downto 0);
    sine_o            : out std_logic_vector(7  downto 0)
);
end awg;

architecture behavioral of awg is

    signal s_even_sawtooth    : std_logic;
    signal s_triangle_dir     : std_logic;
    signal s_clk_count        : unsigned(23 downto 0);
    signal s_sawtooth_count   : unsigned(7 downto 0);
    signal s_triangle_count   : unsigned(7 downto 0);
    signal s_square_count     : unsigned(7 downto 0);
    signal s_dc_count         : unsigned(7 downto 0);
    signal s_low_level        : unsigned(7 downto 0);
    signal s_high_level       : unsigned(7 downto 0);
    signal s_high_level_unsat : unsigned(8 downto 0);
    signal s_sine             : unsigned(7 downto 0);
    signal s_sine_lut         :   signed(7 downto 0);
    signal s_sine_unsat       :   signed(9 downto 0);
    signal s_sine_index       : unsigned(7 downto 0);
    signal s_sine_div         : integer range 0 to 7;
begin
    p_main_counter : process (clk_i, reset_i)
    begin
        if reset_i = '1' then
            s_clk_count          <= (others => '0');
        elsif rising_edge(clk_i) then
            s_clk_count <= s_clk_count + 1;
            if s_clk_count >= unsigned(period_i) then
                s_clk_count <= (others => '0');
            end if;
        end if;
    end process;

    p_level_sat : process (clk_i, reset_i)
    begin
        if reset_i = '1' then
            s_low_level          <= (others => '0');
            s_high_level         <= (others => '0');
            s_high_level_unsat   <= (others => '0');

        elsif rising_edge(clk_i) then
            if unsigned(offset_i) < unsigned(amplitude_i) then
                s_low_level <= (others => '0');
            else
                s_low_level <= unsigned(offset_i) - unsigned(amplitude_i);
            end if;
            s_high_level_unsat <= resize(unsigned(offset_i),    s_high_level_unsat'length)
                                + resize(unsigned(amplitude_i), s_high_level_unsat'length);

            if s_high_level_unsat(8) = '1' then
                s_high_level <= (others => '1');
            else
                s_high_level <= s_high_level_unsat(7 downto 0);
            end if;
        end if;
    end process;

    p_signals : process (clk_i, reset_i)
    begin
        if reset_i = '1' then
            s_even_sawtooth      <= '1';
            s_triangle_dir       <= '0';
            s_sawtooth_count     <= (others => '0');
            s_triangle_count     <= (others => '0');
            s_square_count       <= (others => '0');
            s_dc_count           <= (others => '0');

        elsif rising_edge(clk_i) then

            if s_clk_count = "0" then
                s_even_sawtooth <= not s_even_sawtooth;

                s_dc_count <= unsigned(offset_i);

                if s_even_sawtooth = '1' then
                    -- count every second one to have same frequency as others
                    -- but reset immediately if exceeding maximum
                    s_sawtooth_count <= s_sawtooth_count + 1;
                end if;
                if s_sawtooth_count >= s_high_level then
                    s_sawtooth_count <= s_low_level;
                end if;

                if s_triangle_dir = '1' then
                    s_triangle_count <= s_triangle_count + 1;
                    if s_triangle_count >= s_high_level then
                        s_triangle_count <= s_triangle_count - 1;
                        s_triangle_dir <= '0';
                    end if;

                    s_square_count <= s_high_level;
                else
                    s_triangle_count <= s_triangle_count - 1;
                    if s_triangle_count <= s_low_level then
                        s_triangle_count <= s_triangle_count + 1;
                        s_triangle_dir <= '1';
                    end if;

                    s_square_count <= s_low_level;
                end if;

            end if;

        end if;
    end process;

    -- Amplitude is saturated to 7 (max) divides by 2 for each step smaller than 7,
    -- hence, 6 divides by 2**1, 5 divides by 2**2, etc.
    -- If we should need finer granularity, we could add more summands of that kind
    -- and possibly define additional bit fields in amplitude for that purpose.
    p_sine : process (clk_i, reset_i)
    begin
        if reset_i = '1' then
            s_sine               <= (others => '0');
            s_sine_lut           <= (others => '0');
            s_sine_unsat         <= (others => '0');
            s_sine_index         <= (others => '0');
            s_sine_div           <= 0;
        elsif rising_edge(clk_i) then

            s_sine_lut   <= to_signed(C_SINE_ARRAY(to_integer(s_sine_index)), s_sine_lut'length);

            if unsigned(amplitude_i) > to_unsigned(7, amplitude_i'length) then
                s_sine_div   <= 0;
            else
                s_sine_div   <= 7 - to_integer(unsigned(amplitude_i));
            end if;

            s_sine_unsat <= resize(signed('0' & offset_i),                          s_sine_unsat'length)
                          + resize(s_sine_lut(7) & s_sine_lut(7 downto s_sine_div), s_sine_unsat'length);
            
            if s_sine_unsat(9) = '1' then
                -- underflow
                s_sine <= (others => '0');
            elsif s_sine_unsat(8) = '1' then
                -- overflow
                s_sine <= (others => '1');
            else
                -- in range
                s_sine <= unsigned(s_sine_unsat(7 downto 0));
            end if;
            s_sine_index <= s_sine_index + 1;
        end if;
    end process;

    dc_o               <= std_logic_vector(s_dc_count);
    sawtooth_o         <= std_logic_vector(s_sawtooth_count);
    triangle_o         <= std_logic_vector(s_triangle_count);
    square_o           <= std_logic_vector(s_square_count);
    sine_o             <= std_logic_vector(s_sine);
    
end behavioral;
