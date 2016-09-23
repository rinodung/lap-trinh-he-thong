
/* Attack target declarations across all files */

/*
  NOTE: Different files are compiled differentially:
  main.c: Specific to TARGET_ID, independent of IS_CHECKER
  buf.c: Specifict to TARGET_ID, independent of IS_CHECKER
  support.c: Specific to IS_CHECKER, independent of TARGET_ID
  visible.c: Independent of both TARGET_ID and IS_CHECKER.

  Global variables are used to indicate required values in places where can't use constants
  (E.g., is_checker, notify, user)
*/


/* Constants *************************************************************/

/* What is timeout for checker */
#ifndef CHECKER_TIMEOUT
#define CHECKER_TIMEOUT 5
#endif

/* 
 * Default is to move stack to segment allocated by mmap to provide
 * stable stack location (except when stack placement randomization enabled 
 */
#ifndef USE_MMAP
#define USE_MMAP
#endif

/*
 * Default is to generate a regular target.
 * Checker target uses customized version of support.o
 */
#ifndef IS_CHECKER
#define IS_CHECKER 0
#endif

/*
 * Should the target be able to notify autolab for successful attacks?
 */

#ifndef NOTIFY
#define NOTIFY 0
#endif

/* Position of stack when stabilized via mmap */
#ifndef STACK
#define STACK 0x55586000
#endif

/* Size of buffer in getbuf */
#define BUFFER_SIZE (16 + 16 * ((TARGET_ID) %3))

/* Global Variables *************************************************************/
/* Defined in buf.c */
unsigned getbuf();

/* Defined in support.c */
int is_checker;
unsigned cookie;
unsigned authkey;
int vlevel;
int check_level;
int notify;
FILE *infile;
size_t buf_offset;
char target_prefix;

/* Defined in main.c */

/* Function Prototypes *************************************************************/
/* Defined in buf.c */
unsigned getbuf();

/* Defined in visible.c */
void touch1();
void touch2(unsigned val);
void touch3(char *sval);
void test();

/* Defined in support.c */
char *Gets(char *);
void validate(int);
void fail(int);
void check_fail();
void notify_server(int, int);
void bushandler(int);
void seghandler(int);
void illegalhandler(int);
void sigalrmhandler(int);
void launch(size_t);
void stable_launch(size_t);

/* Defined in main.c */

/* Defined in scramble.c */
unsigned scramble(unsigned val);
