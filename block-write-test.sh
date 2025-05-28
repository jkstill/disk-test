#!/usr/bin/env bash

# read the 1g test file '1Gfile.txt' in 8k chunks and write to a test file

mkdir -p trace

# valid values are sync and async
arg=$1 # only using 1 arg
set -u
: ${DRYRUN:='N'}
: ${ioType:='async'}
: ${blockSize:='8k'}

if	 [[ $DRYRUN == 'N' ]]; then
	dryRunCmd=''
elif [[ $DRYRUN == 'Y' ]]; then
	dryRunCmd='echo '
else
	echo "Unknown value for DRYRUN"
	exit 1
fi

# in dd 'bs' does not mean 'block size', it is 'bytes per step'
# but, it accomplishes what we want to test
# see dd man page for legal values for bs
# mostly we are using 8k and 1M

echo ioType: $ioType >&2

scriptName=$(basename $0);

usage () {

cat <<-EOF

  [ioType=(async|sync)] $scriptName

  ioType: default is async
  blockSize: default is 8k

  examples:

	 $scriptName

	 ioType=async $scriptName

	 ioType=sync $scriptName

	 blockSize=1M ioType=sync $scriptName

EOF

}

case $arg in
	-[?hz]) usage; exit 0;;
	'') ;;
	*) usage; exit 1;;
esac

case $ioType in
	'sync') ddSyncOpts=' oflag=dsync conv=fdatasync ';;
	'async') ddSyncOpts='';;
	*) usage; exit 1;;
esac

#time dd if=1Gfile.txt of=1Gfile_copy.txt bs=8k
mkdir -p trace
$dryRunCmd strace -f -T -ttt -o trace/$(hostname -s)-block-write-${ioType}-${blockSize}-$(date '+%Y-%m-%d_%H-%M-%S').strace dd status=progress $ddSyncOpts if=data/1Gfile.txt of=data/1Gfile_copy.txt bs=$blockSize

