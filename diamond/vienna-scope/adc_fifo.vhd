-- VHDL netlist generated by SCUBA Diamond (64-bit) 3.12.0.240.2
-- Module  Version: 5.8
--/usr/local/diamond/3.12/ispfpga/bin/lin64/scuba -w -n adc_fifo -lang vhdl -synth lse -bus_exp 7 -bb -arch xo2c00 -type ebfifo -depth 1024 -width 32 -rwidth 32 -no_enable -pe 10 -pf 1022 

-- Tue Feb  9 20:16:59 2021

library IEEE;
use IEEE.std_logic_1164.all;
-- synopsys translate_off
library MACHXO2;
use MACHXO2.components.all;
-- synopsys translate_on

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
        AlmostFull: out  std_logic);
end adc_fifo;

architecture Structure of adc_fifo is

    -- internal signal declarations
    signal scuba_vhi: std_logic;
    signal Empty_int: std_logic;
    signal Full_int: std_logic;
    signal scuba_vlo: std_logic;

    -- local component declarations
    component VHI
        port (Z: out  std_logic);
    end component;
    component VLO
        port (Z: out  std_logic);
    end component;
    component FIFO8KB
        generic (FULLPOINTER1 : in String; FULLPOINTER : in String; 
                AFPOINTER1 : in String; AFPOINTER : in String; 
                AEPOINTER1 : in String; AEPOINTER : in String; 
                ASYNC_RESET_RELEASE : in String; RESETMODE : in String; 
                GSR : in String; CSDECODE_R : in String; 
                CSDECODE_W : in String; REGMODE : in String; 
                DATA_WIDTH_R : in Integer; DATA_WIDTH_W : in Integer);
        port (DI0: in  std_logic; DI1: in  std_logic; DI2: in  std_logic; 
            DI3: in  std_logic; DI4: in  std_logic; DI5: in  std_logic; 
            DI6: in  std_logic; DI7: in  std_logic; DI8: in  std_logic; 
            DI9: in  std_logic; DI10: in  std_logic; DI11: in  std_logic; 
            DI12: in  std_logic; DI13: in  std_logic; 
            DI14: in  std_logic; DI15: in  std_logic; 
            DI16: in  std_logic; DI17: in  std_logic; 
            CSW0: in  std_logic; CSW1: in  std_logic; 
            CSR0: in  std_logic; CSR1: in  std_logic; 
            FULLI: in  std_logic; EMPTYI: in  std_logic; 
            WE: in  std_logic; RE: in  std_logic; ORE: in  std_logic; 
            CLKW: in  std_logic; CLKR: in  std_logic; RST: in  std_logic; 
            RPRST: in  std_logic; DO0: out  std_logic; 
            DO1: out  std_logic; DO2: out  std_logic; 
            DO3: out  std_logic; DO4: out  std_logic; 
            DO5: out  std_logic; DO6: out  std_logic; 
            DO7: out  std_logic; DO8: out  std_logic; 
            DO9: out  std_logic; DO10: out  std_logic; 
            DO11: out  std_logic; DO12: out  std_logic; 
            DO13: out  std_logic; DO14: out  std_logic; 
            DO15: out  std_logic; DO16: out  std_logic; 
            DO17: out  std_logic; EF: out  std_logic; 
            AEF: out  std_logic; AFF: out  std_logic; FF: out  std_logic);
    end component;
    attribute syn_keep : boolean;
    attribute NGD_DRC_MASK : integer;
    attribute NGD_DRC_MASK of Structure : architecture is 1;

begin
    -- component instantiation statements
    adc_fifo_0_3: FIFO8KB
        generic map (FULLPOINTER1=> "0b01111111111000", FULLPOINTER=> "0b10000000000000", 
        AFPOINTER1=> "0b01111111101000", AFPOINTER=> "0b01111111110000", 
        AEPOINTER1=> "0b00000001011000", AEPOINTER=> "0b00000001010000", 
        ASYNC_RESET_RELEASE=> "SYNC", GSR=> "DISABLED", RESETMODE=> "ASYNC", 
        REGMODE=> "NOREG", CSDECODE_R=> "0b11", CSDECODE_W=> "0b11", 
        DATA_WIDTH_R=>  9, DATA_WIDTH_W=>  9)
        port map (DI0=>Data(0), DI1=>Data(1), DI2=>Data(2), DI3=>Data(3), 
            DI4=>Data(4), DI5=>Data(5), DI6=>Data(6), DI7=>Data(7), 
            DI8=>Data(8), DI9=>scuba_vlo, DI10=>scuba_vlo, 
            DI11=>scuba_vlo, DI12=>scuba_vlo, DI13=>scuba_vlo, 
            DI14=>scuba_vlo, DI15=>scuba_vlo, DI16=>scuba_vlo, 
            DI17=>scuba_vlo, CSW0=>scuba_vhi, CSW1=>scuba_vhi, 
            CSR0=>scuba_vhi, CSR1=>scuba_vhi, FULLI=>Full_int, 
            EMPTYI=>Empty_int, WE=>WrEn, RE=>RdEn, ORE=>RdEn, 
            CLKW=>WrClock, CLKR=>RdClock, RST=>Reset, RPRST=>RPReset, 
            DO0=>Q(0), DO1=>Q(1), DO2=>Q(2), DO3=>Q(3), DO4=>Q(4), 
            DO5=>Q(5), DO6=>Q(6), DO7=>Q(7), DO8=>Q(8), DO9=>open, 
            DO10=>open, DO11=>open, DO12=>open, DO13=>open, DO14=>open, 
            DO15=>open, DO16=>open, DO17=>open, EF=>Empty_int, 
            AEF=>AlmostEmpty, AFF=>AlmostFull, FF=>Full_int);

    adc_fifo_1_2: FIFO8KB
        generic map (FULLPOINTER1=> "0b00000000000000", FULLPOINTER=> "0b11111111111000", 
        AFPOINTER1=> "0b00000000000000", AFPOINTER=> "0b11111111111000", 
        AEPOINTER1=> "0b00000000000000", AEPOINTER=> "0b11111111111000", 
        ASYNC_RESET_RELEASE=> "SYNC", GSR=> "DISABLED", RESETMODE=> "ASYNC", 
        REGMODE=> "NOREG", CSDECODE_R=> "0b11", CSDECODE_W=> "0b11", 
        DATA_WIDTH_R=>  9, DATA_WIDTH_W=>  9)
        port map (DI0=>Data(9), DI1=>Data(10), DI2=>Data(11), 
            DI3=>Data(12), DI4=>Data(13), DI5=>Data(14), DI6=>Data(15), 
            DI7=>Data(16), DI8=>Data(17), DI9=>scuba_vlo, 
            DI10=>scuba_vlo, DI11=>scuba_vlo, DI12=>scuba_vlo, 
            DI13=>scuba_vlo, DI14=>scuba_vlo, DI15=>scuba_vlo, 
            DI16=>scuba_vlo, DI17=>scuba_vlo, CSW0=>scuba_vhi, 
            CSW1=>scuba_vhi, CSR0=>scuba_vhi, CSR1=>scuba_vhi, 
            FULLI=>Full_int, EMPTYI=>Empty_int, WE=>WrEn, RE=>RdEn, 
            ORE=>RdEn, CLKW=>WrClock, CLKR=>RdClock, RST=>Reset, 
            RPRST=>RPReset, DO0=>Q(9), DO1=>Q(10), DO2=>Q(11), 
            DO3=>Q(12), DO4=>Q(13), DO5=>Q(14), DO6=>Q(15), DO7=>Q(16), 
            DO8=>Q(17), DO9=>open, DO10=>open, DO11=>open, DO12=>open, 
            DO13=>open, DO14=>open, DO15=>open, DO16=>open, DO17=>open, 
            EF=>open, AEF=>open, AFF=>open, FF=>open);

    adc_fifo_2_1: FIFO8KB
        generic map (FULLPOINTER1=> "0b00000000000000", FULLPOINTER=> "0b11111111111000", 
        AFPOINTER1=> "0b00000000000000", AFPOINTER=> "0b11111111111000", 
        AEPOINTER1=> "0b00000000000000", AEPOINTER=> "0b11111111111000", 
        ASYNC_RESET_RELEASE=> "SYNC", GSR=> "DISABLED", RESETMODE=> "ASYNC", 
        REGMODE=> "NOREG", CSDECODE_R=> "0b11", CSDECODE_W=> "0b11", 
        DATA_WIDTH_R=>  9, DATA_WIDTH_W=>  9)
        port map (DI0=>Data(18), DI1=>Data(19), DI2=>Data(20), 
            DI3=>Data(21), DI4=>Data(22), DI5=>Data(23), DI6=>Data(24), 
            DI7=>Data(25), DI8=>Data(26), DI9=>scuba_vlo, 
            DI10=>scuba_vlo, DI11=>scuba_vlo, DI12=>scuba_vlo, 
            DI13=>scuba_vlo, DI14=>scuba_vlo, DI15=>scuba_vlo, 
            DI16=>scuba_vlo, DI17=>scuba_vlo, CSW0=>scuba_vhi, 
            CSW1=>scuba_vhi, CSR0=>scuba_vhi, CSR1=>scuba_vhi, 
            FULLI=>Full_int, EMPTYI=>Empty_int, WE=>WrEn, RE=>RdEn, 
            ORE=>RdEn, CLKW=>WrClock, CLKR=>RdClock, RST=>Reset, 
            RPRST=>RPReset, DO0=>Q(18), DO1=>Q(19), DO2=>Q(20), 
            DO3=>Q(21), DO4=>Q(22), DO5=>Q(23), DO6=>Q(24), DO7=>Q(25), 
            DO8=>Q(26), DO9=>open, DO10=>open, DO11=>open, DO12=>open, 
            DO13=>open, DO14=>open, DO15=>open, DO16=>open, DO17=>open, 
            EF=>open, AEF=>open, AFF=>open, FF=>open);

    scuba_vhi_inst: VHI
        port map (Z=>scuba_vhi);

    scuba_vlo_inst: VLO
        port map (Z=>scuba_vlo);

    adc_fifo_3_0: FIFO8KB
        generic map (FULLPOINTER1=> "0b00000000000000", FULLPOINTER=> "0b11111111111000", 
        AFPOINTER1=> "0b00000000000000", AFPOINTER=> "0b11111111111000", 
        AEPOINTER1=> "0b00000000000000", AEPOINTER=> "0b11111111111000", 
        ASYNC_RESET_RELEASE=> "SYNC", GSR=> "DISABLED", RESETMODE=> "ASYNC", 
        REGMODE=> "NOREG", CSDECODE_R=> "0b11", CSDECODE_W=> "0b11", 
        DATA_WIDTH_R=>  9, DATA_WIDTH_W=>  9)
        port map (DI0=>Data(27), DI1=>Data(28), DI2=>Data(29), 
            DI3=>Data(30), DI4=>Data(31), DI5=>scuba_vlo, DI6=>scuba_vlo, 
            DI7=>scuba_vlo, DI8=>scuba_vlo, DI9=>scuba_vlo, 
            DI10=>scuba_vlo, DI11=>scuba_vlo, DI12=>scuba_vlo, 
            DI13=>scuba_vlo, DI14=>scuba_vlo, DI15=>scuba_vlo, 
            DI16=>scuba_vlo, DI17=>scuba_vlo, CSW0=>scuba_vhi, 
            CSW1=>scuba_vhi, CSR0=>scuba_vhi, CSR1=>scuba_vhi, 
            FULLI=>Full_int, EMPTYI=>Empty_int, WE=>WrEn, RE=>RdEn, 
            ORE=>RdEn, CLKW=>WrClock, CLKR=>RdClock, RST=>Reset, 
            RPRST=>RPReset, DO0=>Q(27), DO1=>Q(28), DO2=>Q(29), 
            DO3=>Q(30), DO4=>Q(31), DO5=>open, DO6=>open, DO7=>open, 
            DO8=>open, DO9=>open, DO10=>open, DO11=>open, DO12=>open, 
            DO13=>open, DO14=>open, DO15=>open, DO16=>open, DO17=>open, 
            EF=>open, AEF=>open, AFF=>open, FF=>open);

    Empty <= Empty_int;
    Full <= Full_int;
end Structure;

-- synopsys translate_off
library MACHXO2;
configuration Structure_CON of adc_fifo is
    for Structure
        for all:VHI use entity MACHXO2.VHI(V); end for;
        for all:VLO use entity MACHXO2.VLO(V); end for;
        for all:FIFO8KB use entity MACHXO2.FIFO8KB(V); end for;
    end for;
end Structure_CON;

-- synopsys translate_on
