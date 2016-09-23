#!/usr/bin/perl
#######################################################################
# solve-all.pl - Generate solutions for all phases and store as files
#######################################################################
# 
# Assumes that solution information available in same directory as ctarget and rtarget
#

use Getopt::Std;

getopts('ht:d:s:');

if ($opt_h) {
    printf STDERR "Usage: $0 [-h] -t ID [-d DIR] [-s DIR]\n";
    printf STDERR "  -t ID     Specify target ID\n";
    printf STDERR "  -d DIR    Specify directory of target\n";
    printf STDERR "  -s DIR    Specify solve directory\n";
    exit(0);
}

if ($opt_t) {
    $id = $opt_t;
} else {
    printf STDERR "Must specify target ID\n";
    exit(1);
}

if ($opt_d) {
    $targetdir = $opt_d;
} else {
    $targetdir = "../../targets/target$id";
}

if ($opt_s) {
    $solvedir = $opt_s;
} else {
    $solvedir = ".";
}

system "$solvedir/solver.pl -l 1 -t $id -d $targetdir -s $solvedir > $targetdir/ctarget.l1"
    || die "Couldn't generate ctarget.l1";

system "$solvedir/solver.pl -l 2 -t $id -d $targetdir -s $solvedir > $targetdir/ctarget.l2"
    || die "Couldn't generate ctarget.l2";

system "$solvedir/solver.pl -l 3 -t $id -d $targetdir -s $solvedir > $targetdir/ctarget.l3"
    || die "Couldn't generate ctarget.l3";

system "$solvedir/solver.pl -r -l 2 -t $id -d $targetdir -s $solvedir > $targetdir/rtarget.l2"
    || die "Couldn't generate rtarget.l2";

system "$solvedir/solver.pl -r -l 3 -t $id -d $targetdir -s $solvedir > $targetdir/rtarget.l3"
    || die "Couldn't generate rtarget.l3";


