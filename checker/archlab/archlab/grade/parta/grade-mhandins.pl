#!/usr/bin/perl 
use Getopt::Std;
use lib ".";
use config;

############################################################################
# grade-mhandins.pl - Autograding driver program for multiple handin files
#
# Copyright (c) 2002-2013, R. Bryant and D. O'Hallaron, All rights reserved.

# This program automatically runs an autograder on each file <prefix>* in a 
# <handin> directory, placing the resulting grade reports in the file 
# called <handin>.grades/<prefix>.out.
#
#  unix> ./grade-mhandins
# 
# Bugs:
# - Because the Unix system() call masks SIGINT signals, you can't 
#   always kill this program by typing ctrl-c. You have to
#   use kill -9 from another process to kill it.
#     
#########################################################################

# Autoflush output on every print statement
$| = 1; 

#
# usage - Print the help message and terminate
#
sub usage {
    printf STDERR "Usage: $0 [-he] [-d <directory>] [-s <srcdir>]\n";
    printf STDERR "Options:\n";
    printf STDERR "  -h             Print this message\n";
    printf STDERR "  -e             Don't include original handin file on the grade sheet\n";
    printf STDERR "  -d <handindir> Handin directory\n";
    printf STDERR "  -s <codedir>   Directory (abs path) with autograder test codes\n";
    die "\n";
}

##############
# Main routine
##############

$0 =~ s#.*/##s;                        # this prog's basename

#
# Parse the command line arguments
#
getopts('hed:s:');
if ($opt_h) {
    usage();
}

# Override defaults in config.pm
if ($opt_s) {
    $CODEDIR = $opt_s;
}
if ($opt_d) {
    $HANDINDIR = $opt_d;
}

# 
# Set the relative paths of the autograder and the output directory
# where the grade sheets should go.
#
$grader = "grade-$LABNAME.pl";      # autograder
$output_dir = "$HANDINDIR.grades";  # directory where output grade sheets go

# 
# Make sure the command line arguments are OK
#
-e $HANDINDIR
    or die "$0: ERROR: $HANDINDIR not found\n";
-d $HANDINDIR
    or die "$0: ERROR: $HANDINDIR is not a directory\n";
-e $grader 
    or die "$0: ERROR: $grader not found\n";
-x $grader 
    or die "$0: ERROR: $grader is not an executable program\n";

#
# Get the absolute path name of the grader and the output directory
#
$cwd = `pwd`;
chomp($cwd);
$grader_abs = "$cwd/$grader";
$output_dir_abs = "$cwd/$output_dir";

#
# Create the output directory.
#
system("rm -rf $output_dir_abs");
system("mkdir $output_dir_abs") == 0
    or die "$0: ERROR: Couldn't create the $output_dir directory\n";

#
# Get a sorted list of the files (except . and ..) in the handin directory
#
opendir(DIR, $HANDINDIR) 
    or die print "Couldn't open $HANDINDIR\n";
@files = grep(!/^\.\.?$/, readdir(DIR)); # elide . and .. from the list
@files = sort(@files);
closedir(DIR);


#
# Compute a unique set of file <prefix>'s in the handin directory,
# where each file has a name of the form <prefix>-<name>. Each
# student has a unique <prefix>, typically a unique userid.

@prefixes = @files;
for ($i=0; $i <= $#prefixes; $i++) {
  foreach $prog (@PROGS) {
    $prefixes[$i] =~ s/-$prog.*//;  # e.g., bovik-1-sum.ys becomes bovik-1
  }
}
%seen = ();
@unique = grep { ! $seen{$_}++} @prefixes; # compute unique set of prefixes

# By default we emit the student's src code on the grade sheet
# Override this default with the -e flag
$emitarg = "";
if ($opt_e) {
    $emitarg = "-e";
}

#
# Grade each each unique set of handins in the handin directory.  
#
foreach $prefix (@unique) {
    print "Grading $HANDINDIR/$prefix\n";
    system("$grader_abs $emitarg -f $HANDINDIR/$prefix -s $CODEDIR > $output_dir_abs/$prefix.out 2>&1") == 0 
	or print "$0: ERROR: Encountered some problem with $HANDINDIR/$prefix\nSee $output_dir/$prefix.out for details.\n";
}

print "$0: Finished\n";
exit;
