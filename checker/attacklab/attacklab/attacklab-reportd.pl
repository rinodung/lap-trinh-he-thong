#!/usr/bin/perl
#######################################################################
# attacklab-reportd.pl - Attack Lab reporting daemon
#
# Copyright (c) 2016, R. Bryant and D. O'Hallaron, All rights reserved.
#
# Repeatedly calls the validate.pl program to validate the most recent
# exploits for each student, and generate the scoreboard web page and
# the scores.csv file.
#
#######################################################################
use strict 'vars';
use Getopt::Std;

use lib ".";
use Attacklab;

$| = 1; # autoflush output on every print statement
$0 =~ s#.*/##s;  # Extract the base name from argv[0] 

##############
# Main routine
##############

# 
# Parse and check the command line arguments
#
no strict 'vars';
getopts('hq');
if ($opt_h) {
    usage("");
}

$Attacklab::QUIET = 0;
if ($opt_q) {
    $Attacklab::QUIET = 1;
}
use strict 'vars';

# Check that the autograder exists 
-e $Attacklab::UPDATE and -x $Attacklab::UPDATE
    or log_die("ERROR: Update script ($Attacklab::UPDATE) either missing or not executable\n");

#
# Repeatedly call the update script to validate the submissions,
# create a new scoreboard web page and scores file. 
#
while (1) {
    system("./$Attacklab::UPDATE") == 0
	or log_msg("Error: Update script ($Attacklab::UPDATE) failed: $!");
    
    sleep($Attacklab::UPDATE_PERIOD);
}

# Control never actually reaches here
exit;

#
# void usage - print help message and terminate
#
sub usage 
{
    printf STDERR "$_[0]\n";
    printf STDERR "Usage: $0 [-h]\n";
    printf STDERR "Options:\n";
    printf STDERR "  -h   Print this message.\n";
    printf STDERR "  -q   Quiet. Send error and status msgs to $Attacklab::STATUSLOG instead of tty.\n";
    die "\n" ;
}

