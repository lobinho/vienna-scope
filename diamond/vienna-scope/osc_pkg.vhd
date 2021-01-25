library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;

package osc_pkg is
     COMPONENT OSCH
          -- synthesis translate_off
          GENERIC (
               NOM_FREQ    : string := "53.20"
          );
          -- synthesis translate_on
          PORT (
               STDBY       : IN  std_logic;
               OSC         : OUT std_logic;
               SEDSTDBY    : OUT  std_logic
          );
     END COMPONENT;

end package osc_pkg;
