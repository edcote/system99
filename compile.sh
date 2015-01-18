#!/bin/sh

cd testcode/rom
sde-make clean; sde-make 
cp rom.hex ../..
cd ../..

cd testcode/flash
sde-make clean; sde-make 
cp flash.bin  ../..
cd ../..

chmod -x flash.bin
java -jar bin2flash.jar --input=flash.bin --location=0x0 --output=flash.srec





