#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <unistd.h>
#include <time.h>

#include "target.h"
#include "gencookie.h"
#include "driverlib.h"
#include "config.h"


/* Have option to have stack randomization as either the standard or an option */
#ifndef RANDOMSTACK
#define RANDOMSTACK 1
#endif

/* Is this ctarget or rtarget? */
#ifndef IS_CTARGET
#define IS_CTARGET 1
#endif

/* Put initialization code here, where it can be target-dependent */
/* force_random will cause stack to be randomized from run to run. */
static void initialize_target(int opt_level, int force_random) {
    check_level = opt_level;
    /* Parameters computed from ID */
    cookie = gencookie(target_id);
    authkey = gencookie(cookie);
    srandom(target_id+1);
    unsigned r1 = scramble(random());
    unsigned r2 = 0;
    if (force_random) {
	srandom((unsigned) time(NULL));
	r2 = random();
    }
    buf_offset = 0x100 + 8 * ((r1+r2) % 0x10000);
    target_prefix = IS_CTARGET ? 'c' : 'r';
    if (notify && !is_checker) {
	int i;
	char hostname[MAX_HOSTNAMELEN];
	char status_msg[SUBMITR_MAXBUF];
	int valid_host = 0;
	/* Get the host name of the machine */
	if (gethostname(hostname, MAX_HOSTNAMELEN) != 0) {
	    printf("FAILED: Initialization error: Running on unknown host\n");
	    exit(8);
	}
	/* Make sure it's in the list of legal machines */
	for (i = 0; host_table[i]; i++) {
	    if (strcasecmp(host_table[i], hostname) == 0) {
		valid_host = 1;
		break;
	    }
	}
	if (!valid_host) {
	    printf("FAILED: Initialization error: Running on an illegal host [%s]\n", hostname);
	    exit(8);
	}

	/* Initialize the submitr package */
	if (init_driver(status_msg) < 0) {
	    printf("FAILED: Initialization error:\n%s\n", status_msg);
	    exit(8);
	}
    }
}

/*
 * usage - prints usage information
 */
static void usage(char *name)
{
    if (is_checker) {
	printf("Usage: [-h] %s -i <infile> -a <authkey> -l <level>\n",  name);
	printf("  -h           Print help information\n");
	printf("  -i <infile>  Input file\n");
	printf("  -a <authkey> Authentication key\n");
	printf("  -l <level>   Attack level\n");
    } else {
	printf("Usage: [-hq] %s -i <infile> \n",  name);
	printf("  -h          Print help information\n");
	printf("  -q          Don't submit result to server\n");
	printf("  -i <infile> Input file\n");
    }
    exit(0);
}


/* 
 * main - The main routine
 */


int main(int argc, char *argv[])
{
    char c;
    int stable = !RANDOMSTACK;
    char *optstring = "hqi:";
    unsigned opt_authkey = 0;
    unsigned opt_level = 0;

    /* Install handlers for the inevitable faults */
    signal(SIGSEGV, seghandler);
    signal(SIGBUS,  bushandler);
    signal(SIGILL,  illegalhandler);
    if (is_checker) {
	signal(SIGALRM, sigalrmhandler);
	alarm(CHECKER_TIMEOUT);
	optstring = "hi:a:l:";
    }

    /* Parse command line arguments */
    infile = stdin;
    while ((c = getopt(argc, argv, optstring)) != -1)
	switch(c) {
	case 'h': /* print help info */
	    usage(argv[0]);
	    break;
	case 'i': /* Input file */
	    infile = fopen(optarg, "r");
	    if (!infile) {
		fprintf(stderr, "Cannot open input file '%s'\n", optarg);
		return 1;
	    }
	    break;
	case 'a': /* Authentication key */
	    opt_authkey = strtoul(optarg, NULL, 16);
	    break;
	case 'l': /* Attack level */
	    opt_level = atoi(optarg);
	    break;
	case 'q': /* Quiet */
	    notify = 0;
	    break;
	default:
	    printf("Unknown flag '%c'\n", c);
	    usage(argv[0]);
	}

    /* Initialize the target. */
    initialize_target(opt_level, !stable);
    if (is_checker && opt_authkey != authkey) {
	printf("Supplied authentication key 0x%x != target key\n", opt_authkey);
	check_fail();
    }

    /* Print some basic info */
    printf("Cookie: 0x%x\n", cookie);

    if (stable)
	stable_launch(buf_offset);
    else
	launch(buf_offset);
    return 0;
}

