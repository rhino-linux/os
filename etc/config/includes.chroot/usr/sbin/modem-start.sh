#!/bin/bash -e

echo 0 > /sys/class/modem-power/modem-power/device/powered
fastboot oem stay &
echo 1 > /sys/class/modem-power/modem-power/device/powered
sh /usr/bin/enable-modem
