#!/usr/bin/perl
#!/usr/local/bin/perl

##################################################
# Generate different versions of ncopy program.
# This program can generate versions using a variety of different
# optimizations.  
#

# The given file ncopy.ys has a CPE of 15.18.  It contains a load
# hazard in the inner loop, which can be eliminated by either 
# reordering the instructions or introducing load forwarding in the pipeline
# to get a CPE of 14.18.

# For all variants generated by this program, the default is to
# replace conditional jumps with conditional moves.  Use the -s option
# to prevent that.  In our testing it is best NOT to use conditional
# moves.  All data below assumes use of conditional jumps.

# The baseline optimization is to use the iaddq instruction
# and to also dedicate register %r8 to hold the constant 1.
# This yields a CPE of 10.77 (using jumps and load forwarding).
# 
# Setting parameter -u to something > 1 implements loop unrolling.
# The standard version then single-steps through any remaining
# elements, as is described in CS:APP3e Section 5.8.  The best
# performance is obtained by unrolling by a factor of 6, giving an
# average CPE of 8.26.
#
# Various alternative methods of handling the extra elements from
# loop unrolling are implemented.  Let r = n mod u be the number of
# elements that need to be handled outside of the main loop.
# 
# -c   Cascading powers of two
# Considers the binary representation of r, with blocks of code
# handling the copying for different powers of two.  Best performance
# obtained when unrolling by 8.  Gives average CPE of 8.10.
#
# -j   Jump into completion code
# Code finishes with a block of u-1 copies.  Jumps to point where
# remaining r copies take place.  The standard version computes this
# position by recognizing that the code to copy each element is 
# either 28 bytes (conditional moves) or 33 bytes (conditional jumps).
# With the -t option, the code uses a jump table.
# Best performance is with a jump table and unrolling by 12, giving
# an average CPE of 7.48.  (The degree of unrolling is limited
# by the 1000 byte limit.)
#
# -e Early fixup
# At the beginning of the function, the code jumps into
# the main loop to a point where r copies will take place.  With the
# -t otion, the code uses a jump table to determine jump target.  This
# code version can only unroll by powers of two.  Best performance is
# to use a jump table and unroll by 16, giving an average CPE of 8.11.

# Bottom line:
# The best performance was obtained with the following options:
# ./gen-ncopy.pl -u 12 -sjt
##################################################


$tabwidth = 8;
$commentstart = 32;

# Setting this to zero will reduce CPE, but also increase code size
# Requires jump table for either -j or -e.
$useconstreg = 1;

# Print formatted line of assembly code, with comment in appropriate spot
sub aline
{
  local ($cmd, $cmt) = @_;
  local $cpos = length($cmd);
  # See if cmd is a label
  if (!($cmd =~ ":")) {
    print "\t";
    $cpos += $tabwidth;
  }
  print $cmd;
  if (length($cmt) > 0) {
    while ($cpos < $commentstart) {
      print " ";
      $cpos ++;
    }
    print "# ";
    print $cmt;
  }
  print "\n";
}

sub cline
{
   local ($cmt) = @_;
   print "# $cmt\n";
}

sub bline
{
  print "\n";
}

sub ecpy
{
    local ($i,$tag) = @_;
    local $i8 = $i * 8;
    cline("\tCode block for offset $i");
    if ($useskip) {
	aline("mrmovq $i8(%rdi), %r10", "read val from src+$i");
	aline("rmmovq %r10, $i8(%rsi)", "Store val at dst+$i");
	aline("andq %r10, %r10", "Test val");
	aline("jle Npos$tag$i", "Skip if <= 0");
	if ($useconstreg) {
	    aline("addq %r8, %rax", "count++");
	} else {
	    aline("iaddq \$1, %rax", "count++");
	}
	aline("Npos$tag$i:");
    } else {
	aline("mrmovq $i8(%rdi), %r10", "read val from src+$i");
	aline("rrmovq %rax, %r11", "Copy count");
	if ($useconstreg) {
	    aline("addq %r8, %r11", "count+1");
	} else {
	    aline("iaddq \$1, %r11", "count+1");
	}
	aline("andq %r10, %r10", "Test val");
	aline("cmovg %r11, %rax", "If val > 0, count = count+1");
	aline("rmmovq %r10, $i8(%rsi)", "Store val at dst+$i");
    }
}

# gen-ncopy Program to generate different versions of copy routine 

use Getopt::Std;

# What unrolling factor should be used.
$unroll = 1;
$useskip = 0;
$usespecial = 0;
$usecascade = 0;
$usejump = 0;
$earlyfixup = 0;
$usetable = 0;

getopts('hu:cjset');

if ($opt_h) {
    print STDERR "Usage $argv[0] [-h] [-u U] ([-s][-c|-j|-e][-t]) [-s]\n";
    print STDERR "   -h      print help message\n";
    print STDERR "   -u U    set unrolling factor\n";
    print STDERR "   -s      Use jump to skip increment instead of conditional move\n";
    print STDERR "   -c      use cascading powers of 2\n";
    print STDERR "   -j      use computed jump\n";
    print STDERR "   -e      Do early fixup\n";
    print STDERR "   -t      Use jump table (in conjunction with -j and -e)\n" ;
    die "\n";
}

if ($opt_u) {
    $unroll = $opt_u;
}

if ($opt_s) {
    $useskip = 1;
}
 
if ($opt_c) {
  if ($unroll < 2) {
    print STDERR "Cannot cascade without unrolling\n";
    die "\n";
  }
  $usecascade = 1;
}

if ($opt_j) {
  if ($usecascade) {
    print STDERR "Can't use both jump and cascade\n";
    die "\n";
  }
  if ($unroll < 2) {
    print STDERR "Cannot use jumps without unrolling\n";
    die "\n";
  }
  $usejump = 1;
}

if ($opt_e) {
  if ($usecascade) {
    print STDERR "Can't use both early fixup and cascade\n";
    die "\n";
  }
  if ($unroll < 2) {
    print STDERR "Cannot use early fixup without unrolling\n";
    die "\n";
  }
  $earlyfixup = 1;
}

if ($opt_t) {
  $usetable = 1;
}

# Determine if $unroll is a power of 2
$ispwr2 = 0;

$idx = 1;
while ($idx < $unroll) {
    $idx *= 2;
}
if ($idx == $unroll) {
    $ispwr2 = 1;
}

if ($earlyfixup && !$ispwr2) {
  die "Early fixup requires unrolling by power of 2\n";
}

cline("#################################################################");
cline("ncopy.ys - Copy a src block of len words to dst.");
cline("Return the number of positive ints (>0) contained in src.");
cline("");
cline("Include your name and ID here."); cline("");
cline("Describe how and why you modified the baseline code.");
cline("This code unrolls the main loop by a factor of $unroll.");
if ($usecascade) {
  cline("It finishes the remaining elements by selectively copying");
  cline("blocks with lengths that are ascending powers of 2");
} elsif ($usejump) {
  cline("It finishes by jumping to the appropriate position in a code");
  cline("sequence that copies the possible remaining elements");
} elsif($earlyfixup) {
  cline("It jumps partway into the initial loop based on the value");
  cline("of len mod $unroll");
}
cline("#################################################################");
bline();
cline("Do not modify this portion");
cline("Function prologue");
cline("%rdi = src, %rsi = dst, %rdx = len");
aline("ncopy:");
bline();
cline("#################################################################");
cline("You can modify this portion");
bline();

if ($useconstreg) {
    aline("irmovq \$1, %r8", "Constant 1");
}
aline("xorq %rax,%rax", "count = 0");
if ($earlyfixup) {
  $um1 = $unroll-1;
  aline("irmovq \$$um1, %r10", "Mask for residue");
  aline("andq %rdx, %r10", "residue = len mod $unroll");
  aline("irmovq \$$unroll, %r11");
  aline("subq %r10, %r11", "a = $unroll - residue");
  if (!$usetable) {
      aline("rrmovq %r11, %r10", "a (For later use)");
  }
  cline("Back up starting point of copy by a (between 1 and $unroll)");
  aline("addq %r11, %rdx", "Increase len by a");
  aline("addq %r11, %r11", "2a");
  aline("addq %r11, %r11", "4a");
  aline("addq %r11, %r11", "8a");
  aline("subq %r11, %rdi", "src-a");
  aline("subq %r11, %rsi", "dst-a");
  if ($usetable) {
      cline("Fetch starting point from jump table");
      aline("mrmovq JTab(%r11), %r10", "Get jump target");
      aline("pushq %r10");
  } elsif ($useskip) {
      cline("Compute offset into loop code by 33a");
      aline("addq %r11, %r11", "16a");
      aline("addq %r11, %r11", "32a");
      aline("addq %r10, %r11", "33a");
      aline("iaddq Loop, %r11", "Starting position for first loop");
      aline("pushq %r11");
  } else {
      cline("Compute offset into loop code by 28a");
      aline("subq %r10, %r11", "7a");
      aline("addq %r11, %r11", "14a");
      aline("addq %r11, %r11", "28a");
      aline("iaddq Loop, %r11", "Starting position for first loop");
      aline("pushq %r11");
  }
  aline("ret", "Jump to starting position");
} elsif ($unroll == 1) {
  aline("andq %rdx,%rdx", "Test len");
  aline("jle SkipLoop", "if <= 0, skip loop");
} else {
  aline("iaddq \$-$unroll, %rdx", "lmu = len - $unroll");
  aline("jl SkipLoop", "If < 0, skip loop");
  bline();
}
cline("Main loop.  Copy $unroll elements per iteration");
aline("Loop:");

$u8 = $unroll*8;

for ($i = 0; $i < $unroll; $i++) {
  if ($earlyfixup) {
    aline("Copied$i:");
  }
  &ecpy($i,"_m_");
}
if ($earlyfixup) {
  aline("Copied$unroll:");
}

aline("iaddq \$$u8, %rdi", "src+=$unroll");
aline("iaddq \$$u8, %rsi", "dst+=$unroll");
if ($earlyfixup) {
  aline("iaddq \$-$unroll, %rdx", "len-=$unroll");
  aline("jg Loop", "if len > 0, goto Loop");
} elsif ($unroll == 1) {
  aline("iaddq \$-$unroll, %rdx", "len-=$unroll");
  aline("jg Loop", "if len > 0, goto Loop");
} else {
  aline("iaddq \$-$unroll, %rdx", "lmu-=$unroll");
  aline("jge Loop", "if lmu >= 0, goto Loop");
}

if (!$earlyfixup) {
  aline("SkipLoop:");


  if (!$usejump && $unroll > 1) {
    cline("Set %rdx to number or remaining elements");
    $um1 = $unroll -1;
    cline("(between 0 and $um1)");
    aline("iaddq \$$unroll, %rdx", "len = lmu + $unroll");
  }

  if ($usecascade == 1) {
    for ($idx = 1; $idx < $unroll; $idx = 2*$idx) {
      aline("# Handle any block of $idx elements");
      $idx8 = $idx * 8;
      aline("irmovq \$$idx,%r10", "idx = $idx");
      aline("andq %rdx,%r10", "idx & len");
      aline("je Skip$idx", "If 0, goto next block");
      for ($i = 0; $i < $idx; $i++) {
	&ecpy($i,"_$idx" . "_");
      }
      if (2*$idx < $unroll) {
	aline("iaddq \$$idx8, %rdi", "src+=$idx");
	aline("iaddq \$$idx8, %rsi", "dst+=$idx");
      }
      bline();
      aline("Skip$idx:");
    }
  }

  if ($usejump) {
    cline("Finish remaining elements\n");
    if ($usetable) {
      cline("Find jump offset at table position lmu (between -u & -1)");
      aline("addq %rdx, %rdx", "2*lmu");
      aline("addq %rdx, %rdx", "4*lmu");
      aline("addq %rdx, %rdx", "8*lmu");
      aline("mrmovq JTab(%rdx), %rdx", "Fetch offset");
    } elsif ($useskip) {
      cline("Compute jump offset as 33*(-lmu-1)");
      aline("irmovq \$-1, %r10");
      aline("subq %rdx, %r10", "-1-lmu");
      aline("rrmovq %r10, %rdx", "-1-lmu");
      aline("addq %rdx, %rdx", "2*(-1-lmu)");
      aline("addq %rdx, %rdx", "4*(-1-lmu)");
      aline("addq %rdx, %rdx", "8*(-1-lmu)");
      aline("addq %rdx, %rdx", "16*(-1-lmu)");
      aline("addq %rdx, %rdx", "32*(-1-lmu)");
      aline("addq %r10, %rdx", "33*(-1-lmu)");
      aline("iaddq jstart, %rdx", "jump target");
    } else {
      cline("Compute jump offset as 28*(-lmu-1)");
      aline("irmovq \$-1, %r10");
      aline("subq %rdx, %r10", "-1-lmu");
      aline("rrmovq %r10, %rdx", "-1-lmu");
      aline("addq %rdx, %rdx", "2*(-1-lmu)");
      aline("addq %rdx, %rdx", "4*(-1-lmu)");
      aline("addq %rdx, %rdx", "8*(-1-lmu)");
      aline("subq %r10, %rdx", "7*(-1-lmu)");
      aline("addq %rdx, %rdx", "14*(-1-lmu)");
      aline("addq %rdx, %rdx", "28*(-1-lmu)");
      aline("iaddq jstart, %rdx", "jump target");
    }
    aline("pushq %rdx", "Put jump target on stack");
    aline("ret", "Jump to it");
    aline("jstart:", "Copying code for remaining possible elements");
    cline("Completion code");
    $j = 0;
    for ($i = $unroll-2; $i >= 0; $i--) {
      if ($usetable) {
	aline("Copied$j:");
	$j++;
      }
      &ecpy($i,"_c_");
    }
  }
  if ($usetable) {
    aline("Copied$j:");
  }

  if ($unroll > 1 && !($usecascade || $usejump)) {
    aline("# Single step remaining elements");
    aline("je Done");
    aline("SingleLoop:");
    &ecpy(0,"_s_");
    aline("iaddq \$8, %rdi", "src++");
    aline("iaddq \$8, %rsi", "dst++");
    aline("iaddq \$-1, %rdx", "len--");
    aline("jg SingleLoop", "if len > 0, goto SingleLoop");
  }
}

bline();
cline("#################################################################");
bline();
cline("Do not modify the following section of code");
cline("Function epilogue");
aline("Done:");
aline("ret");

if ($usetable) {
  cline("#################################################################");
  cline("Jump table");
  aline(".align 8");
  if ($earlyfixup) {
      $tsize = $unroll+1;
      aline("JTab:");
      for ($i = 0; $i < $tsize; $i++) {
	  aline(".quad Copied$i");
      }
  } else {
      $tsize = $unroll;
      for ($i = $tsize-1; $i >= 0; $i--) {
	  aline(".quad Copied$i");
      }
      aline("JTab:", "This table has negative offsets");      
  }
}

cline("##################################################################");
cline("# Keep the following label at the end of your function");
aline("End:");
