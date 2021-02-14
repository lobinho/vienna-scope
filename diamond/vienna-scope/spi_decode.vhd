library ieee;
use ieee.std_logic_1164.all;

use ieee.std_logic_misc.all;
use ieee.std_logic_signed.all;
use ieee.numeric_std.all;

use work.vienna_scope_pkg.all;

entity spi_decode is
port (
    clk_i             : in  std_logic;
    reset_i           : in  std_logic;
    data_rx_i         : in  std_logic_vector(7 downto 0);
    data_rx_strobe_i  : in  std_logic;
    
    address_o         : out std_logic_vector(7 downto 0);
    write_data_o      : out std_logic_vector(7 downto 0);
    read_strobe_o     : out std_logic;
    write_strobe_o    : out std_logic;
    state_o           : out com_state_t
);
end spi_decode;

architecture behavioral of spi_decode is
    constant C_STROBE_STRETCH   : integer := 1;
    signal s_com_state          : com_state_t;
    signal s_address            : std_logic_vector(7 downto 0);
    signal s_write_data         : std_logic_vector(7 downto 0);
    signal s_read_strobe        : std_logic;
    signal s_write_strobe       : std_logic;
    signal s_read_strobe_cnt    : integer range 0 to 3;
    signal s_write_strobe_cnt   : integer range 0 to 3;

begin
    -- we don't need to register inputs data_rx_i and data_rx_strobe_i, they already come from another register

    p_com_fsm : process (clk_i, reset_i)
    begin
        if reset_i = '1' then
            s_com_state         <= WAIT_FOR_CMD;
            s_address           <= (others => '0');
            s_write_data        <= (others => '0');
            s_read_strobe       <= '0';
            s_write_strobe      <= '0';
            s_read_strobe_cnt   <= 0;
            s_write_strobe_cnt  <= 0;
        elsif rising_edge(clk_i) then

            s_read_strobe  <= '0';
            s_write_strobe <= '0';
            if s_read_strobe_cnt > 0 then
                s_read_strobe_cnt <= s_read_strobe_cnt - 1;
            end if;
            if s_write_strobe_cnt > 0 then
                s_write_strobe_cnt <= s_write_strobe_cnt - 1;
            end if;
            if data_rx_strobe_i = '1' then
                case s_com_state is
                    when WAIT_FOR_CMD =>
                        if    data_rx_i = C_SPI_CMD_RD then s_com_state <= WAIT_FOR_ADDR_RD;
                        elsif data_rx_i = C_SPI_CMD_WR then s_com_state <= WAIT_FOR_ADDR_WR;
                        end if;
                        -- possibly we need to introduce a ignore-state when writing to 3-wire SPI of LMH6518
                        -- which always sends 2 bytes, first read/write, second data. In that case we would need
                        -- to ensure that second byte could not be interpreted as command in case both CS signals
                        -- come the same time. If this was possible, one could send adc data to RPi while changing
                        -- LMH6518 config. Only SDIO (MOSI - slave in) is shared.

                    when WAIT_FOR_ADDR_RD =>
                        -- after providing read back address we need to ignore the next byte that is clocked by the master
                        -- to read the data of desired address
                        s_address          <= data_rx_i;
                        s_write_data       <= (others => '0');
                        s_com_state        <= WAIT_FOR_DATA_RD;
                        s_read_strobe      <= '1';
                        s_read_strobe_cnt  <= C_STROBE_STRETCH;

                    when WAIT_FOR_DATA_RD =>
                        -- ignore slave in while slave out is clocked
                        s_com_state        <= WAIT_FOR_CMD;

                    when WAIT_FOR_ADDR_WR =>
                        s_address          <= data_rx_i;
                        s_com_state        <= WAIT_FOR_DATA_WR;

                    when WAIT_FOR_DATA_WR =>
                        s_write_data       <= data_rx_i;
                        s_com_state        <= WAIT_FOR_CMD;
                        s_write_strobe     <= '1';
                        s_write_strobe_cnt <= C_STROBE_STRETCH;

                    when others =>
                        s_com_state <= WAIT_FOR_CMD;

                end case;
            end if;
        end if;
    end process;
    address_o         <= s_address;
    write_data_o      <= s_write_data;
    read_strobe_o     <= '1' when s_read_strobe_cnt  > 0 else '0';
    write_strobe_o    <= '1' when s_write_strobe_cnt > 0 else '0';
    state_o           <= s_com_state;

end behavioral;
