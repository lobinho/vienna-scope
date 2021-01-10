# MCP4728: https://ww1.microchip.com/downloads/en/DeviceDoc/22187E.pdf, pg34
# 12 bit value in 0 .. 4095
# DAC voltage = Vref * Dn / 4096 * G with Vref = 2.048V
# Note that output voltage cannot exceed supply voltage of 3.3V.

from smbus2 import SMBus


class MCP4728:
    CH = {
        'A': 0,
        'B': 1,
        'C': 2,
        'D': 3
    }
    PD = {
        'normal': 0,
        '1k to ground': 1,
        '100k to ground': 2,
        '500k to ground': 3
    }
    def __init__(self, i2c_channel, i2c_address=0x60):
        self.i2c_channel = i2c_channel
        self.i2c_address = i2c_address

    def __enter__(self):
        return self

    def __exit__(self, type, value, trace):
        pass

    def write_sequential(self, data_4ch):
        """Write channels A-D sequentially using fast mode, setting
        data bits only. Power is always enabled. EEPROM is untouched.
        """
        data64 = []
        print(f'MCP4728 on i2c/{self.i2c_channel} sequential write: {data_4ch}')
        for i, d in enumerate(data_4ch):
            if d not in range(4096):
                raise Exception(f'DAC channel {MCP4728.CH[i]} value out of range: {d}')
            data16 = [(MCP4728.PD['normal'] << 4 ) + (d >> 8),
                      d & 0xFF]
            data64.extend(data16)
        with SMBus(self.i2c_channel) as bus:
            bus.write_i2c_block_data(self.i2c_address, data64[0], data64[1:])

    def write_single(self, dac_channel, d):
        """Write single channel and keep others on previous values.
        """
        rd = self.read_sequential()
        data_4ch = rd['dac']
        data_4ch[MCP4728.CH[dac_channel]] = d
        self.write_sequential(data_4ch)

    def write_single_eeprom(self, dac_channel, d):
        """Single channel fast write with EEPROM:
        C2 | C1 | C0 | W1 | W0 | DAC1 | DAC0 | _UDAC
        C2=0 C1=1 C0=0 W1=1 W0=1
        _UDAC is ignored as we pull _LDAC Low
        DAC1 DAC0 selects channel
        Set all to internal ref (bit 7), gain = 2 (bit 4) of first byte.
        Refer to Fig. 5-10.
        """
        print(f'MCP4728 on i2c/{self.i2c_channel}, Ch {dac_channel} write: {d} (EEPROM)')
        if d not in range(4096):
            raise Exception(f'DAC value out of range: {d}')
        cmd = 0x58 + (MCP4728.CH[dac_channel] << 1)
        data = [0x90 + (d >> 8),
                d & 0xFF]
        with SMBus(self.i2c_channel) as bus:
            bus.write_i2c_block_data(self.i2c_address, cmd, data)

    def read_sequential(self):
        """Read channels A-D sequentially.
        1st byte is read access
        2nd - 4th bytes are the contents of the DAC Input Register,
        5th - 7th bytes are the EEPROM contents.
        Master reads 6 bytes and ends with STOP bit. Subsequent read
        access provide all 4 channels sequentially.
        """
        data = {
            'dac': [],
            'eeprom': []
        }
        with SMBus(self.i2c_channel) as bus:
            data_4ch = bus.read_i2c_block_data(self.i2c_address, 0, 4*6)
        for i in range(4):
            data_ch = data_4ch[6*i:6*i+6]
            ch_register = (data_ch[0] >> 4) & 0x3
            ch_eeprom = (data_ch[3] >> 4) & 0x3
            if ch_register != ch_eeprom or ch_register != i:
                print(f'Invalid channel: {ch_register}, {ch_eeprom}, expecting {i}.')
            data['dac'].append(((data_ch[1] & 0x0F) << 8) + data_ch[2])
            data['eeprom'].append(((data_ch[4] & 0x0F) << 8) + data_ch[5])
        return data

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description='MCP4728 4 channel DAC.')
    parser.add_argument('--i2c_channel', type=int, default=1, help='defaults to 1')
    parser.add_argument('--dac_channel', required=True, help='A, B, C, D')
    parser.add_argument('--d', type=int, required=True, help='Voltage in mV: 0 ... 4095')
    
    args = parser.parse_args()
    i2c_channel = args.i2c_channel
    dac_channel = args.dac_channel
    d = args.d
    with MCP4728(i2c_channel) as dac:
        print(dac.read_sequential())
        dac.write_single(dac_channel, d)

