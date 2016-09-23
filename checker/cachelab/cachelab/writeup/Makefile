all:
	latex cachelab.tex
	latex cachelab.tex # again to resolve references
	dvips -o cachelab.ps cachelab.dvi
	ps2pdf cachelab.ps

clean:
	rm -f *.aux *.ps *.pdf *.dvi *.log *~

