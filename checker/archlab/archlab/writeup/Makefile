ROOT = ../../../..
C2TEX = $(ROOT)/bin/c2tex
CODE = ../src

all: codefiles
	pdflatex archlab.tex
	pdflatex archlab.tex  # to resolve references

codefiles:
	$(C2TEX) -n -f $(CODE)/pipe/ncopy.c -t ncopy
	$(C2TEX) -n -f $(CODE)/pipe/ncopy.ys -t ncopy-ys
	$(C2TEX) -n -f $(CODE)/misc/examples.c -t examples

clean:
	rm -f *~ *.dvi *.log *.aux archlab.ps archlab.pdf



