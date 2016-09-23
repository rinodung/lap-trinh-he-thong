#!/usr/bin/perl 
#!/usr/local/bin/perl 

## Script to extract different versions from a single document.
## User gives list of single-character version names <vers>.
## Normal case: Each line has one of three forms:
## <line>: Include <line> in every version
## $<chars>\t<line> Include <line>
##        only if some character in <vers> is in <chars>
## $!<chars>\t<line> Include <line>
##        unless some character in <vers> is in <chars>
use Getopt::Std;

## parse command line arguments
getopts('v:o');

$versions = "";

if ($opt_v) {
    $versions = $opt_v;
}

## process the lines
while (<>) {
    $line = $_;
    if (substr($line,0,1) eq "\$") {
	$pos = index($line, "\t");
	if ($pos < 0) {
	    $pos = length($line)-1;
	}
	if (substr($line,1,1) eq "!") {
	    $include = 1;
	    $chars = substr($line,2,$pos-2);
	} else {
	    $include = 0;
	    $chars = substr($line,1,$pos-1);
	}
	$line = substr($line, $pos+1, length($line) - $pos - 1);
	@tags = split("", $chars);
	$found = 0;
	foreach $c (@tags) {
	    if (index($versions, $c) >= 0) {
		$found = 1;
	    }
	}
	$ok = $include ^ $found;
	if ($ok) {
	    print "$line";
	}
    } else {
      print "$line";
    }
}
