PROC=pipe
VERSION=std
VARIANT=
# Set if want lab solution rather than problem.
# ANS=-ans
ANS=

HCL = ../$(PROC)/$(PROC)$(VARIANT)-$(VERSION)$(ANS).hcl
PROCV = components/$(PROC)$(VARIANT)-proc.v

PROG = asum
BLOCK = components/blocks.v

CONTROL = components/controller.v
MEM = components/combram.v

#VERILOGDIR = /usr/local/bin
VERILOGDIR = /src/iverilog/bin
IVERILOG = $(VERILOGDIR)/iverilog
VVP = $(VERILOGDIR)/vvp

HCL2V = ../misc/hcl2v
YAS = ../misc/yas

.SUFFIXES:
.SUFFIXES: .ys .v .vvp .sout .yo

.ys.yo:
	../misc/yas $*.ys

.ys.v: $(HCL) $(PROCV) $(BLOCK) $(CONTROL)
	./gen-sim.pl -H $(HCL) -p $(PROCV) -m $(MEM) -b $(BLOCK) -c $(CONTROL) -a $*.ys -o $*.v

.v.vvp:
	$(IVERILOG) -o $*.vvp $*.v

.vvp.sout:
	$(VVP) $*.vvp > $*.sout

all: pipe-synth.v seq-synth.v seq+-synth.v pipe-fetch.v

run:
	rm -f $(PROG).v* ; 
	make $(PROG).vvp PROC=$(PROC) VERSION=$(VERSION) VARIANT=$(VARIANT) ANS=$(ANS) ; 
	$(VVP) $(PROG).vvp

pipe-synth.v: components/pipe-proc.v components/blocks.v ../pipe/pipe-std.hcl
	./gen-synth.pl -b components/blocks.v -m components/synchram.v -p components/pipe-proc.v -H ../pipe/pipe-std.hcl  -o pipe-synth.v

seq-synth.v: components/seq-proc.v components/blocks.v ../seq/seq-std.hcl
	./gen-synth.pl -b components/blocks.v -m components/combram.v -p components/seq-proc.v -H ../seq/seq-std.hcl  -o seq-synth.v

seq+-synth.v: components/seq+-proc.v components/blocks.v ../seq/seq+-std.hcl
	./gen-synth.pl -b components/blocks.v -m components/combram.v -p components/seq+-proc.v -H ../seq/seq+-std.hcl  -o seq+-synth.v

pipe-fetch.v: ../hcl/pipe-fetch.hcl
	$(HCL2V) < ../hcl/pipe-fetch.hcl > pipe-fetch.v

test:
	./test-sim.pl -H $(HCL) -p $(PROCV) -m $(MEM) -b $(BLOCK) -c $(CONTROL) -a $(PROG) 

clean:
	rm -f *~ *.exe *.vvp *.v a.out components/*~
	rm -f *-synth.v

