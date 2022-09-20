#! /bin/bash

# Try to unload running drivers
rmmod w1-gpio
rmmod w1_therm

insmod w1-gpio.ko
insmod w1_therm.ko

sleep 1

echo "Temperatures, in mC"
cat /sys/bus/w1/devices/*/temperature
