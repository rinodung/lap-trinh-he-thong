/* Support code for attacklab
 * Copyright (c) 2002-2015, R. Bryant and D. O'Hallaron, All rights reserved.
 */

#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <string.h>
#include <alloca.h>

#include "config.h"
#include "target.h"
#include "driverlib.h"

#ifdef USE_MMAP
#include <sys/mman.h>
/* Not sure whether this is really required */
#include "stack.h"
#endif

/* Binary code for HLT (halt) instruction */
#define HALT_INSTR 0xF4

/* Global variables */
#if 0 && IS_CHECKER
/* Insert some additional global variables,
   so that remaining ones are offset in checking code
*/
volatile long bpad01 = 0;
volatile long bpad02 = 0;
volatile long bpad03 = 0;
volatile long bpad04 = 0;
volatile long bpad05 = 0;
volatile long bpad06 = 0;
volatile long bpad07 = 0;
volatile long bpad08 = 0;
volatile long bpad09 = 0;
volatile long bpad10 = 0;
#endif

int is_checker = IS_CHECKER;
unsigned cookie = 0; /* unique cookie computed from target id */
unsigned authkey = 0; /* Hidden unique ID */
size_t buf_offset = 256;
int vlevel = 0; /* Used to prevent spoofing the validation procedure */
int check_level = 0; /* When checking, what level of attack should this be? */

int notify = NOTIFY;
FILE *infile = NULL;

/* Buffer for input to gets */
#define GETLEN 1024
static int  gets_cnt = 0;
static char gets_buf[3*GETLEN+1] = {0};

#if 0 && IS_CHECKER
/* Insert some additional global variables,
   so that remaining ones are offset in checking code
*/
volatile long epad01 = 0;
volatile long epad02 = 0;
volatile long epad03 = 0;
volatile long epad04 = 0;
volatile long epad05 = 0;
volatile long epad06 = 0;
volatile long epad07 = 0;
volatile long epad08 = 0;
volatile long epad09 = 0;
volatile long epad10 = 0;
#endif


#if IS_CHECKER
/*
 * This function should never be called.
 * Its purpose is to shift the positions of the other functions in the file
 * so that students cannot jump directly to the validation code.
 * The most likely reason for calling this function would be an attempt by the
 * student to call validate() directly
 */

void bad_validate(int level)
{
    if (is_checker) {
	printf("Invalid call to validate(%d) detected!\n", level);
	check_fail();
    } else {
	printf("Reject!: Invalid call to validate(%d) detected!\n", level);
	printf("You are not allowed to call any support functions directly\n");
	notify_server(0, level);
    }
    exit(0);
}
#endif /* IS_CHECKER */


void validate(int level)
{
    if (is_checker) {
	if (vlevel != level) {
	    printf("\nMismatched validation levels\n");
	    check_fail();
	} else if (check_level != level) {
	    printf("\nCheck level %d != attack level %d\n", check_level, level);
	    check_fail();
	} else {
	    printf("PASS\t%ctarget\t%d\t%s\n", target_prefix, level, gets_buf);
	}
    } else {
	if (vlevel != level) {
	    printf("\nMismatched validation levels\n");
	    notify_server(0, level);
	} else {
	    printf("Valid solution for level %d with target %ctarget\n", level, target_prefix);
	    notify_server(1, level);
	}
    }
}

/* Should only be called when running checker. */
void check_fail() {
    printf("\nFAIL\t%ctarget\t%d\t%s\n", target_prefix, check_level, gets_buf);
    exit(1);
}

void fail(int level)
{
    if (is_checker) {
	check_fail();
    } else {
	notify_server(0, level);
    }
}


/* 
 * Gets - Like gets(),
 * except that it stores hex string representation of input string
 * in global buffer gets_buf.
 */

static char trans_char[16] = 
	{'0', '1', '2', '3', '4', '5', '6', '7', 
	 '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'};


static void save_char(unsigned char c)
{
    if (gets_cnt < GETLEN) {
	gets_buf[3*gets_cnt] = trans_char[(c>>4)&0xF];
	gets_buf[3*gets_cnt+1] = trans_char[c&0xF];
	gets_buf[3*gets_cnt+2] = ' ';
	gets_cnt++;
    }
}

static void save_term()
{
    gets_buf[3*gets_cnt] = '\0';
}

char *Gets(char *dest)
{
    int c;
    char *sp = dest;

    gets_cnt = 0;

    while ((c = getc(infile)) != EOF && c != '\n') {
	*sp++ = c;
	save_char(c);
    }

    *sp++ = '\0';
    save_term();
    return dest;
}

void notify_server(int pass, int level) {
    /* Format autograder string */
    char autoresult[SUBMITR_MAXBUF];
    char status_msg[SUBMITR_MAXBUF];
    int status;

    if (is_checker)
	return;

    if (gets_cnt + 100 > SUBMITR_MAXBUF) {
	printf("Internal Error: Input string is too large.");
	exit(1);
    }
    
    sprintf(autoresult, "%d:%s:0x%.8x:%ctarget:%d:%s",
            target_id,
	    pass ? "PASS" : "FAIL",
            notify ? authkey : -1,
            target_prefix,
	    level, 
	    gets_buf);

#if NOTIFY    
    if (notify) {
        if (pass) {
            status = driver_post(user_id, course, lab, autoresult, 0, status_msg);
            if (status < 0) {
                printf("FAILED: %s\n", status_msg);
                exit(1);
            }
	    printf("PASS: Sent exploit string to server to be validated.\n");
	    printf("NICE JOB!\n");
	} else {
	    printf("FAILED\n");
	}
    } else {
	printf("%s: Would have posted the following:\n", pass ? "PASS" : "FAIL");
	printf("\tuser id\t%s\n", user_id);
	printf("\tcourse\t%s\n", course);
	printf("\tlab\t%s\n", lab);
	printf("\tresult\t%s\n", autoresult);
    }
#else
	printf("%s\n", pass ? "PASS" : "FAIL");
#endif
}

/* 
 * Signal handlers for bus errors, seg faults, and illegal instruction
 * faults
 */
void bushandler(int sig)
{
    if (is_checker) {
	printf("Bus error\n");
	check_fail();
    } else {
	printf("Crash!: You caused a bus error!\n");
	printf("Better luck next time\n");
	notify_server(0, 0);
    }
    exit(1);
}

void seghandler(int sig)
{
    if (is_checker) {
	printf("Segmentation Fault\n");
	check_fail();
    } else {
	printf("Ouch!: You caused a segmentation fault!\n");
	printf("Better luck next time\n");
	notify_server(0, 0);
    }
    exit(1);
}

void illegalhandler(int sig)
{
    if (is_checker) {
	printf("Illegal instruction\n");
	check_fail();
    } else {
	printf("Oops!: You executed an illegal instruction\n");
	printf("Better luck next time\n");
	notify_server(0, 0);
    }
    exit(1);
}

void sigalrmhandler(int sig)
{
    if (is_checker) {
	printf("Timeout\n");
	check_fail();
    } else {
	printf("\nTimeout!: Your attack takes more than %d seconds\n", CHECKER_TIMEOUT);
	notify_server(0, 0);
    }
    exit(1);
}

/* 
 * launch - Calls test
 */
void launch(size_t offset)
{
    void *space = alloca(offset);

    /* Fill full of halt instructions, so that will get seg fault */
    memset(space, HALT_INSTR, offset);

    /* Call the test function */
    if (infile == stdin)
	printf("Type string:");
    vlevel = 0;
    test();
    if (is_checker) {
	printf("No exploit\n");
	check_fail();
    } else {
	printf("Normal return\n");
    }
}

/* 
 * stable_launch - Version of the launching code that uses mmap() to 
 * generate a stable stack position, regardless of any stack randomization
 * used by the runtime system. 
 */

/* Must put context information in global vars, since stack will get
   messed up */
size_t global_offset = 0;
volatile void *stack_top;
volatile void *global_save_stack = NULL;

void stable_launch(size_t offset)
{
    /* Assign from stack to globals before we move the stack location */
    global_offset = offset;

#ifdef USE_MMAP
    void *new_stack = mmap(START_ADDR, STACK_SIZE, PROT_EXEC|PROT_READ|PROT_WRITE,
		     MAP_PRIVATE | MAP_GROWSDOWN | MAP_ANONYMOUS | MAP_FIXED,
		     0, 0);
    if (new_stack != START_ADDR) {
	munmap(new_stack, STACK_SIZE);
	fprintf(stderr, "Couldn't map stack to segment at 0x%lx\n", (size_t) START_ADDR);
	exit(1);
    }

    stack_top = new_stack + STACK_SIZE - 8;
    asm("movq %%rsp,%%rax ; movq %1,%%rsp ; movq %%rax,%0"
	: "=r" (global_save_stack)
	: "r"  (stack_top)
	: "%rax"
	);

#endif

    launch(global_offset);
    
#ifdef USE_MMAP
    asm("movq %0,%%rsp"
	: 
	: "r" (global_save_stack)
	);
    munmap(new_stack, STACK_SIZE);
#endif

}

