#!/bin/sh
IP="raspberrypi.local"
TARGET_DIR="/home/pi/vienna-scope/"
PROJECT_PATH="./"

ssh -o ConnectTimeout=5 pi@$IP "mkdir -p $TARGET_DIR/i2c;mkdir -p $TARGET_DIR/spi"
scp -o ConnectTimeout=5 $PROJECT_PATH/i2c/* pi@$IP:$TARGET_DIR/i2c
scp -o ConnectTimeout=5 $PROJECT_PATH/spi/* pi@$IP:$TARGET_DIR/spi
