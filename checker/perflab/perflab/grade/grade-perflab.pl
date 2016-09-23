#!/usr/bin/perl   
#!/usr/local/bin/perl 
use Getopt::Std;
use config;

#########################################################################
# grade-perflab.pl - Performance Lab autograder
#
# Copyright (c) 2002, R. Bryant and D. O'Hallaron, All rights reserved.
# May not be used, modified, or copied without permission.
#########################################################################

# autoflush output on every print statement
$| = 1; 

# Any tmp files created by this script are readable only by the user
umask(0077); 

#
# These are the src files we need to compile the driver (besides kernels.c). 
# Look for them in $SRCDIR,  which is set by default in config.pm 
# and can be altered with -s.
#
$driverfiles = "Makefile,driver.c,config.h,defs.h,fcyc.c,fcyc.h,clock.c,clock.h";

#
# usage - print help message and terminate
#
sub usage {
    printf STDERR "$_[0]\n";
    printf STDERR "Usage: $0 -f <file> [-he] [-s <srcdir>]\n";
    printf STDERR "Options:\n";
    printf STDERR "  -h          Print this message.\n";
    printf STDERR "  -e          Don't include original handin file on the grade sheet\n";
    printf STDERR "  -f <file>   Name of handin file to be graded\n";
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
system("cp $infile $tmpdir/kernels.c");
system("cp $SRCDIR/\{$driverfiles\} $tmpdir");

# Print header
print "\nCS:APP Performance Lab: Grading Sheet for $infile_basename\n\n";

#
# Compile the driver
#
print "Part 1: Compiling the driver\n\n";
system("(cd $tmpdir; make)") == 0 
    or die "$0: ERROR: Unable to compile driver program. $diemsg\n";


#
# Run the driver and extract the speedups from the output 
#
print "\n\nPart 2: Running the driver with the -g autograder option\n\n";
system("(cd $tmpdir; ./driver -g > results.txt)") == 0 
    or die "$0: ERROR: Unable to run driver program. $diemsg\n";

$result = `(cd $tmpdir; cat results.txt)`;
$result =~ /bestscores:(.*):(.*):/;
$rotate_speedup = $1;
$smooth_speedup = $2;

print $result;

#
# Compute the number of points for each solution
#
$rotate_points = rotate_score($rotate_speedup);
$smooth_points = smooth_score($smooth_speedup);

#
# Print the grade summary
#
print "\n\nPart 3: Grade\n\n";
printf "Rotate: %3.0f /  50\n", $rotate_points; 
printf "Smooth: %3.0f /  50\n", $smooth_points;
print "\n";
printf "Total : %3.0f / 100\n", $rotate_points + $smooth_points;

# 
# Optionally print the original handin file 
#
if (!$opt_e) {
    print "\f\nPart 4: Handin file $infile_basename\n\n";
    system("cat $infile");
} 

#
# Everything went OK, so remove the scratch directory
#
system("rm -fr $tmpdir");

exit;


