/*
  Generate C code containing bytes with which students can construct ROP attacks.
  Also known as a "gadget farm"
*/

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "gencode.h"

/* Maximum number of code words generated */
#define MAX_CODE 200

/* Lab parameters */

/*
  Redundancy count: How many copies of each basic gadget be generated.
  May want > 1 to avoid problems with bad addresses.
*/
#ifdef REDCNT
static int redcnt = REDCNT;
#else
static int redcnt = 2;
#endif     


/*
  Repetition counts:
  How many copies of each basic gadget (or a broken version should be generated.
  Must be >= redundancy count.  Use more as ways to obfuscate gadget farm.

  Numbers may differ for the two levels
*/
#ifdef REP2CNT
static int rep2cnt = REP2CNT;
#else
static int rep2cnt = 2;
#endif     

#ifdef REP3CNT
static int rep3cnt = REP3CNT;
#else
static int rep3cnt = 2;
#endif     

/* Store set of code words */
static unsigned code_set[MAX_CODE];
static int code_cnt = 0;

static void init_code() {
    code_cnt = 0;
}

static void store_code(unsigned code) {
    code_set[code_cnt] = code;
    code_cnt++;
}

/* Randomly permute elements of an array */
static void permute_array(unsigned a[], int len) {
    int i;
    for (i = 0; i < len-1; i++) {
	int idx = i + rval(len-i-1);
	unsigned t = a[idx];
	a[idx] = a[i];
	a[i] = t;
    }
}

static void gen_header(FILE *out) {
    fprintf(out, "/* This function marks the start of the farm */\n");
    fprintf(out, "int start_farm()\n");
    fprintf(out, "{\n");
    fprintf(out, "    return 1;\n");
    fprintf(out, "}\n");
    fprintf(out, "\n");
}

static void gen_middle(FILE *out) {
    fprintf(out, "/* This function marks the middle of the farm */\n");
    fprintf(out, "int mid_farm()\n");
    fprintf(out, "{\n");
    fprintf(out, "    return 1;\n");
    fprintf(out, "}\n");
    fprintf(out, "\n");
    fprintf(out, "/* Add two arguments */\n");
    fprintf(out, "long add_xy(long x, long y)\n");
    fprintf(out, "{\n");
    fprintf(out, "    return x+y;\n");
    fprintf(out, "}\n");
    fprintf(out, "\n");
}

static void gen_footer(FILE *out) {
    fprintf(out, "/* This function marks the end of the farm */\n");
    fprintf(out, "int end_farm()\n");
    fprintf(out, "{\n");
    fprintf(out, "    return 1;\n");
    fprintf(out, "}\n");
    
}

/* Add functions that will encode movq src, dst */
static void add_movq(int src, int dst, int obfuscate, int red_cnt, int rep_cnt)
{
    int i;
    for (i = 0; i < red_cnt; i++) {
	int embed_ret = rbit(0.5);
	store_code(gen_movq_code(src, dst, obfuscate, 0, embed_ret));
    }
    for (i = red_cnt; i < rep_cnt; i++) {
	int embed_ret = rbit(0.5);
	store_code(gen_movq_code(src, dst, obfuscate, 1, embed_ret));
    }
}

/* Add function that will encode movl src, dst */    
static void add_movl(int src, int dst, int obfuscate, int red_cnt, int rep_cnt)
{
    int i;
    for (i = 0; i < red_cnt; i++) {
	int embed_ret = rbit(0.2);
	store_code(gen_movl_code(src, dst, obfuscate, 0, embed_ret));
    }
    for (i = red_cnt; i < rep_cnt; i++) {
	int embed_ret = rbit(0.2);
	store_code(gen_movl_code(src, dst, obfuscate, 1, embed_ret));
    }
}

/* Add functions that will encode popq reg */
static void add_popq(int reg, int obfuscate, int red_cnt, int rep_cnt)
{
    int i;
    for (i = 0; i < red_cnt; i++) {
	int embed_ret = rbit(0.5);
	store_code(gen_pop_code(reg, obfuscate, 0, embed_ret));
    }
    for (i = red_cnt; i < rep_cnt; i++) {
	int embed_ret = rbit(0.5);
	store_code(gen_pop_code(reg, obfuscate, 1, embed_ret));
    }
}

static void write_code(FILE *out, int permute) {
    if (permute)
	permute_array(code_set, code_cnt);
    int i;
    for (i = 0; i < code_cnt; i++) {
	unsigned code = code_set[i];
	gen_function(out, code);
    }
}

static void gen_farm(FILE *out, int permute) {
    unsigned reg[2] = {RCX, RDX};
    /* Randomize registers */
    permute_array(reg, 2);

    gen_header(out);

    /*
      Gadgets needed to call touch2:
      pop cookie to RAX
      movq RAX, RDI
    */
    init_code();
    add_popq(RAX, 1, redcnt, rep2cnt);
    add_movq(RAX, RDI, 1, redcnt, rep2cnt);
    write_code(out, permute);

    gen_middle(out);

    init_code();
    /*
      Gadgets needed to call touch3.
      Registers reg[0] & reg[1] serve as intermediate points
      
      pop offset to RAX
      movl RAX, reg[0]
      movl reg[0], reg[1]
      movl reg[1], RSI
      movq RSP, RAX
      movq RAX, RDI
      lea (RDI, RSI, 1), RAX
      movq RAX, RDI
    */
    add_movq(RSP, RAX, 2, redcnt, rep3cnt);
    add_movl(RAX, reg[0],  2, redcnt, rep3cnt);
    add_movl(reg[0],  reg[1],  2, redcnt, rep3cnt);
    add_movl(reg[1],  RSI, 2, redcnt, rep3cnt);
    write_code(out, permute);

    gen_footer(out);
}



void usage(char *name) {
    printf("Usage: %s [-hp] [-s VAL] [-2 REP2] [-3 REP3] [-r RED] [-o DEST]\n", name);
    printf("    -h     Print help information\n");
    printf("    -p     Permute functions\n");
    printf("    -s VAL Set initial seed\n");
    printf("    -2 REP2 Set number of repetitions of functions in level 2\n");
    printf("    -3 REP3 Set number of repetitions of functions in level 3\n");
    printf("    -r RED Set number of implementations of of each capability\n");
    printf("    -o DEST Specify destination file\n");
    exit(0);
}


int main(int argc, char *argv[]) {
    int permute = 0;
    unsigned seed = 0;
    FILE *out = stdout;
    int opt;
    while ((opt = getopt(argc, argv, "hps:r:2:3:o:")) > 0) {
	switch (opt) {
	case 'h':
	    usage(argv[0]);
	case 'p':
	    permute = 2;
	    break;
	case 's':
	    seed = atoi(optarg);
	    break;
	case '2':
	    rep2cnt = atoi(optarg);
	    break;
	case '3':
	    rep3cnt = atoi(optarg);
	    break;
	case 'r':
	    redcnt = atoi(optarg);
	    break;
	case 'o':
	    out = fopen(optarg, "w");
	    if (out == NULL) {
		fprintf(stderr, "Couldn't open '%s'\n", optarg);
		exit(0);
	    }
	    break;
	default:
	    printf("Invalid option '%c'\n", opt);
	    usage(argv[0]);
	}
    }
    ginit(seed);
    gen_farm(out, permute);
    fclose(out);
    return 0;
}
