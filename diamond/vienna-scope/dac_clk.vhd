library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_signed.all;
use ieee.numeric_std.all;

entity dac_clk is
port (
    clk_i        : in  std_logic;
    reset_i      : in  std_logic;
    clk_div_i    : in  std_logic_vector(3 downto 0);
    dac_clkp_o   : out std_logic;
    dac_clkn_o   : out std_logic
    );
end dac_clk;

architecture behavioral of dac_clk is
    signal s_clk_count     : unsigned(23 downto 0);
begin
    p_diff_clk : process (clk_i, reset_i)
    begin
        if reset_i = '1' then
            s_clk_count     <= (others => '0');
        elsif rising_edge(clk_i) then
            s_clk_count <= s_clk_count + 1;
        end if;
    end process;

    -- DAC output clock is differential and divids input clock by 64 or 2**6: s_clk_count(6)
    -- index -> clk_div_i
    dac_clkp_o    <= s_clk_count(6);
    dac_clkn_o    <= not s_clk_count(6);
    
end behavioral;