#
# Builds the Cache Lab simulators and tools
#
CC = gcc
CFLAGS = -g -Wall -Werror -std=c99

all: csim csim-ref test-csim test-trans tracegen

csim: csim.c cachelab.c cachelab.h
	$(CC) $(CFLAGS) -o csim csim.c cachelab.c -lm 

csim-ref: csim-ref.c cachelab.c cachelab.h
	$(CC) $(CFLAGS) -o csim-ref csim-ref.c cachelab.c -lm

test-csim: test-csim.c 
	$(CC) $(CFLAGS) -o test-csim test-csim.c 

test-trans: test-trans.c trans.o cachelab.c cachelab.h
	$(CC) $(CFLAGS) -o test-trans test-trans.c cachelab.c trans.o 

trans.o: trans.c
	$(CC) $(CFLAGS) -O0 -c trans.c

tracegen: tracegen.c trans.o cachelab.c
	$(CC) $(CFLAGS) -O0 -o tracegen tracegen.c trans.o cachelab.c

handin:
	tar -cvhf ${USER}-handin.tar  csim.c trans.c 

#
# Use these rules to switch between different test simulators and trans functions
#
# The reference solution
ref:
	rm -f csim csim.c trans.c trans.o
	ln -s csim-ref.c csim.c
	ln -s trans-ref.c trans.c

# Initial handout version
handout:
	rm -f csim csim.c trans.c trans.o
	ln -s csim-handout.c csim.c
	ln -s trans-handout.c trans.c

#
# Clean the src dirctory
#
clean:
	rm -rf *.o
	rm -rf *.tmp
	rm -f csim csim-ref
	rm -f test-csim test-trans
	rm -f tracegen
	rm -f trace.all trace.f*
	rm -f .csim_results .marker
