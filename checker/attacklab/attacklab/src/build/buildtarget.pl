#!/usr/bin/perl

#######################################################################
# buildtarget.pl: Generate files for attack target
#######################################################################

# This program should be run within the build subdirectory

use Getopt::Std;

$troot = "../../targets";

$solve = 0;

getopts('hSt:u:');

if ($opt_h) {
    printf STDERR "Usage: $0 [-hS] [-u USR] -t ID\n";
    printf STDERR "  -S     Don't include solution information\n";
    printf STDERR "  -u USR Identify user\n";
    printf STDERR "  -t ID  Set id for target\n";
    exit(0);
}

if ($opt_t) {
    $id = $opt_t;
} else {
    printf STDERR "Must indicate numeric target ID\n";
    exit(0);
}

if ($opt_S) {
    $solve = 0;
} else {
    $solve = 1;
}

if ($opt_u) {
    $user = $opt_u;
} else {
    $user = "NoOne";
}

$dest = "$troot/target$id";

# Make sure everything has been compiled
system "cd ../common; make" || die "Couldn't run make in ../common\n";
system "make" || die "Couldn't run make\n";
if ($solve) {
    system "cd ../solve; make" || die "Couldn't run make in ../solve\n";
}

$cookie = `./makecookie $id` || die "Could not compute cookie\n";
chomp $cookie;

$authkey = `./makecookie $cookie` || die "Could not compute authentication key\n";
chomp $authkey;


# Construct target programs
system "make ctarget-$id TARGET_ID=$id USER_ID='\"$user\"'" || die "Couldn't build ctarget-$id\n";
system "make rtarget-$id TARGET_ID=$id USER_ID='\"$user\"'" || die "Couldn't build rtarget-$id\n";
system "make ctarget-check-$id TARGET_ID=$id USER_ID='\"$user\"'" || die "Couldn't build ctarget-check-$id\n";
system "make rtarget-check-$id TARGET_ID=$id USER_ID='\"$user\"'" || die "Couldn't build rtarget-check-$id\n";

# Clean out any existing target directory
system "rm -rf $dest" || die "Couldn't remove old version of $dest\n";
system "mkdir $dest" || die "Couldn't create $dest\n";

system "cp ctarget-$id $dest/ctarget"
  || die "Couldn't move ctarget binary to $dest\n";

system "cp rtarget-$id $dest/rtarget"
  || die "Couldn't move rtarget binary to $dest\n";

system "cp ctarget-check-$id $dest/ctarget-check"
  || die "Couldn't move ctarget-check binary to $dest\n";

system "cp rtarget-check-$id $dest/rtarget-check"
  || die "Couldn't move rtarget-check binary to $dest\n";

system "cp farm-$id.c $dest/farm.c"
  || die "Couldn't move farm.c to $dest\n";

system "cp hex2raw $dest/hex2raw"
  || die "Couldn't copy hex2raw to $dest\n";

system "./makecookie $id > $dest/cookie.txt"
  || die "Couldn't generate cookie at $dest\n";

system "cp README-handout.txt $dest/README.txt"
  || die "Couldn't generate cookie at $dest\n";

open OUT, ">$dest/ID.txt" || die "Couldn't open $dest/USERID.txt";
print OUT "user:$user\n" || die "Couldn't write to $dest/USERID.txt";
print OUT "targetid:$id\n" || die "Couldn't write to $dest/USERID.txt";
print OUT "cookie:$cookie\n" || die "Couldn't write to $dest/USERID.txt";
print OUT "authkey:$authkey\n" || die "Couldn't write to $dest/USERID.txt";
close OUT;

if ($solve) {
# Construct solution information
    system "cp ctarget-$id.d $dest/ctarget.d"
	|| die "Couldn't move ctarget disassembly to $dest\n";

    system "cp rtarget-$id.d $dest/rtarget.d"
	|| die "Couldn't move rtarget disassembly to $dest\n";

    system "../solve/readd.pl -f touch1:touch2:touch3 < $dest/ctarget.d > $dest/ctarget.b" || die "Couldn't build ctarget.b\n";

    system "../solve/readd.pl -f touch1:touch2:touch3 -b start_farm:end_farm < $dest/rtarget.d  > $dest/rtarget.b"
	|| die "Couldn't build rtarget.b\n";

    system "../solve/harvest -f start_farm -i $dest/rtarget.b -o $dest/rtarget.g"
	|| die "Couldn't build rtarget.g\n";

    system "../solve/addresses.pl -b $dest/ctarget > $dest/addresses.txt" || die "Couldn't compute offset\n";

    system "../solve/solve-all.pl -t $id -s ../solve" || die "Couldn't generate solutions\n";

    system "cp -p ../solve/README-solve.txt $dest/README-solve.txt"
	|| die "Couldn't copy README-solve.txt to $dest\n";
	
}

# Build .tar file
my $status = system "(cd $dest/..; tar cf target$id.tar target$id/README.txt target$id/ctarget target$id/rtarget target$id/farm.c target$id/cookie.txt target$id/hex2raw)";
if ($status != 0) {
    system("rm -f $dest/../target$id.tar");
    die "buildtarget.pl: Couldn't build .tar file at $dest/..\n";
}

# Clean up
system "rm -f *-$id*";
