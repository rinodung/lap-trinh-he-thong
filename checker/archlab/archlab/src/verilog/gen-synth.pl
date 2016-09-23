#!/usr/bin/perl
#!/usr/local/bin/perl

## Generate synthesizable Verilog description of processor. 
## Requires combining framework for processor, with code extracted from HCL

use Getopt::Std;

getopts('hm:b:H:p:c:a:o:O:');

$ifile = "../verilog/components/pipe-proc.v";
$bfile = "../verilog/components/blocks.v";
$mfile = "../verilog/components/combram.v";
$ofile = "pipe-synth.v";

if ($opt_h) {
    print STDERR "Usage $argv[0] [-h] [-H <hcl>] [-b <blocks>] [-m <memory>] [-o <output>]\n";
    print STDERR "   -h        print Help message\n";
    print STDERR "   -b        Specify block file ($bfile)\n";
    print STDERR "   -m        Specify memory file ($mfile)\n";
    print STDERR "   -p        Specify processor file ($ifile)\n";
    print STDERR "   -H        Specify HCL file (none)\n";
    print STDERR "   -o        Specify output file ($ofile)\n";
    die "\n";
}

$hclstring = "";

$hcl2v = "../misc/hcl2v";

if ($opt_b) {
    $bfile = $opt_b;
}

if ($opt_m) {
    $mfile = $opt_m;
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

print OUTFILE "//* \$begin pipe-synth-verilog */\n";
print OUTFILE "// --------------------------------------------------------------------\n";
print OUTFILE "// Verilog representation of PIPE processor\n";
print OUTFILE "// --------------------------------------------------------------------\n";
print OUTFILE "\n";
print OUTFILE "// --------------------------------------------------------------------\n";
print OUTFILE "// Memory module for implementing bank memories\n";
print OUTFILE "// --------------------------------------------------------------------\n";

open(MFILE, $mfile) || die("Can't find memory file '$mfile'\n");

while (<MFILE>) {
  $line = $_;
  print OUTFILE $line;
}
close(MFILE);

print OUTFILE "\n";
print OUTFILE "// --------------------------------------------------------------------\n";
print OUTFILE "// Other building blocks\n";
print OUTFILE "// --------------------------------------------------------------------\n";
print OUTFILE "\n";


open(BFILE, $bfile) || die("Can't find block file '$bfile'\n");
while (<BFILE>) {
  $line = $_;
  print OUTFILE $line;
}
close(BFILE);

print OUTFILE "\n";
print OUTFILE "// --------------------------------------------------------------------\n";
print OUTFILE "// Processor implementation\n";
print OUTFILE "// --------------------------------------------------------------------\n";
print OUTFILE "\n";

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
print OUTFILE "//* \$end pipe-synth-verilog */\n";
close(OUTFILE);
