-- Arbitrary Waveform generator test bench
-- 2021-01-22, wf


library ieee;
use ieee.std_logic_1164.all;

entity awg_tb is
end awg_tb;

architecture behavioral of awg_tb is
    --- inputs
    signal s_clk        : std_logic := '0';
    signal s_reset      : std_logic;
    signal s_amplitude  : std_logic_vector(7  downto 0);
    signal s_offset     : std_logic_vector(7  downto 0);
    signal s_period     : std_logic_vector(23 downto 0) := X"000001";

    --- outputs
    signal s_dc         : std_logic_vector(7 downto 0);
    signal s_sawtooth   : std_logic_vector(7 downto 0);
    signal s_triangle   : std_logic_vector(7 downto 0);
    signal s_square     : std_logic_vector(7 downto 0);
    signal s_sine       : std_logic_vector(7 downto 0);

begin
    s_clk   <= not s_clk  after 5 ns;  -- 100 MHz clock
    s_reset <= '1',
               '0' after 10 ns;

    s_amplitude     <= X"FF",
                       X"7F" after 2400 us,
                       X"20" after 2440 us,
                       X"06" after 2660 us,
                       X"04" after 2680 us,
                       X"02" after 2700 us,
                       X"01" after 2740 us,
                       X"05" after 2760 us;
    s_offset        <= X"00",
                       X"7F" after 2480 us,
                       X"40" after 2520 us,
                       X"F0" after 2560 us,
                       X"A0" after 2640 us,
                       X"60" after 2780 us;

    p_stimulus : process
    begin
        wait for 200 us;
        s_period    <= X"000" & s_period(10 downto 0) & s_period(11);
        -- s_period    <= s_period(22 downto 0) & s_period(23);
    end process p_stimulus;

    i_dut : entity work.awg
        port map (
            clk_i               => s_clk,
            reset_i             => s_reset,
            amplitude_i         => s_amplitude,
            offset_i            => s_offset,
            period_i            => s_period,
            dc_o                => s_dc,
            sawtooth_o          => s_sawtooth,
            triangle_o          => s_triangle,
            square_o            => s_square,
            sine_o              => s_sine
    );

end behavioral;
