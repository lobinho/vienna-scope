# Si5356A: https://www.silabs.com/documents/public/data-sheets/si5356a-datasheet.pdf
from smbus2 import SMBus
import pandas as pd
import time


class Si5356A:
    def __init__(self, i2c_channel, i2c_address=0x70):
        self.i2c_channel = i2c_channel
        self.i2c_address = i2c_address

    def __enter__(self):
        return self

    def __exit__(self, type, value, trace):
        pass

    def get_status(self):
        """Status register at address 218 is available to help
            identify the exact event that caused interrupt.
        """
        pass

    def get_register_pairs(self, file):
        """Use SiliconLabs Clock Builder Pro export to C and extract data in the format:
            # Address,Data,Mask
            6,0x08,0x1D
        """
        df = pd.read_table(file, sep=',', header=0, comment='#', 
                           names=['Address', 'Data', 'Mask'],
                           converters = {'Address': lambda x: int(x),
                                         'Data': lambda x: int(x, 16),
                                         'Mask': lambda x: int(x, 16)})
        return df
        

    def config(self, file):
        """3.5.2. Creating a New Configuration for RAM
            using ClockBuilder Desktop
            and procedure as Figure 5.
            Spread spectrum is off.

            1) Set OEB_ALL = 1; reg230[4]
            2) Set reg241 = 0x65
            3) Write register map from ClockBuilder -> loop over self.get_register_pairs('Si5356_10MHz_8x.csv')
            4) Set SOFT_RESET = 1; reg246[1]
            5) Set OEB_ALL = 0; reg230[4]
            
        """
        print(f'Si5356A on i2c/{self.i2c_channel} config: {file}')
        with SMBus(self.i2c_channel) as bus:
            bus.write_byte_data(self.i2c_address, 255, 0)
            rd_ = bus.read_byte_data(self.i2c_address, 230)
            bus.write_byte_data(self.i2c_address, 230, rd_ | (1 << 4))
            print(f'Writing OEB: {rd_ | (1 << 4)}')
            bus.write_byte_data(self.i2c_address, 241, 0x65)
            time.sleep(0.1)
            for row in self.get_register_pairs(file).itertuples():
                if row.Mask > 0:
                    if row.Mask == 0xFF:
                        value = row.Data
                    else:
                        rd = bus.read_byte_data(self.i2c_address, row.Address)
                        value = (rd & (~row.Mask)) | (row.Data & row.Mask)
                    print(f' > {row.Address:3} = {value:03X}')
                    bus.write_byte_data(self.i2c_address, row.Address, value)
                if row.Address == 255:
                    if row.Data == 0:
                        print('Setting page 0')
                    else:
                        print('Setting page 1')

            # Do not use read-modify-write procedure to perform soft reset:
            bus.write_byte_data(self.i2c_address, 246, 0x2)
            # spread spectrum (should not be necessary though..)
            # rd_ = bus.read_byte_data(self.i2c_address, 226)
            # bus.write_byte_data(self.i2c_address, 226, rd_ | (1 << 2))
            # time.sleep(0.001)
            # bus.write_byte_data(self.i2c_address, 226, rd_ & (~ (1 << 2)))
            # spread spectrum end
            rd_ = bus.read_byte_data(self.i2c_address, 230)
            bus.write_byte_data(self.i2c_address, 230, rd_ & (~ (1 << 4)))
            print(f'Writing OEB: {rd_ & (~ (1 << 4))}')

    def get_status(self):
        """Get status register 218 of page 0.
        0 is good, 1 is lost.
        XTAL shall be godd. CLKIN shall be lost.
        """
        with SMBus(self.i2c_channel) as bus:
            rd = bus.read_byte_data(self.i2c_address, 218)
        status = {
            'Device calibration in progress': rd & 1,
            'XTAL loss': (rd >> 2) & 1,
            'CLKIN loss': (rd >> 3) & 1,
            'PLL loss of lock': (rd >> 4) & 1
        }
        return status

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description='Si5356A clock generator.')
    parser.add_argument('--i2c_channel', type=int, default=1, help='defaults to 1')
    parser.add_argument('--file', default='Si5356_1MHz_8x.csv',
                        help='defaults to Si5356_1MHz_8x.csv')
    args = parser.parse_args()
    i2c_channel = args.i2c_channel
    file = args.file
    # file = 'Si5356_10MHz_8x.csv'
    # file = 'Si5356_25MHz_2x.csv'
    with Si5356A(i2c_channel) as clk_gen:
        clk_gen.config(file)
        time.sleep(0.5)
        print('Status: {}'.format(clk_gen.get_status()))
