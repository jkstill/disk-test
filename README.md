
dd disk tests
=============

Focus at this time is on block writes, but reads are also reported.

What the tests do:

- create a test file
- read and write a test file with a specific 'block' size, and sync or asycn.
  - strace is used and must be enable for the the user

Then the `strace-breakdown.pl` script is used to get a breakdown of system calls.

A more appropriate name might be 'fs-test' for file system, though these tests could
be performed directly on disks with slight modifications..

### block-write-reports.sh

Generate reports for all files in `./trace`

### block-write-test.sh

Runs the block write tests via dd

```text
$ ./block-write-test.sh -h
ioType: async

  [ioType=(async|sync)] block-write-test.sh

  ioType: default is async
  blockSize: default is 8k

  examples:

 block-write-test.sh

 ioType=async block-write-test.sh

 ioType=sync block-write-test.sh

 blockSize=1M ioType=sync block-write-test.sh
```

### create-file.sh

Create the test file used for the tests.

### write-tests.sh

Calls `block-write-test.sh`  for several scenarios.

### strace-breakdown.pl

Print a report from an strace file


```text
$ ./strace-breakdown.pl trace/server-block-write-sync-8k-2025-05-28_13-33-28.strace

  Total Counted Time: 73.862959999957
  Total Elapsed Time: 90.6644258499146
Unaccounted for Time: 16.8014658499576

                      Call       Count          Elapsed                Min             Max          Avg ms
                 getrandom           1           0.000025         0.000025        0.000025        0.000025
                 fdatasync           1           0.000027         0.000027        0.000027        0.000027
                    access           1           0.000027         0.000027        0.000027        0.000027
                    munmap           1           0.000041         0.000041        0.000041        0.000041
                arch_prctl           2           0.000042         0.000021        0.000021        0.000021
                     lseek           2           0.000043         0.000021        0.000022        0.000022
                      dup2           2           0.000052         0.000025        0.000027        0.000026
              rt_sigaction           3           0.000062         0.000020        0.000021        0.000021
                       brk           4           0.000087         0.000021        0.000023        0.000022
                     fstat           4           0.000100         0.000021        0.000034        0.000025
                  mprotect           4           0.000116         0.000028        0.000031        0.000029
                      mmap           7           0.000217         0.000027        0.000040        0.000031
                     close           9           0.000339         0.000024        0.000119        0.000038
                      stat          19           0.000429         0.000022        0.000026        0.000023
                    execve           1           0.000562         0.000562        0.000562        0.000562
                    openat          31           0.115074         0.000031        0.113807        0.003712
                      read      131077           3.917788         0.000019        0.000108        0.000030
                     write      131256          69.827929         0.000031        0.016271        0.000532
```

## Histograms

Install the Histogram Perl package and scripts:

```
git clone https://github.com/jkstill/Histogram
perl Makefile.pl
sudo make install
```
### Examples

with default values

``` text
grep 'write(1'  trace/server-block-write-2025-05-17.strace | awk '{ print $NF }' | tr -d '<>' |  awk '{ printf "%d\n", 1e6 * $1 }' | data-histogram.pl --show-count

Metrics per '*':  1306.56
                             168:  99.7%  ****************************************************************************************************
                             336:   0.2%  240
                             504:   0.0%  31
                             672:   0.0%  37
                             840:   0.0%  19
                            1008:   0.0%  45
                            1176:   0.0%  7
                            1344:   0.0%  7
                            1512:   0.0%  12
                            1680:   0.0%  6
                            1848:   0.0%  3
                            2016:   0.0%  1
                            2184:   0.0%  1
                            2520:   0.0%  2
                            2856:   0.0%  1
                            3192:   0.0%  2
                            3360:   0.0%  1
                            3528:   0.0%  1


```

filter to values between 0 and 100
( looks a  bug in --upper-limit-val filter)

```text
grep 'write(1'  trace/server-block-write-2025-05-17.strace | awk '{ print $NF }' | tr -d '<>' |  awk '{ printf "%d\n", 1e6 * $1 }' | data-histogram.pl --show-count --upper-limit-op '<' --upper-limit-val 100 --lower-limit-op '>' --lower-limit-val 0
Metrics per '*':  369.40
                              24:   0.0%  10
                              28:   0.0%  21
                              32:   3.4%  ***********
                              36:  28.4%  ****************************************************************************************************
                              40:  27.1%  ***********************************************************************************************
                              44:  12.7%  ********************************************
                              48:   7.6%  **************************
                              52:   6.1%  *********************
                              56:   4.8%  ****************
                              60:   3.3%  ***********
                              64:   2.2%  *******
                              68:   1.5%  *****
                              72:   1.0%  ***
                              76:   0.6%  **
                              80:   0.5%  *
                              84:   0.3%  357
                              88:   0.2%  303
                              92:   0.2%  202
                              96:   0.1%  157
                             100:   0.1%  99


```

