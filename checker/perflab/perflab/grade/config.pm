######################################################################
# Configuration file for the Performance Lab autograders
#
# Copyright (c) 2002, R. Bryant and D. O'Hallaron, All rights reserved.
# May not be used, modified, or copied without permission.
######################################################################

# What is the name of this Lab?
$LABNAME = "perflab";

# Where are the source files for the driver? 
# (override with -s to grade-perflab.pl and grade-handins.pl)
$SRCDIR = "../src";

# Where is the handin directory? 
# (override with -d to grade-handins.pl)
$HANDINDIR = "./handin";

#
# The instructor provides a scoring function for each kernel that
# returns the number of points as a function of the measured
# speedup $s. Here are the functions that we use at CMU:
#

#
# rotate_score - returns score for rotate() as a function of speedup s
# (used by grade-perflab.pl)
#
sub rotate_score {
    my $s = $_[0];

    if ($s <= 1.0) {             # s <= 1.0
	return 0.0;
    }
    elsif ($s <= 2.4) {          # 1.0 < s <= 2.4    
	return 40.0 * (($s-1.0) / (2.4-1.0));
    }
    elsif ($s <= 2.9) {          # 2.4 < s <= 2.9
	return 40.0 + 10.0 * (($s-2.4) / (2.9-2.4));
    }
    else {                       # s > 2.9
	return 50.0;
    }
}

#
# smooth_score - returns score for smooth as a function of speedup s
# (used by grade-perflab.pl)
#
sub smooth_score {
    my $s = $_[0];

    if ($s <= 1.0) {             # s <= 1.0
	return 0.0;
    }
    elsif ($s <= 6.2) {          # 1.0 < s <= 6.2    
	return 40.0 * (($s-1.0) / (6.2-1.0));
    }
    elsif ($s <= 7.3) {          # 6.2 < s <= 7.3
	return 40.0 + 10.0 * (($s-6.2) / (7.3-6.2));
    }
    else {                       # s > 7.3
	return 50.0;
    }
}


