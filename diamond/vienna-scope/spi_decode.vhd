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
    write_strobe_o    : out std_logic
);
end spi_decode;

architecture behavioral of spi_decode is
    signal s_com_state          : com_state_t;
    signal s_data_rx            : std_logic_vector(7 downto 0);
    signal s_data_rx_strobe     : std_logic;
    signal s_address            : std_logic_vector(7 downto 0);
    signal s_write_data         : std_logic_vector(7 downto 0);
    signal s_read_strobe        : std_logic;
    signal s_write_strobe       : std_logic;

begin
    p_register : process (clk_i, reset_i)
    begin
        if reset_i = '1' then
            s_data_rx           <= (others => '0');
            s_data_rx_strobe    <= '0';
        elsif rising_edge(clk_i) then
            s_data_rx           <= data_rx_i;
            s_data_rx_strobe    <= data_rx_strobe_i;
        end if;
    end process;

    p_com_fsm : process (clk_i, reset_i)
    begin
        if reset_i = '1' then
            s_com_state         <= WAIT_FOR_CMD;
            s_address           <= (others => '0');
            s_write_data        <= (others => '0');
            s_read_strobe       <= '0';
            s_write_strobe      <= '0';
        elsif rising_edge(clk_i) then

            s_read_strobe  <= '0';
            s_write_strobe <= '0';
            if s_data_rx_strobe = '1' then
                case s_com_state is
                    when WAIT_FOR_CMD =>
                        if    s_data_rx = C_SPI_CMD_RD then s_com_state <= WAIT_FOR_ADDR_RD;
                        elsif s_data_rx = C_SPI_CMD_WR then s_com_state <= WAIT_FOR_ADDR_WR;
                        end if;
                        -- possibly we need to introduce a ignore-state when writing to 3-wire SPI of LMH6518
                        -- which always sends 2 bytes, first read/write, second data. In that case we would need
                        -- to ensure that second byte could not be interpreted as command in case both CS signals
                        -- come the same time. If this was possible, one could send adc data to RPi while changing
                        -- LMH6518 config. Only SDIO (MOSI - slave in) is shared.

                    when WAIT_FOR_ADDR_RD =>
                        s_address      <= s_data_rx;
                        s_write_data   <= (others => '0');
                        s_com_state    <= WAIT_FOR_CMD;
                        s_read_strobe  <= '1';

                    when WAIT_FOR_ADDR_WR =>
                        s_address      <= s_data_rx;
                        s_com_state    <= WAIT_FOR_DATA_WR;

                    when WAIT_FOR_DATA_WR =>
                        s_write_data   <= s_data_rx;
                        s_com_state    <= WAIT_FOR_CMD;
                        s_write_strobe <= '1';
                    
                    when others =>
                        s_com_state <= WAIT_FOR_CMD;

                end case;
            end if;
        end if;
    end process;
    address_o         <= s_address;
    write_data_o      <= s_write_data;
    read_strobe_o     <= s_read_strobe;
    write_strobe_o    <= s_write_strobe;

end behavioral;
