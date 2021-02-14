library ieee;
use ieee.std_logic_1164.all;

use ieee.std_logic_misc.all;
use ieee.std_logic_signed.all;
use ieee.numeric_std.all;

use work.vienna_scope_pkg.all;

entity spi_slave is
generic(
    G_MISO_WIDTH    : integer := 1
);
port (
    clk_i           : in  std_logic;
    reset_i         : in  std_logic;
    -------------
    sck_i           : in  std_logic;
    csn_i           : in  std_logic;   -- low active
    mosi_i          : in  std_logic;
    miso_o          : out std_logic_vector(G_MISO_WIDTH-1 downto 0);
    -------------
    data_tx_valid_i : in  std_logic;
    data_tx_i       : in  slv8_array_t(0 to G_MISO_WIDTH-1);
    loopback_i      : in  std_logic;
    data_rx_o       : out std_logic_vector(7 downto 0);
    data_rx_valid_o : out std_logic;
    busy_o          : out std_logic;
    com_error_o     : out std_logic
);
end spi_slave;

architecture behavioral of spi_slave is
    -- constant C_COM_TIMEOUT      : unsigned(15 downto 0) :=  X"03E7";
    constant C_COM_TIMEOUT      : unsigned(15 downto 0) :=  X"FFFF";
    signal s_count_sck          : unsigned(2  downto 0);
    signal s_count_sck_z        : unsigned(2  downto 0);
    signal s_count_timeout      : unsigned(15 downto 0);
    signal s_sck                : std_logic;
    signal s_csn                : std_logic;
    signal s_mosi               : std_logic;
    signal s_miso               : std_logic_vector(G_MISO_WIDTH-1 downto 0);
    signal s_sck_z              : std_logic;
    signal s_sck_redg           : std_logic;

    signal s_data_rx_valid      : std_logic;
    signal s_data_rx            : std_logic_vector(7 downto 0);
    signal s_shift_in           : std_logic_vector(7 downto 0);
    signal s_shift_out          : slv8_array_t(0 to G_MISO_WIDTH-1);
    signal s_shift_out_queue    : slv8_array_t(0 to G_MISO_WIDTH-1);
begin
    p_register : process (clk_i, reset_i)
    begin
        if reset_i = '1' then
            s_sck               <= '0';
            s_csn               <= '0';
            s_mosi              <= '0';
            s_sck_z             <= '0';
        elsif rising_edge(clk_i) then
            s_sck               <= sck_i;
            s_csn               <= csn_i;
            s_mosi              <= mosi_i;
            s_sck_z             <= s_sck;
        end if;
    end process;
    s_sck_redg <= s_sck and not s_sck_z;

    p_sck_count : process (clk_i, reset_i)
    begin
        if reset_i = '1' then
            s_count_sck        <= (others => '0');
            s_count_sck_z      <= (others => '0');
            s_count_timeout    <= (others => '0');
        elsif rising_edge(clk_i) then
            if (s_sck_redg = '1' and s_csn = '0') then
                s_count_sck <= s_count_sck + 1;
                s_count_timeout   <= (others => '0');
            end if;
            s_count_sck_z <= s_count_sck;
            if s_count_sck /= "0" then
                -- temp. disable: s_count_timeout <= s_count_timeout + 1;
                if s_count_timeout >= C_COM_TIMEOUT then
                    -- reset on timeout
                    s_count_sck <= (others => '0');
                end if;
            end if;
        end if;
    end process;

    p_shift_in : process (clk_i, reset_i)
    begin
        if reset_i = '1' then
            s_data_rx  <= (others => '0');
            s_shift_in <= (others => '0');
        elsif rising_edge(clk_i) then
            s_data_rx_valid <= '0';
            if s_count_sck = "000" and s_count_sck_z = "111" then
                s_data_rx_valid <= '1';
                s_data_rx       <= s_shift_in;
            elsif (s_sck_redg = '1' and s_csn = '0') then
                s_shift_in <= s_shift_in(6 downto 0) & s_mosi;
            end if;
        end if;
    end process;
    data_rx_o       <= s_data_rx;
    data_rx_valid_o <= s_data_rx_valid;

    p_shift_out : process (clk_i, reset_i)
    begin
        if reset_i = '1' then
            for i in 0 to G_MISO_WIDTH-1 loop
                s_shift_out(i)       <= (others => '0');
                s_shift_out_queue(i) <= (others => '0');
            end loop;
            s_miso                   <= (others => 'Z');
        elsif rising_edge(clk_i) then
            for i in 0 to G_MISO_WIDTH-1 loop
                if data_tx_valid_i = '1' then
                    s_shift_out_queue(i) <= data_tx_i(i);
                end if;
                if (s_sck_redg = '1' and s_csn = '0') then
                    s_shift_out(i) <= s_shift_out(i)(6 downto 0) & '0';
                elsif s_count_sck = "000" then
                    s_shift_out(i) <= s_shift_out_queue(i);
                end if;
                s_miso(i) <= s_shift_out(i)(7);
            end loop;
            if loopback_i = '1' then
                s_miso(0) <= s_mosi;
            end if;
        end if;
    end process;
    miso_o      <= s_miso when s_csn = '0' else (others => 'Z');
    busy_o      <= '0' when s_count_sck = "000" else '1';
    com_error_o <= '1' when s_count_timeout >= C_COM_TIMEOUT else '0';

end behavioral;
