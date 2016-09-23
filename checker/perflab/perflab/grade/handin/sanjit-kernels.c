/*******************************************
 * Solutions for the CS:APP Performance Lab
 ********************************************/

#include <stdio.h>
#include <stdlib.h>
#include "defs.h"

/* 
 * Please fill in the following team struct 
 */
team_t team = {
    "solution",           /* Team name */

    "Sanjit Seshia",      /* First member full name */
    "sanjit@nowhere.edu",  /* First member email address */

    "",                   /* Second member full name (leave blank if none) */
    ""                    /* Second member email addr (leave blank if none) */
};

/***************
 * ROTATE KERNEL
 ***************/

/******************************************************
 * Your different versions of the rotate kernel go here
 ******************************************************/

/* 
 * naive_rotate - The naive baseline version of rotate 
 */
char naive_rotate_descr[] = "naive_rotate: Naive baseline implementation";
void naive_rotate(int dim, pixel *src, pixel *dst) 
{
    int i, j;

    for (i = 0; i < dim; i++)
	for (j = 0; j < dim; j++)
	    dst[RIDX(dim-1-j, i, dim)] = src[RIDX(i, j, dim)];
}

char rotate_c_descr[] = "rotate_c: Naive col-wise traversal of src";
void rotate_c(int dim, pixel *src, pixel *dst) {
    int i, j;

    for(j=0; j < dim; j++) {
	for(i=0; i < dim; i++) {
	    dst[RIDX(dim-1-j,i,dim)] = src[RIDX(i,j,dim)];
	    /* Does slightly worse if you copy each field over separately
	       dst[RIDX(dim-1-j,i,dim)].red = src[RIDX(i,j,dim)].red;
	       dst[RIDX(dim-1-j,i,dim)].green = src[RIDX(i,j,dim)].green;
	       dst[RIDX(dim-1-j,i,dim)].blue = src[RIDX(i,j,dim)].blue;
	    */
	}
    }

    return;
}


char rotate_b8_descr[] = "rotate_b8: Rotate using 8x8 blocking";
void rotate_b8(int dim, pixel *src, pixel *dst) {
    int i, j;
    int ii, jj;

    for(ii=0; ii < dim; ii+=8)
	for(jj=0; jj < dim; jj+=8)
	    for(i=ii; i < ii+8; i++) 
		for(j=jj; j < jj+8; j++) 
		    dst[RIDX(dim-1-j,i,dim)] = src[RIDX(i,j,dim)];

    return;
}

char rotate_b4_descr[] = "rotate_b4: Rotate using 4x4 blocking";
void rotate_b4(int dim, pixel *src, pixel *dst) {
    int i, j;
    int ii, jj;

    for(ii=0; ii < dim; ii+=4) 
	for(jj=0; jj < dim; jj+=4) 
	    for(i=ii; i < ii+4; i++) 
		for(j=jj; j < jj+4; j++) 
		    dst[RIDX(dim-1-j,i,dim)] = src[RIDX(i,j,dim)];

    return;
}

char rotate_b16_u2_descr[] = "rotate_b16_u2: Rotate using 16x16 blocking, 2x unrolling";
void rotate_b16_u2(int dim, pixel *src, pixel *dst) {
    int i, j;
    int ii, jj;

    for(ii=0; ii < dim; ii+=16) 
	for(jj=0; jj < dim; jj+=16)
	    for(i=ii; i < ii+16; i+=2) 
		for(j=jj; j < jj+16; j+=2) { 
		    dst[RIDX(dim-1-j,i,dim)] = src[RIDX(i,j,dim)];
		    dst[RIDX(dim-1-j,i+1,dim)] = src[RIDX(i+1,j,dim)];
		    dst[RIDX(dim-1-j-1,i,dim)] = src[RIDX(i,j+1,dim)];
		    dst[RIDX(dim-1-j-1,i+1,dim)] = src[RIDX(i+1,j+1,dim)];
		}

    return;
}

char rotate_b32_u2_descr[] = "rotate_b32_u2: Rotate using 32x32 blocking, 2x unrolling";
void rotate_b32_u2(int dim, pixel *src, pixel *dst) {
    int i, j;
    int ii, jj;

    for(ii=0; ii < dim; ii+=32)
	for(jj=0; jj < dim; jj+=32)
	    for(i=ii; i < ii+32; i+=2) 
		for(j=jj; j < jj+32; j+=2) {
		    dst[RIDX(dim-1-j,i,dim)] = src[RIDX(i,j,dim)];
		    dst[RIDX(dim-1-j,i+1,dim)] = src[RIDX(i+1,j,dim)];
		    dst[RIDX(dim-1-j-1,i,dim)] = src[RIDX(i,j+1,dim)];
		    dst[RIDX(dim-1-j-1,i+1,dim)] = src[RIDX(i+1,j+1,dim)];
		}

    return;
}

char rotate_b8_u4_c_descr[] = "rotate_b8_u4_c: Rotate col-wise using 8x8 blocking, 4x unrolling";
void rotate_b8_u4_c(int dim, pixel *src, pixel *dst) {
    int i, j;
    int ii, jj;

    for(jj=0; jj < dim; jj+=8)
	for(ii=0; ii < dim; ii+=8)
	    for(j=jj; j < jj+8; j+=4) 
		for(i=ii; i < ii+8; i+=4) { 
		    dst[RIDX(dim-1-j,i,dim)] = src[RIDX(i,j,dim)];
		    dst[RIDX(dim-1-j,i+1,dim)] = src[RIDX(i+1,j,dim)];
		    dst[RIDX(dim-1-j,i+2,dim)] = src[RIDX(i+2,j,dim)];
		    dst[RIDX(dim-1-j,i+3,dim)] = src[RIDX(i+3,j,dim)];
		    dst[RIDX(dim-1-j-1,i,dim)] = src[RIDX(i,j+1,dim)];
		    dst[RIDX(dim-1-j-1,i+1,dim)] = src[RIDX(i+1,j+1,dim)];
		    dst[RIDX(dim-1-j-1,i+2,dim)] = src[RIDX(i+2,j+1,dim)];
		    dst[RIDX(dim-1-j-1,i+3,dim)] = src[RIDX(i+3,j+1,dim)];
		    dst[RIDX(dim-1-j-2,i,dim)] = src[RIDX(i,j+2,dim)];
		    dst[RIDX(dim-1-j-2,i+1,dim)] = src[RIDX(i+1,j+2,dim)];
		    dst[RIDX(dim-1-j-2,i+2,dim)] = src[RIDX(i+2,j+2,dim)];
		    dst[RIDX(dim-1-j-2,i+3,dim)] = src[RIDX(i+3,j+2,dim)];
		    dst[RIDX(dim-1-j-3,i,dim)] = src[RIDX(i,j+3,dim)];
		    dst[RIDX(dim-1-j-3,i+1,dim)] = src[RIDX(i+1,j+3,dim)];
		    dst[RIDX(dim-1-j-3,i+2,dim)] = src[RIDX(i+2,j+3,dim)];
		    dst[RIDX(dim-1-j-3,i+3,dim)] = src[RIDX(i+3,j+3,dim)];
		}

    return;
}


char rotate_b8_u4_descr[] = "rotate_b8_u4: Rotate using 8x8 blocking, 4x unrolling";
void rotate_b8_u4(int dim, pixel *src, pixel *dst) {
    int i, j;
    int ii, jj;

    for(ii=0; ii < dim; ii+=8)
	for(jj=0; jj < dim; jj+=8)
	    for(i=ii; i < ii+8; i+=4) 
		for(j=jj; j < jj+8; j+=4) {
		    dst[RIDX(dim-1-j,i,dim)] = src[RIDX(i,j,dim)];
		    dst[RIDX(dim-1-j,i+1,dim)] = src[RIDX(i+1,j,dim)];
		    dst[RIDX(dim-1-j,i+2,dim)] = src[RIDX(i+2,j,dim)];
		    dst[RIDX(dim-1-j,i+3,dim)] = src[RIDX(i+3,j,dim)];
		    dst[RIDX(dim-1-j-1,i,dim)] = src[RIDX(i,j+1,dim)];
		    dst[RIDX(dim-1-j-1,i+1,dim)] = src[RIDX(i+1,j+1,dim)];
		    dst[RIDX(dim-1-j-1,i+2,dim)] = src[RIDX(i+2,j+1,dim)];
		    dst[RIDX(dim-1-j-1,i+3,dim)] = src[RIDX(i+3,j+1,dim)];
		    dst[RIDX(dim-1-j-2,i,dim)] = src[RIDX(i,j+2,dim)];
		    dst[RIDX(dim-1-j-2,i+1,dim)] = src[RIDX(i+1,j+2,dim)];
		    dst[RIDX(dim-1-j-2,i+2,dim)] = src[RIDX(i+2,j+2,dim)];
		    dst[RIDX(dim-1-j-2,i+3,dim)] = src[RIDX(i+3,j+2,dim)];
		    dst[RIDX(dim-1-j-3,i,dim)] = src[RIDX(i,j+3,dim)];
		    dst[RIDX(dim-1-j-3,i+1,dim)] = src[RIDX(i+1,j+3,dim)];
		    dst[RIDX(dim-1-j-3,i+2,dim)] = src[RIDX(i+2,j+3,dim)];
		    dst[RIDX(dim-1-j-3,i+3,dim)] = src[RIDX(i+3,j+3,dim)];
		}

    return;
}




char rotate_b16_u4_descr[] = "rotate_b16_u4: Rotate using 16x16 blocking, 4x unrolling";
void rotate_b16_u4(int dim, pixel *src, pixel *dst) {
    int i, j;
    int ii, jj;

    for(ii=0; ii < dim; ii+=16)
	for(jj=0; jj < dim; jj+=16)
	    for(i=ii; i < ii+16; i+=4) 
		for(j=jj; j < jj+16; j+=4) {
		    dst[RIDX(dim-1-j,i,dim)] = src[RIDX(i,j,dim)];
		    dst[RIDX(dim-1-j,i+1,dim)] = src[RIDX(i+1,j,dim)];
		    dst[RIDX(dim-1-j,i+2,dim)] = src[RIDX(i+2,j,dim)];
		    dst[RIDX(dim-1-j,i+3,dim)] = src[RIDX(i+3,j,dim)];
		    dst[RIDX(dim-1-j-1,i,dim)] = src[RIDX(i,j+1,dim)];
		    dst[RIDX(dim-1-j-1,i+1,dim)] = src[RIDX(i+1,j+1,dim)];
		    dst[RIDX(dim-1-j-1,i+2,dim)] = src[RIDX(i+2,j+1,dim)];
		    dst[RIDX(dim-1-j-1,i+3,dim)] = src[RIDX(i+3,j+1,dim)];
		    dst[RIDX(dim-1-j-2,i,dim)] = src[RIDX(i,j+2,dim)];
		    dst[RIDX(dim-1-j-2,i+1,dim)] = src[RIDX(i+1,j+2,dim)];
		    dst[RIDX(dim-1-j-2,i+2,dim)] = src[RIDX(i+2,j+2,dim)];
		    dst[RIDX(dim-1-j-2,i+3,dim)] = src[RIDX(i+3,j+2,dim)];
		    dst[RIDX(dim-1-j-3,i,dim)] = src[RIDX(i,j+3,dim)];
		    dst[RIDX(dim-1-j-3,i+1,dim)] = src[RIDX(i+1,j+3,dim)];
		    dst[RIDX(dim-1-j-3,i+2,dim)] = src[RIDX(i+2,j+3,dim)];
		    dst[RIDX(dim-1-j-3,i+3,dim)] = src[RIDX(i+3,j+3,dim)];
		}

    return;
}

char rotate_b16_u4_c_descr[] = "rotate_b16_u4_c: Rotate Col-wise using 16x16 blocking, 4x unrolling";
void rotate_b16_u4_c(int dim, pixel *src, pixel *dst) {
    int i, j;
    int ii, jj;

    for(jj=0; jj < dim; jj+=16)
	for(ii=0; ii < dim; ii+=16)
	    for(j=jj; j < jj+16; j+=4) 
		for(i=ii; i < ii+16; i+=4) {
		    dst[RIDX(dim-1-j,i,dim)] = src[RIDX(i,j,dim)];
		    dst[RIDX(dim-1-j,i+1,dim)] = src[RIDX(i+1,j,dim)];
		    dst[RIDX(dim-1-j,i+2,dim)] = src[RIDX(i+2,j,dim)];
		    dst[RIDX(dim-1-j,i+3,dim)] = src[RIDX(i+3,j,dim)];
		    dst[RIDX(dim-1-j-1,i,dim)] = src[RIDX(i,j+1,dim)];
		    dst[RIDX(dim-1-j-1,i+1,dim)] = src[RIDX(i+1,j+1,dim)];
		    dst[RIDX(dim-1-j-1,i+2,dim)] = src[RIDX(i+2,j+1,dim)];
		    dst[RIDX(dim-1-j-1,i+3,dim)] = src[RIDX(i+3,j+1,dim)];
		    dst[RIDX(dim-1-j-2,i,dim)] = src[RIDX(i,j+2,dim)];
		    dst[RIDX(dim-1-j-2,i+1,dim)] = src[RIDX(i+1,j+2,dim)];
		    dst[RIDX(dim-1-j-2,i+2,dim)] = src[RIDX(i+2,j+2,dim)];
		    dst[RIDX(dim-1-j-2,i+3,dim)] = src[RIDX(i+3,j+2,dim)];
		    dst[RIDX(dim-1-j-3,i,dim)] = src[RIDX(i,j+3,dim)];
		    dst[RIDX(dim-1-j-3,i+1,dim)] = src[RIDX(i+1,j+3,dim)];
		    dst[RIDX(dim-1-j-3,i+2,dim)] = src[RIDX(i+2,j+3,dim)];
		    dst[RIDX(dim-1-j-3,i+3,dim)] = src[RIDX(i+3,j+3,dim)];
		}

    return;
}



char rotate_b32_u4_descr[] = "rotate_b32_u4: Rotate using 32x32 blocking, 4x unrolling";
void rotate_b32_u4(int dim, pixel *src, pixel *dst) {
    int i, j;
    int ii, jj;

    for(ii=0; ii < dim; ii+=32)
	for(jj=0; jj < dim; jj+=32)
	    for(i=ii; i < ii+32; i+=4) 
		for(j=jj; j < jj+32; j+=4) {
		    dst[RIDX(dim-1-j,i,dim)] = src[RIDX(i,j,dim)];
		    dst[RIDX(dim-1-j,i+1,dim)] = src[RIDX(i+1,j,dim)];
		    dst[RIDX(dim-1-j,i+2,dim)] = src[RIDX(i+2,j,dim)];
		    dst[RIDX(dim-1-j,i+3,dim)] = src[RIDX(i+3,j,dim)];
		    dst[RIDX(dim-1-j-1,i,dim)] = src[RIDX(i,j+1,dim)];
		    dst[RIDX(dim-1-j-1,i+1,dim)] = src[RIDX(i+1,j+1,dim)];
		    dst[RIDX(dim-1-j-1,i+2,dim)] = src[RIDX(i+2,j+1,dim)];
		    dst[RIDX(dim-1-j-1,i+3,dim)] = src[RIDX(i+3,j+1,dim)];
		    dst[RIDX(dim-1-j-2,i,dim)] = src[RIDX(i,j+2,dim)];
		    dst[RIDX(dim-1-j-2,i+1,dim)] = src[RIDX(i+1,j+2,dim)];
		    dst[RIDX(dim-1-j-2,i+2,dim)] = src[RIDX(i+2,j+2,dim)];
		    dst[RIDX(dim-1-j-2,i+3,dim)] = src[RIDX(i+3,j+2,dim)];
		    dst[RIDX(dim-1-j-3,i,dim)] = src[RIDX(i,j+3,dim)];
		    dst[RIDX(dim-1-j-3,i+1,dim)] = src[RIDX(i+1,j+3,dim)];
		    dst[RIDX(dim-1-j-3,i+2,dim)] = src[RIDX(i+2,j+3,dim)];
		    dst[RIDX(dim-1-j-3,i+3,dim)] = src[RIDX(i+3,j+3,dim)];
		}

    return;
}



char rotate_b32_u4_c_descr[] = "rotate_b32_u4_c: Rotate Col-wise using 32x32 blocking, 4x unrolling";
void rotate_b32_u4_c(int dim, pixel *src, pixel *dst) {
    int i, j;
    int ii, jj;

    for(jj=0; jj < dim; jj+=32)
	for(ii=0; ii < dim; ii+=32)
	    for(j=jj; j < jj+32; j+=4) 
		for(i=ii; i < ii+32; i+=4) { 
		    dst[RIDX(dim-1-j,i,dim)] = src[RIDX(i,j,dim)];
		    dst[RIDX(dim-1-j,i+1,dim)] = src[RIDX(i+1,j,dim)];
		    dst[RIDX(dim-1-j,i+2,dim)] = src[RIDX(i+2,j,dim)];
		    dst[RIDX(dim-1-j,i+3,dim)] = src[RIDX(i+3,j,dim)];
		    dst[RIDX(dim-1-j-1,i,dim)] = src[RIDX(i,j+1,dim)];
		    dst[RIDX(dim-1-j-1,i+1,dim)] = src[RIDX(i+1,j+1,dim)];
		    dst[RIDX(dim-1-j-1,i+2,dim)] = src[RIDX(i+2,j+1,dim)];
		    dst[RIDX(dim-1-j-1,i+3,dim)] = src[RIDX(i+3,j+1,dim)];
		    dst[RIDX(dim-1-j-2,i,dim)] = src[RIDX(i,j+2,dim)];
		    dst[RIDX(dim-1-j-2,i+1,dim)] = src[RIDX(i+1,j+2,dim)];
		    dst[RIDX(dim-1-j-2,i+2,dim)] = src[RIDX(i+2,j+2,dim)];
		    dst[RIDX(dim-1-j-2,i+3,dim)] = src[RIDX(i+3,j+2,dim)];
		    dst[RIDX(dim-1-j-3,i,dim)] = src[RIDX(i,j+3,dim)];
		    dst[RIDX(dim-1-j-3,i+1,dim)] = src[RIDX(i+1,j+3,dim)];
		    dst[RIDX(dim-1-j-3,i+2,dim)] = src[RIDX(i+2,j+3,dim)];
		    dst[RIDX(dim-1-j-3,i+3,dim)] = src[RIDX(i+3,j+3,dim)];
		}

    return;
}


/* Cache optimization ideas from Fall 99 */
/* Rotate 4x4 array */
void r4(pixel *dst, pixel *src, int dim)
{
    int i;
    int j;
    for (j = 0; j < 4; j++)
	for (i = 0; i < 4; i++)
	    dst[RIDX(3-j,i,dim)] = src[RIDX(i,j,dim)];
}

/* Rotate 4x4 array, saving diagonal element to end */
void r4o(pixel *dst, pixel *src, int dim)
{
    int i;
    int j;
    for (i = 0; i < 4; i++)
	for (j = 0; j < 4; j++) {
	    int jj = (i+j+1) % 4;
	    dst[RIDX(dim-1-jj,i,dim)] = src[RIDX(i,jj,dim)];
	}
}


/* Do 8x8 blocks divided into 4x4 quadrants */
void row8qo_rotate_helper(pixel *dst, pixel *src, 
			  int size, int dim)
{
    int i, j;
    for (j = 0; j < size; j+=8) {
	for (i = 0; i < size; i+=8) {
	    r4(dst+RIDX(j,i,dim), src+RIDX(i,j+4,dim), dim);
	    r4(dst+RIDX(j,i+4,dim), src+RIDX(i+4,j+4,dim), dim);
	    r4(dst+RIDX(j+4,i,dim), src+RIDX(i,j,dim), dim);
	    r4(dst+RIDX(j+4,i+4,dim), src+RIDX(i+4,j,dim), dim);
	}
    }
}

/* Do 16x16 blocks divided into 8x8 quadrants */
void row16qo_rotate_helper(pixel *dst, pixel *src, 
			   int size, int dim)
{
    int i, j;
    int s2 = size >> 1;
    for (j = 0; j < size; j+=16) {
	for (i = 0; i < size; i+=16) {
	    row8qo_rotate_helper(dst+RIDX(j,i,dim), src+RIDX(i,j+8,dim), s2, dim);
	    row8qo_rotate_helper(dst+RIDX(j,i+8,dim), src+RIDX(i+8,j+8,dim), s2, dim);
	    row8qo_rotate_helper(dst+RIDX(j+8,i,dim), src+RIDX(i,j,dim), s2, dim);
	    row8qo_rotate_helper(dst+RIDX(j+8,i+8,dim), src+RIDX(i+8,j,dim), s2, dim);
	}
    }
}


/* This code is only to be used for dim a power of 2 */
void quado_rotate_helper(pixel *dst, pixel *src, int size,
			 int dim, int size_cutoff, int toggle)
{
    int s2 = size >> 1;

    if (size <= size_cutoff) {
	/* Stop the recursion */
	if (size_cutoff == 8)
	    row8qo_rotate_helper(dst, src, size, dim);
	else 
	    row16qo_rotate_helper(dst, src, size, dim);
	return;
    }
    if (toggle) {
	quado_rotate_helper(dst+RIDX(0,0,dim),
			    src+RIDX(0,s2,dim),
			    s2, dim, size_cutoff, toggle);
	quado_rotate_helper(dst+RIDX(0,s2,dim),
			    src+RIDX(s2,s2,dim),
			    s2, dim, size_cutoff, toggle);
	quado_rotate_helper(dst+RIDX(s2,0,dim),
			    src+RIDX(0,0,dim),
			    s2, dim, size_cutoff, toggle);
	quado_rotate_helper(dst+RIDX(s2,s2,dim),
			    src+RIDX(s2,0,dim),
			    s2, dim, size_cutoff, toggle);
    } else {
	quado_rotate_helper(dst+RIDX(0,0,dim),
			    src+RIDX(0,s2,dim),
			    s2, dim, size_cutoff, toggle);
	quado_rotate_helper(dst+RIDX(0,s2,dim),
			    src+RIDX(s2,s2,dim),
			    s2, dim, size_cutoff, toggle);
	quado_rotate_helper(dst+RIDX(s2,0,dim),
			    src+RIDX(0,0,dim),
			    s2, dim, size_cutoff, toggle);
	quado_rotate_helper(dst+RIDX(s2,s2,dim),
			    src+RIDX(s2,0,dim),
			    s2, dim, size_cutoff, toggle);
    }
}


char rotate_rec_descr[] = "rotate_rec: Recursive quadrant based rotate";
void rotate_rec(int dim, pixel *src, pixel *dst) {
    static int toggle = 0;
    switch(dim) {
    case 64:
	quado_rotate_helper(dst, src, dim, dim, 8, toggle);
	break;
    case 128:
    case 256:
    case 512:
    case 1024:
	quado_rotate_helper(dst, src, dim, dim, 16, toggle);
	break;
    default:
	if (dim <= 96) 
	    rotate_c(dim, src, dst);
	else
	    rotate_b32_u4_c(dim, src, dst);
	break;
    }
    toggle = 1-toggle;
}


#define COPY(d,s) *(d) = *(s)

char toggle32_rotate_descr[] = "toggle32_rotate: Unrolled 32 Rows, toggle";
void toggle32_rotate(int dim, pixel *src, pixel *dst)
{
    static int sense = 0;
    int i, j;
    if (sense) {
	for (i = 0; i < dim; i+=32) {
	    for (j = dim-1; j >= 0; j-=1) {
		pixel *dptr = dst+RIDX(dim-1-j,i,dim);
		pixel *sptr = src+RIDX(i,j,dim);
		COPY(dptr, sptr); sptr += dim;
		COPY(dptr+1, sptr); sptr += dim;
		COPY(dptr+2, sptr); sptr += dim;
		COPY(dptr+3, sptr); sptr += dim;
		COPY(dptr+4, sptr); sptr += dim;
		COPY(dptr+5, sptr); sptr += dim;
		COPY(dptr+6, sptr); sptr += dim;
		COPY(dptr+7, sptr); sptr += dim;
		COPY(dptr+8, sptr); sptr += dim;
		COPY(dptr+9, sptr); sptr += dim;
		COPY(dptr+10, sptr); sptr += dim;
		COPY(dptr+11, sptr); sptr += dim;
		COPY(dptr+12, sptr); sptr += dim;
		COPY(dptr+13, sptr); sptr += dim;
		COPY(dptr+14, sptr); sptr += dim;
		COPY(dptr+15, sptr); sptr += dim;
		COPY(dptr+16, sptr); sptr += dim;
		COPY(dptr+17, sptr); sptr += dim;
		COPY(dptr+18, sptr); sptr += dim;
		COPY(dptr+19, sptr); sptr += dim;
		COPY(dptr+20, sptr); sptr += dim;
		COPY(dptr+21, sptr); sptr += dim;
		COPY(dptr+22, sptr); sptr += dim;
		COPY(dptr+23, sptr); sptr += dim;
		COPY(dptr+24, sptr); sptr += dim;
		COPY(dptr+25, sptr); sptr += dim;
		COPY(dptr+26, sptr); sptr += dim;
		COPY(dptr+27, sptr); sptr += dim;
		COPY(dptr+28, sptr); sptr += dim;
		COPY(dptr+29, sptr); sptr += dim;
		COPY(dptr+30, sptr); sptr += dim;
		COPY(dptr+31, sptr);
	    }
	}
    } else {
	for (i = dim-32; i >= 0; i-=32) {
	    for (j = 0; j < dim; j+=1) {
		pixel *dptr = dst+RIDX(dim-1-j,i,dim);
		pixel *sptr = src+RIDX(i,j,dim);
		COPY(dptr, sptr); sptr += dim;
		COPY(dptr+1, sptr); sptr += dim;
		COPY(dptr+2, sptr); sptr += dim;
		COPY(dptr+3, sptr); sptr += dim;
		COPY(dptr+4, sptr); sptr += dim;
		COPY(dptr+5, sptr); sptr += dim;
		COPY(dptr+6, sptr); sptr += dim;
		COPY(dptr+7, sptr); sptr += dim;
		COPY(dptr+8, sptr); sptr += dim;
		COPY(dptr+9, sptr); sptr += dim;
		COPY(dptr+10, sptr); sptr += dim;
		COPY(dptr+11, sptr); sptr += dim;
		COPY(dptr+12, sptr); sptr += dim;
		COPY(dptr+13, sptr); sptr += dim;
		COPY(dptr+14, sptr); sptr += dim;
		COPY(dptr+15, sptr); sptr += dim;
		COPY(dptr+16, sptr); sptr += dim;
		COPY(dptr+17, sptr); sptr += dim;
		COPY(dptr+18, sptr); sptr += dim;
		COPY(dptr+19, sptr); sptr += dim;
		COPY(dptr+20, sptr); sptr += dim;
		COPY(dptr+21, sptr); sptr += dim;
		COPY(dptr+22, sptr); sptr += dim;
		COPY(dptr+23, sptr); sptr += dim;
		COPY(dptr+24, sptr); sptr += dim;
		COPY(dptr+25, sptr); sptr += dim;
		COPY(dptr+26, sptr); sptr += dim;
		COPY(dptr+27, sptr); sptr += dim;
		COPY(dptr+28, sptr); sptr += dim;
		COPY(dptr+29, sptr); sptr += dim;
		COPY(dptr+30, sptr); sptr += dim;
		COPY(dptr+31, sptr);
	    }
	}

    }
    sense = 1-sense; /* Toggle for next time */
}


char toggle64_rotate_descr[] = "toggle64_rotate: Unrolled 64 Rows";
void toggle64_rotate(int dim, pixel *src, pixel *dst)
{
    int i, j;

    for (i = 0; i < dim; i+=64) {
	for (j = dim-1; j >= 0; j-=1) {
	    pixel *dptr = dst+RIDX(dim-1-j,i,dim);
	    pixel *sptr = src+RIDX(i,j,dim);
	    COPY(dptr, sptr); sptr += dim;
	    COPY(dptr+1, sptr); sptr += dim;
	    COPY(dptr+2, sptr); sptr += dim;
	    COPY(dptr+3, sptr); sptr += dim;
	    COPY(dptr+4, sptr); sptr += dim;
	    COPY(dptr+5, sptr); sptr += dim;
	    COPY(dptr+6, sptr); sptr += dim;
	    COPY(dptr+7, sptr); sptr += dim;
	    COPY(dptr+8, sptr); sptr += dim;
	    COPY(dptr+9, sptr); sptr += dim;
	    COPY(dptr+10, sptr); sptr += dim;
	    COPY(dptr+11, sptr); sptr += dim;
	    COPY(dptr+12, sptr); sptr += dim;
	    COPY(dptr+13, sptr); sptr += dim;
	    COPY(dptr+14, sptr); sptr += dim;
	    COPY(dptr+15, sptr); sptr += dim;
	    COPY(dptr+16, sptr); sptr += dim;
	    COPY(dptr+17, sptr); sptr += dim;
	    COPY(dptr+18, sptr); sptr += dim;
	    COPY(dptr+19, sptr); sptr += dim;
	    COPY(dptr+20, sptr); sptr += dim;
	    COPY(dptr+21, sptr); sptr += dim;
	    COPY(dptr+22, sptr); sptr += dim;
	    COPY(dptr+23, sptr); sptr += dim;
	    COPY(dptr+24, sptr); sptr += dim;
	    COPY(dptr+25, sptr); sptr += dim;
	    COPY(dptr+26, sptr); sptr += dim;
	    COPY(dptr+27, sptr); sptr += dim;
	    COPY(dptr+28, sptr); sptr += dim;
	    COPY(dptr+29, sptr); sptr += dim;
	    COPY(dptr+30, sptr); sptr += dim;
	    COPY(dptr+31, sptr); sptr += dim;
	    COPY(dptr+32, sptr); sptr += dim;
	    COPY(dptr+33, sptr); sptr += dim;
	    COPY(dptr+34, sptr); sptr += dim;
	    COPY(dptr+35, sptr); sptr += dim;
	    COPY(dptr+36, sptr); sptr += dim;
	    COPY(dptr+37, sptr); sptr += dim;
	    COPY(dptr+38, sptr); sptr += dim;
	    COPY(dptr+39, sptr); sptr += dim;
	    COPY(dptr+40, sptr); sptr += dim;
	    COPY(dptr+41, sptr); sptr += dim;
	    COPY(dptr+42, sptr); sptr += dim;
	    COPY(dptr+43, sptr); sptr += dim;
	    COPY(dptr+44, sptr); sptr += dim;
	    COPY(dptr+45, sptr); sptr += dim;
	    COPY(dptr+46, sptr); sptr += dim;
	    COPY(dptr+47, sptr); sptr += dim;
	    COPY(dptr+48, sptr); sptr += dim;
	    COPY(dptr+49, sptr); sptr += dim;
	    COPY(dptr+50, sptr); sptr += dim;
	    COPY(dptr+51, sptr); sptr += dim;
	    COPY(dptr+52, sptr); sptr += dim;
	    COPY(dptr+53, sptr); sptr += dim;
	    COPY(dptr+54, sptr); sptr += dim;
	    COPY(dptr+55, sptr); sptr += dim;
	    COPY(dptr+56, sptr); sptr += dim;
	    COPY(dptr+57, sptr); sptr += dim;
	    COPY(dptr+58, sptr); sptr += dim;
	    COPY(dptr+59, sptr); sptr += dim;
	    COPY(dptr+60, sptr); sptr += dim;
	    COPY(dptr+61, sptr); sptr += dim;
	    COPY(dptr+62, sptr); sptr += dim;
	    COPY(dptr+63, sptr); 
	}
    }
} 


char toggle16x2_rotate_descr[] = "toggle16x2_rotate: Unrolled 16 Rows X 2 Cols, toggle";
void toggle16x2_rotate(int dim, pixel *src, pixel *dst)
{
    static int sense = 0;
    int dim2 = dim >> 1;
    int i, jj;
    sense = 1-sense; /* Toggle for next time */
    if (sense) {
	for (i = 0; i < dim; i+=16) {
	    for (jj = dim2; jj > 0; jj-=2) {
		int j = jj-1;
		pixel *dptr = dst+RIDX(dim-1-j,i,dim);
		pixel *sptr = src+RIDX(i,j,dim);
		COPY(dptr, sptr); sptr += dim;
		COPY(dptr+1, sptr); sptr += dim;
		COPY(dptr+2, sptr); sptr += dim;
		COPY(dptr+3, sptr); sptr += dim;
		COPY(dptr+4, sptr); sptr += dim;
		COPY(dptr+5, sptr); sptr += dim;
		COPY(dptr+6, sptr); sptr += dim;
		COPY(dptr+7, sptr); sptr += dim;
		COPY(dptr+8, sptr); sptr += dim;
		COPY(dptr+9, sptr); sptr += dim;
		COPY(dptr+10, sptr); sptr += dim;
		COPY(dptr+11, sptr); sptr += dim;
		COPY(dptr+12, sptr); sptr += dim;
		COPY(dptr+13, sptr); sptr += dim;
		COPY(dptr+14, sptr); sptr += dim;
		COPY(dptr+15, sptr);
		/* Now go back up */
		dptr += dim; sptr--;
		COPY(dptr+15, sptr); sptr -= dim;
		COPY(dptr+14, sptr); sptr -= dim;
		COPY(dptr+13, sptr); sptr -= dim;
		COPY(dptr+12, sptr); sptr -= dim;
		COPY(dptr+11, sptr); sptr -= dim;
		COPY(dptr+10, sptr); sptr -= dim;
		COPY(dptr+9, sptr); sptr -= dim;
		COPY(dptr+8, sptr); sptr -= dim;
		COPY(dptr+7, sptr); sptr -= dim;
		COPY(dptr+6, sptr); sptr -= dim;
		COPY(dptr+5, sptr); sptr -= dim;
		COPY(dptr+4, sptr); sptr -= dim;
		COPY(dptr+3, sptr); sptr -= dim;
		COPY(dptr+2, sptr); sptr -= dim;
		COPY(dptr+1, sptr); sptr -= dim;
		COPY(dptr, sptr);
	    }
	    for (jj = dim2; jj < dim; jj+=2) {
		int j = jj;
		pixel *dptr = dst+RIDX(dim-1-j,i,dim);
		pixel *sptr = src+RIDX(i,j,dim);
		COPY(dptr, sptr); sptr += dim;
		COPY(dptr+1, sptr); sptr += dim;
		COPY(dptr+2, sptr); sptr += dim;
		COPY(dptr+3, sptr); sptr += dim;
		COPY(dptr+4, sptr); sptr += dim;
		COPY(dptr+5, sptr); sptr += dim;
		COPY(dptr+6, sptr); sptr += dim;
		COPY(dptr+7, sptr); sptr += dim;
		COPY(dptr+8, sptr); sptr += dim;
		COPY(dptr+9, sptr); sptr += dim;
		COPY(dptr+10, sptr); sptr += dim;
		COPY(dptr+11, sptr); sptr += dim;
		COPY(dptr+12, sptr); sptr += dim;
		COPY(dptr+13, sptr); sptr += dim;
		COPY(dptr+14, sptr); sptr += dim;
		COPY(dptr+15, sptr);
		/* Now go back up */
		dptr -= dim; sptr++;
		COPY(dptr+15, sptr); sptr -= dim;
		COPY(dptr+14, sptr); sptr -= dim;
		COPY(dptr+13, sptr); sptr -= dim;
		COPY(dptr+12, sptr); sptr -= dim;
		COPY(dptr+11, sptr); sptr -= dim;
		COPY(dptr+10, sptr); sptr -= dim;
		COPY(dptr+9, sptr); sptr -= dim;
		COPY(dptr+8, sptr); sptr -= dim;
		COPY(dptr+7, sptr); sptr -= dim;
		COPY(dptr+6, sptr); sptr -= dim;
		COPY(dptr+5, sptr); sptr -= dim;
		COPY(dptr+4, sptr); sptr -= dim;
		COPY(dptr+3, sptr); sptr -= dim;
		COPY(dptr+2, sptr); sptr -= dim;
		COPY(dptr+1, sptr); sptr -= dim;
		COPY(dptr, sptr);
	    }
	}
    } else {
	for (i = dim-16; i >= 0; i-=16) {
	    for (jj = dim2; jj > 0; jj-=2) {
		int j = jj-1;
		pixel *dptr = dst+RIDX(dim-1-j,i,dim);
		pixel *sptr = src+RIDX(i,j,dim);
		COPY(dptr, sptr); sptr += dim;
		COPY(dptr+1, sptr); sptr += dim;
		COPY(dptr+2, sptr); sptr += dim;
		COPY(dptr+3, sptr); sptr += dim;
		COPY(dptr+4, sptr); sptr += dim;
		COPY(dptr+5, sptr); sptr += dim;
		COPY(dptr+6, sptr); sptr += dim;
		COPY(dptr+7, sptr); sptr += dim;
		COPY(dptr+8, sptr); sptr += dim;
		COPY(dptr+9, sptr); sptr += dim;
		COPY(dptr+10, sptr); sptr += dim;
		COPY(dptr+11, sptr); sptr += dim;
		COPY(dptr+12, sptr); sptr += dim;
		COPY(dptr+13, sptr); sptr += dim;
		COPY(dptr+14, sptr); sptr += dim;
		COPY(dptr+15, sptr);
		/* Now go back up */
		dptr += dim; sptr--;
		COPY(dptr+15, sptr); sptr -= dim;
		COPY(dptr+14, sptr); sptr -= dim;
		COPY(dptr+13, sptr); sptr -= dim;
		COPY(dptr+12, sptr); sptr -= dim;
		COPY(dptr+11, sptr); sptr -= dim;
		COPY(dptr+10, sptr); sptr -= dim;
		COPY(dptr+9, sptr); sptr -= dim;
		COPY(dptr+8, sptr); sptr -= dim;
		COPY(dptr+7, sptr); sptr -= dim;
		COPY(dptr+6, sptr); sptr -= dim;
		COPY(dptr+5, sptr); sptr -= dim;
		COPY(dptr+4, sptr); sptr -= dim;
		COPY(dptr+3, sptr); sptr -= dim;
		COPY(dptr+2, sptr); sptr -= dim;
		COPY(dptr+1, sptr); sptr -= dim;
		COPY(dptr, sptr);
	    }
	    for (jj = dim2; jj < dim; jj+=2) {
		int j = jj;
		pixel *dptr = dst+RIDX(dim-1-j,i,dim);
		pixel *sptr = src+RIDX(i,j,dim);
		COPY(dptr, sptr); sptr += dim;
		COPY(dptr+1, sptr); sptr += dim;
		COPY(dptr+2, sptr); sptr += dim;
		COPY(dptr+3, sptr); sptr += dim;
		COPY(dptr+4, sptr); sptr += dim;
		COPY(dptr+5, sptr); sptr += dim;
		COPY(dptr+6, sptr); sptr += dim;
		COPY(dptr+7, sptr); sptr += dim;
		COPY(dptr+8, sptr); sptr += dim;
		COPY(dptr+9, sptr); sptr += dim;
		COPY(dptr+10, sptr); sptr += dim;
		COPY(dptr+11, sptr); sptr += dim;
		COPY(dptr+12, sptr); sptr += dim;
		COPY(dptr+13, sptr); sptr += dim;
		COPY(dptr+14, sptr); sptr += dim;
		COPY(dptr+15, sptr);
		/* Now go back up */
		dptr -= dim; sptr++;
		COPY(dptr+15, sptr); sptr -= dim;
		COPY(dptr+14, sptr); sptr -= dim;
		COPY(dptr+13, sptr); sptr -= dim;
		COPY(dptr+12, sptr); sptr -= dim;
		COPY(dptr+11, sptr); sptr -= dim;
		COPY(dptr+10, sptr); sptr -= dim;
		COPY(dptr+9, sptr); sptr -= dim;
		COPY(dptr+8, sptr); sptr -= dim;
		COPY(dptr+7, sptr); sptr -= dim;
		COPY(dptr+6, sptr); sptr -= dim;
		COPY(dptr+5, sptr); sptr -= dim;
		COPY(dptr+4, sptr); sptr -= dim;
		COPY(dptr+3, sptr); sptr -= dim;
		COPY(dptr+2, sptr); sptr -= dim;
		COPY(dptr+1, sptr); sptr -= dim;
		COPY(dptr, sptr);
	    }
	}
    }
}

char rotate_64or32_descr[] = "rotate_64or32: Hybrid of unroll 64 rows and unroll 32 rows";
void rotate_64or32(int dim, pixel *src, pixel *dst) {
    if (dim < 128) 
	toggle32_rotate(dim, src, dst);
    else
	toggle64_rotate(dim, src, dst);
}

char rotate_hybrid_descr[] = "rotate_hybrid: Hybrid of toggle32 and toggle16x2";
void rotate_hybrid(int dim, pixel *src, pixel *dst) {
    if (dim <= 256)
	toggle32_rotate(dim, src, dst);
    else
	toggle16x2_rotate(dim, src, dst);
}

/* 
 * rotate - Your current working version of rotate
 * IMPORTANT: This is the version you will be graded on
 */
char rotate_descr[] = "rotate: Current working version";
void rotate(int dim, pixel *src, pixel *dst) 
{
    rotate_hybrid(dim, src, dst);
}

/*********************************************************************
 * register_rotate_functions - Register all of your different versions
 *     of the rotate kernel with the driver by calling the
 *     add_rotate_function() for each test function. When you run the
 *     driver program, it will test and report the performance of each
 *     registered test function.  
 *********************************************************************/

void register_rotate_functions() {
    add_rotate_function(&rotate, rotate_descr);
    add_rotate_function(&naive_rotate, naive_rotate_descr);
    add_rotate_function(&rotate_b4, rotate_b4_descr);
    add_rotate_function(&rotate_b8, rotate_b8_descr);
    add_rotate_function(&rotate_c, rotate_c_descr);
    add_rotate_function(&rotate_b16_u2, rotate_b16_u2_descr);
    add_rotate_function(&rotate_b32_u2, rotate_b32_u2_descr);
    add_rotate_function(&rotate_b8_u4, rotate_b8_u4_descr);
    add_rotate_function(&rotate_b8_u4_c, rotate_b8_u4_c_descr);
    add_rotate_function(&rotate_b16_u4, rotate_b16_u4_descr);
    add_rotate_function(&rotate_b16_u4_c, rotate_b16_u4_c_descr);
    add_rotate_function(&rotate_b32_u4, rotate_b32_u4_descr);
    add_rotate_function(&rotate_b32_u4_c, rotate_b32_u4_c_descr);
    add_rotate_function(&rotate_64or32, rotate_64or32_descr);
    add_rotate_function(&rotate_rec, rotate_rec_descr);
    add_rotate_function(&toggle32_rotate, toggle32_rotate_descr);
    add_rotate_function(&toggle16x2_rotate, toggle16x2_rotate_descr);
    add_rotate_function(&rotate_hybrid, rotate_hybrid_descr);
}


/***************
 * SMOOTH KERNEL
 **************/

/***************************************************************
 * Various typedefs and helper functions for the smooth function
 * You may modify these any way you like.
 **************************************************************/

/* A struct used to compute averaged pixel value */
typedef struct {
    int red;
    int green;
    int blue;
    int num;
} pixel_sum;

/************************************************
 * Various helper functions for the smooth kernel
 ************************************************/

/* Compute min and max of two integers, respectively */
static int min(a,b) { return (a < b ? a : b); }
static int max(a,b) { return (a > b ? a : b); }

/* Faster macro versions of min and max */
#define fastmin(a,b) (a < b ? a : b)
#define fastmax(a,b) (a > b ? a : b)

/* 
 * initialize_pixel_sum - Initializes all fields of sum to 0 
 */
static void initialize_pixel_sum(pixel_sum *sum) 
{
    sum->red = sum->green = sum->blue = 0;
    sum->num = 0;
    return;
}

/* 
 * accumulate_sum - Accumulates field values of p in corresponding 
 * fields of sum 
 */
static void accumulate_sum(pixel_sum *sum, pixel p) 
{
    sum->red += (int) p.red;
    sum->green += (int) p.green;
    sum->blue += (int) p.blue;
    sum->num++;
    return;
}

/* 
 * assign_sum_to_pixel - Computes averaged pixel value in current_pixel 
 */
static void assign_sum_to_pixel(pixel *current_pixel, pixel_sum sum) 
{
    current_pixel->red = (unsigned short) (sum.red/sum.num);
    current_pixel->green = (unsigned short) (sum.green/sum.num);
    current_pixel->blue = (unsigned short) (sum.blue/sum.num);
    return;
}

/* 
 * avg - Returns averaged pixel value at (i,j) 
 */
static pixel avg(int dim, int i, int j, pixel *src) 
{
    int ii, jj;
    pixel_sum sum;
    pixel current_pixel;

    initialize_pixel_sum(&sum);
    for(jj=max(j-1, 0); jj <= min(j+1, dim-1); jj++) 
	for(ii=max(i-1, 0); ii <= min(i+1, dim-1); ii++) 
	    accumulate_sum(&sum, src[RIDX(ii,jj,dim)]);

    assign_sum_to_pixel(&current_pixel, sum);
 
    return current_pixel;
}

/* 
 * fastavg - Returns averaged pixel value at (i,j) 
 * (using macro min/max versions) 
 */
static pixel fastavg(int dim, int i, int j, pixel *src) 
{
    int ii, jj;
    pixel_sum sum;
    pixel current_pixel;

    initialize_pixel_sum(&sum);
    for(jj = fastmax(j-1, 0); jj <= fastmin(j+1, dim-1); jj++) 
	for(ii = fastmax(i-1, 0); ii <= fastmin(i+1, dim-1); ii++) 
	    accumulate_sum(&sum, src[RIDX(ii,jj,dim)]);

    assign_sum_to_pixel(&current_pixel, sum);
 
    return current_pixel;
}



/******************************************************
 * Your different versions of the smooth kernel go here
 ******************************************************/

/*
 * naive_smooth - The naive baseline version of smooth 
 */
char naive_smooth_descr[] = "naive_smooth: Naive baseline implementation";
void naive_smooth(int dim, pixel *src, pixel *dst) 
{
    int i, j;

    for (i = 0; i < dim; i++)
	for (j = 0; j < dim; j++)
	    dst[RIDX(i, j, dim)] = avg(dim, i, j, src);
}

char smooth_macro_descr[] = "smooth_macro: Naive version with macro versions of min/max";
void smooth_macro(int dim, pixel *src, pixel *dst) 
{
    int i, j;

    for(i=0; i < dim; i++)
	for(j=0; j < dim; j++)
	    dst[RIDX(i,j,dim)] = fastavg(dim, i, j, src);

    return;
}

char smooth_opt1_descr[] = "smooth_opt1: Optimized version with loop unrolling and local variables";
void smooth_opt1(int dim, pixel *src, pixel *dst) {
    int ii, i, j, jj;
    int red, blue, green;
    short num;
    int test1, test2, test3, test4;
    int maxelement;
    int temp1, temp2;
    int first, second;
    maxelement = dim - 1;

    for(i = 0; i < dim; i++) {
	first = i*dim;
	test3 = (i-1 > 0 ? i-1 : 0);
	test4 = (i+1 < maxelement ? i+1 : maxelement);
	for(j = 0; j < dim; j++) {
	    red = blue = green = 0;
	    test1 = (j-1 > 0 ? j-1 : 0);
	    test2 = (j+1 < maxelement ? j+1 : maxelement);
	    num = (test2 - test1 + 1) * (test4 - test3 + 1);
	    for(ii = test3; ii <= test4; ii++) {
		second = ii*dim;
		for(jj = test1; jj <= test2; jj++) {
		    temp2 = second + jj;
		    red += src[temp2].red;
		    blue += src[temp2].blue;
		    green += src[temp2].green;
		}
	    }
	    temp1 = first + j;	    
	    if(num == 9) {	    
		dst[temp1].red = (unsigned short) (red/9);
		dst[temp1].blue = (unsigned short) (blue/9);
		dst[temp1].green = (unsigned short) (green/9);
	    } else if(num == 6) {	    
		dst[temp1].red = (unsigned short) (red/6);
		dst[temp1].blue = (unsigned short) (blue/6);
		dst[temp1].green = (unsigned short) (green/6);
	    } else {
		dst[temp1].red = (unsigned short) (red/4);
		dst[temp1].blue = (unsigned short) (blue/4);
		dst[temp1].green = (unsigned short) (green/4);
	    } 
	}
    }
      
    return;
}

char smooth_opt2_descr[] = "smooth_opt2: Optimized version with complete loop unrolling";
void smooth_opt2(int dim, pixel *src, pixel *dst) 
{
    int i, j;
    int row;

    /* calculate top left corner */
    dst[0].red = (src[0].red + src[1].red + src[dim].red + 
		  src[dim + 1].red)/4;
    dst[0].blue = (src[0].blue + src[1].blue + 
		   src[dim].blue + src[dim + 1].blue)/4;
    dst[0].green = (src[0].green + src[1].green + 
		    src[dim].green + src[dim + 1].green)/4;

    /* calculate top row */
    for(i = 1; i < dim - 1; i++) {
	dst[i].red = (src[i].red + src[i-1].red + src[i+1].red + 
		      src[dim + i - 1].red + src[dim + i].red + 
		      src[dim + i + 1].red)/6;
	dst[i].blue = (src[i].blue + src[i-1].blue + src[i+1].blue + 
		       src[dim + i - 1].blue + src[dim + i].blue + 
		       src[dim + i + 1].blue)/6;
	dst[i].green = (src[i].green + src[i-1].green + src[i+1].green + 
			src[dim + i - 1].green + src[dim + i].green + 
			src[dim + i + 1].green)/6;
    }

    /*  calculate top right corner */
    dst[dim-1].red = (src[dim-1].red + src[dim-2].red + 
		      src[dim + dim - 2].red + src[dim + dim - 1].red)/4;
    dst[dim-1].blue = (src[dim-1].blue + src[dim-2].blue + 
		       src[dim + dim - 2].blue + src[dim + dim - 1].blue)/4;
    dst[dim-1].green = (src[dim-1].green + src[dim-2].green + 
			src[dim + dim - 2].green + src[dim + dim - 1].green)/4;

    /* calculate left column */
    for(i = 1; i < dim - 1; i++) {
	j = dim*i;
	dst[j].red = (src[j].red + src[j - dim].red + src[j - dim + 1].red + 
		      src[j + 1].red + src[j + dim].red + 
		      src[j + dim + 1].red)/6;
	dst[j].blue = (src[j].blue + src[j - dim].blue + 
		       src[j - dim + 1].blue + src[j + 1].blue + 
		       src[j + dim].blue + src[j + dim + 1].blue)/6;
	dst[j].green = (src[j].green + src[j - dim].green + 
			src[j - dim + 1].green + src[j + 1].green + 
			src[j + dim].green + src[j + dim + 1].green)/6;  
    }


    /* calculate right column */
    for(i = 1; i < dim - 1; i++) {
	j = dim*i + dim - 1;
	dst[j].red = (src[j].red + src[j - dim].red + 
		      src[j - dim - 1].red + src[j - 1].red + 
		      src[j + dim].red + src[j + dim - 1].red)/6;
	dst[j].blue = (src[j].blue + src[j - dim].blue + 
		       src[j - dim - 1].blue + src[j - 1].blue + 
		       src[j + dim].blue + src[j + dim - 1].blue)/6;
	dst[j].green = (src[j].green + src[j - dim].green + 
			src[j - dim - 1].green + src[j - 1].green + 
			src[j + dim].green + src[j + dim - 1].green)/6;  
    }

    /* calculate bottom left corner */
    j = dim*(dim - 1);
    dst[j].red = (src[j].red + src[j - dim].red + 
		  src[j - dim + 1].red + src[j + 1].red)/4;
    dst[j].blue = (src[j].blue + src[j - dim].blue + 
		   src[j - dim + 1].blue + src[j + 1].blue)/4;
    dst[j].green = (src[j].green + src[j - dim].green + 
		    src[j - dim + 1].green + src[j + 1].green)/4;


    /* calculate bottom row */
    for(i = 1; i < dim - 1; i++) {
	dst[j+i].red = (src[j+i].red + src[j+i-1].red + 
			src[j+i-dim-1].red + src[j+i-dim].red + 
			src[j+i-dim+1].red + src[j+i+1].red)/6;
	dst[j+i].blue = (src[j+i].blue + src[j+i-1].blue + 
			 src[j+i-dim-1].blue + src[j+i-dim].blue + 
			 src[j+i-dim+1].blue + src[j+i+1].blue)/6;
	dst[j+i].green = (src[j+i].green + src[j+i-1].green + 
			  src[j+i-dim-1].green + src[j+i-dim].green + 
			  src[j+i-dim+1].green + src[j+i+1].green)/6;
    }

    /* calculate bottom right corner */
    j = (dim+1)*(dim-1);
    dst[j].red = (src[j].red + src[j - dim].red + 
		  src[j - dim - 1].red + src[j - 1].red)/4;
    dst[j].blue = (src[j].blue + src[j - dim].blue + 
		   src[j - dim - 1].blue + src[j - 1].blue)/4;
    dst[j].green = (src[j].green + src[j - dim].green + 
		    src[j - dim - 1].green + src[j - 1].green)/4;


    /* calculate main block */
    for(i = 1;i < dim-1; i++) {
	row = i*dim;
	for(j = 1;j < dim-1; j++) {
	    dst[row + j].red = (src[row + j].red + 
				src[row + j - 1].red + 
				src[row + j + 1].red + 
				src[row + j - dim - 1].red + 
				src[row + j - dim].red + 
				src[row + j - dim + 1].red +
				src[row + j + dim - 1].red + 
				src[row + j + dim].red + 
				src[row + j + dim + 1].red)/9;

	    dst[row + j].blue = (src[row + j].blue + 
				 src[row + j - 1].blue + 
				 src[row + j + 1].blue + 
				 src[row + j - dim - 1].blue + 
				 src[row + j - dim].blue + 
				 src[row + j - dim + 1].blue + 
				 src[row + j + dim - 1].blue + 
				 src[row + j + dim].blue + 
				 src[row + j + dim + 1].blue)/9;

	    dst[row + j].green = (src[row + j].green + 
				  src[row + j - 1].green + 
				  src[row + j + 1].green + 
				  src[row + j - dim - 1].green + 
				  src[row + j - dim].green +
				  src[row + j - dim + 1].green + 
				  src[row + j + dim - 1].green + 
				  src[row + j + dim].green + 
				  src[row + j + dim + 1].green)/9;
	}
    }
}


/*
 * smooth - Your current working version of smooth. 
 * IMPORTANT: This is the version you will be graded on
 */
char smooth_descr[] = "smooth: Current working version";
void smooth(int dim, pixel *src, pixel *dst) 
{
    smooth_opt2(dim, src, dst);
}

/********************************************************************* 
 * register_smooth_functions - Register all of your different versions
 *     of the smooth kernel with the driver by calling the
 *     add_smooth_function() for each test function.  When you run the
 *     driver program, it will test and report the performance of each
 *     registered test function.  
 *********************************************************************/

void register_smooth_functions() {
    add_smooth_function(&smooth, smooth_descr);
    add_smooth_function(&naive_smooth, naive_smooth_descr);
    add_smooth_function(&smooth_macro, smooth_macro_descr);
    add_smooth_function(&smooth_opt1, smooth_opt1_descr);
    add_smooth_function(&smooth_opt2, smooth_opt2_descr);
}





