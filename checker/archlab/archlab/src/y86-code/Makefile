CC=gcc
CFLAGS=-Wall -Og -m64

ISADIR = ../misc
YAS=$(ISADIR)/yas
YIS=$(ISADIR)/yis
PIPE=../pipe/psim
SEQ=../seq/ssim
SEQ+ =../seq/ssim+
VEXTRACT=../hcl/vextract.pl

BOOKDIR=.

YOFILES = abs-asum-cmov.yo abs-asum-jmp.yo asum.yo asumr.yo asumi.yo codefrags.yo cjr.yo frag.yo j-cc.yo poptest.yo pushquestion.yo pushtest.yo prog1.yo prog2.yo prog3.yo prog4.yo prog5.yo prog6.yo prog7.yo prog8.yo prog9.yo prog10.yo encode.yo decode.yo ret-hazard.yo seq-eg.yo cmov-noforward.yo

PIPEFILES = asum.pipe asumr.pipe cjr.pipe j-cc.pipe poptest.pipe pushquestion.pipe pushtest.pipe prog1.pipe prog2.pipe prog3.pipe prog4.pipe prog5.pipe prog6.pipe prog8.pipe ret-hazard.yo

SEQFILES = asum.seq asumr.seq cjr.seq j-cc.seq poptest.seq pushquestion.seq pushtest.seq prog1.seq prog2.seq prog3.seq prog4.seq prog5.seq prog6.seq prog8.seq

SEQ+FILES = asum.seq+ asumr.seq+ cjr.seq+ j-cc.seq+ poptest.seq+ pushquestion.seq+ pushtest.seq+ prog1.seq+ prog2.seq+ prog3.seq+ prog4.seq+ prog5.seq+ prog6.seq+ prog8.seq+

.SUFFIXES:
.SUFFIXES: .c .s .o .ys .yo .yis .pipe .seq .seq+ .txt

all: asum.ys book $(YOFILES) asum.yis seq-eg.txt prog6.txt prog7.txt prog10.txt
# prog1.txt prog2.txt prog3.txt prog4.txt prog5.txt prog6.txt
# prog7.txt prog8.txt prog9.txt seq-eg.txt

test: testpsim testssim testssim+

testpsim: $(PIPEFILES)
	grep "ISA Check" *.pipe
	rm $(PIPEFILES)

testssim: $(SEQFILES)
	grep "ISA Check" *.seq
	rm $(SEQFILES)

testssim+: $(SEQ+FILES)
	grep "ISA Check" *.seq+
	rm $(SEQ+FILES)

.c.s:
	$(CC) $(CFLAGS) -S $*.c

.ys.yo:
	$(YAS) $*.ys

# Extracting code fragments
.yo.txt:
	egrep "\|   #|:[ a-f0-9]*\|" $*.yo | \
	perl -ne "s/:[ a-f0-9]+\|/:/; s/[ ]*\|[ ]*#/#/; print;" > $*.txt

.yo.yis: $(YIS)
	$(YIS) $*.yo > $*.yis

.yo.pipe: $(PIPE)
	$(PIPE) -t $*.yo  > $*.pipe

.yo.seq: $(SEQ)
	$(SEQ) -t $*.yo > $*.seq

.yo.seq+: $(SEQ+)
	$(SEQ+) -t $*.yo > $*.seq+


asum.ys: master-asum.ys
	$(VEXTRACT) -v y < master-asum.ys > asum.ys

asum-fun.ys: master-asum.ys
	$(VEXTRACT) -v a < master-asum.ys > asum-fun.ys

asum-src.ys: master-asum.ys
	$(VEXTRACT) -v s < master-asum.ys > asum-src.ys

asum-obj.yo: master-asum.ys
	$(VEXTRACT) -v o < master-asum.ys > asum-obj.ys
	$(YAS) asum-obj.ys

asum-sim.yo: master-asum.ys
	$(VEXTRACT) -v g < master-asum.ys > asum-sim.ys
	$(YAS) asum-sim.ys

dist:
	cp -p abs-asum-cmov.ys abs-asum-jmp.ys asum.ys asumr.ys asumi.ys\
		cjr.ys j-cc.ys poptest.ys \
		pushquestion.ys pushtest.ys prog1.ys prog2.ys prog3.ys \
		prog4.ys prog5.ys prog6.ys prog7.ys prog8.ys prog9.ys prog10.ys \
		ret-hazard.ys README \
		$(DISTDIR)/y86-code
	cp -p Makefile-sim $(DISTDIR)/y86-code/Makefile

code-linux: code-linux.c
	$(CC) $(CFLAGS) code-linux.c -o code-linux
	$(CC) $(CFLAGS) -S code-linux.c -o code-linux.rs
	grep -v ".L[A-F]" code-linux.rs | grep -v ".cfi_" | grep -v ".p2align" > code-linux.s

book:	asum-fun.ys asum-obj.yo asum-src.ys asum-sim.yo
	cp -p asum-fun.ys asum-fun.sa

clean:
	rm -f *.o *.yis *~ *.yo *.pipe *.seq *.seq+ asum.ys *.txt asum-*.* asum.* abs-asum-jmp.sa  abs-asum-cmov.sa
