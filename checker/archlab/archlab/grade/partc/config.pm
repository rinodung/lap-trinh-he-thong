######################################################################
# Configuration file for the Architecture Lab Part C autograders
#
# Copyright (c) 2002, R. Bryant and D. O'Hallaron, All rights reserved.
# May not be used, modified, or copied without permission.
######################################################################

# What is the name of this Lab?
$LABNAME = "archlabc";

# Where are the Y86-64 tools located?
# (override with -s)
$CODEDIR = "../../src";

# Where is the handin directory? 
# (override with -d)
$HANDINDIR = "./handin";

# What are the basenames of the handin files?
@PROGS = ("pipe-full.hcl", "ncopy.ys");

# Points available
$PERF_POINTS = 60;
