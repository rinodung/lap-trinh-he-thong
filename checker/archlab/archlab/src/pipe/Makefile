# Modify this line to indicate the default version to build

VERSION=full-ans

# Comment this out if you don't have Tcl/Tk on your system

GUIMODE=-DHAS_GUI

# Modify the following line so that gcc can find the libtcl.so and
# libtk.so libraries on your system. You may need to use the -L option
# to tell gcc which directory to look in. Comment this out if you
# don't have Tcl/Tk.

TKLIBS=-L/usr/lib -ltk -ltcl

# Modify the following line so that gcc can find the tcl.h and tk.h
# header files on your system. Comment this out if you don't have
# Tcl/Tk.

TKINC=-isystem /usr/include/tcl8.5

# Modify these two lines to choose your compiler and compile time
# flags.

CC=gcc
CFLAGS=-Wall -O2

##################################################
# You shouldn't need to modify anything below here
##################################################

MISCDIR=../misc
HCL2C=$(MISCDIR)/hcl2c
INC=$(TKINC) -I$(MISCDIR) $(GUIMODE)
LIBS=$(TKLIBS) -lm
YAS = ../misc/yas

all: psim drivers

# This rule builds the PIPE simulator
psim: psim.c sim.h pipe-$(VERSION).hcl $(MISCDIR)/isa.c $(MISCDIR)/isa.h 
	# Building the pipe-$(VERSION).hcl version of PIPE
	$(HCL2C) -n pipe-$(VERSION).hcl < pipe-$(VERSION).hcl > pipe-$(VERSION).c
	$(CC) $(CFLAGS) $(INC) -o psim psim.c pipe-$(VERSION).c \
		$(MISCDIR)/isa.c $(LIBS)

# This rule builds driver programs for Part C of the Architecture Lab
drivers: 
	./gen-driver.pl -n 4 -f ncopy.ys > sdriver.ys
	../misc/yas sdriver.ys
	./gen-driver.pl -n 63 -f ncopy.ys > ldriver.ys
	../misc/yas ldriver.ys


## Here is a complete collection of the possible variations on ncopy
## with 8x unrolling
ncopy8: ncopy-u8.yo ncopy-u8c.yo ncopy-u8j.yo ncopy-u8jt.yo ncopy-u8e.yo ncopy-u8et.yo \
	 ncopy-su8.yo ncopy-su8c.yo ncopy-su8j.yo ncopy-su8jt.yo ncopy-su8e.yo ncopy-su8et.yo

ncopy-u8.ys: gen-ncopy.pl
	./gen-ncopy.pl -u 8 > ncopy-u8.ys

ncopy-u8c.ys: gen-ncopy.pl
	./gen-ncopy.pl -u 8 -c > ncopy-u8c.ys

ncopy-u8j.ys: gen-ncopy.pl
	./gen-ncopy.pl -u 8 -j > ncopy-u8j.ys

ncopy-u8jt.ys: gen-ncopy.pl
	./gen-ncopy.pl -u 8 -j -t > ncopy-u8jt.ys

ncopy-u8e.ys: gen-ncopy.pl
	./gen-ncopy.pl -u 8 -e > ncopy-u8e.ys

ncopy-u8et.ys: gen-ncopy.pl
	./gen-ncopy.pl -u 8 -e -t > ncopy-u8et.ys

ncopy-su8.ys: gen-ncopy.pl
	./gen-ncopy.pl -s -u 8 > ncopy-su8.ys

ncopy-su8c.ys: gen-ncopy.pl
	./gen-ncopy.pl -s -u 8 -c > ncopy-su8c.ys

ncopy-su8j.ys: gen-ncopy.pl
	./gen-ncopy.pl -s -u 8 -j > ncopy-su8j.ys

ncopy-su8jt.ys: gen-ncopy.pl
	./gen-ncopy.pl -s -u 8 -j -t > ncopy-su8jt.ys

ncopy-su8e.ys: gen-ncopy.pl
	./gen-ncopy.pl -s -u 8 -e > ncopy-su8e.ys

ncopy-su8et.ys: gen-ncopy.pl
	./gen-ncopy.pl -s -u 8 -e -t > ncopy-su8et.ys


# Automatic generation and testing of benchmarks
# Parameters for best result found
UNROLL = 6
NCFLAG = 

benchmark:
	./gen-ncopy.pl -u $(UNROLL) $(NCFLAG) > ncopyl$(UNROLL)$(NCFLAG).ys
	make ncopyl$(UNROLL)$(NCFLAG).yo
	./check-len.pl < ncopyl$(UNROLL)$(NCFLAG).yo
	./correctness.pl -q -f ncopyl$(UNROLL)$(NCFLAG)
	./benchmark.pl -q -f ncopyl$(UNROLL)$(NCFLAG)

# These are implicit rules for assembling .yo files from .ys files.
.SUFFIXES: .ys .yo
.ys.yo:
	$(YAS) $*.ys


# This rule builds the student distribution of the Y86-64 tool chain in ../sim
dist:
	cp -p	pipe-1w.hcl pipe-broken.hcl pipe-btfnt.hcl pipe-full.hcl \
		pipe-lf.hcl pipe-nobypass.hcl pipe-nt.hcl pipe-std.hcl \
		psim.c pipe.tcl pipeline.h sim.h stages.h $(DISTDIR)/pipe
	cp -p Makefile-sim $(DISTDIR)/pipe/Makefile
	cp -p README $(DISTDIR)/pipe/README
	cp -p ncopy.c ncopy.ys $(DISTDIR)/pipe
	cp -p benchmark.pl correctness.pl gen-driver.pl check-len.pl $(DISTDIR)/pipe

clean:
	mkdir tmp; mv ncopy.ys tmp; rm -f *.ys; mv tmp/ncopy.ys .; rmdir tmp
	rm -f psim pipe-*.c *.a *.o *.exe ldriver.* sdriver.* *.yo *~ *.exe



