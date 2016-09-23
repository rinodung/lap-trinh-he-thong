#!/usr/bin/perl

use Getopt::Std;

$troot = "../../targets";

getopts('hskf:n:');


if ($opt_h) {
    printf STDERR "Usage: $0 [-hsk] [-f FIRST] [-n CNT]\n";
    printf STDERR "  -s       Include solution information\n";
    printf STDERR "  -k       DON'T overwrite existing targets\n";
    printf STDERR "  -f FIRST First ID to use\n";
    printf STDERR "  -n CNT   Number of targets to generate\n";
    exit(0);
}

if ($opt_s) {
    $solvestr = "";
} else {
    $solvestr = "-S";
}

if ($opt_k) {
    $overwrite = 0;
} else {
    $overwrite = 1;
}

if ($opt_f) {
    $first = $opt_f;
} else {
    $first = 1;
}

if ($opt_n) {
    $count = $opt_n;
} else {
    $count = 10;
}

$bcount = 0;
$id = $first;

while ($bcount < $count) {
    $tdir = "$troot/target$id";
    if ($overwrite || !(-e $tdir)) {
	system "./buildtarget.pl -u User$id $solvestr -t $id" || die "Could not build target $id\n";
	$bcount += 1;
    }
    $id += 1;
}

print "Build $bcount targets\n";
