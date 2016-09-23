#!/usr/bin/perl
#!/usr/local/bin/perl

## Compare result of simulating code with verilog model and with instruction simulator
## Only compares values of PC, registers, condition codes, and exit code

use Getopt::Std;

$verilogdir = "/src/iverilog/bin";
$iverilog = "$verilogdir/iverilog";

getopts('hb:m:H:p:c:a:O:');

$mfile = "../verilog/components/combram.v";
$bfile = "../verilog/components/blocks.v";
$ifile = "../verilog/components/pipe-proc.v";
$cfile = "../verilog/components/controller.v";
$hclfile = "../pipe/pipe-std.hcl";
$afile = "../y86-code/asum.ys";

if ($opt_h) {
    print STDERR "Usage $argv[0] [-h] [-H <hcl>] [-b <blocks>] [-m <memory>] [-a <assembly>] [-o <output>]\n";
    print STDERR "   -h        print Help message\n";
    print STDERR "   -b        Specify block file ($bfile)\n";
    print STDERR "   -m        Specify memory file ($mfile)\n";
    print STDERR "   -p        Specify processor file ($ifile)\n";
    print STDERR "   -c        Specify controller file ($cfile)\n";
    print STDERR "   -H        Specify HCL file ($hclfile)\n";
    print STDERR "   -a        Specify assembly code file ($afile)\n";
   die "\n";
}

$codestring = "";
$hclstring = "";

$yas = "../misc/yas";
$yis = "../misc/yis";
$hcl2v = "../misc/hcl2v";
$gensim = "../verilog/gen-sim.pl";

if ($opt_a) {
    $afile = $opt_a;
}

if ($opt_b) {
    $bfile = $opt_b;
}

if ($opt_m) {
    $mfile = $opt_m;
}

$rootname = $afile;
$rootname =~ s/\.ys//;
$afile = "$rootname.ys";

if ($opt_H) {
    $hclfile = $opt_H;
}

if ($opt_p) {
    $ifile = $opt_p;
}

system "$yas $afile" || die("Couldn't assemble $afile\n");

$yisresult = `$yis $rootname.yo` || die("Couldn't run yis on $rootname.yo\n");

print "Calling '$gensim -H $hclfile -p  $ifile -b $bfile -m $mfile -c $cfile -a $rootname.ys -o $rootname.v'\n";
system "$gensim -H $hclfile -p  $ifile -b $bfile -m $mfile -c $cfile -a $rootname.ys -o $rootname.v" || die("Couldn't generate verilog file $rootname.v\n");

system "$iverilog -o $rootname.vvp $rootname.v" || die("Couldn't compile verilog file $rootname.v");


print "Running $rootname\n";

$vresult = `./$rootname.vvp` || die("Couldn't simulate $rootname.vvp");

system "rm $rootname.yo";
system "rm $rootname.v";
system "rm $rootname.vvp";

@regname = ("eax", "ecx", "edx", "ebx", "esp", "ebp", "esi", "edi");

## Extract values from YIS
$ystat = "NONE";
$ypc = -1;
@yf = (-1, -1, -1);
@yreg = (0, 0, 0, 0, 0, 0, 0, 0);

if ($yisresult =~ /Status '(HLT|INS|ADR|AOK)'/) {
    $ystat = $1;
}

if ($yisresult =~ /PC = 0x([0-9a-fA-F]*)/) {
    $ypc = hex($1);
}

if ($yisresult =~ /Z=([0-1]) S=([0-1]) O=([0-1])/) {
    @yf = ($1, $2, $3);
}

for ($i = 0; $i < 8; $i++) {
    if ($yisresult =~ /$regname[$i]:\t0x[0-9a-fA-F]*\t0x([0-9a-fA-F]*)/) {
	$yreg[$i] = hex($1);
    }
}

## Extract values from VVP
$vstat = "NONE";
$vpc = -1;
@vf = (-1, -1, -1);
@vreg = (0, 0, 0, 0, 0, 0, 0, 0);

if ($vresult =~ /status '\s*(HLT|INS|ADR|AOK)'/) {
    $vstat = $1;
}

if ($vresult =~ /PC = 0x([0-9a-fA-F]*)/) {
    $vpc = hex($1);
}

if ($vresult =~ /Z=([0-1]) S=([0-1]) O=([0-1])/) {
    @vf = ($1, $2, $3);
}

for ($i = 0; $i < 8; $i++) {
    if ($vresult =~ /$regname[$i]: 0x([0-9a-fA-F]*)/) {
	$vreg[$i] = hex($1);
    }
}

$ok = 1;

if (!($ystat eq $vstat)) {
    print "YIS status ($ystat) != V status ($vstat)\n";
    $ok = 0;
}

if ($ypc != $vpc) {
    printf "YIS PC (0x%x) != V PC (0x%x)\n", $ypc, $vpc;
    $ok = 0;
}

if (@yf != @vf) {
    print "YIS CC (@yf) != V CC (@vf)\n";
    $ok = 0;
}

for ($i = 0; $i < 8; $i++) {
    if ($yreg[$i] != $vreg[$i]) {
	printf "YIS %s (0x%x) != V %s (0x%x)\n", $regname[$i], $yreg[$i], $regname[$i], $vreg[$i];
	$ok = 0;
    }
}

if ($ok) {
    print "Results match for $afile\n";
} else {
    print "Failed for $afile\n";
}

