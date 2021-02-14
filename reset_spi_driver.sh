#!/bin/sh
sudo modprobe -r spidev
sudo modprobe -r spi_bcm2835
sudo modprobe spidev
sudo modprobe spi_bcm2835 
