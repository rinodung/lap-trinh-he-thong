#include <stdio.h>
#include <stdlib.h>
#include "gencode.h"

#define MIN_ID 100
#define MAX_ID 500

char *rname[8] = {"rax", "rcx", "rdx", "rbx", "rsp", "rbp", "rsi", "rdi"};
char *ename[8] = {"eax", "ecx", "edx", "ebx", "esp", "ebp", "esi", "edi"};

/* Keep track of which unique IDs have been generated */
static unsigned id_set[MAX_ID-MIN_ID];

void ginit(unsigned cookie)
{
    srandom(cookie);
    int i;
    for (i = 0; i < MAX_ID-MIN_ID; i++)
	id_set[i] = 0;
}

/* Generate random value */
int rval(unsigned max) {
    return random() % (max+1);
}

/* Generate unique ID */
unsigned gen_id() {
    unsigned val;
    do {
	val = MIN_ID + rval(MAX_ID-MIN_ID-1);
    } while (id_set[val-MIN_ID] == 1);
    id_set[val-MIN_ID] = 1;
    return val;
}


#define RANGE 1000000
/* Weighted random bit generation */
int rbit(float wt) {
    unsigned choice = rval(RANGE-1);
    return (wt * RANGE > choice);
}

/* Generate random byte sequence */
static unsigned rbytes(int cnt) {
    unsigned result = 0;
    while (cnt) {
	result = (result << 8) + rval(255);
	cnt--;
    }
    return result;
}

static unsigned code_movl(int src, int dst, int disable) {
    unsigned op = MOVL(src, dst);
    if (disable) {
	int bit = rval(7);
	op ^= (1 << bit);
    }
    return op;
}

static unsigned code_movq(int src, int dst, int disable) {
    unsigned op = MOVQ(src, dst);
    if (disable) {
	int bit = rval(15);
	op ^= (1 << bit);
    }
    return op;
}

/* Have identified 4 X 4 2-byte function nops
   Each identified by two identifiers, ranging from 0 to 3
*/
unsigned nop2(unsigned oidx, unsigned ridx) {
    unsigned char ops[] = {0x08, 0x20, 0x38, 0x84};
    unsigned op = ops[oidx];
    unsigned reg = 0xc0 + 9*ridx;
    return INT2(op, reg);
}

static unsigned gen_nop2(int disable)
{
    /* Opcodes for andb, orb, cmpb, and testb */
    int oidx = rval(3);
    int ridx = rval(3);
    unsigned result = nop2(oidx, ridx);
    if (disable) {
	result ^= 1 << (4 + rval(2));
    }
    return result;
}

static unsigned gen_nop(int disable) {
    unsigned result = NOP;
    if (disable) {
	result ^= (1 << rval(2));
    }
    return result;
}

static unsigned gen_pop(int reg, int disable) {
    unsigned result = POP(reg);
    if (disable) {
	int bit = 3 + rval(4);
	result ^= (1 << bit);
    }
    return result;
}

static unsigned gen_ret(int disable) {
    unsigned result = RET;
    if (disable) {
	result ^= (1 << rval(2));
    }
    return result;
}

/* Generate unsigned number embedding opcode with given length plus ret */
static unsigned embed_op_ret(unsigned op, int len, int obfuscate, int disable)
{
    /*
      From low to high, word will consist of:
      fill_low op nop* ret fill_high
      where fill_high and fill_low are arbitrary byte sequences
      Include nop's only when obfuscating
    */
    int fill_low_len = sizeof(unsigned) - len - 1;
    int nop_len = 0;
    if (fill_low_len > 0 && obfuscate > 0) {
	nop_len = rval(fill_low_len);
	fill_low_len -= nop_len;
    }
    int fill_high_len = 0;
    if (fill_low_len > 0) {
	fill_high_len = rval(fill_low_len);
	fill_low_len -= fill_high_len;
    }
    /* Construct pieces */
    unsigned fill_low = rbytes(fill_low_len);
    unsigned fill_high = rbytes(fill_high_len);
    unsigned nop = 0;
    int cnt = nop_len;
    while (obfuscate > 1 && rbit(0.7) && cnt >= 2) {
	int dis = disable ? rbit(0.3) : 0;
	disable -= dis;
	nop = (nop << 16) + gen_nop2(dis);
	cnt -= 2;
    }
    while (cnt > 0) {
	int dis = disable ? rbit(0.5) : 0;
	disable -= dis;
	nop = (nop << 8) + gen_nop(dis);
	cnt--;
    }
    unsigned result = fill_high;
    result = (result << 8) + gen_ret(disable);
    result = (result << (8*nop_len)) + nop;
    result = (result << (8*len)) + op;
    result = (result << (8*fill_low_len)) + fill_low;
    return result;
}    

/* Generate unsigned number embedding opcode with given length, without ret */
static unsigned embed_op(unsigned op, int len, int obfuscate, int disable)
{
    /*
      From low to high, word will consist of:
      fill_low op nop*
      where fill_low is arbitrary byte sequence
      Include nop's only when obfuscating
    */
    /* If disabling this sequence, need to have at least one nop */
    int nop_len = disable;
    /* If doing high level of obfuscation, want to bias toward use of 2-byte nop */
    if (obfuscate > 1 && sizeof(unsigned) - len >= 2 && rbit(0.8))
	nop_len = 2;
    int fill_low_len = sizeof(unsigned) - len - nop_len;
    if (fill_low_len > 0 && obfuscate > 0) {
	int add_len = rval(fill_low_len);
	nop_len += add_len;
	fill_low_len -= add_len;
    }
    /* Construct pieces */
    unsigned fill_low = rbytes(fill_low_len);
    unsigned nop = 0;
    int cnt = nop_len;
    while (obfuscate > 1 && rbit(0.9) && cnt >= 2) {
	int dis = 0;
	if (disable) {
	    dis = (cnt > 2) ? rval(0.5) : 1;
	}
	disable -= dis;
	nop = (nop << 16) + gen_nop2(dis);
	cnt -= 2;
    }
    while (cnt > 0) {
	int dis = 0;
	if (disable) {
	    dis = (cnt > 1) ? rval(0.5) : 1;
	}
	disable -= dis;
	nop = (nop << 8) + gen_nop(dis);
	cnt--;
    }
    unsigned result = nop;
    result = (result << (8*len)) + op;
    result = (result << (8*fill_low_len)) + fill_low;
    return result;
}    

unsigned gen_movq_code(int src, int dst, int obfuscate, int disable, int embed_ret)
{
    int disable_op = disable ? rbit(0.5) : 0;
    int disable_rest = disable - disable_op;
    unsigned op = code_movq(src, dst, disable_op);
    unsigned code = embed_ret ?
	embed_op_ret(op, MOVQ_LEN, obfuscate, disable_rest) :
	embed_op(op, MOVQ_LEN, obfuscate, disable_rest);
    return code;
}

unsigned gen_movl_code(int src, int dst, int obfuscate, int disable, int embed_ret)
{
    int disable_op = disable ? rbit(0.5) : 0;
    int disable_rest = disable - disable_op;
    unsigned op = code_movl(src, dst, disable_op);
    unsigned code = embed_ret ?
	embed_op_ret(op, MOVL_LEN, obfuscate, disable_rest) :
	embed_op(op, MOVL_LEN, obfuscate, disable_rest);
    return code;
}

unsigned gen_pop_code(int reg, int obfuscate, int disable, int embed_ret)
{
    int disable_op = disable ? rbit(0.5) : 0;
    int disable_rest = disable - disable_op;
    unsigned op = gen_pop(reg, disable_op);
    unsigned code = embed_ret ?
	embed_op_ret(op, POP_LEN, obfuscate, disable_rest) :
	embed_op(op, POP_LEN, obfuscate, disable_rest);
    return code;
}

/* Generate C functions */

static void gen_add(FILE *out, unsigned code, unsigned id) {
    fprintf(out, "unsigned addval_%u(unsigned x)\n", id);
    fprintf(out, "{\n");
    fprintf(out, "    return x + %uU;\n", code);
    fprintf(out, "}\n");
    fprintf(out, "\n");
}

static void gen_get(FILE *out, unsigned code, unsigned id) {
    fprintf(out, "unsigned getval_%u()\n", id);
    fprintf(out, "{\n");
    fprintf(out, "    return %uU;\n", code);
    fprintf(out, "}\n");
    fprintf(out, "\n");
}

static void gen_set(FILE *out, unsigned code, unsigned id) {
    fprintf(out, "void setval_%u(unsigned *p)\n", id);
    fprintf(out, "{\n");
    fprintf(out, "    *p = %uU;\n", code);
    fprintf(out, "}\n");
    fprintf(out, "\n");
}

void gen_function(FILE *out, unsigned code)
{
    int fun_type = rval(2);
    switch (fun_type) {
    case 0:
	gen_add(out, code, gen_id());
	break;
    case 1:
	gen_get(out, code, gen_id());
	break;
    case 2:
	gen_set(out, code, gen_id());
	break;
    }
}    


/* Testing code */

static char *suffixes[] = {"ax", "cx", "dx", "bx", "sp", "bp", "si", "di"};

/* Convert into assembly code */
void format_move(char *buf, int src, int dst, int quad) {
    char *fstring = quad ? "movq %%r%s, %%r%s" : "movl %%e%s, %%e%s";
    sprintf(buf, fstring, suffixes[src], suffixes[dst]);
}

/* Convert into assembly code */
void format_pop(char *buf, int reg)
{
    sprintf(buf, "popq %%r%s", suffixes[reg]);
}

void format_word(char *buf, unsigned w) {
    int i;
    for (i = 0; i < sizeof(unsigned); i++) {
	unsigned b = w & 0xFF;
	w >>= 8;
	sprintf(buf, "%.2x ", b);
	buf += 3;
    }
}

void move_code_test(int obfuscate, int disable, int embed_ret, int quad)
{
    int src = rval(7);
    int dst = rval(7);
    unsigned code = quad ?
	gen_movq_code(src, dst, obfuscate, disable, embed_ret) :
	gen_movl_code(src, dst, obfuscate, disable, embed_ret);
    char *rstring = embed_ret ? "" : "; ret";
    char *cstring = embed_ret ? "" : " + c3" ;
    char ibuf[40];
    char cbuf[20];
    format_move(ibuf, src, dst, quad);
    format_word(cbuf, code);
    printf("%s%s --> %s%s\n", ibuf, rstring, cbuf, cstring);
}

void pop_code_test(int obfuscate, int disable, int embed_ret)
{
    int reg= rval(7);
    unsigned code = gen_pop_code(reg, obfuscate, disable, embed_ret);
    char *rstring = embed_ret ? "" : "; ret";
    char *cstring = embed_ret ? "" : " + c3" ;
    char ibuf[40];
    char cbuf[20];
    format_pop(ibuf, reg);
    format_word(cbuf, code);
    printf("%s%s --> %s%s\n", ibuf, rstring, cbuf, cstring);
}
