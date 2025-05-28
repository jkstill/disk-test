#!/usr/bin/env bash

dryRun='N'

DRYRUN=$dryRun ioType=async blockSize=8k ./block-write-test.sh
DRYRUN=$dryRun ioType=sync blockSize=8k ./block-write-test.sh

DRYRUN=$dryRun ioType=async blockSize=1M ./block-write-test.sh
DRYRUN=$dryRun ioType=sync blockSize=1M ./block-write-test.sh

