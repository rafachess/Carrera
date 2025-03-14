#!/bin/bash

echo "===== PROCESSING ====="
dmesg | grep cp210x | grep -o USB.*$ | tail -n1

echo ""
echo ""

echo "===== ARDUINO ====="
dmesg | grep ch341 | grep -o USB.*$ | tail -n1

sleep 3

arduino &
processing ~/JuFo_Projekte/Carrera/CarreraControl/CarreraControl.pde  &

