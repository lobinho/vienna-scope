# Insert this result to diamond/vienna-scope/vienna_scope_pkg.vhd
# for an 8-bit signed LUT of a sine wave.

import numpy as np
import math

bit_width = 8
N = 2 ** bit_width
x = np.linspace(0, 2*math.pi, N)
A = 2 ** (bit_width - 1) - 0.5
A0 = 0
y = [round(A0 + A * math.sin(p)) for p in x]

if min(y) < (-N/2) or max(y) >= (N/2):
    raise Exception(f'Exceeding signed{bit_width} range: ({-N/2}, {N/2-1})!')
print('CONSTANT C_SINE_ARRAY : sine_array_t := \n\t{0};'
      .format((str(y).replace('[', '(').replace(']', ')'))))
