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

    def get_register_pairs_legacy(self, file):
        """Use SiliconLabs Clock Builder Pro export to csv without
        headers to get files in the format:
            # Address,Data
            6,08h
        """
        df = pd.read_table(file, sep=',', header=0, names=['Address', 'Data'])
        df['Data'] = df['Data'].apply(lambda x: int(x[:-1], 16))
        return df
        
    def get_register_pairs(self, file):
        """Use SiliconLabs Clock Builder Pro export to C and extract data in the format:
            # Address,Data,Mask
            6,0x08,0x1D
        """
        df = pd.read_table(file, sep=',', header=0, names=['Address', 'Data', 'Mask'])
        df['Data'] = df['Data'].apply(lambda x: int(x, 16))
        df['Mask'] = df['Mask'].apply(lambda x: int(x, 16))
        return df
        

    def config(self):
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
        config_file = 'Si5356_10MHz_8x.csv'
        print(f'Si5356A on i2c/{self.i2c_channel} config: {config_file}')

        rd = []
        with SMBus(self.i2c_channel) as bus:
            # Read all 350 registers with chunks of 32 bytes ~ 11 times
            for i in range(12):
                rd256 = bus.read_i2c_block_data(self.i2c_address, 32 * i, 32)
                rd.extend(rd256)
                time.sleep(0.1)
            bus.write_byte_data(self.i2c_address, 230, rd[230] | (1 << 4))
            bus.write_byte_data(self.i2c_address, 241, 0x65)
            for row in self.get_register_pairs(config_file).itertuples():
                if row.Mask > 0:
                    value = (rd[row.Address] & (~row.Mask)) | (row.Data & row.Mask)
                    bus.write_byte_data(self.i2c_address, row.Address, value)
            bus.write_byte_data(self.i2c_address, 246, 0x2)
            bus.write_byte_data(self.i2c_address, 230, rd[230] & (~ (1 << 4)))


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description='Si5356A clock generator.')
    parser.add_argument('--i2c_channel', type=int, default=1, help='defaults to 1')
    args = parser.parse_args()
    i2c_channel = args.i2c_channel
    with Si5356A(i2c_channel) as clk_gen:
        clk_gen.config()
