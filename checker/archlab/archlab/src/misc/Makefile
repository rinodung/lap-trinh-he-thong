CC=gcc
CFLAGS=-Wall -g -O0
LCFLAGS=-O1 -g
LEX = flex
YACC=bison
LEXLIB = -lfl
YAS=./yas

all: yis yas hcl2c mux4


# These are implicit rules for making .yo files from .ys files.
# E.g., make sum.yo
.SUFFIXES: .ys .yo .c .o
.ys.yo:
	$(YAS) $*.ys
.c.s:
	$(CC) -Og -S $*.c


# These are the explicit rules for making yis yas and hcl2c and hcl2v
yas-grammar.o: yas-grammar.c
	$(CC) $(LCFLAGS) -c yas-grammar.c

yas-grammar.c: yas-grammar.lex
	$(LEX) yas-grammar.lex
	mv lex.yy.c yas-grammar.c

isa.o: isa.c isa.h
	$(CC) $(CFLAGS) -c isa.c

yas: yas.c yas.h isa.h yas-grammar.o isa.o
	$(CC) $(CFLAGS) yas-grammar.o yas.c isa.o ${LEXLIB} -o yas

yis.o: yis.c isa.h
	$(CC) $(CFLAGS) -c yis.c

yis: yis.o isa.o
	$(CC) $(CFLAGS) yis.o isa.o -o yis

hcl2c: hcl.tab.c lex.yy.c node.c outgen.c
	$(CC) $(LCFLAGS) node.c lex.yy.c hcl.tab.c outgen.c -o hcl2c

hcl2v: hcl.tab.c lex.yy.c node.c outgen.c
	$(CC) $(LCFLAGS) -DVLOG node.c lex.yy.c hcl.tab.c outgen.c -o hcl2v

hcl2u: hcl.tab.c lex.yy.c node.c outgen.c
	$(CC) $(LCFLAGS) -DUCLID node.c lex.yy.c hcl.tab.c outgen.c -o hcl2u

lex.yy.c: hcl.lex
	$(LEX) hcl.lex

hcl.tab.c: hcl.y
	$(YACC) -d hcl.y

# This rule creates the students distribution of the misc directory
dist:
	cp -p Makefile-sim $(DISTDIR)/misc/Makefile
	cp -p README node.c node.h outgen.c outgen.h $(DISTDIR)/misc
	cp -p mux4.hcl isa.h isa.c yas.c yas.h yis.c $(DISTDIR)/misc
	cp -p examples.c $(DISTDIR)/misc
	cp -p hcl.lex hcl.y hcl.tab.c hcl.tab.h $(DISTDIR)/misc
	cp -p yas-grammar.lex lex.yy.c yas-grammar.c $(DISTDIR)/misc

# Used only by the CS:APP authors
book:
	cp -p frag.hcl reg-file.hcl $(BOOKDIR)/misc

mux4: mux4.hcl
	./hcl2c < mux4.hcl > mux4.c
	$(CC) $(CFLAGS) mux4.c -o mux4

clean:
	rm -f *.o *.yo *.exe yis yas hcl2c mux4 *~ core.* 
	rm -f hcl.tab.c hcl.tab.h hcl2v lex.yy.c yas-grammar.c


