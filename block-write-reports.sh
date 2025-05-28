#!/usr/bin/env bash

: << 'COMMENT'
strace files:
trace/lestrade-block-write-async-1M.strace
trace/lestrade-block-write-async-8k.strace
trace/lestrade-block-write-sync-1M.strace
trace/lestrade-block-write-sync-8k.strace

naming

	host	 test name	  io	block
							 type size
 lestrade-block-write-sync-8k.strace

COMMENT

mkdir -p reports

currDir=$(pwd)

for traceFile in trace/*.strace
do
	baseFile=$(basename $traceFile | cut -f1 -d\.)
	host=$(echo $baseFile | cut -d- -f1)
	testType=$(echo $baseFile | cut -d- -f2,3)
	ioType=$(echo $baseFile | cut -d- -f4)
	blockSize=$(echo $baseFile | cut -d- -f5)

cat <<-EOF

  ============================================
		 file: $traceFile
		 host: $host
  test type: $testType
	 io type: $ioType
 block size: $blockSize
   location: $currDir

EOF

	rptName="reports/$host-$testType-$ioType-$blockSize-rpt.txt"
	echo rptName: $rptName

	./strace-breakdown.pl $traceFile > $rptName

done

