import time

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
        self.set_direction(dir)

    def set_direction(self, direction):
        writef('/sys/class/gpio/gpio%s/direction' % self.num, direction)

    def close(self):
        self.set_direction('in')
        writef('/sys/class/gpio/unexport', '%s' % self.num)

    def get(self):
        return int(readf('/sys/class/gpio/gpio%s/value' % self.num))

    def set(self, val=1):
        self.val = 0 if val == 0 else 1
        writef('/sys/class/gpio/gpio%s/value' % self.num, '%s' % self.val)
        return self.val

    def clear(self):
        self.set(0)
