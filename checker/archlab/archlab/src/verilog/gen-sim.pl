#!/usr/bin/perl
#!/usr/local/bin/perl

## Generate Verilog description of processor with loaded program
## Requires combining framework for processor, with code extracted from HCL
##   and memory state extracted from object code

use Getopt::Std;

getopts('hm:b:H:p:c:a:o:O:');

$mfile = "../verilog/components/combram.v";
$bfile = "../verilog/components/blocks.v";
$ifile = "../verilog/components/pipe-proc.v";
$cfile = "../verilog/components/controller.v";
$ofile = "pipe-sim.v";

if ($opt_h) {
    print STDERR "Usage $argv[0] [-h] [-H <hcl>] [-b <blocks>] [-m <memory>] [-a <assembly>] [-o <output>]\n";
    print STDERR "   -h        print Help message\n";
    print STDERR "   -b        Specify block file ($bfile)\n";
    print STDERR "   -m        Specify memory file ($mfile)\n";
    print STDERR "   -p        Specify processor file ($ifile)\n";
    print STDERR "   -c        Specify controller file ($cfile)\n";
    print STDERR "   -H        Specify HCL file (none)\n";
    print STDERR "   -a        Specify assembly code file (none)\n";
    print STDERR "   -o        Specify output file ($ofile)\n";
    die "\n";
}

$codestring = "";
$hclstring = "";

$yas = "../misc/yas";
$hcl2v = "../misc/hcl2v";

if ($opt_b) {
    $bfile = $opt_b;
}


if ($opt_m) {
    $mfile = $opt_m;
}

if ($opt_a) {
    $codestring = `$yas -V $opt_a` || die("Couldn't run assembler '$yas' on file '$opt_a'\n");
    $bcodestring = `$yas -V8 $opt_a` || die("Couldn't run assembler '$yas' on file '$opt_a'\n");
}

if ($opt_H) {
    $hclstring = `$hcl2v < $opt_H` || die("Couldn't run '$hcl2v' on file '$opt_H'\n");
}

if ($opt_p) {
    $ifile = $opt_p;
}

if ($opt_c) {
    $cfile = $opt_c;
}

if ($opt_o) {
    $ofile = $opt_o;
}

open(OUTFILE, ">$ofile") || die("Can't open output file '$ofile'\n");


open(MFILE, $mfile) || die("Can't find memory file '$mfile'\n");

while (<MFILE>) {
  $line = $_;
  print OUTFILE $line;
}
close(MFILE);

open(BFILE, $bfile) || die("Can't find block file '$bfile'\n");

while (<BFILE>) {
    $line = $_;
    print OUTFILE $line;
}
close(BFILE);


open(INFILE, $ifile) || die("Can't find processor file '$ifile'\n");
while (<INFILE>) {
    $line = $_;
    if ($line =~ "INSERT_LOGIC_HERE") {
	print OUTFILE $hclstring;
    } else {
        print OUTFILE $line;
    }
}

close(INFILE);

open(CFILE, $cfile) || die("Can't find controller file '$cfile'\n");
while (<CFILE>) {
    $line = $_;
    if ($line =~ "INSERT_CODE_HERE") {
	print OUTFILE $codestring;
    } else {
	if ($line =~ "INSERT_BCODE_HERE") {
	    print OUTFILE $bcodestring;
	} else {
	    print OUTFILE $line;
	}
    }
}
close(CFILE);
close(OUTFILE);
