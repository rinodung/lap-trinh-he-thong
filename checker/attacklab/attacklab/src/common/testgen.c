/* Testing of gadget code generation */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "gencode.h"

void usage(char *name) {
    printf("Usage: %s -h (-p|l|q) [-o LVL] [-d] [-e] [-s VAL] [-n CNT]\n", name);
    printf("    -h     Print help information\n");
    printf("    -p     Test popq\n");
    printf("    -l     Test movl\n");
    printf("    -q     Test movq\n");
    printf("    -o LVL Set obfuscation level (0-2)\n");
    printf("    -d     Disable operation\n");
    printf("    -e     Embed ret\n");
    printf("    -s VAL Set initial seed\n");
    printf("    -n CNT Repeat CNT times\n");
    exit(0);
}

int main(int argc, char *argv[]) {
    int opt;
    int pop = 0;
    int quad = rbit(0.5);
    int obfuscate = 0;
    int disable = 0;
    int embed = 0;
    int cnt = 1;
    int seed = 0;
    while ((opt = getopt(argc, argv, "hplqo:den:s:")) > 0) {
	switch (opt) {
	case 'h':
	    usage(argv[0]);
	case 'p':
	    pop = 1;
	    break;
	case 'l':
	    quad = 0;
	    break;
	case 'q':
	    quad = 1;
	    break;
	case 'o':
	    obfuscate = atoi(optarg);
	    break;
	case 'd':
	    disable = 1;
	    break;
	case 'e':
	    embed = 1;
	    break;
	case 'n':
	    cnt = atoi(optarg);
	    break;
	case 's':
	    seed = atoi(optarg);
	    break;
	default:
	    printf("Invalid option '%c'\n", opt);
	    usage(argv[0]);
	}
    }
    ginit(seed);
    int i;
    for (i = 0; i < cnt; i++) {
	if (pop) {
	    pop_code_test(obfuscate, disable, embed);
	} else {
	    move_code_test(obfuscate, disable, embed, quad);
	}
    }
    return 0;
}
