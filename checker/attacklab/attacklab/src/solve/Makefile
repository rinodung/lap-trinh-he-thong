CC = gcc
OFLAGS = -Og
CFLAGS = $(OFLAGS) -Wall -g
INC = ../common

.SUFFIXES: .c .s .d .b .g

.c.s:
	$(CC) $(OFLAGS) -S $*.c

.s.d:
	as $*.s -o $*.o
	objdump -d $*.o > $*.d
	rm -f $*.o

.d.b:
	./readd.pl -f touch1:touch2:touch3 -b start_farm:end_farm < $*.d > $*.b

.b.g:
	./harvest -f start_farm -i $*.b -o $*.g

all: harvest exploit

harvest: harvest.c $(INC)/gencode.o
	$(CC) $(CFLAGS) -I$(INC) -o harvest harvest.c $(INC)/gencode.o

exploit: exploit.c $(INC)/gencode.o
	$(CC) $(CFLAGS) -I$(INC) -o exploit exploit.c $(INC)/gencode.o

clean:
	rm -f *~ *.o *.d *.b *.g *.s
	rm -f harvest exploit
