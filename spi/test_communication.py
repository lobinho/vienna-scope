from communication import Communication
import numpy as np
import matplotlib.pyplot as plt
import logging
logger = logging.getLogger(__name__)


def plot(data):
    x = np.linspace(0, 1, len(data))
    x = range(len(data))
    y = data
    fig, ax = plt.subplots()
    ax.plot(x, y)
    ax.set(xlabel='Sample', ylabel='Digit',
           title='Vienna-Scope')
    ax.grid()
    plt.show()


if __name__ == '__main__':
    logging.basicConfig(format='%(levelname)s:%(message)s', level=logging.DEBUG)
    with Communication() as com:
        print(com.read('version'))
        print(com.read('led_mode'))
        print(com.read('clk_div'))

        com.write('awg_amplitude', 10)
        com.write('awg_period_7_0', 0x0D)
        com.write('awg_period_15_8', 0x00)
        com.write('awg_period_23_16', 0x00)

        com.write('awg_shape', 1)       # sawtooth
        fifo = com.read_fifo('AWG')
        plot(fifo)
        com.write('awg_shape', 2)       # triangle
        fifo = com.read_fifo('AWG')
        plot(fifo)
        com.write('awg_shape', 3)       # square
        fifo = com.read_fifo('AWG')
        plot(fifo)
        com.write('awg_shape', 4)       # sine
        com.write('awg_offset', 127)
        com.write('awg_amplitude', 5)
        fifo = com.read_fifo('AWG')
        plot(fifo)
