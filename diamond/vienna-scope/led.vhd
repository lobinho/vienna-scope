library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_signed.all;
use ieee.numeric_std.all;

entity led is
port (
    clk_i       : in  std_logic;
    reset_i     : in  std_logic;
    source_i    : in  std_logic;
    speed_i     : in  std_logic;
    led_o       : out std_logic
);
end led;

architecture behavioral of led is
    constant C_PERIOD_SLOW     : unsigned(31 downto 0) := X"032BC480";  -- 53200000
    constant C_PERIOD_FAST     : unsigned(31 downto 0) := X"00CAF120";  -- 13300000
    signal s_counter           : unsigned(31 downto 0) := X"00000000";
    signal s_led               : std_logic;
    signal s_period            : unsigned(31 downto 0);
    signal s_source            : std_logic;
    signal s_source_z          : std_logic;
    signal s_source_re         : std_logic;
begin
    process (clk_i, reset_i)
    begin
        if reset_i = '1' then
            s_counter   <= (others => '0');
            s_led       <= '0';
            s_period    <= C_PERIOD_SLOW - 1;
            s_source    <= '0';
            s_source_z  <= '0';
        elsif rising_edge(clk_i) then
            if speed_i = '0' then
                s_period <= C_PERIOD_SLOW - 1;
            else
                s_period <= C_PERIOD_FAST - 1;
            end if;
            if s_source_re = '1' then
                -- if s_counter >= s_period then
                --     s_counter <= (others => '0');
                     s_led <= not s_led;
                -- else
                --     s_counter <= s_counter + 1;
                -- end if;
            end if;
            s_source   <= source_i;
            s_source_z <= s_source;
        end if;
    end process;
    s_source_re <= not s_source_z and s_source;
    led_o       <= std_logic(s_led);
end behavioral;