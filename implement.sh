#!/bin/sh
rm -rf quartus; mkdir quartus; cd quartus
cp ../precision/system_impl/*.edf .
cp ../*.hex .
quartus_sh -t ../implement.tcl
quartus quartus.qpf &
cd ..
