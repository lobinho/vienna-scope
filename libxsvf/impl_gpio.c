#include "libxsvf.h"
#include <bcm2835.h>
#include <sys/time.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>


/** BEGIN: Low-Level I/O Implementation **/

/* 	Configure Lattice MachXO2 via JTAG using RPi GPIOs only.
GPIO_04 -> Pin07 -> TMS
GPIO_14 -> Pin08 -> TCK
GPIO_15 -> Pin10 -> TDI
GPIO_18 -> Pin12 -> TDO
*/
#define TMS RPI_BPLUS_GPIO_J8_07
#define TCK RPI_BPLUS_GPIO_J8_08
#define TDI RPI_BPLUS_GPIO_J8_10
#define TDO RPI_BPLUS_GPIO_J8_12

void io_setup(void)
{
	if(!bcm2835_init()) {
		fprintf(stderr, "io_setup: bcm283_init failed\n");
		exit(1);
	}
	bcm2835_gpio_fsel(TCK, BCM2835_GPIO_FSEL_OUTP);
	bcm2835_gpio_fsel(TMS, BCM2835_GPIO_FSEL_OUTP);
	bcm2835_gpio_fsel(TDI, BCM2835_GPIO_FSEL_OUTP);
	bcm2835_gpio_fsel(TDO, BCM2835_GPIO_FSEL_INPT);
}

void io_shutdown(void)
{
	bcm2835_gpio_fsel(TCK, BCM2835_GPIO_FSEL_INPT);
	bcm2835_gpio_fsel(TMS, BCM2835_GPIO_FSEL_INPT);
	bcm2835_gpio_fsel(TDI, BCM2835_GPIO_FSEL_INPT);
	bcm2835_gpio_fsel(TDO, BCM2835_GPIO_FSEL_INPT);
}

void io_tms(int val)
{
	bcm2835_gpio_write(TMS, val ? HIGH : LOW);
}

void io_tdi(int val)
{
	bcm2835_gpio_write(TDI, val ? HIGH : LOW);
}

void io_tck(int val)
{
	bcm2835_gpio_write(TCK, val ? HIGH : LOW);
}

void io_sck(int val)
{
}

void io_trst(int val)
{
}

int io_tdo()
{
	return bcm2835_gpio_lev(TDO);
}


/** END: Low-Level I/O Implementation **/
