#!/usr/bin/perl 
#######################################################################
# readd.pl - Read useful information from disassembly files
#######################################################################

# Warning:
# When extracting range of bytes, make sure all functions are within one section (e.g., .text).

use Getopt::Std;

@funs = ();
$dobytes = 0;
$start_name = "";
$finish_name = "";

$disassemble_all = 0;
$found_start = 0;
$found_end = 0;

getopts('haf:b:');

if ($opt_h) {
    printf STDERR "Usage: $0 [-ha] [-f NAMELIST] [-b SFUN:LASTFUN] < program.d \n";
    printf STDERR "  -a            Show disassembly for all bytes\n";
    printf STDERR "  -f NAMELIST   Find start address for functions\n";
    printf STDERR "     (NAMELIST is colon-separated)\n";
    printf STDERR "  -b SFUN:LFUN  List range of bytes between starting and ending functions\n";
    exit(0);
}

if ($opt_f) {
    @funs = split ":", $opt_f;
}

if ($opt_b) {
    ($start_fun, $last_fun) = split ":", $opt_b;
}


if ($opt_a) {
    $disassemble_all = 1;
}

while (<>) {
    $line = $_;
    chomp($line);

    for $fun (@funs) {
	if ($line =~ m/<$fun>:/) {
	    $line =~ m/([0-9a-f]+)/;
	    $addr = $1;
	    print "$fun:$addr:\n";
	}
    }
    @fields = split "\t", $line;
    # Have observed that lines with code have at least two tab-separated fields.
    $fcnt = scalar(@fields);
    if (($disassemble_all || $found_start && !$found_end) && $fcnt >= 2) {
	$digs = $fields[1];
	my @bytes = split(/\W/, $digs);
	my $bytecount = scalar(@bytes);
	for (my $j = 0; $j < $bytecount; $j++)	{
	    my $byte = $bytes[$j];
	    if ($byte =~ m/[0-9a-f][0-9a-f]/) {
		print "$byte ";
	    }
	}
    } elsif ($line =~ m/<$start_fun>:/) {
	$found_start = 1;
	$line =~ m/([0-9a-f]+)/;
	$addr = $1;

	if (!$disassemble_all) {
	    print "$start_fun:$addr:";
	}
    } elsif ($line =~ m/<$last_fun>:/) {
	$found_end = 1;
	print "\n";
    }

}
