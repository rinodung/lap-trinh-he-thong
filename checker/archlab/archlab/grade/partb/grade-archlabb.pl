#!/usr/bin/perl   
use Getopt::Std;
use lib ".";
use config;

#########################################################################
# grade-archlabb.pl - Architecture Lab Part B autograder
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
    printf STDERR "  -f <file>    HCL file to be graded\n";
    printf STDERR "  -s <codedir> Directory where Y86-64 simulators are located\n";
    die "\n";
}

##############
# Main routine
##############
my @partb_scores = (0, 0, 0);
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
if ($opt_s) {         # simulator code directory
    $CODEDIR = $opt_s;
}

# 
# Initialize some file and path names
#
$infile = $opt_f;
($infile_basename = $infile) =~ s#.*/##s;     # basename of input files
$0 =~ s#.*/##s;                               # this prog's basename

# location of the temporary student distribution
$tmpdir = "/tmp/sim.$$";      

# absolute pathname of code directory
$codedir_abs = `cd $CODEDIR; pwd`; 
chomp($codedir_abs);

# 
# This is a message we use in several places when the program dies
#
$diemsg = "The files are in $tmpdir.";

# 
# Make sure the Y86-64 tools directory and the sssim binary exists
#
(-e $codedir_abs and -x $codedir_abs)
    or die "$0: ERROR: Can't access $codedir_abs.\n";
(-e "$codedir_abs/seq/ssim" and -x "$codedir_abs/seq/ssim")
    or die "$0: ERROR: Can't access $codedir_abs/seq/ssim\n";

# 
# Set up the contents of a scratch directory with a student
# distribution of the Y86-64 tools
#
system("mkdir $tmpdir") == 0
  or die "ERROR: mkdir $tmpdir failed\n";
system("(cd $codedir_abs; make -s DISTDIR=$tmpdir/sim dist > /dev/null 2>&1)") == 0
  or die "ERROR: Could not create Y86-64 tools in $tmpdir/sim\n";
system("(cd $tmpdir/sim; make -s clean; make -s > /dev/null 2>&1 )") == 0
  or die "ERROR: Could not make baseline simulator\n";

# Make sure the input file exists and is readable
open(INFILE, $infile)
    or die "$0: ERROR: Could not open $infile\n";
close(INFILE);

# Print grade sheet header
print "\nCS:APP Architecture Lab Part B: Grading Sheet for $infile_basename\n\n";

#
# Compile the HCL file and link into the simulator
# 
print "**********\n";
print "Part 1: Compiling simulator using $infile...\n";
print "**********\n";

system("rm -f $tmpdir/sim/seq/seq-full.hcl") == 0
    or warn "ERROR: Could not remove $tmpdir/sim/seq/seq-full.hcl\n";
system("cp $infile $tmpdir/sim/seq/seq-full.hcl") == 0
    or warn "ERROR: Could not copy input file $infile\n";
system("(cd $tmpdir/sim/seq; make -s clean; make VERSION=full ssim)") == 0
    or warn "ERROR: Could not make simulator\n";

#
# Run benchmark regression tests
#
print "\n";
print "**********\n";
print "Part 2: Benchmark regression tests\n";
print "**********\n";
if (system("(cd $tmpdir/sim/y86-code; make testssim > outfile 2>&1)") != 0) {
    $aok = 0;
    warn "ERROR: Could not run benchmark regression tests\n";
}
$outfile = `cat $tmpdir/sim/y86-code/outfile`;
print "$outfile";

# Count the number of sucessful regression tests
$succeed = 0;
$total = 0;
while ($outfile =~ m/Succeed/g) {
    $succeed++;
    $total++;
}
while ($outfile =~ m/Fails/g) {
    $total++;
}

# Display the score
print "\n";
print "Passed $succeed/$total benchmark regression tests\n";
if ($succeed == $total) {
    $partb_scores[0] = $REGRESSION_POINTS;
}    
print "Score: $partb_scores[0]/$REGRESSION_POINTS\n";

#
# Run synthetic regression tests for iaddq
#
print "\n";
print "**********\n";
print "Part 3: Extensive regression tests for iaddq\n";
print "**********\n";
system("(cd $tmpdir/sim/ptest; make SIM=../seq/ssim TFLAGS=-i  > outfile 2>&1)") == 0
  or die "ERROR: Could not run extensive regression tests for iaddq. The files are in $tmpdir.\n";
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

# Display the score
print "\n";
print "Passed $succeed/$total tests\n";
if ($succeed == $total) {
    $partb_scores[1] = $IADDQ_POINTS;
}    
print "Score: $partb_scores[1]/$IADDQ_POINTS\n";


#
# Run extensive regression tests for leave
#
print "\n";
print "**********\n";
print "Part 4: extensive regression tests for leave\n";
print "**********\n";
system("(cd $tmpdir/sim/ptest; rm -f outfile; make SIM=../seq/ssim TFLAGS=-l  > outfile 2>&1)") == 0
  or die "ERROR: Could not run extensive regression tests for leave\n";

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

# Display the score
print "\n";
print "Passed $succeed/$total tests\n";
if ($succeed == $total) {
    $partb_scores[2] = $LEAVE_POINTS;
}    
print "Score: $partb_scores[2]/$LEAVE_POINTS\n";


#
# Summarize scores
#
print "\n";
print "PARTB_SCORES = $partb_scores[0]:$partb_scores[1]:$partb_scores[2]\n";

# 
# Optionally print the original handin file 
#
if (!$opt_e) {
    print "\n\f\nPart 5: Handin file $infile_basename\n\n";
    system("cat $infile");
} 

#
# If everything went OK, then remove the scratch directory
#
system("rm -fr $tmpdir") if $aok;

exit;


