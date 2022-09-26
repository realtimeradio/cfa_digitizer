#! /usr/bin/env python
import sys
import time
import argparse
import logging
import casperfpga
from t0743_adc2tge import T0743Adc2Tge

def run(host, fpgfile,
        use_wr_pps=False,
        sync=True,
        dest_port=10000,
        dest_ip='10.100.100.1',
        dest_mac='a0:48:1c:e0:41:98',
        skipprog=False,
        source_ip='10.100.100.100',
        samples_per_packet=256,
				header=0,
        ):

    logger = logging.getLogger(__file__)
    logger.setLevel(logging.INFO)
    #handler = logging.StreamHandler(sys.stdout)
    #handler.setLevel(logging.INFO)
    #logger.addHandler(handler)

    logger.info("Connecting to board with hostname %s" % host)
    cfpga = casperfpga.CasperFpga(host, transport=casperfpga.KatcpTransport)

    logger.info("Instantiating control object with fpgfile %s" % fpgfile)
    adze = T0743Adc2Tge(cfpga, fpgfile=fpgfile)

    if not skipprog:
        logger.info("Programming FPGA at %s with %s" % (host, fpgfile))
        adze.program_fpga()

    logger.info("Firmware version is %d" % adze.get_firmware_version())
    logger.info("Firmware build time: %s" % time.ctime(adze.get_build_time()))
    fpga_clock_mhz = adze.cfpga.estimate_fpga_clock()
    logger.info("Estimated FPGA clock is %.2f MHz" % fpga_clock_mhz)

    if fpga_clock_mhz < 1:
        raise RuntimeError("FPGA doesn't seem to be clocking correctly")

    adze.eth_disable() # Stop packet flow before reconfiguring
    logger.info("Setting packets to size %d samples" % samples_per_packet)
    adze.set_packet_nsamples(samples_per_packet)
    logger.info("Setting 16-bit header field to %d" % header)
    adze.set_header_field(header)
    logger.info("Setting packet source IP to %s" % source_ip)
    adze.eth_configure(source_ip)
    adze.eth_reset()
    mac_int = int(dest_mac.replace(':', ''), 16)
    if source_ip.split('.')[0:3] != dest_ip.split('.')[0:3]:
        logger.warning("Source and destination IPs are not on the same /24 subnet")
    logger.info("Setting packet destination to IP %s:%d, MAC 0x%.12x" % (dest_ip, dest_port, mac_int))
    adze.set_packet_dest(dest_ip, mac_int, port=dest_port)
    logger.info("Resetting timestamp counters")
    adze.arm_timestamp_reset()
    if use_wr_pps:
        logger.info("Setting PPS source to White Rabbit")
        adze.set_pps_source(source="wr")
    else:
        logger.info("Setting PPS source to internal software-controlled register")
        adze.set_pps_source(source="sw")
    if sync and not use_wr_pps:
        logger.info("Issuing software controlled PPS trigger")
        adze.issue_sw_pps()
    adze.eth_enable()

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Program and initialize a T0743 ADC->10GbE design',
                                 formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('host', type=str,
                        help = 'Hostname / IP of T0743 board')
    parser.add_argument('fpgfile', type=str, 
                        help = '.fpgfile to program or /read')
    parser.add_argument('--use_wr_pps', action='store_true', default=False,
                        help ='Use this flag to sync the design from WR PPS pulses')
    parser.add_argument('-s', dest='sync', action='store_true', default=True,
                        help ='Use this flag to re-arm the design\'s sync logic')
    parser.add_argument('--dest_port', type=int, default=10000,
                        help='10GBe destination port')
    parser.add_argument('--dest_ip', type=str, default='10.100.100.1',
                        help='10GBe destination IP address, in dotted-quad notation')
    parser.add_argument('--dest_mac', type=str, default='a0:48:1c:e0:41:98',
                        help='10GBe destination IP address, in xx:xx:xx:xx:xx:xx notation')
    parser.add_argument('--skipprog', dest='skipprog', action='store_true', default=False,
                        help='Skip programming .fpg file')
    parser.add_argument('--source_ip', type=str, default='10.100.100.100',
                        help='10GBe Source IP address, in dotted-quad notation')
    parser.add_argument('-n', dest='samples_per_packet', type=int, default=256,
                        help ='Number of samples (per polarization) to pack in a single UDP packet')
    parser.add_argument('--header', type=int, default=0,
                        help ='16-bit header value to place in 10GbE packets')

    args = parser.parse_args()
    run(args.host, args.fpgfile,
        use_wr_pps=args.use_wr_pps,
        sync=args.sync,
        dest_port=args.dest_port,
        dest_ip = args.dest_ip,
        dest_mac=args.dest_mac,
        skipprog=args.skipprog,
        source_ip=args.source_ip,
        samples_per_packet=args.samples_per_packet,
				header=args.header,
        )
