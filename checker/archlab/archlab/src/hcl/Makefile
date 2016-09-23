VEXTRACT=./vextract.pl
SNIPPET=./snippet.pl
PIPEDIR=../pipe
SEQDIR=../seq

PIPE-PUBLIC=pipe-std.hcl pipe-full.hcl pipe-lf.hcl pipe-nobypass.hcl \
	pipe-nt.hcl pipe-btfnt.hcl pipe-1w.hcl pipe-broken.hcl

PIPE-PRIVATE=pipe-full-ans.hcl pipe-lf-ans.hcl pipe-nobypass-ans.hcl \
	pipe-nt-ans.hcl pipe-btfnt-ans.hcl pipe-1w-ans.hcl \
	pipe-super.hcl

PIPE-ANN= pipe-std-annotate.hcl pipe-nobypass-annotate.hcl \
	pipe-1w-annotate.hcl

PIPE-VLOG= pipe-fetch.hcl

SEQ-PUBLIC=seq-std.hcl seq-full.hcl seq+-std.hcl 

SEQ-ANN=seq-std-annotate.hcl \
	seq-nocmov-annotate.hcl \
	seq+-std-annotate.hcl

SEQ-PRIVATE=seq-full-ans.hcl

all: pipe-public pipe-private pipe-ann pipe-vlog seq-public seq-private seq-ann

pipe-public: $(PIPE-PUBLIC)
	cp -p $(PIPE-PUBLIC) $(PIPEDIR)

pipe-private: $(PIPE-PRIVATE)
	cp -p $(PIPE-PRIVATE) $(PIPEDIR)

pipe-ann: $(PIPE-ANN)

pipe-std.hcl: master-pipe.hcl
	$(VEXTRACT) < master-pipe.hcl > pipe-std.hcl

pipe-std-annotate.hcl: master-pipe.hcl
	$(VEXTRACT) -v a < master-pipe.hcl > pipe-std-annotate.hcl

pipe-broken.hcl: master-pipe.hcl
	$(VEXTRACT) -v b < master-pipe.hcl > pipe-broken.hcl

pipe-full.hcl: master-pipe.hcl
	$(VEXTRACT) -v f < master-pipe.hcl > pipe-full.hcl

pipe-full-ans.hcl: master-pipe.hcl
	$(VEXTRACT) -v F < master-pipe.hcl > pipe-full-ans.hcl

pipe-lf.hcl: master-pipe.hcl
	$(VEXTRACT) -v l < master-pipe.hcl > pipe-lf.hcl

pipe-lf-ans.hcl: master-pipe.hcl
	$(VEXTRACT) -v L < master-pipe.hcl > pipe-lf-ans.hcl

pipe-super.hcl: master-pipe.hcl
	$(VEXTRACT) -v LF < master-pipe.hcl > pipe-super.hcl

pipe-nt.hcl: master-pipe.hcl
	$(VEXTRACT) -v n < master-pipe.hcl > pipe-nt.hcl

pipe-nt-ans.hcl: master-pipe.hcl
	$(VEXTRACT) -v N < master-pipe.hcl > pipe-nt-ans.hcl

pipe-btfnt.hcl: master-pipe.hcl
	$(VEXTRACT) -v t < master-pipe.hcl > pipe-btfnt.hcl

pipe-btfnt-ans.hcl: master-pipe.hcl
	$(VEXTRACT) -v T < master-pipe.hcl > pipe-btfnt-ans.hcl

pipe-1w.hcl: master-pipe.hcl
	$(VEXTRACT) -v w < master-pipe.hcl > pipe-1w.hcl

pipe-1w-annotate.hcl: master-pipe.hcl
	$(VEXTRACT) -v wa < master-pipe.hcl > pipe-1w-annotate.hcl

pipe-1w-ans.hcl: master-pipe.hcl
	$(VEXTRACT) -v W < master-pipe.hcl > pipe-1w-ans.hcl

pipe-nobypass.hcl: master-pipe.hcl
	$(VEXTRACT) -v s < master-pipe.hcl > pipe-nobypass.hcl

pipe-nobypass-annotate.hcl: master-pipe.hcl
	$(VEXTRACT) -v sa < master-pipe.hcl > pipe-nobypass-annotate.hcl

pipe-nobypass-ans.hcl: master-pipe.hcl
	$(VEXTRACT) -v S < master-pipe.hcl > pipe-nobypass-ans.hcl

pipe-vlog: $(PIPE-VLOG)

pipe-fetch.hcl: pipe-std-annotate.hcl
	$(SNIPPET) -s pipe-fetch-all-hcl < pipe-std-annotate.hcl > pipe-fetch.hcl

seq-public: $(SEQ-PUBLIC)
	cp -p $(SEQ-PUBLIC) $(SEQDIR)

seq-private: $(SEQ-PRIVATE)
	cp -p $(SEQ-PRIVATE) $(SEQDIR)

seq-ann: $(SEQ-ANN)

seq-std.hcl: master-seq.hcl
	$(VEXTRACT) < master-seq.hcl > seq-std.hcl

seq-nocmov-annotate.hcl: master-seq.hcl
	$(VEXTRACT) -v ra < master-seq.hcl > seq-nocmov-annotate.hcl

seq-std-annotate.hcl: master-seq.hcl
	$(VEXTRACT) -v a < master-seq.hcl > seq-std-annotate.hcl

seq-full.hcl: master-seq.hcl
	$(VEXTRACT) -v f < master-seq.hcl > seq-full.hcl

seq-full-ans.hcl: master-seq.hcl
	$(VEXTRACT) -v F < master-seq.hcl > seq-full-ans.hcl

seq+-std.hcl: master-seq.hcl
	$(VEXTRACT) -v + < master-seq.hcl > seq+-std.hcl

seq+-std-annotate.hcl: master-seq.hcl
	$(VEXTRACT) -v +a < master-seq.hcl > seq+-std-annotate.hcl

clean:
	rm -f core *~ pipe*.hcl seq*.hcl



