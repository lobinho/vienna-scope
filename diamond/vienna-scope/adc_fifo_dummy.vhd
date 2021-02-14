-- This architecture does nothing.
-- It is intended only for simulation to use e.g. Vivado simulator with Lattice IPs.
-- Do not use for synthesis in Diamond!

library ieee;
use ieee.std_logic_1164.all;
 
entity adc_fifo is
    port (
        Data: in  std_logic_vector(31 downto 0); 
        WrClock: in  std_logic;
        RdClock: in  std_logic; 
        WrEn: in  std_logic;
        RdEn: in  std_logic;
        Reset: in  std_logic; 
        RPReset: in  std_logic;
        Q: out  std_logic_vector(31 downto 0); 
        Empty: out  std_logic;
        Full: out  std_logic; 
        AlmostEmpty: out  std_logic;
        AlmostFull: out  std_logic
    );
end adc_fifo;
 
architecture adc_fifo_dummy_arch of adc_fifo is
begin
    Q            <= (others => '0');
    Empty        <= '0';
    Full         <= '0';
    AlmostEmpty  <= '0';
    AlmostFull   <= '0';
end adc_fifo_dummy_arch;
