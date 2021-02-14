import spidev
import logging
logger = logging.getLogger(__name__)


def get_register_map():
    reg_map = {
        'version': 0x01,
        'led_mode': 0x02,
        'clk_div': 0x03,
        'awg_shape': 0x20,
        'awg_amplitude': 0x21,
        'awg_offset': 0x22,
        'awg_period_7_0': 0x23,
        'awg_period_15_8': 0x24,
        'awg_period_23_16': 0x25
    }
    return reg_map


class Communication:
    """High level communication between Lattice MachXO2 and RPi using SPI.
    Register and data width is currently 8 bit.
    Further commands can be added if desired.
    """
    SPI_SPEED = 1000000
    CMD_READ = 1
    CMD_WRITE = 2
    def __init__(self, bus=0, device=0):
        self.bus = bus
        self.device = device
        self.spi = spidev.SpiDev()
        self.spi.open(bus, device)
        self.spi.max_speed_hz = self.SPI_SPEED
        self.spi.mode = 0
        self.reg_map = get_register_map()

    def __enter__(self):
        return self

    def __exit__(self, type, value, trace):
        self.spi.close()

    def _xfer(self, command, address, value):
        """Generic register access:
        Byte 1: command
        Byte 2: address
        Byte 3: value to write to slave (MachXO2)
        """
        try:
            address = self.reg_map[address]
        except KeyError:
            pass
        if address not in range(0x100):
            raise(f'Address out of range: {address}.')
        if value not in range(0x100):
            raise(f'Value of range: {value}.')
        rd = self.spi.xfer2([command, address, value])
        if rd[0:2] != [command, address]:
            raise Exception(f'Transfer failed. Received: {rd}.')
        return rd[2]

    def read(self, address):
        """Read register from address.
        """
        try:
            return self._xfer(self.CMD_READ, address, 0)
        except Exception as e:
            raise Exception(f'Read failed: {e}.')

    def write(self, address, value):
        """Write register from address.
        """
        try:
            self._xfer(self.CMD_WRITE, address, value)
        except Exception as e:
            raise Exception(f'Write failed: {e}.')

    def read_fifo(self, source='ADC', channel=0):
        """Stop writing FIFO, reset FIFO and initiate a new write cycle.
        Default source is ADC. For testing, we may use AWG instead with known signal.
        2 channels are mapped to ADCs, further 2 are dummies.
        """
        # FIFO is 1024x32 bit wide. We read only first byte of 32 bit:
        N = 1024
        fifo_sources = {
            'ADC': 0x00,
            'AWG': 0x01,
            'ADC_CLK': 0x10
        }
        if channel not in range(4):
            raise(f'Channel out of range: {channel}.')
        self.write(
            0x51,
            ((0x3 & fifo_sources[source]) << 4) + (0x3 & channel)
        )
        self.write(0x52, 0x00)
        self.write(0x53, 0x03)
        self.write(0x53, 0x00)
        logger.info(f'FIFO should be empty. 0x54: {self.read(0x54)}')
        self.write(0x52, 0x01 if channel == 0 else (0x01 << 4))
        self.write(0x52, 0x00)
        logger.info(f'FIFO should be full. 0x54: {self.read(0x54)}')

        fifo = [self.read(0x50) for i in range(N)]
        logger.debug(fifo)
        logger.info(f'Finished. FIFO should be empty. 0x54: {self.read(0x54)}')
        return fifo


if __name__ == '__main__':
    logging.basicConfig(format='%(levelname)s:%(message)s', level=logging.DEBUG)
    with Communication() as com:
        logger.info(com.read('version'))
        logger.info(com.read('led_mode'))
        logger.info(com.read('clk_div'))
        com.write('clk_div', 23)
