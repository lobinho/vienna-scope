# Vienna Scope

## PCB design
https://workspace.circuitmaker.com/Projects/Details/lobo/Vienna-Scope

## GPIOs
https://pinout.xyz/pinout/spi

work in progress:
           pin  pin
3V3         1    2      5V
0/2 (SDA)   3    4      5V
1/3 (SCL)   5    6      0V
4           7    8      14 (TXD)
0V          9   10      15 (RXD)
17 (ce1)   11   12      18 (ce0)
21/27      13   14      0V
22         15   16      23
3V3        17   18      24
10 (MOSI)  19   20      0V
9 (MISO)   21   22      25
11 (SCLK)  23   24      8 (CE0)
0V         25   26      7 (CE1)
           .......
0 (ID_SD)  27   28      1 (ID_SC)
5          29   30      0V
6          31   32      12
13         33   34      0V
19 (miso)  35   36      16 (ce2)
26         37   38      20 (mosi)
0V         39   40      21 (sclk)

### SPI

MachXO2 - RPi connection using (Q)SPI:
Single MISO line:
miso: 125  ---  SPI.MISO0:   SPI_MISO0 = GPIO09
sck:  126  ---  SPI.SCLK_M:  SPI_SCLK  = GPIO11
csn:  140  ---  SPI.CS2:                 GPIO25
mosi: 139  ---  SPI.SDIO:    SPI_MOMI  = GPIO10


https://raw.githubusercontent.com/raspberrypi/firmware/master/boot/overlays/README
For dtparam, we use standard pins of RPi for clock and data and custom CS
which should be possible, see
    /boot/overlays/README
    dtoverlay -h spi0-1cs
Hence we go with /boot/config.txt:
dtparam=i2c_arm=on,i2c_arm_baudrate=100000
dtparam=spi=on
dtoverlay=spi0-1cs,cs0_pin=25

## Build Lattice project - bin - svg:
This requires diamond being available.
Run diamond in batch mode
```bash
diamond -t vienna_scope/build_svg.tcl
```
or start the GUI and run the tcl-script in the diamond tcl console:
```bash
source build_svg.tcl
```
to generate the bitstream and convert it to serial vector format (svf).

In case you run in a container, the latter option is clearly more convenient.

## Configure FPGA
Make sure the RPi GPIOs are connceted to the MachXO2 JTAG pins and play the svf file using this script
```bash
play_svg.sh
```
using libxsvf.

In future, possibly another implementation using the I2C GPIO expander may be added. However, this is not yet fully working and not 100% clear whether it is a reasonable alternative at all. 
## Restore SPI
Currently, RPi configures the LMH6518 devices via bidirectional SPI on startup. This makes use of one shared GPIO (SDIO) that is also used for SPI communication with MachXO2.
Run this script to reload the SPI driver:
```bash
reset_spi_driver.sh
```

## Simulation
Unfortunately, Diamond does not come with a simulator on Linux. However, all the provided testbenches can be used with the free Webpack version of Xilinx Vivado (e.g. Vivado 2019.1 on Linux). Each testbench comes with a default waveform configuration file that is used loaded after running the simulation.

For top module, the internal signal s_clk_sys is generated with the OSCH module. For simulation, this signal shall be forced to produce the desired clock. To this end, use the following tcl-script from diamond/vivado_sim from the tcl console after starting the simulation:
```bash
source load_top_tb.tcl
```
