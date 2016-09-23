#!/usr/bin/perl 
#######################################################################
# reval.pl - Decode ROP attack submissions
#######################################################################

# Names of functions that define target ranges
$first_fun = "_init";
$start_farm = "start_farm";
$end_farm = "end_farm";
$last_fun = "_fini";
$touch1_fun = "touch1";
$touch2_fun = "touch2";
$touch3_fun = "touch3";

# Number of bytes in a word
$word_size = 8;

# Names of other programs to call (relative to src directory)
$reader = "solve/readd.pl";

use Getopt::Std;


$src_dir = "../../src";
$target_dir = ".";

# Names of target files (relative to target directory)
$target_bfile = "rtarget";
$target_dfile = "rtarget.d";
$target_gfile = "rtarget.g";

getopts('hd:');

if ($opt_h) {
    printf STDERR "Usage: $0 [-h] [-d DIR] [-s SRC] < SFILE\n";
    printf STDERR "  -d DIR        Directory containing rtarget files\n";
    printf STDERR "  -s SRC        Directory containing source files\n";
    printf STDERR "< SFILE         Attack string file\n";
    exit(0);
}

if ($opt_d) {
    $target_dir = $opt_d;
}

if ($opt_s) {
    $src_dir = $opt_s;
}

# Generate disassembly if needed
if (!-e "$target_dir/$target_dfile") {
    if (-e "$target_dir/$target_bfile") {
	system "objdump -d $target_dir/$target_bfile > $target_dir/$target_dfile"
	    || die("ERROR, couldn't generate $target_dir/$target_dfile\n");
	print "Generated $target_dir/$target_dfile\n";
    } else {
	die("ERROR, couldn't find $target_dir/$target_dfile\n");
    }
}

# Get bracketing addresses for code
$scaddr = `$src_dir/$reader -f $first_fun:$start_farm:$end_farm:$last_fun:$touch1_fun:$touch2_fun:$touch3_fun < $target_dir/$target_dfile`
    || die "Couldn't get code addresses";

$first_addr = 0;
$start_farm_addr = 0;
$end_farm_addr = 0;
$last_addr = 0;
$touch1_addr = 0;
$touch2_addr = 0;
$touch3_addr = 0;


for $line (split "\n", $scaddr) {
    chomp($line);
    @fields = split ":", $line;
    if ($fields[0] eq $first_fun) {
	$first_addr = hex($fields[1]);
    } elsif ($fields[0] eq $start_farm) {
	$start_farm_addr = hex($fields[1]);
    } elsif ($fields[0] eq $end_farm) {
	$end_farm_addr = hex($fields[1]);
    } elsif ($fields[0] eq $last_fun) {
	$last_addr = hex($fields[1]);
    } elsif ($fields[0] eq $touch1_fun) {
	$touch1_addr = hex($fields[1]);
    } elsif ($fields[0] eq $touch2_fun) {
	$touch2_addr = hex($fields[1]);
    } elsif ($fields[0] eq $touch3_fun) {
	$touch3_addr = hex($fields[1]);
    }
}

printf ("Bad ranges: 0x%x--0x%x, 0x%x--0x%x\n", $first_addr, $start_farm_addr, $end_farm_addr, $last_addr);
printf ("touch1: 0x%x, touch2: 0x%x, touch3: 0x%x\n", $touch1_addr, $touch2_addr, $touch_addr);

# Assemble attack string
@bytes = {};
$bytecnt = 0;

$in_comment = 0;
while (<>) {
    $line = $_;
    chomp($line);
    @lbytes = split " ", $line;
    for $b (@lbytes) {
	if ($in_comment) {
	    if ($b eq "*/") {
		$in_comment = 0;
	    }
	} elsif ($b eq "/*") {
	    $in_comment = 1;
	} else {
	    $bytes[$bytecnt] = $b;
	    $bytecnt += 1;
	}
    }
}

print "Attack string has $bytecnt bytes\n";
$gadget_cnt = 0;

for ($i = 0; $i < $bytecnt; $i += $word_size) {
    $line = "";
    $val = 0;
    # Assemble block of bytes
    $wt = 1;
    for ($j = $i; $j < $i + $word_size && $j < $bytecnt; $j += 1) {
	$b = $bytes[$j];
	$v = hex($b);
	$val = $val + $wt * $v;
	$wt *= 256;
	$line = "$line $b";
    }
    $hval = sprintf("%x", $val);
    $comment = "/* (0x$hval)";
    if ($val == $touch1_addr) {
	$comment = "$comment $touch1_fun";
    } elsif ($val == $touch2_addr) {
	$comment = "$comment $touch2_fun";
    } elsif ($val == $touch3_addr) {
	$comment = "$comment $touch3_fun";
    } elsif ($val >= $first_addr && $val < $start_farm_addr) {
	$comment = "$comment ERROR. invalid gadget address";
    } elsif ($val > $end_farm_addr && $val <= $last_addr) {
	$comment = "$comment ERROR. invalid gadget address";
    } elsif ($val >= $start_farm_addr && $val <= $end_farm_addr) {
#	print "Looking for $hval\n";
	$gline = `grep $hval $target_dir/$target_gfile`;
	chomp $gline;
	$comment = "$comment $gline";
	$gadget_cnt += 1;
    }
    print "$line   $comment */\n";
}

print "$gadget_cnt gadgets\n";

