
# Try to unload running drivers
sudo rmmod w1-gpio
sudo rmmod w1_therm

insmod w1-gpio.ko
insmod w1_therm.ko

echo "Temperatures, in mC"
cat /sys/bu/w1/devices/*/temperature
