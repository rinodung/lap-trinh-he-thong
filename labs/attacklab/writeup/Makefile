LAB = attacklab

# Perl script that extracts code from bufbomb.c file
C2TEX = ./c2tex

# Program to extract bytes from disassembly
READD = ../src/solve/readd.pl -a

# Location of bufbomb.c sources
CFILE = ../src/build/visible.c
CBFILE = ../src/build/buf.c

all: codefiles tex
	pdflatex $(LAB).tex
	bibtex $(LAB)
	pdflatex $(LAB).tex
	pdflatex $(LAB).tex

tex:
	(cd itables; make tex; cd ..)

example.d: example.s
	gcc -c example.s
	objdump -d example.o > example.d

example.txt: example.d
	$(READD) < example.d > example.txt

codefiles: example.d example.txt
	$(C2TEX) -n -f $(CBFILE) -t getbuf-c
	$(C2TEX) -n -f $(CFILE) -t touch1-c
	$(C2TEX) -n -f $(CFILE) -t touch2-c
	$(C2TEX) -n -f $(CFILE) -t touch3-c
	$(C2TEX) -n -f $(CFILE) -t test-c
	$(C2TEX) -n -f $(CFILE) -t test-c
	$(C2TEX) -f farm-eg.c -t farm-eg-c	
	$(C2TEX) -f farm-eg.d -t farm-eg-d	

clean:
	rm -f *.aux *.dvi *.log *.o $(LAB).pdf *~






