#!/usr/bin/perl
use Getopt::Std;

# Generate matrix of pop instruction encodings

@suffixes = ("ax", "cx", "dx", "bx", "sp", "bp", "si", "di");

$dotex = 0;

$mode = 'q';
$prefix = "r";

getopts('hx');

if ($opt_h) {
    printf STDERR "Usage: $0 [-h] [-x]\n";
    exit(0);
}

if ($opt_x) {
    $dotex = 1;
}

$poproot = "pop$mode";
$popasm = "$poproot.s";
$popobj = "$poproot.o";
$popdis = "$poproot.d";
$poptex = "$poproot.tex";
$poptext = "$poproot.txt";

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
	print OUT "\tpop$mode $rname\n";
    }
    close OUT;
}

sub getcode
{
    local ($reg) = @_;
    local ($rname);
    $rname = &regname($reg);
    $cmd = "pop.*$rname";
    $line = `grep '$cmd' $popdis`;
    chomp($line);
    $line =~ ":[\t ]*([0-9a-f]{2})";
    $code = $1;
    return $code;
}

sub gentex
{
    local ($outfile) = @_;
    local ($rname);
    open(OUT, ">$outfile") || die("Can't open $outfile\n");
    # Print header
    print OUT "\\begin{tabular}{|c|c|c|c|c|c|c|c|c|}\n";
    print OUT "\\hline\n";
    print OUT "Operation & \\multicolumn{8}{|c|}{Register \$R\$} \\\\\n";
    print OUT "\\cline{2-9}\n";
    print OUT " ";
    for $reg (@suffixes) {
	$rname = &regname($reg);
	print OUT "& \\verb\@$rname\@ ";
    }
    print OUT "\\\\\n";
    print OUT "\\hline\n";    
    print OUT "\\texttt{popq \$R\$} ";

    for $reg (@suffixes) {
	$rname = &regname($reg);
	$code = &getcode($reg);
	print OUT "& \\texttt{$code} ";
    }
    print OUT "\\\\\n";
    print OUT "\\hline\n";    
    print OUT "\\end{tabular}\n";
    close OUT;
}

sub gentext
{
    local ($outfile) = @_;
    open(OUT, ">$outfile") || die("Can't open $outfile\n");
    for $reg (@suffixes) {
	$code = &getcode($reg);
	print OUT "popq:$reg:$code\n";
    }
    close OUT;
}

print "Generating $popasm\n";
&genasm($popasm);
print "Generating $popobj\n";
system "as $popasm -o $popobj";
print "Generating $popdis\n";
system "objdump -d $popobj > $popdis";
if ($dotex) {
    print "Generating $poptex\n";
    &gentex($poptex);
} else {
    print "Generating $poptext\n";
    &gentext($poptext);
}
