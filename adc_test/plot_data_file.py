#!/usr/bin/env python
import argparse
from matplotlib import pyplot as plt

parser = argparse.ArgumentParser(description='Plot received packet files',
             formatter_class=argparse.ArgumentDefaultsHelpFormatter)

parser.add_argument('filename', type=str, default=None,
                    help='Plot packets from filename.x.data and filename.y.data')
parser.add_argument('-n', '--npacket', type=int, default=1,
                    help='Number of packets to plot')
args = parser.parse_args()

fhx = open("%s.x.data" % args.filename, "r")
fhy = open("%s.y.data" % args.filename, "r")

for line in range(args.npacket):
    xtd = list(map(int, fhx.readline().split(',')))
    xt = xtd[0]
    xd = xtd[1:]
    ytd = list(map(int, fhy.readline().split(',')))
    yt = ytd[0]
    yd = ytd[1:]
    plt.plot(xd, '-o', label="X,%d"%xt)
    plt.plot(yd, '-o', label="Y,%d"%yt)
plt.legend()
plt.show()
