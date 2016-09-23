CC = gcc
OFLAGS = -Og
CFLAGS = $(OFLAGS) -Wall

.SUFFIXES: .c .s .d .b .g

.c.s:
	$(CC) $(OFLAGS) -S $*.c

.s.d:
	as $*.s -o $*.o
	objdump -d $*.o > $*.d
	rm -f $*.o

.d.b:
	./stripd.pl < $*.d > $*.b

.b.g:
	./harvest -i $*.b -o $*.g

tex: popq.tex nopb.tex movq.tex movl.tex

movw.txt: genmov.pl
	./genmov.pl -w

movw.tex: genmov.pl
	./genmov.pl -xw

movl.txt: genmov.pl
	./genmov.pl -l

movl.tex: genmov.pl
	./genmov.pl -xl

movq.txt: genmov.pl
	./genmov.pl -q

movq.tex: genmov.pl
	./genmov.pl -xq

nopb.txt: gennop.pl
	./gennop.pl -b

nopb.tex: gennop.pl
	./gennop.pl -xb

nopw.txt: gennop.pl
	./gennop.pl -w

nopw.tex: gennop.pl
	./gennop.pl -xw

nopl.txt: gennop.pl
	./gennop.pl -l

nopl.tex: gennop.pl
	./gennop.pl -xl

nopq.txt: gennop.pl
	./gennop.pl -q

nopq.tex: gennop.pl
	./gennop.pl -xq

popq.txt: genpop.pl
	./genpop.pl 

popq.tex: genpop.pl
	./genpop.pl -x

clean:
	rm -f *~ *.txt *.tex *.s *.d *.o
