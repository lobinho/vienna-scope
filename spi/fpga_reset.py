import time
from gpio import GPIO

FPGA_RESET_PIN = 12   # RPI_TMS = GPIO12 works as SPI_MISO3 - temporarily reset input for FPGA

if __name__ == '__main__':
    try:
        reset = GPIO(FPGA_RESET_PIN)
        print(f'Resetting FPGA using RPi GPIO {FPGA_RESET_PIN}...')
        reset.set(1)
        time.sleep(1)
        reset.set(0)
        print('Done.')
    finally:
        reset.close()
