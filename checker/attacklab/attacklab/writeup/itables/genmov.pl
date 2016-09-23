#!/usr/bin/perl
use Getopt::Std;

# Generate matrix of mov instruction encodings

@suffixes = ("ax", "cx", "dx", "bx", "sp", "bp", "si", "di");

%prefixes = (
    q => "r",
    l => "e",
    w => "",
);

$dotex = 0;

$mode = "q";

getopts('hlwqx');

if ($opt_h) {
    printf STDERR "Usage: $0 [-h] [-(w|l|q)] [-x]\n";
    exit(0);
}

if ($opt_w) {
    $mode = "w";
}

if ($opt_l) {
    $mode = "l";
}

$prefix = $prefixes{$mode};

if ($opt_x) {
    $dotex = 1;
}

$movroot = "mov$mode";
$movasm = "$movroot.s";
$movobj = "$movroot.o";
$movdis = "$movroot.d";
$movtex = "$movroot.tex";
$movtext = "$movroot.txt";

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
	for $src (@suffixes) {
	    $sreg = &regname($src);
	    $dreg = &regname($dst);
	    print OUT "\tmov$mode $sreg, $dreg\n";
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
    $cmd = "mov.*$sreg,.*$dreg";
    $line = `grep '$cmd' $movdis`;
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
    print OUT "\\begin{tabular}{|c|c|c|c|c|c|c|c|c|}\n";
    print OUT "\\multicolumn{9}{l}{\\texttt{mov$mode \$S\$, \$D\$}} \\\\\n";
    print OUT "\\hline\n";
    print OUT "Source & \\multicolumn{8}{|c|}{Destination \$D\$} \\\\\n";
    print OUT "\\cline{2-9}\n";
    print OUT "  \$S\$ ";
    for $dst (@suffixes) {
	$dreg = &regname($dst);
	print OUT "& \\verb\@$dreg\@ ";
    }
    print OUT "\\\\\n";
    print OUT "\\hline\n";
    # Print body
    for $src (@suffixes) {
	$sreg = &regname($src);
	print OUT "\\verb\@$sreg\@ ";
	for $dst (@suffixes) {
	    $code = &getcode($src, $dst);
	    print OUT "& \\texttt{$code} ";
	}
	print OUT "\\\\\n";
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
	for $dst (@suffixes) {
	    $code = &getcode($src, $dst);
	    print OUT "$src:$dst:$code\n";
	}
    }
    close OUT;
}

print "Generating $movasm\n";
&genasm($movasm);
print "Generating $movobj\n";
system "as $movasm -o $movobj";
print "Generating $movdis\n";
system "objdump -d $movobj > $movdis";
if ($dotex) {
    print "Generating $movtex\n";
    &gentex($movtex);
} else {
    print "Generating $movtext\n";
    &gentext($movtext);
}
