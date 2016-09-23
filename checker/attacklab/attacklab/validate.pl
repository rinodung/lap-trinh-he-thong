#!/usr/bin/perl
############################################################
#
# validate.pl - Called periodically by the attacklab-reportd.pl
#     daemon. Scans the submissions in log.txt. Validates the most
#     recent submission for each phase submitted by each user. Updates
#     the scoreboard, creates reports for each student in the reports/
#     directory, and generates the scores.txt file with the score for
#     each students.
#
# Usage: ./validate.pl
#
############################################################
use strict 'vars';
use Getopt::Std;
use Fcntl qw(:DEFAULT :flock);
use Cwd;

use Date::Parse;
use Date::Format;

use lib ".";
use Attacklab;

# Generic setting
$| = 1;      # Autoflush output on every print statement

# Manifest constants
my $MAX_LEVEL = 3;
my $MAX_PHASE = 5;
my $MAX_CTARGET_PHASE = 3;
my $MIN_RTARGET_LEVEL = 2;
my $MAX_STRLEN = 1024;
my @WEIGHT = (0, 10, 25, 25, 35, 5); # indexed starting at 1

# Parameters
my $silent_make = "-s";
my $redirect = "> /dev/null 2>&1";

# Use these settings while debugging
#my $silent_make = "";
#my $redirect = "";

# Structured data
my %users = ();    # Submissions for each user
my %rankings = (); # Info used to order the scoreboard page
my %row = ();      # Scoreboard row for each user
my @valid = ();    # Is phase i valid, i=1..5 

# Other variables used in main
my $logfile = $Attacklab::LOGFILE;
my $scorefile = $Attacklab::SCOREFILE;
my $webpage = $Attacklab::SCOREBOARDPAGE;
my $srcdir = "src";
my $builddir = "build";
my $reportfile;
my $total;
my $output;

my $username;
my $exploitfile;
my $targetid;
my $exploit;
my $program;
my $authkey;
my $level;
my $status;
my $i;
my $k;

# 
# Main program
#

# Read the submissions for each user into an array of the most recent
# solutions for each phase.
%users = read_logfile($logfile);

# Create the reports directory if necessary
if (! -e "reports") {
    system("mkdir reports") == 0 
        or log_die("Unable to make reports directory");
}
elsif (! -d "reports") {
    system("rm reports; mkdir reports") == 0
        or log_die("Unable to remake reports directory");
}

# Open the scores file for appending
if (!open(SCOREFILE, ">$scorefile")) {
    log_die "Could not open $scorefile for appending";
}

 
# Before changing to the src/build directory, get the absolute
# pathname of the original working directory.
my $owd = getcwd();

# Hack so that logging will work after we change to the src/build
# directory
$Attacklab::STATUSLOG = "$owd/$Attacklab::STATUSLOG";

# Prepare the src directory
chdir($srcdir)
    or log_die "Could not change directory to $srcdir.";
system ("make $silent_make clean; make $silent_make") == 0 
    or log_die "Couldn't make $srcdir";
chdir($builddir) 
    or log_die "Could not change directory to $builddir.";

# Validate each user's submissions
foreach $username (keys %users) {
    $reportfile = "$owd/reports/$username";
    system "rm -f $reportfile" == 0
        or log_die "Unable to remove $reportfile";

    if (!open(REPORTFILE, ">$reportfile")) {
        log_die "Could not open $reportfile for output";
        next;
    }

    # Print a summary of the user's most recent submissions 
    print REPORTFILE "Evaluating the most recent submissions for user $username:\n";
    foreach $i (1..$MAX_PHASE) { 
        print REPORTFILE "Phase $i: ";
        if ($users{$username}[$i]) {
            print REPORTFILE "$users{$username}[$i]{'time'}:";
            print REPORTFILE "$users{$username}[$i]{'targetid'}:";
            print REPORTFILE "$users{$username}[$i]{'program'}:";
            print REPORTFILE "$users{$username}[$i]{'level'}:";
            print REPORTFILE "$users{$username}[$i]{'exploit'}\n";
        }
        else {
            print REPORTFILE "No submission.\n";
        }
    }
    print REPORTFILE "\n";

    #
    # Validate each submission entry
    #
    foreach $i (1..$MAX_PHASE)  {
        $valid[$i] = 0;
        if ($users{$username}[$i]) {
            $targetid = $users{$username}[$i]{'targetid'};
            $exploit = $users{$username}[$i]{'exploit'};
            $program = $users{$username}[$i]{'program'};
            $authkey = $users{$username}[$i]{'authkey'};
            $level = $users{$username}[$i]{'level'};

            # Create the exploit file
            $exploitfile = "$program.l$level";
            open(OUTPUTFILE, ">$exploitfile")
                or log_die("Couldn't open $exploitfile for output: $|");
            print OUTPUTFILE "$exploit\n";
            close(OUTPUTFILE);

            # Run the checker
            print REPORTFILE "Validating exploit for phase $i.\n";

            # Run ctarget once
            if ($program eq "ctarget") {
                $status = system ("cat $exploitfile | ./hex2raw | ../../targets/target$targetid/ctarget-check -a $authkey -l $level > /tmp/out$$.txt 2>&1");
                $output = `cat /tmp/out$$.txt`;
                system("rm /tmp/out$$.txt");
                print REPORTFILE $output;
                if ($status == 0) {
                    $valid[$i] = 1;
                    print REPORTFILE "SUCCESS: Phase $i exploit is valid ($WEIGHT[$i])\n";
                }
                else {
                    $valid[$i] = 0;
                    print REPORTFILE "FAILURE: Phase $i exploit is invalid. (0)\n";
                }
                print REPORTFILE "\n";
            }

            # Run rtarget 
            else {
                $status = system ("cat $exploitfile | ./hex2raw | ../../targets/target$targetid/rtarget-check -a $authkey -l $level > /tmp/out$$.txt 2>&1");
                $output = `cat /tmp/out$$.txt`;
                system("rm /tmp/out$$.txt");
                print REPORTFILE $output;
                
                if ($status == 0) {
                    $valid[$i] = 1;
                    print REPORTFILE "SUCCESS: Phase $i exploit is valid ($WEIGHT[$i])\n";
                }
                else {
                    $valid[$i] = 0;
                    print REPORTFILE "FAILURE: Phase $i exploit is invalid (0)\n";
                    last;
                }
                print REPORTFILE "\n";
            }
        }
    }

    #
    # At this point we have validated each phase for this
    # user. Compute their score and append to the score file.
    #
    my $maxscore = $WEIGHT[1]+$WEIGHT[2]+$WEIGHT[3]+$WEIGHT[4]+$WEIGHT[5];
    my $score = 
        ($valid[1] * $WEIGHT[1]) +
        ($valid[2] * $WEIGHT[2]) +
        ($valid[3] * $WEIGHT[3]) +
        ($valid[4] * $WEIGHT[4]) +
        ($valid[5] * $WEIGHT[5]);
    print SCOREFILE "$username,$score\n";
    print REPORTFILE "\nScore: $score/$maxscore\n";

    # Get the time for the most recent submission
    my $maxtime = 0;
    my $maxdate = "";
    my $tmp;
    my $date;
    foreach $i (1..$MAX_PHASE) { 
        if ($users{$username}[$i]) {
            $date = $users{$username}[$i]{'time'};
            $tmp = date2time($date);
            if ($tmp > $maxtime) {
                $maxtime = $tmp;
                $maxdate = $date;
            }
        }
    }

    # Update the hash that will be used to sort submissions on the
    # scoreboard. Should really be a hash of hashes but I couldn't
    # figure out the the arcane sorting syntax for a hash of hashes.
    $rankings{$username}[0] = $score;
    $rankings{$username}[1] = $maxtime;

    # Save info that will needed to generate the scoreboard row for this user
    $row{$username}{'maxdate'} = $maxdate;
    $row{$username}{'targetid'} = $targetid;
    foreach $i (1..$MAX_PHASE) {
        $row{$username}{'valid'}[$i] = $valid[$i];
    }
}

#
# Generate the HTML scoreboard page. 
#

#
# Open and lock the output Web page
#
chdir($owd) 
    or log_die("Unable to cd back to $owd\n");
open(WEB, ">$webpage")
    or log_die("Unable to open $webpage: $!");
flock(WEB, LOCK_EX)
    or log_die("Unable to lock $webpage: $!");

#
# Emit the basic header information
#
print WEB "
<html>
<head>
<title>Attack Lab Scoreboard</title>
</head>
<body bgcolor=ffffff>

<table width=650><tr><td>
<h2>Attack Lab Scoreboard</h2>
<p>
Here is the latest information that we have received from your 
targets. 
</td></tr></table>
";

print WEB "Last updated: ", scalar localtime, 
   " (updated every $Attacklab::UPDATE_PERIOD secs)<br>\n";

print WEB "
<p>
<table border=0 cellspacing=1 cellpadding=1>
<tr bgcolor=$Attacklab::DARK_GREY align=center>
<th align=center width=40> <b>#</b></th>
<th align=center width=60> <b>Target</b></th>
<th align=center width=200> <b>Date</b></th>
<th align=center width=70> <b>Score</b></th>
<th align=center width=70> <b>Phase 1 </b></th>
<th align=center width=70> <b>Phase 2 </b></th>
<th align=center width=70> <b>Phase 3 </b></th>
<th align=center width=70> <b>Phase 4</b></th>
<th align=center width=70> <b>Phase 5</b></th>
</tr>
";

# 
# Sort each user by score (desc), then by time of last submission (asc)
#     rankings{$usename}[0] stores the total score
#     rankings{$username}[1] stores the time (in secs) of the latest submission
#
my $num_students = 0;
foreach $username (sort {$rankings{$b}[0] <=> $rankings{$a}[0] ||
                             $rankings{$a}[1] <=> $rankings{$b}[1] ||
                             $a <=> $b}
                   keys %rankings) {

    # Print a row in the scoreboard
    my $targetid = $row{$username}{'targetid'};
    my $date = $row{$username}{'maxdate'};
    my $score = $rankings{$username}[0];
    
    $num_students++;
    print WEB "<tr bgcolor=$Attacklab::LIGHT_GREY align=center>\n";
    print WEB "<td align=right>$num_students</td>\n";
    print WEB "<td align=right>$targetid</td>";
    print WEB "<td align=center>$date</td>";
    print WEB "<td align=right>$score</td>";

    foreach $i (1..$MAX_PHASE) { 
        print WEB "<td align=right>";
        if ($users{$username}[$i]) {
            if ($row{$username}{'valid'}[$i]) {
                print WEB "$WEIGHT[$i]</td>";
            }
            else {
                print WEB "<font color=red><b>invalid</b></font>";
            }
        }
        else {
            print WEB "0";
        }
        print WEB "</td>"
    }
    print WEB "</tr>\n";
}
print WEB "</table></body></html>\n";

close WEB;

exit 0;

#
# read_logfile - The logfile consists of the submissions from all
#     targets in the order they were submitted. Read the logfile and
#     create an hash entry for each user that consists of an array of
#     their most recent submissions for each phase. Return the user
#     hash to the caller.
#
sub read_logfile() {
    my $logfile = shift;

    # Array of most recent submission for each phase from this user
    my %users;
    my @entry; 

    # Misc
    my $phase;
    my $linenum;
    my $line;

    # Components of each log entry
    my $hostname;
    my $time;
    my $userid;
    my $course;
    my $targetid;
    my $status;
    my $authkey;
    my $program;
    my $level;
    my $exploitstr;

    open(LOGFILE, $logfile) or 
        log_die("Couldn't open logfile $logfile: $!");
    
    $linenum = 0;
    while ($line = <LOGFILE>) {
        $linenum++;
        chomp($line);

        # Skip blank lines
        if ($line eq "") {
            next;
        }

        # Parse the input line
        $line =~ /(.*)\|(.*)\|(.*)\|(.*)\|([0-9]*):(.*):(.*):(.*):([0-9]*):(.*)$/g;
        $hostname = $1;
        $time = $2;
        $userid = $3;
        $course = $4;
        $targetid = $5;
        $status = $6;
        $authkey = $7;
        $program = $8;
        $level = $9;
        $exploit = $10;	

        # Check the input line
        if (!$userid or !$course or !$targetid or !$status or !$authkey or !$program or !$level or !$exploit) {
            log_msg("Warning: Invalid line $linenum in $logfile.");
            next;
        }
        if ($status eq "FAIL") {
            next;
        }

        if (($program ne "ctarget") and ($program ne "rtarget")) {
            log_msg("Warning: Bad program name ($program) in line $linenum. Ignored.");
            next;
        }
        if (($level < 1) or ($level > $MAX_LEVEL)) {
            log_msg("Warning: Bad level ($level > $MAX_LEVEL) in line $linenum. Ignored.");
            next;
        }
        if (length($exploit) > $MAX_STRLEN) {
            log_msg("Warning: Input string too long in line $linenum. Ignored.");
            next;
        }
        if (($program eq "ctarget") and ($level > $MAX_CTARGET_PHASE)) {
            log_msg("Warning: [$userid:$linenum] ctarget invoked with invalid level ($level). Ignored.");
            next;
        }
        if (($program eq "rtarget") and ($level < $MIN_RTARGET_LEVEL)) {
            log_msg("Warning: [$userid:$linenum] rtarget invoked with invalid level ($level). Ignored.");
            next;
        }

        # Compute the offset into the submit array
        if ($program eq "ctarget") {
            $phase = $level;
        }
        else {
            $phase = $MAX_CTARGET_PHASE - 1 + $level;
        }

        # Add the submission to the array of phase entries
        $users{$userid}[$phase] = {time => $time, user => $userid, targetid => $targetid,
                          authkey => $authkey, program => $program, level => $level,
                          exploit => $exploit, valid => 0 };

    }
    
    close (LOGFILE);

    return %users;
}
