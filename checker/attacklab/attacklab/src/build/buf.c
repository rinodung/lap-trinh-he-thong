/* Buffer procedures used by buffer bomb */
/* Implemented as separate file to allow rest of code to use stack protector */
#include <stdio.h>
#include "config.h"
#include "target.h"

/*
 * getbuf - Has buffer overflow vulnerability
 */
/* $begin getbuf-c */
unsigned getbuf()
{
    char buf[BUFFER_SIZE];
    Gets(buf);
    return 1;
}
/* $end getbuf-c */
