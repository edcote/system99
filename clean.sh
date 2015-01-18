#!/bin/sh

# Cleanup
find . -type f -name "*~"    -exec rm -f '{}' \;
find . -type f -name "\#*"   -exec rm -f '{}' \;
find . -type f -name "*.bak" -exec rm -f '{}' \;
rm -f transcript *.wlf *.vstf wlf* *.hex *.bin *.ver *.mif *.srec

# Clean Quartus II project
rm -rf quartus

# Clear Precision RTL project
rm -rf precision

# Re-initialize ModelSim work directory
rm -rf work
vlib work
vmap work work
chmod -x modelsim.ini
