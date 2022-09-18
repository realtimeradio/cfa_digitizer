#!/usr/bin/env python

import os
import socket
import time
import struct
import sys
import argparse
import numpy as np
import json

PACKET_BUF = 8300
BASE_HEADER_SIZE = 8
NPOL = 2
NSAMPLE_BYTES = 2
SAMPLE_FORMAT = "h"

def decode_packet(p, nsample):
    x = struct.unpack('>Q', p[0:BASE_HEADER_SIZE])
    h = {}
    h['t'] = x[0]
    payload_bytes = NSAMPLE_BYTES * NPOL * nsample
    d = np.array(struct.unpack('>%d%s' % (NPOL*nsample, SAMPLE_FORMAT), p[BASE_HEADER_SIZE:]), dtype=int)
    dx = d[0::2]
    dy = d[1::2]
    return h, dx, dy

parser = argparse.ArgumentParser(description='Receive Sampler packets',
             formatter_class=argparse.ArgumentDefaultsHelpFormatter)

parser.add_argument('-P', '--port', type=int, default=10000,
                    help='UDP port to which to listen')
parser.add_argument('-i', '--ip', type=str, default='100.100.101.101',
                    help='IP address to which to bind')
parser.add_argument('-d', '--data', action='store_true',
                    help='Use this flag to print packet data rather than just headers')
parser.add_argument('-n', '--nsample', type=int, default=256,
                    help='Number of samples (per polarization) per packet')
args = parser.parse_args()

print("Creating socket and binding to %s:%d" % (args.ip, args.port))
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind((args.ip, args.port))

udp_payload_size = args.nsample * NSAMPLE_BYTES * NPOL + BASE_HEADER_SIZE

print("Expecting packets of size %d bytes" % udp_payload_size)

packet_cnt = 0
try:
    while(True):
        p = sock.recv(PACKET_BUF)
        h, x, y = decode_packet(p, args.nsample)
        print(h)
        if args.data:
            print("X:", x[0:10])
            print("Y:", y[0:10])
        packet_cnt += 1

except KeyboardInterrupt:
    pass
