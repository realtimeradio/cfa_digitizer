#! /bin/bash

# Try to unload running drivers
rmmod w1-gpio
rmmod w1_therm

insmod w1-gpio.ko
insmod w1_therm.ko

sleep 1

echo "Temperatures, in degrees C"
for d in $(ls -d /sys/bus/w1/devices/w1_bus_master1-*)
do
  name=`cat ${d}/name`
  temp_mc=`cat ${d}/temperature`
  temp=`printf %.3f "$((temp_mc))e-3"`
  echo "Sensor ID $name : $temp"
done
