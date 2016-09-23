/* 
 * visible.c - Portion of code that will be part of .text
 * 
 * Copyright (c) 2002-2015, R. Bryant and D. O'Hallaron, All rights reserved.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "config.h"
#include "target.h"

/*
 * The following is the part of the code students will actually look
 * at.  They are put at the beginning of the file to make them easier
 * to find in the diassembly, and to make their locations more stable
 * when other parts of the code get modified.
 */

/* 
 * touch1 - On return from getbuf(), a level 1 exploit executes
 * the code for touch1() instead of returning to test().
 */
/* $begin touch1-c */
void touch1()
{
    vlevel = 1;       /* Part of validation protocol */
    printf("Touch1!: You called touch1()\n");
    validate(1);
    exit(0);
}
/* $end touch1-c */

/* 
 * touch2 - On return from getbuf(), the level 2 exploit executes the
 * code for touch2() instead of returning to test(), and makes it appear
 * that touch2() was passed the users's cookie as an unsigned argument.
 */
/* $begin touch2-c */
void touch2(unsigned val)
{
    vlevel = 2;       /* Part of validation protocol */
    if (val == cookie) {
	printf("Touch2!: You called touch2(0x%.8x)\n", val);
	validate(2);
    } else {
	printf("Misfire: You called touch2(0x%.8x)\n", val);
	fail(2);
    }
    exit(0);
}
/* $end touch2-c */

/* 
 * touch3 - On return from getbuf(), a level-3 exploit executes the
 * code for touch3() instead of returning to test(), and makes it appear
 * that touch3() was passed the string representation of the
 * users's cookie as a char* argument.
 */
/* $begin touch3-c */
/* Compare string to hex represention of unsigned value */
int hexmatch(unsigned val, char *sval)
{
    char cbuf[110];
    /* Make position of check string unpredictable */
    char *s = cbuf + random() % 100;
    sprintf(s, "%.8x", val);
    return strncmp(sval, s, 9) == 0;
}

void touch3(char *sval)
{
    vlevel = 3;       /* Part of validation protocol */
    if (hexmatch(cookie, sval)) {
	printf("Touch3!: You called touch3(\"%s\")\n", sval);
	validate(3);
    } else {
	printf("Misfire: You called touch3(\"%s\")\n", sval);
	fail(3);
    }
    exit(0);
}
/* $end touch3-c */

/* 
 * test - This function calls function with buffer overflow vulnerability
 * If any of the exploits are invoked, then will not return to this function
 */
/* $begin test-c */
void test()
{
    int val;
    val = getbuf(); 
    printf("No exploit.  Getbuf returned 0x%x\n", val);
}
/* $end test-c */
