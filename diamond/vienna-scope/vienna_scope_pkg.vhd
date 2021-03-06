library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

package vienna_scope_pkg is

     constant C_SPI_CMD_RD       : std_logic_vector(7 downto 0) := X"01";
     constant C_SPI_CMD_WR       : std_logic_vector(7 downto 0) := X"02";

     type com_state_t        is (WAIT_FOR_CMD, WAIT_FOR_ADDR_RD, WAIT_FOR_ADDR_WR, WAIT_FOR_DATA_RD, WAIT_FOR_DATA_WR);
     type fifo_rd_state_t    is (DIRECT_READ_RQ, WAIT_FOR_FIFO_0, WAIT_FOR_FIFO_1);
     type slv8_array_t       is array (natural range <>) of std_logic_vector(7 downto 0);
     type unsigned8_array_t  is array (natural range <>) of unsigned(7 downto 0);

     type sine_array_t       is array (0 to 255) of integer range -128 to 127;
     constant C_SINE_ARRAY : sine_array_t := 
        (0, 3, 6, 9, 13, 16, 19, 22, 25, 28, 31, 34, 37, 40, 43, 46, 49, 52, 55, 58, 60, 63, 66, 68, 71, 74, 76, 79, 81, 84, 86, 88, 90, 93, 95, 97, 99, 101, 103, 105, 106, 108, 110, 111, 113, 114, 115, 117, 118, 119, 120, 121, 122, 123, 124, 125, 125, 126, 126, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 126, 126, 125, 125, 124, 123, 123, 122, 121, 120, 119, 117, 116, 115, 113, 112, 110, 109, 107, 105, 104, 102, 100, 98, 96, 94, 92, 89, 87, 85, 82, 80, 77, 75, 72, 70, 67, 64, 62, 59, 56, 53, 50, 48, 45, 42, 39, 36, 33, 30, 27, 23, 20, 17, 14, 11, 8, 5, 2, -2, -5, -8, -11, -14, -17, -20, -23, -27, -30, -33, -36, -39, -42, -45, -48, -50, -53, -56, -59, -62, -64, -67, -70, -72, -75, -77, -80, -82, -85, -87, -89, -92, -94, -96, -98, -100, -102, -104, -105, -107, -109, -110, -112, -113, -115, -116, -117, -119, -120, -121, -122, -123, -123, -124, -125, -125, -126, -126, -127, -127, -127, -127, -127, -127, -127, -127, -127, -127, -126, -126, -125, -125, -124, -123, -122, -121, -120, -119, -118, -117, -115, -114, -113, -111, -110, -108, -106, -105, -103, -101, -99, -97, -95, -93, -90, -88, -86, -84, -81, -79, -76, -74, -71, -68, -66, -63, -60, -58, -55, -52, -49, -46, -43, -40, -37, -34, -31, -28, -25, -22, -19, -16, -13, -9, -6, -3, 0);

end package vienna_scope_pkg;
