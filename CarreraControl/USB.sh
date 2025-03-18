#!/bin/bash

#xclock &
#echo "===== PROCESSING ====="
echo "/dev/$(dmesg | grep cp210x | grep -o 'ttyUSB.*$' | tail -n1)"
#
#echo ""
#echo ""#
#
#echo "===== ARDUINO ====="
#dmesg | grep ch341 | grep -o USB.*$ | tail -n1
#
#sleep 5
