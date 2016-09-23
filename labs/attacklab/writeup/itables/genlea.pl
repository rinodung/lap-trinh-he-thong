#!/usr/bin/perl
use Getopt::Std;

# Generate matrix of lea instruction encodings

@suffixes = ("ax", "cx", "dx", "bx", "sp", "bp", "si", "di");

%prefixes = (
    q => "r",
    l => "e",
    w => "",
);

$dotex = 0;

$mode = "q";

getopts('hx');

if ($opt_h) {
    printf STDERR "Usage: $0 [-h] [-x]\n";
    exit(0);
}

$prefix = $prefixes{$mode};

if ($opt_x) {
    $dotex = 1;
}

$learoot = "lea$mode";
$leaasm = "$learoot.s";
$leaobj = "$learoot.o";
$leadis = "$learoot.d";
$leatex = "$learoot.tex";
$leatext = "$learoot.txt";

sub regname
{
    local ($suffix) = @_;
    return "%$prefix$suffix";
}

sub genasm 
{
    local ($outfile) = @_;
    local ($sreg, $dreg);
    open(OUT, ">$outfile") || die("Can't open $outfile\n");
    for $dst (@suffixes) {
	if (!($dst eq "sp")) {
	    for $src (@suffixes) {
		if (!($src eq "bp")) {
		    $sreg = &regname($src);
		    $dreg = &regname($dst);
		    print OUT "\tlea$mode ($sreg,$dreg,1), %rax\n";
		}
	    }
	}
    }
    close OUT;
}

sub getcode
{
    local ($src,$dst) = @_;
    local ($cmd, $sreg, $dreg);
    $sreg = &regname($src);
    $dreg = &regname($dst);
    $cmd = "lea.*($sreg,.*$dreg,1)";
    $line = `grep '$cmd' $leadis`;
    chomp($line);
    $line =~ ":[\t ]*(([0-9a-f]{2} )*[0-9a-f]{2})";
    $code = $1;
#    print "Extracted '$code' from line '$line'\n";
    return $code;
}

sub gentex
{
    local ($outfile) = @_;
    local ($dreg);
    open(OUT, ">$outfile") || die("Can't open $outfile\n");
    # Print header
    print OUT "\\begin{tabular}{|c|cccccccc|}\n";
    print OUT "\\hline\n";
    print OUT "\\texttt{lea$mode} ";
    for $dst (@suffixes) {
	$dreg = &regname($dst);
	print OUT "& \\texttt{$dreg} ";
    }
    print OUT "\\\\\n";
    print OUT "\\hline\n";
    # Print body
    for $src (@suffixes) {
	if (!($src eq "bp")) {
	    $sreg = &regname($src);
	    print OUT "& \\texttt{$sreg} ";
	    for $dst (@suffixes) {
		if (!($dst eq "sp")) {
		    $code = &getcode($src, $dst);
		    print OUT "& \\texttt{$code} ";
		}
	    }
	    print OUT "\\\\\n";
	}
    }
    # Print footer
    print OUT "\\hline\n";
    print OUT "\\end{tabular}\n";
    close OUT;
}

sub gentext
{
    local ($outfile) = @_;
    open(OUT, ">$outfile") || die("Can't open $outfile\n");
    for $src (@suffixes) {
	if (!($src eq "bp")) {
	    for $dst (@suffixes) {
		if (!($dst eq "sp")) {
		    $code = &getcode($src, $dst);
		    print OUT "$src:$dst:$code\n";
		}
	    }
	}
    }
    close OUT;
}

print "Generating $leaasm\n";
&genasm($leaasm);
print "Generating $leaobj\n";
system "as $leaasm -o $leaobj";
print "Generating $leadis\n";
system "objdump -d $leaobj > $leadis";
if ($dotex) {
    print "Generating $leatex\n";
    &gentex($leatex);
} else {
    print "Generating $leatext\n";
    &gentext($leatext);
}
