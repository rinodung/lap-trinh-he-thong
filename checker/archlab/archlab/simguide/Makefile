
SRC = ../src
ROOT = ../../../..
C2TEX = $(ROOT)/bin/c2tex
WWWDIR = /afs/cs/project/csapp3/www
CODE = $(SRC)/y86-code

all: simguide

simguide: codefiles
	pdflatex simguide
	pdflatex simguide

codefiles:
	$(C2TEX) -nc -f $(CODE)/asum-sim.yo -t code-yssim

# This rule is used only by authors
webpage:
	cp simguide.pdf $(WWWDIR)

clean:
	rm -f *~ *.dvi

