#!/usr/bin/perl   
use Getopt::Std;
use lib ".";
use config;

#########################################################################
# grade-archlabc.pl - Architecture Lab Part C autograder
# 
# Prints a grade sheet for one student's handin.
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
    printf STDERR "  -f <file>    Prefix of handin files to be graded (e.g., bovik-1)\n";
    printf STDERR "  -s <codedir> Directory where Y86-64 simulators are located\n";
    die "\n";
}

##############
# Main routine
##############
my @partc_scores = (0);
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
if ($opt_s) {  # simulator code directory
    $CODEDIR = $opt_s;
}

# 
# Initialize some file and path names
#
$infile = $opt_f;   # This is really the root name of the set of handins
($infile_basename = $infile) =~ s#.*/##s;     # basename of input files
$tmpdir = "/tmp/$infile_basename.$$";         # scratch directory
$0 =~ s#.*/##s;                               # this prog's basename

# absolute pathname of code directory
$codedir_abs = `cd $CODEDIR; pwd`; 
chomp($codedir_abs);

# 
# This is a message we use in several places when the program dies
#
$diemsg = "The files are in $tmpdir.";

# 
# Make sure the code directory and the psim binary exist
#
(-e $codedir_abs and -x $codedir_abs)
    or  die "$0: ERROR: Can't access $codedir_abs.\n";
(-e "$codedir_abs/pipe/psim" and -x "$codedir_abs/pipe/psim")
    or  die "$0: ERROR: Can't access $codedir_abs/pipe/psim.\n";

# 
# Make sure the input files exist and are readable
#
open(INFILE, "$infile-pipe-full.hcl") 
    or die "$0: ERROR: could not open file $infile-pipe-full.hcl\n";
close(INFILE);
open(INFILE, "$infile-ncopy.ys") 
    or die "$0: ERROR: could not open file $infile-ncopy.ys\n";
close(INFILE);

# 
# Set up the contents of a scratch directory with a student
# distribution of the Y86-64 tools
#
system("mkdir $tmpdir") == 0
  or die "ERROR: mkdir $tmpdir failed\n";
system("(cd $codedir_abs; make -s DISTDIR=$tmpdir/sim dist > /dev/null 2>&1)") == 0
  or die "ERROR: Could not create Y86-64 tools in $tmpdir/sim\n";
system("(cd $tmpdir/sim; make -s clean; make -s  > /dev/null 2>&1)") == 0
  or die "ERROR: Could not make baseline simulator\n";


# Print grade sheet header
print "\nCS:APP Architecture Lab Part C: Grading Sheet for $infile_basename\n\n";

#
# Build the student's simulator and copy the student's ncopy.ys file
# 
print "Part 1: Building simulator\n\n";
system("(cp $infile-pipe-full.hcl $tmpdir/sim/pipe/pipe-full.hcl)") == 0
  or die "ERROR: Could not copy HCL file\n";
system("(cd $tmpdir/sim/pipe; make -s clean; make VERSION=full psim)") == 0
  or die "ERROR: Could not make simulator\n";

system("(cp $infile-ncopy.ys $tmpdir/sim/pipe/ncopy.ys)") == 0
  or die "ERROR: Could not input file\n";

#
# Run benchmark regression tests on psim
#
print "\n";
print "**********\n";
print "Part 2: Benchmark regression tests on psim\n";
print "**********\n";
if (system("(cd $tmpdir/sim/y86-code; make testpsim > outfile 2>&1)") != 0) {
    $aok = 0;
    warn "ERROR: Could not run benchmark regression tests\n";
}
$outfile = `cat $tmpdir/sim/y86-code/outfile`;
print "$outfile";

# Count the number of successfull regression tests
$succeed = 0;
$total = 0;
while ($outfile =~ m/Succeed/g) {
    $succeed++;
    $total++;
}
while ($outfile =~ m/Fails/g) {
    $total++;
}

# Remember if there were any failed tests
print "\n";
print "Passed $succeed/$total benchmark regression tests\n";
if ($succeed != $total) {
    $aok = 0;
}

#
# Run extensive regression tests on simulator
#
print "\n";
print "**********\n";
print "Part 3: Extensive regression tests\n";
print "**********\n";
system("(cd $tmpdir/sim/ptest; make SIM=../pipe/psim TFLAGS=  > outfile 2>&1)") == 0
  or die "ERROR: Could not run extensive regression tests\n";
$outfile = `cat $tmpdir/sim/ptest/outfile`;
print "$outfile";

# Count the number of sucessfull regression tests
$succeed = 0;
$total = 0;
while ($outfile =~ m/All (\d+) ISA Checks Succeed/g) {
    $succeed += $1;
    $total += $1;
}
while ($outfile =~ m/(\d+)\/(\d+) ISA Checks Failed/g) {
    $succeed += ($2 - $1);
    $total += $2;
}

# Remember if there were any failed tests
print "\n";
print "Passed $succeed/$total extensive regression tests\n";
if ($succeed != $total) {
    $aok = 0;
}

#
# Run correctness tests on the student's ncopy.ys program using yis
#
print "\n";
print "**********\n";
print "Part 4: Correctness of ncopy program running on ISA simulator\n";
print "**********\n";
system("(cd $tmpdir/sim/pipe; ./correctness.pl -f ncopy.ys > outfile 2>&1)") == 0
  or die "ERROR: Could not run ncopy correctness tests\n";
$outfile = `cat $tmpdir/sim/pipe/outfile`;
print "$outfile";

# Count the number of successfull array sizes
$outfile =~ m/(\d+)\/(\d+) pass correctness test/;
$succeed = $1;
$total = $2;

# Remember if there were any failed tests
if ($succeed != $total) {
    $aok = 0;
}

#
# Run correctness tests on the student's ncopy.ys program using
# pipelined simulator
#
print "\n";
print "**********\n";
print "Part 5: Correctness of ncopy program running on pipeline simulator\n";
print "**********\n";
system("(cd $tmpdir/sim/pipe; ./correctness.pl -p -f ncopy.ys  > outfile 2>&1)") == 0
  or die "ERROR: Could not run ncopy correctness tests on pipeline simulator\n";
$outfile = `cat $tmpdir/sim/pipe/outfile`;
print "$outfile";

# Count the number of successfull array sizes
$outfile =~ m/(\d+)\/(\d+) pass correctness test/;
$succeed = $1;
$total = $2;

# Remember if there were any failed tests
if ($succeed != $total) {
    $aok = 0;
}

#
# Run performance tests on the student's ncopy.ys program
#
print "\n";
print "**********\n";
print "Part 6: Performance test\n";
print "**********\n";
system("(cd $tmpdir/sim/pipe; ./benchmark.pl -f ncopy.ys  > outfile 2>&1)") == 0
  or die "ERROR: Could not run ncopy performance tests\n";
$outfile = `cat $tmpdir/sim/pipe/outfile`;
print "$outfile";

# Extract score (in float format) from the benchmark.pl output
$outfile =~ m/Score\t(\d+.\d+)\/(\d+.\d+)/;
$score = $1;
$total = $2;

# Zero the performance score if there were any correctness issues
if ($aok) {
    $partc_scores[0] = $score;
}
else {
    print "\nNote: Performance score will be zero because of previous correctness issues\n"
}

#
# Summarize scores
#
print "\n";
print "PARTC_SCORES = $partc_scores[0]\n";

# 
# Optionally print the original handin files 
#
if (!$opt_e) {
    print "\f\nPart 7: Handin file $infile_basename-ncopy.ys\n\n";
    system("cat $infile-ncopy.ys");

    print "\f\nPart 8: Handin file $infile_basename-pipe-full.hcl\n\n";
    system("cat $infile-pipe-full.hcl");
} 

#
# Everything went OK, so remove the scratch directory
#
system("rm -fr $tmpdir");

exit;


