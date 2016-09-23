# psim is the default simualator to test
SIM=../pipe/psim
VMODEL=pipe-std
OUTDIR = .

# Uncomment this if you are testing iaddq
#TFLAGS=-i 

ISADIR = ../misc
YAS=$(ISADIR)/yas

.SUFFIXES: .ys .yo

.ys.yo:
	$(YAS) $*.ys

# Quick test
qtest:
	./optest.pl -s $(SIM) -d $(OUTDIR) $(TFLAGS)
	./jtest.pl -s $(SIM) -d $(OUTDIR) $(TFLAGS)
	./cmtest.pl -s $(SIM) -d $(OUTDIR) $(TFLAGS)
	./ctest.pl -s $(SIM) -d $(OUTDIR) $(TFLAGS)
	./etest.pl -s $(SIM) -d $(OUTDIR) $(TFLAGS)

# Full test
test:
	./optest.pl -s $(SIM) -d $(OUTDIR) $(TFLAGS)
	./jtest.pl -s $(SIM) -d $(OUTDIR) $(TFLAGS)
	./cmtest.pl -s $(SIM) -d $(OUTDIR) $(TFLAGS)
	./ctest.pl -s $(SIM) -d $(OUTDIR) $(TFLAGS)
	./htest.pl -s $(SIM) -d $(OUTDIR) $(TFLAGS)
	./etest.pl -s $(SIM) -d $(OUTDIR) $(TFLAGS)

# Verilog test
vtest:
	./optest.pl -V -m $(VMODEL) -d $(OUTDIR) $(TFLAGS)
	./jtest.pl -V -m $(VMODEL) -d $(OUTDIR) $(TFLAGS)
	./cmtest.pl -V -m $(VMODEL) -d $(OUTDIR) $(TFLAGS)
	./ctest.pl -V -m $(VMODEL) -d $(OUTDIR) $(TFLAGS)
	./htest.pl -V -m $(VMODEL) -d $(OUTDIR) $(TFLAGS)
	./etest.pl  -V -m $(VMODEL) -d $(OUTDIR) $(TFLAGS)

dist:
	cp -p README ctest.pl htest.pl jtest.pl optest.pl etest.pl tester.pm $(DISTDIR)/ptest
	cp -p Makefile-sim $(DISTDIR)/ptest/Makefile

clean:
	rm -f *.o *~ *.yo *.ys
	rm -rf psim-* ssim-* ssim+-*

