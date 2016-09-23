#!/usr/bin/perl 
#######################################################################
# offset.pl - Compute offset used by getbuf function in attack target
#######################################################################

use Getopt::Std;

$tbinary = "ctarget";

getopts('hb:');

if ($opt_h) {
    printf STDERR "Usage: $0 [-h] [-b BINARY]\n";
    printf STDERR "  -b BINARY   target binary\n";
    exit(0);
}

if ($opt_b) {
    $tbinary = $opt_b;
}

$gdbfile = "target.gdb";

open(GDB, ">$gdbfile") || die "Can't open GDB file $gdbfile\n";

print GDB <<GDBSTUFF;
break getbuf
run -q
print /x \$rsp
stepi
print /x \$rsp
quit
GDBSTUFF

close GDB;

$gdbout = `gdb -nw -q $tbinary -x $gdbfile | grep "[0-9] = \"`
    || die "Couldn't run gdb on $tbinary with batch file $gdbfile\n";

$gdbout =~ s/\$[0-9]* = //g;
$gdbout =~ s/<[\w+]*>//g;

system "rm -f $gdbfile" || die "Couldn't delete file $gdbfile\n";

($init_stack,$new_stack) = split "\n", $gdbout;

$diff = hex($init_stack) - hex($new_stack);

print "stack:$new_stack\n";
print "offset:$diff\n";
