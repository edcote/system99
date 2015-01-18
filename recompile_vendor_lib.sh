#!/bin/sh
rm -rf altera_mf
vlib altera_mf
vmap altera_mf altera_mf
vlog -quiet -timescale "1 ns / 1 ns" -work altera_mf altera_mf.v
