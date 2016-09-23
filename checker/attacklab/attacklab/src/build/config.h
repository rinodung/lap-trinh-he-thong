/*
 * config.h - configuration info for specific target program
 */


/* Parameters that are tied to target ID */
#ifndef TARGET_ID
#define TARGET_ID 1
#endif


#define MAX_HOSTS 100
#define MAX_HOSTNAMELEN 256

/*
 * We don't want copies of bombs from all over the world contacting 
 * our server, so restrict bomb execution to one of the machines on 
 * the following  NULL-terminated list:
 */
char *host_table[MAX_HOSTS];

/*
 * Course / lab information
 */

char *course;
char *lab;

/*
 * Target-specific information
 */

int target_id;
char *user_id;
