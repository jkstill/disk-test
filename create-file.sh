#!/usr/bin/env bash

# create a 1G file from /dev/urandom

mkdir -p data

time dd if=/dev/urandom of=data/1Gfile.txt bs=1M count=1024

