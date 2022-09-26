# T0743 ADC -> 10G Example Design

The Simulink design `t0743_adc2tge.slx` contains an example firmware design
which captures dual-channel ADC samples, and packages them as a stream of
UDP/IP packets.

## Output format

UDP packet payloads are network- (big-) endian, and comprise a 48-bit timestamp,
which counts samples since the last board synchronisation event (see the
control software's `arm_timestamp_reset()` method), followed by a 16-bit
runtime-configurable header field, followed by a
runtime-configurable number of ADC samples. These samples alternate between the
two ADC channels.
ADC data are presented as 16-bit integers, MSB-aligned with the native ADC
samples. I.e., For a 12-bit ADC, the lower 4 bits of the 16-bit values are
always zero.

A simple method to read a packet of data in python is:

```
import struct
def decode_packet(raw_udp_payload, nsamples):
    """
    parameters:
				raw_udp_payload: The raw UDP payload binary string, obtained from
												 socket.recv()
				nsaples: The number of samples (for each of the two ADC channels)
								 in a packet.

		returns:
				t: Packet timestamp (int)
				h: Packet user-defined 16-bit header (int)
				d0: List of samples from ADC channel 0, running from timestamp t to
						timestamp t+n-1
				d1: List of samples from ADC channel 1, running from timestamp t to
						timestamp t+n-1
		"""

		# Unpack the header word   
		HEADER_SIZE = 8 # Number of bytes in timestamp
		HEADER_FORMAT = "Q" # Python struct format code (unsigned 64-bit)
		x = struct.unpack(">%s" % HEADER_FORMAT, raw_udp_payload[0:HEADER_SIZE])
    t = (x >> 16) & (2**48 - 1)
    h = x & (2**16 - 1)
		# Unpack the rest of the data as ADC samples
		DATA_FORMAT =	"h" # Python struct format code (signed 16-bit)
    # Unpack two ADC channels at once
		data_payload = struct.unpack(">%d%s" % (2*nsamples, DATA_FORMAT), raw_udp_payload[HEADER_SIZE:])
		# De-interleave the two ADC channels
		d0 = data_payload[0::2]
		d1 = data_payload[1::2]

		return t, h, d0, d1
```

## Configuring the design

The Simulink design `t0743_adc2tge.slx` may be compiled using the tool versions
and `mlib_devel` specified in the top-level README file of this repository.

A pre-compiled binary can be found at `t0743_adc2tge/outputs/t0743_adc2tge_2022-09-18_1337.fpg`.
The .fpg file has been tested with the scripts described below.

## Software

Software in this repository was tested with Python 3.6.9

### Control Library

A control class for the firmware design, `T0743Adc2Tge` is provided in
`t0743_adc2tge.py`. This class provides functionality to program, and
configure an ADC->10GbE design on a T0743 (a.k.a. ADZE board).

Example usage can be found in the provided initialization script,
`t0743_adc2tge_init.py`. Also see class docstrings for more infomation.

### Initialization Software

The script `t0743_adc2tge_init.py` is provided to enable command-line
programming, and configuration, of a T0743 board.

Usage information can be obtained by running the script with the `-h` or `--help`
flags:

```
(py3-venv) jackh@rtr-dev2:~/src/cfa_digitizer/adc_test$ ./t0743_adc2tge_init.py -h
usage: t0743_adc2tge_init.py [-h] [--use_wr_pps] [-s] [--dest_port DEST_PORT]
                             [--dest_ip DEST_IP] [--dest_mac DEST_MAC]
                             [--skipprog] [--source_ip SOURCE_IP]
                             [-n SAMPLES_PER_PACKET]
                             host fpgfile

Program and initialize a T0743 ADC->10GbE design

positional arguments:
  host                  Hostname / IP of T0743 board
  fpgfile               .fpgfile to program or /read

optional arguments:
  -h, --help            show this help message and exit
  --use_wr_pps          Use this flag to sync the design from WR PPS pulses
                        (default: False)
  -s                    Use this flag to re-arm the design's sync logic
                        (default: True)
  --dest_port DEST_PORT
                        10GBe destination port (default: 10000)
  --dest_ip DEST_IP     10GBe destination IP address, in dotted-quad notation
                        (default: 10.100.100.1)
  --dest_mac DEST_MAC   10GBe destination IP address, in xx:xx:xx:xx:xx:xx
                        notation (default: a0:48:1c:e0:41:98)
  --skipprog            Skip programming .fpg file (default: False)
  --source_ip SOURCE_IP
                        10GBe Source IP address, in dotted-quad notation
                        (default: 10.100.100.100)
  -n SAMPLES_PER_PACKET
                        Number of samples (per polarization) to pack in a
                        single UDP packet (default: 256)
  --header HEADER       16-bit header value to place in 10GbE packets
                        (default: 0)
```

### Data Capture Software

The script `cature_packets.py` implements a simple Python-based packet receiver.
This receiver can be used to write packets to a simple .csv file, for later plotting.

Usage, as described by the `-h` flag:

```
(py3-venv) jackh@rtr-dev2:~/src/cfa_digitizer/adc_test$ python capture_packets.py -h
usage: capture_packets.py [-h] [-P PORT] [-i IP] [-d] [-t] [-n NSAMPLE]
                          [--outfile OUTFILE]

Receive Sampler packets

optional arguments:
  -h, --help            show this help message and exit
  -P PORT, --port PORT  UDP port to which to listen (default: 10000)
  -i IP, --ip IP        IP address to which to bind (default: 100.100.101.101)
  -d, --data            Use this flag to print packet data (default: False)
  --headers             Use this flag to print packet headers (default: False)
  -n NSAMPLE, --nsample NSAMPLE
                        Number of samples (per polarization) per packet
                        (default: 256)
  --outfile OUTFILE     Record timestamps / data to file <outfile>.x.data and
                        <outfile>.y.data (default: None)
```

Example usage:

To record a packet stream to disk, where packets contain 256 dual-channel,
16-bit samples (i.e., each packet has a payload of 1024 bytes):

```
capture_packets.py -i 10.100.100.1 -P 10000 -n 256 --outfile packet_dump
```

This will record ADC channel 0 packets to a file named `packet_dump.x.data`
and ADC channel 1 packets to a file named `packet_dump.y.data`.

NB: For packets larger than the default Ethernet maximum transmission unit of
1500 Bytes, you will likely need to enable jumbo packet reception by your
NIC and any intermediate Ethernet switches.

The file format is comma-separated integer values, with one line per packet.
The first value in a line represents the timestamp of that line's packet.
Further values are, respectively, the ADC samples in that packet.

Generated data files can be plotted with the example script, `plot_data_file.py`.

Usage, as described by the `-h` flag, is:

```
(py3-venv) jackh@rtr-dev2:~/src/cfa_digitizer/adc_test$ ./plot_data_file.py -h
usage: plot_data_file.py [-h] [-n NPACKET] filename

Plot received packet files

positional arguments:
  filename              Plot packets from filename.x.data and filename.y.data

optional arguments:
  -h, --help            show this help message and exit
  -n NPACKET, --npacket NPACKET
                        Number of packets to plot (default: 1)
```

For example, to plot the first packet written to disk from the example
`capture_packet.py` command:

```
./plot_data_file.py packet_dump -n 1
```

Multiple packets can be plotted, but be aware that the recording software
makes no guarantee that there are no missing packets. As such, multiple
lines in the data file may not represent contiguous samples. The relationship
between data on successive lines of a data file should be checked by examining
each line's timestamp value.

### Simple Plotting

The script `t0743_adc2tge_plot_adc.py` provides basic ADC plotting capabilities.

Usage, as described by the `-h` flag:

```
(casper-python3-venv) jackh@rtr-dev1:~/src/cfa_digitizer/adc_test$ ./t0743_adc2tge_plot_adc.py -h
usage: t0743_adc2tge_plot_adc.py [-h] [--skipprog] [-n PLOT_SAMPLES] [--pps]
                                 host fpgfile

Program and initialize a T0743 ADC->10GbE design

positional arguments:
  host             Hostname / IP of T0743 board
  fpgfile          .fpgfile to program or /read

optional arguments:
  -h, --help       show this help message and exit
  --skipprog       Skip programming .fpg file (default: False)
  -n PLOT_SAMPLES  If specified, plot only this number of samples (default:
                   None)
  --pps            Use this flag to capture samples starting at a PPS edge
                   (default: False)

```

The maximum number of time samples which may be plotted is 8192. This is set
by the size of the ADC snapshot buffers in the firmware design.
