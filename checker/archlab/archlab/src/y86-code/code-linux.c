#include <stdio.h>
#include <stdlib.h>

long array[] = {0x000d000d000d, 0x00c000c000c0,
		    0x0b000b000b00, 0xa000a000a000};

/* $begin sum-c */
long sum(long *start, long count)
{
    long sum = 0;
    while (count) {
	sum += *start;
	start++;
	count--;
    }
    return sum;
}
/* $end sum-c */

/* $begin rsum-c */
long rsum(long *start, long count)
{
    if (count <= 0)
	return 0;
    return *start + rsum(start+1, count-1);
}
/* $end rsum-c */

void prog()
{
    long val = sum(array, 4);
    printf("0x%lx\n", val);
    exit(0);
}

int main()
{
    prog();
    return 0;
}
