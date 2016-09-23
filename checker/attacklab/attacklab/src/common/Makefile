CC = gcc
OFLAGS = -Og
CFLAGS = $(OFLAGS) -Wall -g

.SUFFIXES: .c .s .d

.c.s:
	$(CC) $(OFLAGS) -S $*.c

.s.d:
	as $*.s -o $*.o
	objdump -d $*.o > $*.d
	rm -f $*.o

all: gencookie.o gencode.o testgen

gencookie.o: gencookie.c gencookie.h
	$(CC) $(CFLAGS) -c gencookie.c

gencode.o: gencode.c gencode.h
	$(CC) $(CFLAGS) -c gencode.c

testgen: testgen.c gencode.o
	$(CC) $(CFLAGS) -g -o testgen testgen.c gencode.o

clean:
	rm -f *~ *.o 
	rm -f gencode.o gencookie.o testgen

