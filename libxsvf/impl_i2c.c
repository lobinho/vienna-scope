#include "libxsvf.h"
#include <bcm2835.h>
#include "pca9555.h"
#include <sys/time.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>


char buffer[2];
/** BEGIN: Low-Level I/O Implementation **/
/* 	Configure Lattice MachXO2 via JTAG using PCA9555 GPIO expander connecting to RPi via I2C
*/

void io_setup(void)
{
	if(!bcm2835_init()) {
		fprintf(stderr, "io_setup: bcm283_init failed\n");
		exit(1);
	}
	fpga_ctrl initial, fpga_io;
	bcm2835_i2c_begin();
	bcm2835_i2c_setSlaveAddress(I2C_ADDRESS);
	bcm2835_i2c_set_baudrate(I2C_BAUDRATE);

	// Set outputs as they were initially - otherwise PCA9555 could crash
	buffer[0] = I2C_CMD_INPUT1;
	bcm2835_i2c_read_register_rs(buffer, &initial.byte, 1);
	printf("Initial FPGA port: 0x%x\n", initial.byte);

	buffer[0] = I2C_CMD_OUTPUT1;
	buffer[1] = initial.byte;
    bcm2835_i2c_write(buffer, 2);

	buffer[0] = I2C_CMD_CONFIG1;
	fpga_io.byte = 0xFF;
	fpga_io.fields.FTCK = 0;
	fpga_io.fields.FTMS = 0;
	fpga_io.fields.FTDI = 0;
	fpga_io.fields.FTDO = 1;
    buffer[1] = fpga_io.byte;
    bcm2835_i2c_write(buffer, 2);
	printf("io_setup: i2c config byte: 0x%x\n", fpga_io.byte);

	// drive desired jtag states - this might be unnecessary at all..
	buffer[0] = I2C_CMD_OUTPUT1;
	initial.fields.FTCK = 0;
	initial.fields.FTMS = 0;
	initial.fields.FTDI = 0;
	buffer[1] = initial.byte;
    bcm2835_i2c_write(buffer, 2);
}

void io_shutdown(void)
{
	buffer[0] = I2C_CMD_CONFIG1;
	buffer[1] = 0xFF;
	bcm2835_i2c_write(buffer, 2);
}

void io_tms(int val)
{
	buffer[0] = I2C_CMD_OUTPUT1;
	fpga_ctrl fpga_io;
	fpga_io.byte = buffer[1];
	fpga_io.fields.FTMS = val ? HIGH : LOW;
	buffer[1] = fpga_io.byte;
	bcm2835_i2c_write(buffer, 2);
}

void io_tdi(int val)
{
	buffer[0] = I2C_CMD_OUTPUT1;
	fpga_ctrl fpga_io;
	fpga_io.byte = buffer[1];
	fpga_io.fields.FTDI = val ? HIGH : LOW;
	buffer[1] = fpga_io.byte;
	bcm2835_i2c_write(buffer, 2);
}

void io_tck(int val)
{
	buffer[0] = I2C_CMD_OUTPUT1;
	fpga_ctrl fpga_io;
	fpga_io.byte = buffer[1];
	fpga_io.fields.FTCK = val ? HIGH : LOW;
	buffer[1] = fpga_io.byte;
	bcm2835_i2c_write(buffer, 2);
}

void io_sck(int val)
{
}

void io_trst(int val)
{
}

int io_tdo()
{
	fpga_ctrl read;
	buffer[0] = I2C_CMD_INPUT1;
	bcm2835_i2c_read_register_rs(buffer, &read.byte, 1);
	return read.fields.FTDO ? HIGH : LOW;
}


/** END: Low-Level I/O Implementation **/