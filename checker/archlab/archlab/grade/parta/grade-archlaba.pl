#!/usr/bin/perl   
use Getopt::Std;
use lib ".";
use config;

#########################################################################
# grade-archlaba.pl - Architecture Lab Part A autograder
#
# Copyright (c) 2002-2015, R. Bryant and D. O'Hallaron, All rights reserved.
#########################################################################

# autoflush output on every print statement
$| = 1; 

# Any tmp files created by this script are readable only by the user
umask(0077); 

#
# usage - print help message and terminate
#
sub usage {
    printf STDERR "$_[0]\n";
    printf STDERR "Usage: $0 -f <file> [-he] [-s <codedir>]\n";
    printf STDERR "Options:\n";
    printf STDERR "  -h           Print this message.\n";
    printf STDERR "  -e           Don't include original handin file on the grade sheet\n";
    printf STDERR "  -f <file>    Prefix of handin files to be graded\n";
    printf STDERR "  -s <codedir> Directory where the Y86-64 tools are located\n";
    die "\n";
}

##############
# Main routine
##############

my @parta_scores = (0, 0, 0);
my $aok = 1;

# 
# Parse the command line arguments
#
getopts('hef:s:');
if ($opt_h) {
    usage();
}
if (!$opt_f) {
    usage("Missing required argument (-f)");
}

# 
# These optional flags override defaults in config.pm
#
if ($opt_s) {         # simulator directory
    $CODEDIR = $opt_s;
}

# 
# Initialize some file and path names
#
$infile = $opt_f;
($infile_basename = $infile) =~ s#.*/##s;     # basename of input files
$tmpdir = "/tmp/$infile_basename.$$";         # scratch directory
$0 =~ s#.*/##s;                               # this prog's basename

# absolute pathname of src directory
$simdir_abs = `cd $CODEDIR; pwd`; 
chomp($simdir_abs);

# 
# This is a message we use in several places when the program dies
#
$diemsg = "The files are in $tmpdir.";

# 
# Make sure the yis and yas binaries exist
#
(-e "$simdir_abs/misc/yas" and -x "$simdir_abs/misc/yas")
    or warn "$0: ERROR: Can't access $simdir_abs/misc/yas.\n";
(-e "$simdir_abs/misc/yis" and -x "$simdir_abs/misc/yis")
    or warn "$0: ERROR: Can't access $simdir_abs/misc/yis.\n";

# 
# Set up the contents of the scratch directory
#
system("mkdir $tmpdir") == 0
  or warn "ERROR: mkdir $tmpdir failed\n";
foreach $prog (@PROGS) {
    $prefix = "$infile-$prog";
    system("cp $prefix.ys $tmpdir/$prog.ys") == 0
	or warn "ERROR: cp $prefix.ys to $tmpdir failed\n";
}

# Print header
print "\nCS:APP Architecture Lab Part A: Grading Sheet for $infile_basename\n\n";

#
# Compile and run each example program
# 
#
$partnum = 0;

foreach $prog (@PROGS) {
    $prefix = "$prog";
    print "***************\n";
    print "Problem $partnum: $prefix.ys\n";
    print "***************\n";

    # Compile
    print "Running yas $prefix.ys...\n";
    if (system("(cd $tmpdir; $simdir_abs/misc/yas $prefix.ys)") != 0) { 
	warn "$0: ERROR: Unable to compile $prefix.ys. $diemsg\n\n";
	$partnum++;
	$aok = 0;
	next;
    }

    # Run
    print "Running yis $prefix.yo...\n";
    if (system("(cd $tmpdir; $simdir_abs/misc/yis $prefix.yo > $prefix.out)") != 0) { 
	warn "$0: ERROR: Unable to simulate $prefix.yo. $diemsg\n\n";
	$partnum++;
	$aok = 0;
	next;
    }

    if (system("(cd $tmpdir; cat $prefix.out)") != 0) {
	warn "$0: ERROR: Unable to print $prefix.out. $diemsg\n\n";
	$partnum++;
	$aok = 0;
	next;
    }

    # Assign score
    $line = `(cd $tmpdir; cat $prefix.out | fgrep '%rax')`;
    chomp($line);
    ($reg, $before, $after) = split( /\s+/, $line);
    if ($after eq "0x0000000000000cba") {
	$parta_scores[$partnum] = $POINTS_PER_PROBLEM;
    }
    print "\nScore: $parta_scores[$partnum]/$POINTS_PER_PROBLEM\n";
    print "\n";
    $partnum++;
}

#
# Summarize scores
#
print "PARTA_SCORES = $parta_scores[0]:$parta_scores[1]:$parta_scores[2]\n";


#
# Optionally emit the handin files
#
if (!$opt_e) {
    foreach $prog (@PROGS) {
	print "\n\f\n";
	print "**********\n";
	print "$prog.ys\n";
	print "**********\n";
	system("(cd $tmpdir; cat $prog.ys)") == 0 
	    or warn "$0: ERROR: Unable to emit $prog.ys. $diemsg\n";
    }
}

#
# If everything went OK, then remove the scratch directory
#
system("rm -fr $tmpdir") if $aok;

exit;


