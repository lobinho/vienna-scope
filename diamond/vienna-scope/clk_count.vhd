library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_signed.all;
use ieee.numeric_std.all;

entity clk_count is
port (
    clk_i       : in  std_logic;
    reset_i     : in  std_logic;
    enable_i    : in  std_logic;
    count_o     : out std_logic_vector(31 downto 0)
);
end clk_count;

architecture behavioral of clk_count is
    signal s_counter           : unsigned(31 downto 0);
begin
    process (clk_i, reset_i)
    begin
        if reset_i = '1' then
            s_counter   <= (others => '0');
        elsif rising_edge(clk_i) then
            if enable_i = '1' then
                s_counter <= s_counter + 1;
            end if;
        end if;
    end process;
    count_o <= std_logic_vector(s_counter);
end behavioral;
