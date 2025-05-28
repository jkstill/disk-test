#!/usr/bin/env bash

set -u 

scriptHome=$(dirname $0)

cd $scriptHome/.. || { echo "failed to cd to $scriptHome/.."; exit 1; }

baseDir=$(pwd | cut -f2 -d\/| tr -d '/')

tarFile=/tmp/$(hostname -s)-${baseDir}-disktests.tgz

echo creating $tarFile

tar cvfz $tarFile disk-test/*.sh disk-test/{trace,reports} disk-test/README.md

echo tar file: $tarFile

