#!/bin/sh
IP="raspberrypi.local"
TOOL="xsvftool-gpio"
TARGET_DIR="/home/pi/libxsvf/"
PROJECT_PATH="./diamond/vienna-scope/impl1"
SVF_FILE="vienna-scope_impl1.svf"
TARGET_RESET_DIR="/home/pi/vienna-scope/spi/"

ssh -o ConnectTimeout=5 pi@$IP "mkdir -p $TARGET_DIR"
scp -o ConnectTimeout=5 $PROJECT_PATH/$SVF_FILE pi@$IP:$TARGET_DIR
ssh -o ConnectTimeout=5 pi@$IP "cd $TARGET_DIR;sudo ./$TOOL -c -s $SVF_FILE -vvvv"
ssh -o ConnectTimeout=5 pi@$IP "cd $TARGET_RESET_DIR;python3 fpga_reset.py"
