from smbus2 import SMBus
import time

# PCA9555: https://www.nxp.com/docs/en/data-sheet/PCA9555.pdf
# Register addresses:
# 0 Input port 0
# 1 Input port 1
# 2 Output port 0
# 3 Output port 1
# 4 Polarity Inversion port 0
# 5 Polarity Inversion port 1
# 6 Configuration port 0
# 7 Configuration port 1
REG_IN = [0x0, 0x1]
REG_OUT = [0x2, 0x3]
REG_POL = [0x4, 0x5]
REG_CONF = [0x6, 0x7]

def set_bit(value, bit):
    return value | (1 << bit)

def clear_bit(value, bit):
    return value & ~(1 << bit)

def get_bit(value, bit):
    return bool(value & (1 << bit))

class PCA9555:
    def __init__(self, i2c_channel, i2c_address=0x20):
        self.i2c_channel = i2c_channel
        self.i2c_address = i2c_address

    def __enter__(self):
        return self

    def __exit__(self, type, value, trace):
        pass

    def get_io(self, port, pin):
        IO_PORT = {
            'AFE_PORT': 0,
            'FPGA_PORT': 1
        }
        IO_PIN = {
            'ADC_EXT_CLK_EN_N': 0,
            'ADC_CLK_LOSS': 1,
            'AWFG_DAC_DISABLE': 2,
            'AWFG_CMODE': 3,
            'NOT_IN_USE': 4,
            'RPI_FPGA_LED': 5,    # Read only for Rpi
            'RPI_LED0': 6,
            'RPI_LED1': 7,
            'FPGA_TDO': 0,
            'FPGA_TDI': 1,
            'FPGA_TCK': 2,
            'FPGA_TMS': 3,
            'FPGA_JTAGE_N': 4,
            'FPGA_PROGN': 5,
            'FPGA_INIT': 6,
            'FPGA_DONE': 7
        }
        try:
            port = IO_PORT[port]
        except KeyError:
            pass
        try:
            pin = IO_PIN[pin]
        except KeyError:
            pass
        return port, pin

    def configure(self, port, pin, direction):
        """ port: 0-1
            pin: 0-7
            direction: in/out. set is input (default after reset), clear is output
        """
        port, pin = self.get_io(port, pin)
        with SMBus(self.i2c_channel) as bus:
            cfg = bus.read_byte_data(self.i2c_address, REG_CONF[port])
            if direction == 'in':
                cfg_new = set_bit(cfg, pin)
            elif direction == 'out':
                cfg_new = clear_bit(cfg, pin)
            else:
                raise Exception(f'invalid direction configuration: {direction} '
                                f'for port {port}, pin {pin}')
            if cfg != cfg_new:
                bus.write_byte_data(self.i2c_address, REG_CONF[port], cfg_new)

    def read(self, port, pin):
        """ port: 0-1
            pin: 0-7
        """
        port, pin = self.get_io(port, pin)
        with SMBus(self.i2c_channel) as bus:
            value = bus.read_byte_data(self.i2c_address, REG_IN[port])
        return get_bit(value, pin)

    def write(self, port, pin, value):
        """ port: 0-1
            pin: 0-7
        """
        port, pin = self.get_io(port, pin)
        with SMBus(self.i2c_channel) as bus:
            current_value = bus.read_byte_data(self.i2c_address, REG_OUT[port])
            if value:
                new_value = set_bit(current_value, pin)
            else:
                new_value = clear_bit(current_value, pin)
            if current_value != new_value:
                bus.write_byte_data(self.i2c_address, REG_OUT[port], new_value)


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description='PCA9555 GPIO expander.')
    parser.add_argument('--i2c_channel', type=int, default=1, help='defaults to 1')
    args = parser.parse_args()
    i2c_channel = args.i2c_channel

    with PCA9555(i2c_channel) as expander:
        for port, pin in zip(['FPGA_PORT', 'AFE_PORT', 'AFE_PORT'],
                             ['FPGA_DONE', 'RPI_LED0', 'RPI_LED1']):
            expander.configure(port, pin, 'out')
            print(f'Blinking LED: {port}/{pin}')
            b = True
            for i in range(50):
                expander.write(port, pin, int(b))
                b = not b
                time.sleep(0.05)
            expander.write(port, pin, 1)
            expander.configure(port, pin, 'in')
        
        expander.configure('FPGA_PORT', 'FPGA_DONE', 'out')
        expander.write('FPGA_PORT', 'FPGA_DONE', 0)

        # expander.configure('AFE_PORT', 'ADC_EXT_CLK_EN_N', 'out')
        # expander.write('AFE_PORT', 'ADC_EXT_CLK_EN_N', 0)

        expander.configure('AFE_PORT', 'RPI_FPGA_LED', 'in')
        print('RPI_FPGA_LED: {}'.format(expander.read('AFE_PORT', 'RPI_FPGA_LED')))

        expander.configure('AFE_PORT', 'ADC_CLK_LOSS', 'in')
        print('ADC_CLK_LOSS: {}'.format(expander.read('AFE_PORT', 'ADC_CLK_LOSS')))
