This software should be run locally on the ADZE board

# `onboot.sh`

Run this script as root on boot to:

 1. Program Silabs synthesizer
 2. Start `tcpborphserver3` (the `katcp` communications server)

# `wr_console.sh`

Run this script to talk to a White Rabbit soft-core CPU on the
FPGA. This is only possible if the FPGA is programmed with a design
which includes the WR core.

Once connected to the WR core's serial interface, possible commands
are as follows, and are documented in the
[WRPC user manual](https://ohwr.org/project/wr-cores/wikis/Documents/WR-PTP-Core-v4.2-Files)

```
wrc# help
Available commands:
  ver
  mode
  ptp
  help
  mac
  ps
  uptime
  refresh
  stat
  sfp
  pll
  calibration
  time
  gui
  sdb
  ptrack
  ip
  verbose
  init
  vlan
  diag
  temp
  w1
  w1r
  w1w
wrc# ver
WR Core build: wrpc-v4.2-dirty
Built: Oct 22 2019 21:59:47 by liuweiseu
Built for 128 kB RAM, stack is 2048 bytes
wrc# temp
pcb:22.1250
```

In particular, for a new board, see section 4 of the WRPC manual, which details
commands which might need to be run to set up the core for first time use.

For interactive monitoring of the White Rabbit core,
the `gui` command can be used. For scripted monitoring, the `stat` command
is likely to be most useful.

# `read_onewire_temp.sh`

Run this script as root to load 1-wire communications modules and query
the 1-wire temperature sensors. TODO: make driver loading
automatic at boot.

Script returns:

```
casper@localhost:~/src/cfa_digitizer/adze_sw$ sudo ./read_onewire_temp.sh 
Temperatures, in degrees C
Sensor ID 28-00000e390bd4 : 23.187
Sensor ID 28-00000e390bdb : 21.375
Sensor ID 28-00000e390be6 : 22.250
```
