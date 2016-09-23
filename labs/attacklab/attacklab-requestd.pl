#!/usr/bin/perl
require 5.002;

#######################################################################
# attacklab-requestd.pl - The CS:APP Attack Lab Request Daemon
#
# Copyright (c) 2016, R. Bryant and D. O'Hallaron
#
# The request daemon is a simple special-purpose HTTP server that
# allows students to use their Web browser to request custom made
# targets and to view the realtime scoreboard.
#
# Students request a target by pointing their browser at
#
#     http://$SERVER_NAME:$REQUESTD_PORT
#
# After they submit the resulting form with their personal
# information, the server builds a custom target for the student, tars
# it up and returns the tar file to the browser.
#
# Students check the realtime scoreboard by pointing their browser at
#
#    http://$SERVER_NAME:$REQUESTD_PORT/scoreboard
#
#######################################################################

use strict 'vars';
use Getopt::Std;
use Socket;
use Sys::Hostname; 
use Cwd;

use lib ".";
use Attacklab;

# 
# Generic settings
#
$| = 1;          # Autoflush output on every print statement
$0 =~ s#.*/##s;  # Extract the base name from argv[0] 

# 
# Ignore any SIGPIPE signals caused by the server writing 
# to a connection that has already been closed by the client.
# Also ignore SIGTTIN and SIGTTOUT signals that could cause 
# the request server to be suspended.
$SIG{PIPE} = 'IGNORE'; 
$SIG{TTIN} = 'IGNORE'; 
$SIG{TTOUT} = 'IGNORE'; 

#
# Canned client error messages
#
my $bad_usermail_msg = "Invalid email address.";
my $usermail_taint_msg = "The email address contains an illegal character.";
my $bad_username_msg = "You forgot to enter a user name.";
my $username_taint_msg = "The user name contains an illegal character.";

#
# Configuration variables from Attacklab.pm
#
my $server_dname = $Attacklab::SERVER_NAME;
my $server_port = $Attacklab::REQUESTD_PORT;

#
# Other variables 
#
my $labid = ""; # Not needed for Attacklab
my ($client_port, $client_dname, $client_iaddr);
my $request_hdr;
my $content;
my ($usermail, $username);
my ($targetnum, $maxtargetnum);
my $item;
my $tarfilename;
my $buffer;
my @targets=();

##############
# Main routine
##############

# 
# Parse and check the command line arguments
#
no strict 'vars';
getopts('hq');
if ($opt_h) {
    usage("");
}

$Targetlab::QUIET = 0;
if ($opt_q) {
    $Targetlab::QUIET = 1;
}
use strict 'vars';

#
# Print a startup message
#
log_msg("Request server started on $server_dname:$server_port");

#
# Make sure the files and directories we need are available
#
(-e "$Attacklab::TARGETSRC/$Attacklab::BUILDTARGET" and -x "$Attacklab::TARGETSRC/$Attacklab::BUILDTARGET")
    or log_die("Error: Couldn\'t find an executable $Attacklab::TARGETSRC/$Attacklab::BUILDTARGET script.");

(-e $Attacklab::TARGETDIR)
    or system("mkdir ./$Attacklab::TARGETDIR");

#
# Establish a listening descriptor
# 
socket(SERVER, PF_INET, SOCK_STREAM, getprotobyname('tcp'))
    or log_die("socket: $!");
setsockopt(SERVER, SOL_SOCKET, SO_REUSEADDR, 1)
    or log_die("setsockopt: $!");
bind(SERVER, sockaddr_in($server_port, INADDR_ANY))
    or log_die("Couldn't bind to port $server_port: $!");
listen(SERVER, SOMAXCONN)     
    or log_die("listen: $!");

# LH: On alarm signal (server is hung processing a client request),
# die with message that it happened. The server will then be
# automatically restarted.
$SIG{ALRM} = sub { log_die( "alarm\n") };

#
# Repeatedly wait for scoreboard, form, and target requests
#
while (1) {

    # LH: Cancel alarm before waiting for client request
    alarm(0);

    # 
    # Wait for a connection request from a client
    #
    my $client_paddr = accept(CLIENT, SERVER)
        or log_die "accept: $!\n";

    # LH: Set an alarm for a few seconds, to prevent the server hanging
    # while serving a client
    alarm($Attacklab::REQUESTD_TIMEOUT);

    ($client_port, $client_iaddr) = sockaddr_in($client_paddr);
    $client_dname = gethostbyaddr($client_iaddr, AF_INET);

    # 
    # Read the request header (the first text line in the request)
    #
    $request_hdr = <CLIENT>;
    chomp($request_hdr);

    #
    # Ignore requests for favicon.ico
    #
    # NOTE: To avoid memory leak, be careful to close CLIENT fd before 
    # each "next" statement in this while loop.
    #
    if ($request_hdr =~ /favicon/) {
        #log_msg("Ignoring favicon request");
        close CLIENT; 
        next;         
    }

    #
    # If this is a scoreboard request, then simply return the scoreboard
    #
    if ($request_hdr =~ /\/scoreboard/) {
        $content = "No scoreboard yet...";
        if (-e $Attacklab::SCOREBOARDPAGE) {
            $content = `cat $Attacklab::SCOREBOARDPAGE`;
        }
        sendform($content);
    }

    # 
    # If there aren't any specific HTML form arguments, then we interpret
    # this as an initial request for an HTML form. So we build the 
    # form and send it back to the client.
    #

    elsif (!($request_hdr =~ /usermail=/)) {
        #log_msg("Form request from $client_dname");
        sendform(buildform($server_dname, $server_port, $labid, 
                           "", "", "", "", ""));
    }

    #
    # If this is a reset request, just send the client a clean form
    #
    elsif ($request_hdr =~ /reset=/) {
        #log_msg("Reset request from $client_dname");
        sendform(buildform($server_dname, $server_port, $labid, 
                           "", "", "", "", ""));
    }

    # Otherwise, since it's not a reset (clean form) request and the
    # URI contains a specific HTML form argument, we interpret this as
    # a target request.  So we parse the URI, build the target, tar it up,
    # and transfer it back over the connection to the client.

    else {
        

        #
        # Undo the browser's URI translations of special characters
        #
        $request_hdr =~ s/%25/%/g;  # Do first to handle %xx inputs

        $request_hdr =~ s/%20/ /g; 
        $request_hdr =~ s/\+/ /g; 
        $request_hdr =~ s/%21/!/g;  
        $request_hdr =~ s/%23/#/g;  
        $request_hdr =~ s/%24/\$/g; 
        $request_hdr =~ s/%26/&/g;  
        $request_hdr =~ s/%27/'/g;    
        $request_hdr =~ s/%28/(/g;    
        $request_hdr =~ s/%29/)/g;    
        $request_hdr =~ s/%2A/*/g;    
        $request_hdr =~ s/%2B/+/g;    
        $request_hdr =~ s/%2C/,/g;    
        $request_hdr =~ s/%2D/-/g;    
        $request_hdr =~ s/%2d/-/g;    
        $request_hdr =~ s/%2E/./g;    
        $request_hdr =~ s/%2e/./g;    
        $request_hdr =~ s/%2F/\//g;    

        $request_hdr =~ s/%3A/:/g;    
        $request_hdr =~ s/%3B/;/g;    
        $request_hdr =~ s/%3C/</g;    
        $request_hdr =~ s/%3D/=/g;    
        $request_hdr =~ s/%3E/>/g;    
        $request_hdr =~ s/%3F/?/g;    

        $request_hdr =~ s/%40/@/g;

        $request_hdr =~ s/%5B/[/g;
        $request_hdr =~ s/%5C/\\/g;
        $request_hdr =~ s/%5D/[/g;
        $request_hdr =~ s/%5E/\^/g;
        $request_hdr =~ s/%5F/_/g;
        $request_hdr =~ s/%5f/_/g;

        $request_hdr =~ s/%60/`/g;

        $request_hdr =~ s/%7B/\{/g;
        $request_hdr =~ s/%7C/\|/g;
        $request_hdr =~ s/%7D/\}/g;
        $request_hdr =~ s/%7E/~/g;


        # Parse the request URI to get the user information
        $request_hdr =~ /username=(.*)&usermail=(.*)&/;
        $username = $1;
        $usermail = $2;

        #
        # For security purposes, make sure the form inputs contain only 
        # non-shell metacharacters. The only legal characters are spaces, 
        # letters, numbers, hyphens, underscores, at signs, and dots.
        #

        # email field
        if ($usermail ne "") {
            if (!($usermail =~ /^([\s-\@\w.]+)$/)) {
                log_msg ("Invalid target request from $client_dname: Illegal character in email address ($usermail):"); 
                sendform(buildform($server_dname, $server_port, $labid, 
                                   $usermail, $username, 
                                   $usermail_taint_msg));
                close CLIENT;
                next;
            }
        }

        # user name field
        if ($username ne "") {
            if (!($username =~ /^([\s-\@\w.]+)$/)) {
                log_msg ("Invalid target request from $client_dname: Illegal character in user name ($username):"); 
                sendform(buildform($server_dname, $server_port, $labid, 
                                   $usermail, $username, 
                                   $username_taint_msg));
                close CLIENT;
                next;
            }
        }

        # The user name field is also required. If it's not filled in,
        # or it's all blanks, then it's invalid
        if (!$username or $username eq "" or $username =~ /^ +$/) {
            log_msg ("Invalid target request from $client_dname: Missing user name:");

            sendform(buildform($server_dname, $server_port, $labid, 
                               $usermail, $username, 
                               $bad_username_msg)); 
            close CLIENT;
            next;
        }


        #
        # The user mail field is required. If it's not filled in,
        # or it's all blanks, or it doesn't have an @ sign, then it's invalid
        #
        if (!$usermail or $usermail eq "" or 
            $usermail =~ /^ +$/ or
            !($usermail =~ /\@/)) {
            log_msg ("Invalid target request from $client_dname: Invalid email address ($usermail):"); 
            sendform(buildform($server_dname, $server_port, $labid, 
                               $usermail, $username, 
                               $bad_usermail_msg));
            close CLIENT;
            next;
        }

        #
        # Everything checks out OK. So now we build and deliver the 
        # target to the client.
        # 
        log_msg ("Received target request from $client_dname:$username:$usermail:");
        
        # Get a list of all of the targets in the targets directory
        opendir(DIR, $Attacklab::TARGETDIR) 
            or log_die "ERROR: Couldn't open $Attacklab::TARGETDIR\n";
        @targets = grep(/target/, readdir(DIR)); 
        closedir(DIR);
        
        #
        # Find the largest target number, being careful to use numeric 
        # instead of lexicographic comparisons.
        #
        map s/target//, @targets;
        $maxtargetnum = 0;
        foreach $item (@targets) {
            if ($item > $maxtargetnum) {
                $maxtargetnum = $item;
            }
        } 
        $targetnum = $maxtargetnum + 1;
        
        #
        # Build a new target
        #
        my $owd = getcwd();
        log_msg("Start building target target$targetnum for $username");
        system("(cd $Attacklab::TARGETSRC; ./$Attacklab::BUILDTARGET -u $username -t $targetnum  >> $owd/$Attacklab::STATUSLOG 2>&1)") == 0
            or log_die "ERROR: Couldn't make target$targetnum\n";
        log_msg("Finished building target target$targetnum for $username");
        
        #
        # Tar up the target
        #
#        log_msg("Start creating tarfile of target$targetnum for $username");
#        $tarfilename = "target$targetnum.tar";
#        system("(cd $Attacklab::TARGETDIR; tar cf $tarfilename target$targetnum/README.txt target$targetnum/ctarget target$targetnum/rtarget target$targetnum/farm.c target$targetnum/cookie.txt target$targetnum/hex2raw > /dev/null 2>&1)") == 0
#            or log_die "ERROR: Couldn't tar $tarfilename\n";
#        log_msg("Finished creating tarfile of target$targetnum for $username");
        
        #
        # Now send the target across the connection to the client
        #
        $tarfilename = "target$targetnum.tar";
        print CLIENT "HTTP/1.0 200 OK\r\n";
        print CLIENT "Connection: close\r\n";
        print CLIENT "MIME-Version: 1.0\r\n";
        print CLIENT "Content-Type: application/x-tar\r\n";
        print CLIENT "Content-Disposition: file; filename=\"$tarfilename\"\r\n";
        print CLIENT "\r\n"; 
        open(INFILE, "$Attacklab::TARGETDIR/$tarfilename")
            or log_die "ERROR: Couldn't open $tarfilename\n";
        binmode(INFILE, ":raw");
        binmode(CLIENT, ":raw");
        select((select(CLIENT), $| = 1)[0]);
        while (sysread(INFILE, $buffer, 1)) {
            syswrite(CLIENT, $buffer, 1);
        }
        close(INFILE);
        
        # 
        # Log the successful delivery of the target to the browser
        #
        log_msg ("Sent target $targetnum to $client_dname:$username:$usermail:");
        
        # 
        # Remove the tarfile
        # 
#        unlink("$Attacklab::TARGETDIR/$tarfilename")
#            or log_die "ERROR: Couldn't delete $tarfilename: $!\n";

    } # if-then-elsif-else statement

    #
    # Close the client connection after each request/response pair
    #
    close CLIENT;

} # while loop

exit;

###################
# Helper functions
##################

#
# void usage(void) - print help message and terminate
#
sub usage 
{
    printf STDERR "$_[0]\n";
    printf STDERR "Usage: $0 [-hqs]\n";
    printf STDERR "Options:\n";
    printf STDERR "  -h   Print this message.\n";
    printf STDERR "  -q   Quiet. Send error and status msgs to $Attacklab::STATUSLOG instead of tty.\n";
    die "\n" ;
}

#
# char *buildform(char *hostname, int port, char *labid, 
#                 char *usermail, char *username,
#                 *char *errmsg)
#
# This routine builds an HTML form as a single string.
# The <hostname,port> pair identifies the request daemon.
# The labid is the unique name for this instance of the Lab.
# The user* fields define the default values for the HTML form fields. 
# The errmsg is optional and informs users about input mistakes.
#
sub buildform 
{
    my $hostname = $_[0];
    my $port = $_[1];
    my $labid = $_[2];
    my $usermail = $_[3];
    my $username = $_[4];
    my $errmsg = $_[5];
    my $form = "";
    $form .= "<html><title>CS:APP Attack Lab Target Request</title>\n";
    $form .= "<body bgcolor=white>\n";
    $form .= "<h2>CS:APP Attack Lab Target Request</h2>\n";
    $form .= "<p>Fill in the form and then click the Submit button once to download your unique target.</p>\n";
    $form .= "<p>It takes a few seconds to build your target, so please be patient.</p>\n";
    $form .= "<p>Hit the Reset button to get a clean form.</p>\n";
    $form .= "<p>Legal characters are spaces, letters, numbers, underscores ('_'),<br>";
    $form .= "hyphens ('-'), at signs ('\@'), and dots ('.').</p>\n";
    $form .= "<form action=http://$hostname:$port method=get>\n";
    $form .= "<table>\n";
    $form .= "<tr>\n";
    $form .= "<td><b>User name</b><br><font size=-1><i>$Attacklab::USERNAME_HINT&nbsp;</i></font></td>\n";
    $form .= "<td><input type=text size=$Attacklab::MAX_TEXTBOX maxlength=$Attacklab::MAX_TEXTBOX name=username value=\"$username\"></td>\n";
    $form .= "</tr>\n";
    $form .= "<tr>\n";
    $form .= "<td><b>Email address</b></td>\n";
    $form .= "<td><input type=text size=$Attacklab::MAX_TEXTBOX maxlength=$Attacklab::MAX_TEXTBOX name=usermail value=\"$usermail\"></td>\n";
    $form .= "</tr>\n";
    $form .= "<tr><td>&nbsp;</td></tr>\n";
    $form .= "<tr>\n";
    $form .= "<td><input type=submit name=submit value=\"Submit\"></td>\n";
    $form .= "<td><input type=submit name=reset value=\"Reset\"></td>\n";
    $form .= "</tr>\n";
    $form .= "</table></form>\n";
    if ($errmsg and $errmsg ne "") {
        $form .= "<p><font color=red><b>$errmsg</b></font><p>\n";
    }
    $form .= "</body></html>\n";
    return $form;
}

#
# void sendform(char *form) - Sends a form to the client   
#
sub sendform
{
    my $form = $_[0];
    my $formlength = length($form);
    print CLIENT "HTTP/1.0 200 OK\r\n";
    print CLIENT "MIME-Version: 1.0\r\n";
    print CLIENT "Content-Type: text/html\r\n";
    print CLIENT "Content-Length: $formlength\r\n";
    print CLIENT "\r\n"; 
    print CLIENT $form;
}

