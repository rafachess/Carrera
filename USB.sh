#!/bin/bash


# Get the line number of the last disconnect message
last_disconnect=$(dmesg | grep -n "disconnect" | tail -n 1 | cut -d ':' -f 1)

# If a disconnect message is found
if [ -n "$last_disconnect" ]; then
    # Get all dmesg lines after the last disconnect
    echo "===== PROCESSING ====="
    dmesg | tail -n +$((last_disconnect + 1))| grep "pl2303.*attach" | grep -o USB.*$ | tail -n1
    echo ""
    echo ""

    echo "===== ARDUINO ====="
    dmesg | tail -n +$((last_disconnect + 1)) | grep "ch341.*attach" | grep -o USB.*$ | tail -n1
else
    echo "No disconnect messages found in dmesg."
fi

sleep 5
