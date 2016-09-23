CC = gcc
CFLAGS = -Wall -g
LDFLAGS = -lpthread

OBJS = proxy.o csapp.o

all: proxy proxy-handout.c

proxy: $(OBJS)

# The students are given some helper functions to start with
proxy-handout.c: proxy.c
	./elide.pl -t solution < proxy.c > proxy-handout.c

clean:
	rm -f proxy proxy-handout.c proxy.log *.o *~


