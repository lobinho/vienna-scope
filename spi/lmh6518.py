import os
import time
import subprocess
import array
import sys


# LMH6518 uses three wire SPI, aka half duplex
SCLK_GPIO = 22   # SPI_SCLK_S
SDIO_GPIO = 10   # SPI_MISO0
CS_GPIO = {
    'A': 8,      # SPI_CS0
    'B': 7       # SPI_CS1
}

def writef(file, val):
    with open(file, 'w') as f: f.write(val)

def readf(file):
    with open(file, 'r') as f: ret = f.read()
    return ret

class GPIO:
    def __init__(self, num, dir='out'):
        self.num = num
        self.val = 0
        writef('/sys/class/gpio/export', '%s' % num)
        time.sleep(0.1)
        writef('/sys/class/gpio/gpio%s/direction' % num, dir)

    def close(self):
        writef('/sys/class/gpio/gpio%s/direction' % self.num, 'in')
        writef('/sys/class/gpio/unexport', '%s' % self.num)

    def get(self):
        return int(readf('/sys/class/gpio/gpio%s/value' % self.num))

    def set(self, val=1):
        if val == 0:
            self.val = 0
        else:
            self.val = 1
        writef('/sys/class/gpio/gpio%s/value' % self.num, '%s' % self.val)
        return self.val

    def clear(self):
        self.set(0)

    def pulse(self):
        if (self.val):
            self.set(0)
            time.sleep(1)
            self.set(1)
        else:
            self.set(1)
            time.sleep(1)
            self.set(0)


class SPI:
    def __init__(self, sclk_gpio, sdio_gpio, cs_gpio):
        self.sclk = GPIO(sclk_gpio)
        self.mosi = GPIO(sdio_gpio)
        self.cs = GPIO(cs_gpio)
        self.cs.set(1)
        self.sclk.set(0)
        self.mosi.set(0)

    def __enter__(self):
        return self

    def __exit__(self, type, value, trace):
        self.close()

    def close(self):
        self.sclk.close()
        self.mosi.close()
        self.cs.close()

    def select(self):
        self.cs.set(0)

    def unselect(self):
        self.cs.set(1)

    def clock_out(self, value):
        ret = self.mosi.set(value)
        self.sclk.set(1)
        self.sclk.set(0)
        return ret

    def write(self, *bytes):
        for byte in bytes:
            for i in range(8):
                self.clock_out( (byte << i) & 0b10000000 )

    def clock_in(self):
        self.sclk.set(1)
        ret = self.mosi.get()
        self.sclk.set(0)
        return ret

    def read(self, byte_count=1):
        ret = 0
        writef('/sys/class/gpio/gpio%s/direction' % self.mosi.num, 'in')
        for i in range(8 * byte_count):
            ret <<= 1
            ret |= self.clock_in()
        writef('/sys/class/gpio/gpio%s/direction' % self.mosi.num, 'out')
        return ret


class LMH6518:
    def __init__(self, channel):
        self.channel = channel
        self.spi = SPI(SCLK_GPIO, SDIO_GPIO, CS_GPIO[channel])

    def __enter__(self):
        return self

    def __exit__(self, type, value, trace):
        self.close()

    def close(self):
        self.spi.close()

    def write(self, word):
        print(f'LMH6518 Ch {self.channel} write: 0x{word:02X}')
        self.spi.select()
        self.spi.write(0x00)
        self.spi.write(word >> 8, word & 0xFF)
        self.spi.unselect()

    def read(self):
        self.spi.select()
        self.spi.write(0xFF)
        word = self.spi.read(2)
        self.spi.unselect()
        return word

    def configure(self, ladder, preamp, filter, aux):
        """
        D0-D3: ladder attenuation: 0dB to -20dB in 2dB steps
        D4:    preamp. LG = 10dB, HG = 30dB
        D6-D8: filter bandwidth: 20MHz, 100MHz, 200MHz, 350MHz, 650MHz, 750MHz, 900MHz
        D10: auxiliary output. on, off
        """
        print(f'Configuring LMH6518 to ladder: {ladder}, preamp: {preamp},'
              f' bandwidth: {filter}, auxiliary: {aux}.')
        ladder_attenuation = {
            '0dB': 0,
            '-2dB': 1,
            '-4dB': 2,
            '-6dB': 3,
            '-8dB': 4,
            '-10dB': 5,
            '-12dB': 6,
            '-14dB': 7,
            '-16dB': 8,
            '-18dB': 9,
            '-20dB': 10,
        }
        preamp_gain = {
            'LG': 0,
            'HG': 1
        }
        filter_bw = {
            '20MHz': 1,
            '100MHz': 2,
            '200MHz': 3,
            '350MHz': 4,
            '650MHz': 5,
            '750MHz': 6,
            '900MHz': 0
        }
        auxiliary = {
            'on': 0,
            'off': 1
        }
        word = ((ladder_attenuation[ladder])
                + (preamp_gain[preamp] << 4)
                + (filter_bw[filter] << 6)
                + (auxiliary[aux] << 10))
        self.write(word)
        read = self.read()
        if word != read:
            print(f'LMH6518 Ch {self.channel} writing failed: 0x{word:02X} != 0x{read:02X}')


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description='LMH6518 VGA.')
    parser.add_argument('--channel', default='A', help='defaults to A')
    args = parser.parse_args()
    channel = args.channel

    with LMH6518(channel) as ch:
        # Default after reset is 0x0A
        print('Status: {}'.format(ch.read()))
        ch.configure('-20dB', 'LG', '100MHz', 'off')
        print('Status: {}'.format(ch.read()))
