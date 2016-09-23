#!/usr/bin/perl
use Getopt::Std;

$test_version = "all";
$test_simulator = "all";

# Should this be a test of a Verilog implementation?
$test_vlog = 0;
# What model should be used for Verilog?
$vlogmodel = "all";

$test_type = "test";

getopts('hqv:s:Vm:');

if ($opt_h) {
  print STDERR "Usage $argv[0] [-h] [-q] [-s sim] [-v version] [-V]\n";
  print STDERR " -h          print help message\n";
  print STDERR " -q          perform quick test\n";
  print STDERR " -s sim      only test specified simulator\n";
  print STDERR " -v version  only test specified version\n";
  print STDERR " -V          test Verilog models\n";
  print STDERR " -m model    Model for Verilog\n";
  die "\n";
}

if ($opt_q) {
  $test_type = "qtest";
}

if ($opt_v) {
  $test_version = $opt_v;
}

if ($opt_s) {
  $test_simulator = $opt_s;
}

if ($opt_V) {
  $test_vlog = 1;
  if ($opt_m) {
    $vlogmodel = $opt_m;
  }
}

## Do regression testing of all processor designs

# Version record fields  'model:simulator:dir:version:test'
# Test types:
# std: Normal instructions
# full: Include leave & iaddq instructions
# compile: Just see if it compiles
@versions = 
(
## SEQ
 "seq-std:ssim:seq:std:std",
 "seq-full-ans:ssim:seq:full-ans:full",
 "novlog:ssim:seq:full:compile",
## SEQ+
 "seq+-std:ssim+:seq:std:std",
## PIPE
 "pipe-1w-ans:psim:pipe:1w-ans:std",
 "novlog:psim:pipe:1w:compile",
 "novlog:psim:pipe:broken:compile",
 "pipe-btfnt-ans:psim:pipe:btfnt-ans:std",
 "novlog:psim:pipe:btfnt:compile",
 "pipe-full-ans:psim:pipe:full-ans:full",
 "novlog:psim:pipe:full:compile",
 "pipe-lf-ans:psim:pipe:lf-ans:std",
 "novlog:psim:pipe:lf:compile",
 "pipe-nt-ans:psim:pipe:nt-ans:std",
 "novlog:psim:pipe:nt:compile",
 "pipe-nobypass-ans:psim:pipe:nobypass-ans:std",
 "novlog:psim:pipe:nobypass:compile",
 "pipe-std:psim:pipe:std:std"
);

if ($test_vlog == 0) {
  # Compile all versions
  foreach $line (@versions) {
    ($junk,$simulator, $directory, $version, $test) = split /:/, $line;
    if (($test_version eq "all" || $test_version eq $version) &&
	($test_simulator eq "all" || $test_simulator eq $simulator)) {
      $model = "$simulator-$version";
      system "rm -rf $model; mkdir $model" || die "Couldn't create directory for model $model\n";
      print "Compiling model $model\n";
      $msg = `pushd ../$directory ; rm -f $simulator $simulator.exe ; make $simulator VERSION=$version GUIMODE= ; popd`;
      open (OUTFILE, ">$model/compile.txt") || die "Couldn't open file $model/compile.txt\n";
      if (-e "../$directory/$simulator") {
	system "cp ../$directory/$simulator $model";
      }
      if (-e "../$directory/$simulator.exe") {
	system "cp ../$directory/$simulator.exe $model";
      }
      print OUTFILE $msg;
      close OUTFILE;
    }
  }

# Do the testing
  foreach $line (@versions) {
    ($junk,$simulator, $directory, $version, $test) = split /:/, $line;
    if (($test_version eq "all" || $test_version eq $version) &&
	($test_simulator eq "all" || $test_simulator eq $simulator)) {
      $model = "$simulator-$version";
      if (!($test eq "compile")) {
	$flag = "OUTDIR=$model";
	if ($test eq "full") {
	  $flag = "$flag TFLAGS=-i";
	}
	print "Testing $model with commandline flag '$flag'\n";
	system "rm -f *.ys";
	system "make $test_type SIM=./$model/$simulator $flag > ./$model/test.txt";
      }
    }
  }
} else {
  # Verilog testing
  foreach $line (@versions) {
    ($vmodel,$simulator, $directory, $version, $test) = split /:/, $line;
    if (!($vmodel eq "novlog") &&
	$vlogmodel eq "all" || $vmodel eq $vlogmodel) {
        system "rm -rf $vmodel; mkdir $vmodel" || die "Couldn't create directory for Verilog model $vmodel\n";
	$flag = "OUTDIR=$vmodel";
	if ($test eq "full") {
	  $flag = "$flag TFLAGS=-i";
	}
	print "Verilog testing of $vmodel with commandline flag '$flag'\n";
	system "rm -f *.ys";
	system "make vtest VMODEL=$vmodel $flag > ./$vmodel/test.txt";
      }
  }
}

