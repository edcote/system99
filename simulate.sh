#!/bin/bash

# Parse command line arguments

DO=""
TOP=""
USE_CLI=0

ARG="-L ./altera_mf -novopt -quiet"

while getopts cgd:t: FLAG; do
    case $FLAG in
	d ) DO=$OPTARG;;
	c ) USE_CLI=1;;
	t ) TOP=$OPTARG;;
    esac
done

#if [ $# -eq 0 ] || [ "$TOP" == "" ];
if [ $# -eq 0 ];
then
    echo "Usage: $0 [-c] [-d dofile] [-t top]"
    exit 1
fi

# Run ModelSim

./analyze.sh

if [ $USE_CLI == 1 ]; then
    if [ "$DO" != "" ]; then
	vsim $ARG -do $DO $TOP -c
    else
	vsim $ARG $TOP -c
    fi
else
    if [ "$DO" != "" ]; then
	vsim $ARG -do $DO $TOP -i
    else
        vsim $ARG $TOP -i
    fi
fi
