#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;

=head1 strace-breakdown.pl

 strace must have used the -ttt and -T options

 eg. strace -T [ -tt -ttt] -f ping -c1 google.com

 With -tt there is the possibility of error of the time rolls over past midnight

 It is also a good idea to use the -ff flag, as that will create a separate trace file per pid/thread

 If multiple PIDs/threads are in a single strace file, the results will be incorrect.


 reads from STDIN

=cut


=head2 example - create trace files for Swingbench SOE

=over 3

 This example will cause a lengthy wait on a Fast Object Checkpoint

 strace -f -ff -T -ttt -s 64 -o ko-foc.strace sqlplus -L -S soe/soe <<-EOF

        set timing off time off verify off echo off feed on term on
        alter session set tracefile_identifier = 'KO-CKPT';
        alter session set events '10046 trace name context forever, level 12';
        alter session set "_serial_direct_read" = true;

        select /*+ full(orders) */ count(*) sales_rep_count
        from orders
        where sales_rep_id is not null;

        alter session set events '10046 trace name context off';

        col value format a100
        select value from v\$diag_info where name = 'Default Trace File';

        exit

 EOF

=back

=cut

=head2 Profile a trace file

=over 3

 From the previoius strace example

 $  ./strace-breakdown.pl trace/ko-foc.strace.24555

  Total Counted Time: 1885.853326
  Total Elapsed Time: 1886.2954659462
 Unaccounted for Time: 0.442139946194857

                      Call       Count          Elapsed                Min             Max          Avg ms
                 setrlimit           1           0.000004         0.000004        0.000004        0.000004
                    gettid           1           0.000004         0.000004        0.000004        0.000004
           set_tid_address           1           0.000004         0.000004        0.000004        0.000004
           set_robust_list           1           0.000004         0.000004        0.000004        0.000004
                arch_prctl           1           0.000004         0.000004        0.000004        0.000004
         sched_getaffinity           1           0.000005         0.000005        0.000005        0.000005
               getsockname           1           0.000005         0.000005        0.000005        0.000005
                    statfs           1           0.000007         0.000007        0.000007        0.000007
             get_mempolicy           2           0.000008         0.000004        0.000004        0.000004
                     times           2           0.000008         0.000004        0.000004        0.000004
                    getcwd           2           0.000010         0.000005        0.000005        0.000005
                      pipe           2           0.000011         0.000005        0.000006        0.000005
                  recvfrom           3           0.000014         0.000004        0.000005        0.000005
                     ioctl           4           0.000019         0.000004        0.000005        0.000005
                   recvmsg           3           0.000020         0.000004        0.000010        0.000007
                setsockopt           2           0.000020         0.000005        0.000015        0.000010
                 getrlimit           5           0.000021         0.000004        0.000005        0.000004
                  sendmmsg           1           0.000022         0.000022        0.000022        0.000022
                      bind           2           0.000022         0.000006        0.000016        0.000011
                   getegid           6           0.000024         0.000004        0.000004        0.000004
                    getgid           6           0.000024         0.000004        0.000004        0.000004
                     lstat           5           0.000032         0.000005        0.000008        0.000006
                    sendto           2           0.000033         0.000013        0.000020        0.000017
                  getdents           6           0.000042         0.000004        0.000012        0.000007
                     fcntl          10           0.000044         0.000004        0.000005        0.000004
                     uname           8           0.000051         0.000004        0.000023        0.000006
            rt_sigprocmask           9           0.000051         0.000004        0.000017        0.000006
                   connect           6           0.000056         0.000006        0.000013        0.000009
                    openat           4           0.000062         0.000010        0.000022        0.000016
                   geteuid          20           0.000080         0.000004        0.000004        0.000004
                    access          16           0.000098         0.000004        0.000014        0.000006
                   getppid           7           0.000114         0.000004        0.000082        0.000016
                    socket           8           0.000121         0.000004        0.000045        0.000015
                    getuid          11           0.000125         0.000004        0.000084        0.000011
                      stat          26           0.000141         0.000004        0.000011        0.000005
              rt_sigaction          38           0.000178         0.000004        0.000026        0.000005
                     clone           2           0.000216         0.000065        0.000151        0.000108
                  mprotect          37           0.000291         0.000005        0.000028        0.000008
                     lseek          51           0.000428         0.000004        0.000082        0.000008
                       brk          32           0.000441         0.000003        0.000079        0.000014
                     write          55           0.000462         0.000005        0.000033        0.000008
                     fstat         111           0.000506         0.000004        0.000046        0.000005
                    munmap          89           0.000560         0.000005        0.000024        0.000006
                      poll           5           0.000708         0.000005        0.000359        0.000142
                      mmap         144           0.000861         0.000004        0.000029        0.000006
                     close         155           0.000896         0.000004        0.000078        0.000006
                      open         178           0.001298         0.000004        0.000059        0.000007
                 nanosleep          25           0.001889         0.000075        0.000080        0.000076
                    execve           1           0.080278         0.080278        0.080278        0.080278
                     futex           4           0.541153         0.000005        0.509961        0.135288
                      read         225        1885.221851         0.000004     1884.240770        8.378764

=back 

=cut

my $DEBUG=0;

my ($startTime, $endTime) = ('','');
my ($wallClockTime,$totalCountedTime)=(0,0);

use constant COUNT_IDX => 0;
use constant ELAPSED_IDX => 1;
use constant MIN_IDX => 2;
use constant MAX_IDX => 3;

=head2 %calls

=over 3

$calls { callName => [ count, elapsed, min, max ] }

=back

=cut

my %calls=();

# determine if the first field is a PID
# this occurs if -f is used on strace
# ignoring PID at this time if so

my $pidChk=1;
my $shiftPid=0;

my $timeFormat='';

while (<>) {

	#print;
	chomp;
	next if /<unfinished/;
	next unless /.*>$/;
	
	my @a=split(/\s+/);


	# different PIDs should be separated into different trace files with the strace -ff flag
	if ($pidChk) { 
		$pidChk=0;
		$shiftPid = 1 if $a[0] =~ /^[[:digit:]]{1,7}$/;
		#print "Shifting PID\n" if $shiftPid;
	}

	shift @a if $shiftPid;
	
	# determine if the time format ia hh:mm:ss.ffffff
	# or epoch.ffffff
	unless ( $timeFormat ) {
		if ( $a[0] =~ /[[:digit:]]{2}:[[:digit:]]{2}:[[:digit:]]{2}\.[[:digit:]]{6}/ ) { $timeFormat='ISO8601' }
		else { $timeFormat='epoch' }
	};

	if ( $timeFormat eq 'epoch') {
		$startTime = $a[0] unless $startTime;
		$endTime = $a[0];
	} else {
		#warn "Time Format: $timeFormat\n";
		$startTime = convtime($a[0]) unless $startTime;
		$endTime = convtime($a[0]);
		#warn "Start Time: $startTime\n";
		#warn "  End Time: $endTime\n";
	}

	my $syscall = $a[1];

	my $parenPos = index($syscall,'(');

	if ($parenPos > 0) {
		$syscall = substr($syscall,0,$parenPos);
	}

	#print "syscall: $syscall\n";

	my $elapsed = $a[$#a];
	$elapsed =~ s/[<>]//g;
	#print join(' - ', @a),"\n";
	#print "elapsed: $elapsed\n";

	$calls{$syscall}[COUNT_IDX]++;
	$calls{$syscall}[ELAPSED_IDX] += $elapsed;

	if ( defined( $calls{$syscall}[MIN_IDX] )) {
		if ( $elapsed < $calls{$syscall}[MIN_IDX] ) { $calls{$syscall}[MIN_IDX] = $elapsed }
	} else {
		$calls{$syscall}[MIN_IDX] = $elapsed ;
	}

	if ( defined( $calls{$syscall}[MAX_IDX] )) {
		if ( $elapsed > $calls{$syscall}[MAX_IDX] ) { $calls{$syscall}[MAX_IDX] = $elapsed }
	} else {
		$calls{$syscall}[MAX_IDX] = $elapsed ;
	}

	$totalCountedTime += $elapsed;
	
}

$wallClockTime = $endTime - $startTime;
my $unAccountedForTime = $wallClockTime - $totalCountedTime;


print qq{
       startTime: $startTime
         endTime: $endTime
totalCountedTime: $totalCountedTime
        wallTime: $wallClockTime

} if $DEBUG;

printf "\n  Total Counted Time: $totalCountedTime\n";
print "  Total Elapsed Time: $wallClockTime\n";
print "Unaccounted for Time: $unAccountedForTime\n\n";

printf qq{
  Total Counted Time:   %9.8f
  Total Elapsed Time:   %9.8f
  Unaccounted for Time: %9.8f\n\n},
	, $totalCountedTime
	, $wallClockTime
	, $unAccountedForTime if $DEBUG;

printf "      %20s %11s      %11s        %11s     %11s     %11s\n", 'Call',  'Count', 'Elapsed', 'Min', 'Max', 'Avg ms';


foreach my $syscall ( sort { $calls{$a}[1] <=> $calls{$b}[1] } keys %calls ) {

	printf "      %20s   %9d   %16.6f   %14.6f  %14.6f  %14.6f\n"
		, $syscall
		, $calls{$syscall}[COUNT_IDX]
		, $calls{$syscall}[ELAPSED_IDX]
		, $calls{$syscall}[MIN_IDX]
		, $calls{$syscall}[MAX_IDX]
		, $calls{$syscall}[ELAPSED_IDX] > 0 ? ($calls{$syscall}[ELAPSED_IDX] / $calls{$syscall}[COUNT_IDX]) : 0; # avg

}

# convert a timestamp such as  08:38:16.809792 to seconds.fractional-seconds
sub convtime {
	my ($hours, $minutes, $seconds) = split(/:/,$_[0]);
	return ($hours * 3600) + ($minutes * 60) + $seconds;
}


