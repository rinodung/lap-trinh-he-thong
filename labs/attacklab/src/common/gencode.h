
#define RAX 0x0
#define RCX 0x1
#define RDX 0x2
#define RBX 0x3
#define RSP 0x4
#define RBP 0x5
#define RSI 0x6
#define RDI 0x7

#define PUSH(r) (0x50+(r))
#define POP(r) (0x58+(r))

#define PUSH_LEN 1
#define POP_LEN 1

#define INT4(b0,b1,b2,b3) (((b3)<<24)|((b2)<<16)|((b1)<<8)|(b0))
#define INT3(b0,b1,b2) INT4(b0,b1,b2,0)
#define INT2(b0,b1) INT4(b0,b1,0,0)

#define COMBINE(w1,w2,offset) ((w1)|((w2)<<(8*(offset))))

#define MOVL(s,d) INT2(0x89, 0xc0+((s)<<3)+(d))
#define MOVQ(s,d) COMBINE(0x48, MOVL(s,d),1)

#define MOVL_LEN 2
#define MOVQ_LEN 3

#define RET 0xc3
#define NOP 0x90

#define LEA(x,y) INT4(0x48, 0x8d, 0x04, ((y)<<3)+(x))
#define LEA_LEN 4


/* Name of register of form rXX */
char *rname[8];

/* Name of register of form eXX */
char *ename[8];

/*
  Use 4*4 2-byte function nops
  Each identified by two identifiers, ranging from 0 to 3
*/
unsigned nop2(unsigned oidx, unsigned ridx);

#define NOP2_LEN 2

/* Call this function to initialize everything,
   including the random number generator */
void ginit(unsigned cookie);

/* Generate ID that does not collide with previous IDs */
unsigned gen_id();

/* Generate random number between 0 and max */
int rval(unsigned max);

/* Biased random bit generator */
int rbit(float wt);

/* Arguments:
   src: ID of source register
   dst: ID of destination register
   obfuscate (0/1/2): Add obfuscating nop's.
     0 = None, 1 = 0x90 only, 2 = Use 2-bit nops
   disable (0/1): Introduce something to make sequence invalid
*/
unsigned gen_movq_code(int src, int dst,
		       int obfuscate, int disable, int embed_ret);
unsigned gen_movl_code(int src, int dst,
		       int obfuscate, int disable, int embed_ret);
unsigned gen_pop_code(int reg,
		      int obfuscate, int disable, int embed_ret);

/* Embed code in C function */
void gen_function(FILE *out, unsigned code);


/* Testing functions */
void move_code_test(int obfuscate, int disable, int embed_ret, int quad);
void pop_code_test(int obfuscate, int disable, int embed_ret);
