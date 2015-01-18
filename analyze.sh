#!/bin/sh

#./compile.sh > /dev/null

vlog -sv -novopt -quiet +incdir+"./hdl" -timescale "1 ns / 1 ns" `cat compile_list | tr '\n' ' '`
vlog -sv -novopt -quiet +incdir+"./hdl" -timescale "1 ns / 1 ns" tb/*.v
