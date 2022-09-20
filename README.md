# `cfa_digitizer`

This repository contains software to support the T0743 (a.k.a. ADZE) FPGA
board, including targetting the board using the CASPER toolflow
(see https://casper.berkeley.edu).

## Downloading

To download:

```
git clone https://github.com/realtimeradio/cfa_digitizer
cd cfa_digitizer
git submodule init
git submodule update
```

To run:

```
# From the top-level of the repository
./startsg startsg.local.rtr-dev1
```

You may need to create a new `startsg.local` file if your installation paths
differ from that used on the `rtr-dev1` server.

Software versions used for building / testing this project are:

 - Xilinx Vivado 2019.1.3
 - MATLAB / Simulink 2019a
 - Python 3.6.9
 - Ubuntu 18.04.6 LTS

CASPER library (i.e. `mlib_devel`) versions, as well as versions of other linux
sources, are tracked in this repository via git submodules.

## Firmware

This repository contains various simple firmware designs designed to
test different aspects of the T0743's capabilities.

An example design which exercises most elements of the board can be found
in `adc_test/t0743_adc2tge.slx`. This design captures ADC samples and
packages them as a UDP/IP packet stream, transmitted over 10G Ethernet.
The frequency and time standards used by the design may be locked to a White
Rabbit timing distribution system, if one is provided.

See `adc_test/README.md` for more details.

## Embedded Software

The T0743 board features an OSD 3358 SIP, which is capable of running a linux
OS. This system is used to enable control and monitoring of the T0743 board,
including programming and configuring the board's FPGA.

Instructions to build linux for the T0743 can be found the `linux/README.md`.

Software which should be run locally on the T0743 CPU subsystem can be found
in `adze_sw`. This includes software to configure the board's synthesizer chip,
and to facilitate remote communications, using the `katcp` protocol.

After building linux and a root filesystem for the board, you should

 1. Checkout this repository (and any git submodules in `adze_sw`) on to the T0743.
 2. `make` and `make install` at the top level of `adze_sw/katcp_devel`.
 3. Use CRON (or another method of your choosing) to make sure the `adze_sw/onboot.sh`
script is executed on boot.

You may need to modify the software paths in this script if you clone this repository
to a directory other that `/home/casper/src/cfa_digitizer`.

A pre-built linux SD card image for the T0743 is available on request.
