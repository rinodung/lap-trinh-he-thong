#!/usr/bin/perl
use Getopt::Std;

# Generate matrix of functional nop instruction encodings

@suffixes = ("ax", "cx", "dx", "bx", "sp", "bp", "si", "di");

@instrs = ("and", "or", "cmp", "test");

%prefixes = (
    q => "r",
    l => "e",
    w => "",
    b => "",
);

$dotex = 0;

$prefix = "r";

getopts('hblwqx');

if ($opt_h) {
    printf STDERR "Usage: $0 [-h] [-(b|w|l|q)] [-x]\n";
    exit(0);
}

$mode = 'q';

if ($opt_w) {
    $mode = "w";
}

if ($opt_l) {
    $mode = "l";
}

if ($opt_b) {
    @suffixes = ("al", "cl", "dl", "bl");
    $mode = "b";
}

$prefix = $prefixes{$mode};

if ($opt_x) {
    $dotex = 1;
}

$noproot = "nop$mode";
$nopasm = "$noproot.s";
$nopobj = "$noproot.o";
$nopdis = "$noproot.d";
$noptex = "$noproot.tex";
$noptext = "$noproot.txt";

sub regname
{
    local ($suffix) = @_;
    return "%$prefix$suffix";
}

sub genasm 
{
    local ($outfile) = @_;
    local ($rname);
    open(OUT, ">$outfile") || die("Can't open $outfile\n");
    for $reg (@suffixes) {
	$rname = &regname($reg);
	for $op (@instrs) {
	    print OUT "\t$op$mode $rname, $rname\n";
	}
    }
    close OUT;
}

sub getcode
{
    local ($op,$reg) = @_;
    local ($rname);
    $rname = &regname($reg);
    $cmd = "$op.*$rname,.*$rname";
    $line = `grep '$cmd' $nopdis`;
    chomp($line);
    $line =~ ":[\t ]*(([0-9a-f]{2} )*[0-9a-f]{2})";
    $code = $1;
#    print "Extracted '$code' from line '$line'\n";
    return $code;
}

sub gentex
{
    local ($outfile) = @_;
    local ($rname);
    open(OUT, ">$outfile") || die("Can't open $outfile\n");
    # Print header
    print OUT "\\begin{tabular}{|ll|c|c|c|c|}\n";
    print OUT "\\hline\n";
    print OUT "\\multicolumn{2}{|c|}{Operation} & \\multicolumn{4}{|c|}{Register \$R\$} \\\\\n";
    print OUT "\\cline{3-6}\n";
    print OUT " & ";
    for $reg (@suffixes) {
	$rname = &regname($reg);
	print OUT "& \\verb\@$rname\@ ";
    }
    print OUT "\\\\\n";
    print OUT "\\hline\n";    
    # Print body
    for $op (@instrs) {
	print OUT " \\texttt{$op$mode} & \\texttt{\$R\$, \$R\$} ";
	for $reg (@suffixes) {
	    $rname = &regname($reg);
	    $code = &getcode($op, $reg);
	    print OUT "& \\verb\@$code\@ ";
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
    for $op (@instrs) {
	for $reg (@suffixes) {
	    $code = &getcode($op, $reg);
	    print OUT "$op:$reg:$code\n";
	}
    }
    close OUT;
}

print "Generating $nopasm\n";
&genasm($nopasm);
print "Generating $nopobj\n";
system "as $nopasm -o $nopobj";
print "Generating $nopdis\n";
system "objdump -d $nopobj > $nopdis";
if ($dotex) {
    print "Generating $noptex\n";
    &gentex($noptex);
} else {
    print "Generating $noptext\n";
    &gentext($noptext);
}
