#!/usr/bin/perl
#!/usr/local/bin/perl

## Generate Verilog description of processor. 
## Requires combining framework for processor, with code extracted from HCL

use Getopt::Std;

getopts('hm:b:H:p:c:a:o:O:');

$ifile = "../verilog/pipe-proc.v";
$ofile = "pipe-proc.v";

if ($opt_h) {
    print STDERR "Usage $argv[0] [-h] [-H <hcl>] [-b <blocks>] [-o <output>]\n";
    print STDERR "   -h        print Help message\n";
    print STDERR "   -b        Specify block file (none)\n";
    print STDERR "   -p        Specify processor file ($ifile)\n";
    print STDERR "   -H        Specify HCL file (none)\n";
    print STDERR "   -o        Specify output file ($ofile)\n";
    die "\n";
}

$hclstring = "";

$hcl2v = "../misc/hcl2v";

if ($opt_b) {
    $has_block_file = 1;  
    $bfile = $opt_b;
}

if ($opt_H) {
    $hclstring = `$hcl2v < $opt_H` || die("Couldn't run '$hcl2v' on file '$opt_H'\n");
}

if ($opt_p) {
    $ifile = $opt_p;
}

if ($opt_o) {
    $ofile = $opt_o;
}

open(OUTFILE, ">$ofile") || die("Can't open output file '$ofile'\n");



if ($has_block_file) {
  open(BFILE, $bfile) || die("Can't find block file '$bfile'\n");
  while (<BFILE>) {
    $line = $_;
    print OUTFILE $line;
  }
  close(BFILE);
}

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

close(OUTFILE);
