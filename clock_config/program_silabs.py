import sys
import time
import smbus

I2CBUS = 2
I2CADDR = 0x6a


with open(sys.argv[1], 'r') as fh:
    lines = fh.read().split('\n')

print("Read %d lines" % len(lines))

print("Opening I2C bus %d" % I2CBUS)

iic = smbus.SMBus(I2CBUS)

for line in lines:
    if line.startswith('#'):
        continue
    if line.startswith('Address'):
        continue
    if len(line) == 0:
        continue
    addr, data = line.split(',')
    addr = int(addr, 16)
    data = int(data, 16)
    iic.write_byte_data(I2CADDR, addr, data)
    print('Write I2C device 0x%x addr 0x%x data 0x%x' % (I2CADDR, addr, data))
    time.sleep(0.01)
