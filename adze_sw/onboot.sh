#!/bin/bash

CLOCK_CONF_BIN=/home/casper/src/cfa_digitizer/adze_sw/clock_config/program_silabs.py
CLOCK_CONF_CSV=/home/casper/src/cfa_digitizer/adze_sw/clock_config/Si5332-GM1-RevD-0743-1-Registers.csv

/usr/bin/python3 $CLOCK_CONF_BIN $CLOCK_CONF_CSV

TCPBORPHSERVER=/home/casper/src/cfa_digitizer/adze_sw/katcp_devel/tcpborphserver3/tcpborphserver3

$TCPBORPHSERVER
