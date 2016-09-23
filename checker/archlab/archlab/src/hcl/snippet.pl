#!/usr/bin/perl 
#!/usr/local/bin/perl 

# Extract just limited range of text.  Bracketed by $begin / $end directives
# Do not include any line includes $begin or $end

use Getopt::Std;

getopts('s:');

$snippet = "";

if ($opt_s) {
  $snippet = $opt_s;
}

$found = 0;
$tag = "";
while (<>) {
  $line = $_;
  chomp $line;
  if ($line =~ /\/\* \$begin\s(\S+)/) {
    $tag = $1;
    if ($snippet eq $tag) {
      $found = 1;
    }
  } elsif ($line =~ /\/\* \$end\s(\S+)/) {
    $tag = $1;
    if ($snippet eq $tag) {    
      $found = 0;
    }
  } elsif ($found) {
    print "$line\n";
  }
}
