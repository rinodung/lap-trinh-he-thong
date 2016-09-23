/* Harvest gadgets from byte code */

/* Input is text file, consisting of lines of form
   fun_name:start_addr:bytes
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "gencode.h"

int verbose = 0;

typedef enum { OP_NOP, OP_RET, OP_POP, OP_MOVL, OP_MOVQ, OP_ADD } op_t;

/* Action record */
typedef struct ACT act_rec, *act_ptr;

struct ACT {
    unsigned char op;
    unsigned char arg1;
    unsigned char arg2;
    unsigned len;
    act_ptr next;
};
   
static char *opnames[] = { "nop", "ret", "pop", "movl", "movq", "add" };

static char namebuf[100];

static char *show_action(act_ptr act) {
    sprintf(namebuf, "%s %d,%d. len=%d", opnames[act->op], act->arg1, act->arg2, act->len);
    return namebuf;
}

#define RADIX 256

/* Trie node */
typedef struct TRIE trie_rec, *trie_ptr;
struct TRIE {
    trie_ptr children[RADIX];
    act_ptr action;
};


static trie_ptr main_trie = NULL;

static unsigned instr_cnt = 0;
static unsigned trie_cnt = 0;
static unsigned action_cnt = 0;

static trie_ptr new_node()
{
    trie_ptr result = malloc(sizeof(trie_rec));
    int i;
    result->action = NULL;
    for (i = 0; i < RADIX; i++) {
	result->children[i] = NULL;
    }
    trie_cnt++;
    return result;
}

static act_ptr new_action(unsigned char op, unsigned char arg1, unsigned char arg2, unsigned len) {
    act_ptr result = malloc(sizeof(act_rec));
    if (!result) {
	fprintf(stderr, "Malloc returned NULL\n");
	exit(0);
    }
    result->op = op;
    result->arg1 = arg1;
    result->arg2 = arg2;
    result->len = len;
    result->next = NULL;
    action_cnt++;
    return result;
}

static act_ptr dup_action(act_ptr act) {
    act_ptr nact = new_action(act->op, act->arg1, act->arg2, act->len);
    action_cnt--;
    return nact;
}

/* Make complete copy of action list and put designated pointer at end */
static act_ptr deep_dup_action(act_ptr act, act_ptr last) {
    if (act == NULL)
	return last;
    act_ptr nact = dup_action(act);
    nact->next = deep_dup_action(act->next, last);
    return nact;
}

char code_buf[20];
static char *show_code(unsigned code, int len) {
    int i;
    for (i = 0; i < len; i++) {
	unsigned char byte = code & 0xFF;
	sprintf(&code_buf[3*i], " %.2x", byte);
	code >>= 8;
    }
    return code_buf;
}

static void add_to_trie(unsigned code, unsigned len, act_ptr action)
{
    int i;
    unsigned scode = code;
    if (main_trie == NULL)
	main_trie = new_node();
    trie_ptr node = main_trie;
    for (i = 0; i < len; i++) {
	unsigned char byte = code & 0xFF;
	trie_ptr next = node->children[byte];
	if (!next) {
	    next = new_node();
	    node->children[byte] = next;
	    if (verbose >= 3) {
		printf("Added trie node at depth %d for byte %.2x.  Code = %s\n", i+1, byte, show_code(scode, len));
	    }
	}
	code >>= 8;
	node = next;
    }
    act_ptr new_act =  dup_action(action);
    new_act->next = node->action;
    node->action = new_act;
    instr_cnt++;
}

/* Add all the instructions we deal with */
static void build_trie() {
    act_ptr act = new_action(OP_NOP, 0, 0, 1);
    add_to_trie(NOP, 1, act);
    free(act);

    act = new_action(OP_RET, 0, 0, 1);
    add_to_trie(RET, 1, act);
    free(act);

    int r1, r2;
    /* POP instructions */
    for (r1 = 0; r1 < 8; r1++) {
	act = new_action(OP_POP, r1, 0, POP_LEN);
	add_to_trie(POP(r1), POP_LEN, act);
	free(act);
    }

    /* MOVL instructions */
    for (r1 = 0; r1 < 8; r1++) {
	for (r2 = 0; r2 < 8; r2++) {
	    act = new_action(OP_MOVL, r1, r2, MOVL_LEN);
	    add_to_trie(MOVL(r1,r2), MOVL_LEN, act);
	    free(act);
	}
    }

    /* MOVQ instructions */
    for (r1 = 0; r1 < 8; r1++) {
	for (r2 = 0; r2 < 8; r2++) {
	    act = new_action(OP_MOVQ, r1, r2, MOVQ_LEN);
	    add_to_trie(MOVQ(r1,r2), MOVQ_LEN, act);
	    free(act);
	}
    }

    /* LEA instructions targeting RAX */
    for (r1 = 0; r1 < 8; r1++) {
	if (r1 == RSP || r1 == RBP)
	    continue;
	for (r2 = 0; r2 < 8; r2++) {	
	    if (r1 == RSP || r1 == RBP)
		continue;
	    act = new_action(OP_ADD, r1, r2, LEA_LEN);
	    add_to_trie(LEA(r1,r2), LEA_LEN, act);
	    free(act);
	}
    }

    /* NOP2 instructions */
    act = new_action(OP_NOP, 0, 0, NOP2_LEN);
    for (r1 = 0; r1 < 4; r1++) {
	for (r2 = 0; r2 < 4; r2++) {
	    add_to_trie(nop2(r1,r2), NOP2_LEN, act);
	}
    }
    free(act);

    /* Print statistics */
    if (verbose >= 1)
	printf("%d instructions, %d actions, %d trie nodes\n", instr_cnt, action_cnt, trie_cnt);
}

#define MAXBYTES 100000

static unsigned char bytes[MAXBYTES];
static act_ptr actions[MAXBYTES];

static int byte_cnt = 0;

static size_t start_addr;

/* Functions to aid in reading information */
/* Read single field in colon-separated list */
static size_t read_field(FILE *in, char *dest, size_t maxlen)
{
    int c;
    size_t cnt;
    for (cnt = 0; cnt < maxlen; cnt++) {
	c = getc(in);
	if (c == '\n' || c == EOF || c == ':')  {
	    dest[cnt] = '\0';
	    return cnt;
	}
	dest[cnt] = c;
    }
    dest[cnt] = '\0';
    /* Hit limit.  Skip to end of field */
    while ((c = getc(in)) != EOF && c != '\n' && c != ':')
	;
    return cnt;
}

/* Skip to end of line in file */
static void skipline(FILE *in) {
    int c;
    while ((c = getc(in)) != EOF && c != '\n')
	;
}

static int hexchar(int c) {
    if (c >= '0' && c <= '9')
	return c - '0';
    if (c >= 'a' && c <= 'f')
	return c - 'a' + 0xa;
    if (c >= 'A' && c <= 'F')
	return c - 'A' + 0xA;
    return -1;
}

/* Read hex-formatted byte and store at bdest */
/* Return 1 if successful */
static int read_byte(FILE *in, unsigned char *bdest) {
    int ival;
    unsigned char val;
    int c;
    /* Skip over any blanks */
    while ((c = getc(in)) != EOF && c != ':' && c != '\n'
	   && (c == ' ' || c == '\t'))
	;
    if (c == EOF || c == ':' || c == '\n') {
	/* No digit found */
	return 0;
    }
    /* Read at most 2 characters */
    ival = hexchar(c);
    if (ival < 0) {
	fprintf(stderr, "Encountered non-hex character '%c'\n", c);
	exit(1);
    }
    val = ival;
    c = getc(in);
    if (c == EOF || c == ':' || c == '\n') {
	/* Line ended with single character hex field */
	ungetc(c, in);
	*bdest = val;
	return 1;
    }
    if (c == ' ' || c == '\t') {
	/* Field was single digit */
	*bdest = val;
	return 1;
    }
    ival = hexchar(c);
    if (ival < 0) {
	fprintf(stderr, "Encountered non-hex character '%c'\n", c);
	exit(1);
    }
    val = val * 16 + ival;
    *bdest = val;
    return 1;
}


#define BLEN 100
/* Read in bytes starting with function start_fun */
static void load_bytes(FILE *in, char *fun_name) {
    char buf[BLEN];
    /* Find correct line */
    int found = 0;
    while (!found) {
	read_field(in, buf, BLEN);
	if (strcmp(buf, fun_name) == 0) {
	    found = 1;
	    read_field(in, buf, BLEN);
	    start_addr = strtoul(buf, NULL, 16);
	} else {
	    /* Skip over rest of this line */
	    skipline(in);
	}
    }
    if (!found) {
	fprintf(stderr, "Couldn't find starting address for %s\n", fun_name);
	exit(1);
    }
    /* Read bytes */
    while (byte_cnt < MAXBYTES && read_byte(in, &bytes[byte_cnt]))
	byte_cnt++;
    if (verbose >= 1)
	printf("Byte sequence: start_address = 0x%lx, %d bytes\n", start_addr, byte_cnt);
}

#define MAXDEPTH 5
static void pass_forward() {
    trie_ptr nodes[MAXDEPTH];
    size_t bpos;
    int depth;
    for (depth = MAXDEPTH-1; depth >= 0; depth--)
	nodes[depth] = NULL;
    for (bpos = 0; bpos < byte_cnt; bpos++) {
	unsigned char byte = bytes[bpos];
	if (verbose >= 2)
	    printf("Processing position 0x%lx.  Byte %.2x\n", bpos, byte);
	nodes[0] = main_trie;
	/* Move along existing tries */
	for (depth = MAXDEPTH-1; depth >= 0; depth--) {
	    trie_ptr nd = nodes[depth];
	    nodes[depth] = NULL;
	    if (nd) {
		trie_ptr next = nd->children[byte];
		if (next && depth < MAXDEPTH-1) {
		    nodes[depth+1] = next;
		}
		if (nd->action) {
		    actions[bpos] = deep_dup_action(nd->action, actions[bpos]);
		}
	    }
	}
	if (verbose >= 2 && actions[bpos]) {
	    printf("Actions at position 0x%lx.  Byte code = %.2x:\n", bpos, byte);
	    act_ptr act = actions[bpos];
	    while (act) {
		printf("\t%s\n", show_action(act));
		act = act->next;
	    }
	}
    }
}

/* Check that address does not contain character code for '\n' */
static int address_ok(size_t addr)
{
    int ok = 1;
    int i;
    for (i = 0; i < sizeof(size_t); i++)
	if (((addr>>(8*i)) & 0xff) == '\n')
	    ok = 0;
    return ok;
}

/* Print byte sequence for gadget that starts at bpos */
static void print_gadget_bytes(FILE *out, size_t bpos) {
    unsigned b;
    do {
	b = bytes[bpos++];
	fprintf(out, "%.2x ", b);
    } while (b != RET && bpos < byte_cnt);
    fprintf(out, "\n");
}

static void print_gadget(FILE *out, act_ptr act, size_t bpos) {
    size_t addr = start_addr + bpos;
    int ok = address_ok(addr);
    char *okstr = ok ? "" : "X";
    switch (act->op) {
    case OP_POP:
	fprintf(out, "%lx:%s%s:%d::", addr, okstr, opnames[act->op], act->arg1);
	break;
    case OP_MOVL:
    case OP_MOVQ:
    case OP_ADD:
	fprintf(out, "%lx:%s%s:%d:%d:", addr, okstr, opnames[act->op], act->arg1, act->arg2);
	break;
    default:
	fprintf(out, "%lx:%s%s:::", addr, okstr, opnames[act->op]);
	break;
    }
    print_gadget_bytes(out, bpos);
}

/* Do reverse traversal of actions from bpos */
static void rtraverse(FILE *out, size_t bpos)
{
    if (bpos >= byte_cnt)
	return;
    if (verbose >= 2) {
	printf("Starting reverse traversal at 0x%lx.  Code = %.2x\n", bpos, bytes[bpos]);
    }
    act_ptr act = actions[bpos];
    while (act) {
	if (act->op == OP_NOP) {
	    rtraverse(out, bpos - act->len);
	} else if (act->op == OP_POP || act->op == OP_MOVL || act->op == OP_MOVQ || act->op == OP_ADD) {
	    print_gadget(out, act, bpos-act->len);
	}
	act = act->next;
    }
}

static void pass_backward(FILE *out) {
    size_t bpos;
    for (bpos = byte_cnt-1; bpos < byte_cnt; bpos--) {
	act_ptr act = actions[bpos];
	while (act) {
	    if (act->op == OP_RET) {
		if (verbose >= 2) {
		    printf("Found ret at 0x%lx\n", bpos);
		}
		rtraverse(out, bpos - act->len);
	    }
	    act = act->next;
	}
    }
}

static void usage(char *name) {
    printf("Usage: %s -h [-f FUN] [-i IN] [-o OUT] [-v LVL]\n", name);
    printf("    -h     Print help information\n");
    printf("    -f FUN Specify starting function name\n");
    printf("    -i IN  Specify input file\n");
    printf("    -o OUT Specify output file\n");
    printf("    -v LVL Set verbosity level (0-2)\n");
    exit(0);
}


int main(int argc, char *argv[]) {
    FILE *infile = stdin;
    FILE *outfile = stdout;
    char *start_fun = "start_farm";
    int opt;
    while ((opt = getopt(argc, argv, "hf:i:o:v:")) > 0) {
	switch(opt) {
	case 'h':
	    usage(argv[0]);
	    break;
	case 'v':
	    verbose = atoi(optarg);
	    break;
	case 'f':
	    start_fun = strdup(optarg);
	    break;
	case 'i':
	    infile = fopen(optarg, "r");
	    if (infile == NULL) {
		fprintf(stderr, "Couldn't open input file '%s'\n", optarg);
		exit(1);
	    }
	    break;
	case 'o':
	    outfile = fopen(optarg, "w");
	    if (outfile == NULL) {
		fprintf(stderr, "Couldn't open output file '%s'\n", optarg);
		exit(1);
	    }
	    break;
	default:
	    fprintf(stderr, "Unrecognized option '%c'\n", opt);
	    usage(argv[0]);
	    break;
	}
	
    }

    build_trie();
    load_bytes(infile, start_fun);
    fclose(infile);
    pass_forward();
    pass_backward(outfile);
    fclose(outfile);
    return 0;
}
