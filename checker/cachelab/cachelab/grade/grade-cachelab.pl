#!/usr/bin/perl   
#!/usr/local/bin/perl 
use Getopt::Std;
use config;

#########################################################################
# grade-cachelab.pl - Cache Lab autograder
#
# Copyright (c) 2013, R. Bryant and D. O'Hallaron, All rights reserved.
#########################################################################

# autoflush output on every print statement
$| = 1; 

# Any tmp files created by this script are readable only by the user
umask(0077); 

#
# These are the src files we need to compile the driver (besides the handin files). 
# Look for them in $SRCDIR,  which is set by default in config.pm 
# and can be altered with -s.
#
$driverfiles = "Makefile,driver.py,cachelab.c,cachelab.h,csim-ref.c,test-csim.c,test-trans.c,tracegen.c,traces";

#
# usage - print help message and terminate
#
sub usage {
    printf STDERR "$_[0]\n";
    printf STDERR "Usage: $0 -f <file> [-he] [-s <srcdir>]\n";
    printf STDERR "Options:\n";
    printf STDERR "  -h          Print this message.\n";
    printf STDERR "  -e          Don't include original handin files on the grade sheet\n";
    printf STDERR "  -f <file>   Name of handin tar file to be graded\n";
    printf STDERR "  -s <srcdir> Directory where driver source code is located\n";
    die "\n";
}

##############
# Main routine
##############

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
if ($opt_s) {         # driver src directory
    $SRCDIR = $opt_s;
}

# 
# Initialize some file and path names
#
$infile = $opt_f;
($infile_basename = $infile) =~ s#.*/##s;     # basename of input file
$tmpdir = "/tmp/$infile_basename.$$";         # scratch directory
$0 =~ s#.*/##s;                               # this prog's basename

# 
# This is a message we use in several places when the program dies
#
$diemsg = "The files are in $tmpdir.";

# 
# Make sure the driver src directory exists
#
(-d $SRCDIR and -e $SRCDIR)
    or  die "$0: ERROR: Can't access source directory $SRCDIR.\n";

# 
# Make sure the input file exists and is readable
#
open(INFILE, $infile) 
    or die "$0: ERROR: could not open file $infile\n";
close(INFILE);

# 
# Set up the contents of the scratch directory
#
system("mkdir $tmpdir");
system("cp $infile $tmpdir/handin.tar");
system("cp -rp $SRCDIR/\{$driverfiles\} $tmpdir");

#
# Expand the handin tar file into csim.c and trans.c
#
system("(cd $tmpdir; tar xf handin.tar)") == 0 
    or die "$0: ERROR: Unable to expand the handin.tar file. $diemsg\n";
(-e "$tmpdir/csim.c")
    or  die "$0: ERROR: csim.c not found in handin tar file. $diemsg\n";
(-e "$tmpdir/trans.c")
    or  die "$0: ERROR: trans.c not found in handin tar file. $diemsg\n";

# Print header
print "\nCS:APP Cache Lab: Grading Sheet for $infile_basename\n\n";

#
# Compile the testing framework
#
print "Part 1: Compiling test framework\n\n";
system("(cd $tmpdir; make)") == 0 
    or die "$0: ERROR: Unable to compile test framework. $diemsg\n";

#
# Run the driver and extract the results from the output 
#
print "\n\nPart 2: Running the driver\n\n";
system("(cd $tmpdir; ./driver.py -A > results.txt)") == 0 
    or die "$0: ERROR: Unable to run driver program. $diemsg\n";

$result = `(cd $tmpdir; cat results.txt)`;
$result =~ /AUTORESULT_STRING=(.*):(.*):(.*):(.*)/;
$score = $1;

print $result;

#
# Print the grade summary
#
print "\n\nPart 3: Grade\n\n";
print "\n";
printf "Score : %2.1f / $MAXSCORE\n", $score;

# 
# Optionally print the original handin file 
#
if (!$opt_e) {
    print "\f\nPart 4: Handin files for $infile_basename\n\n";
    print "\n*** csim.c ***\n";
    system("cat $tmpdir/csim.c");
    print "\n*** trans.c ***\n";
    system("cat $tmpdir/trans.c");
} 

#
# Everything went OK, so remove the scratch directory
#
system("rm -fr $tmpdir");

exit;


