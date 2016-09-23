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


##################################################
# You shouldn't need to modify anything below here
##################################################

# Use this rule (make all) to build the Y86-64 tools. The variables you've
# assigned to GUIMODE, TKLIBS, and TKINC will override the values that
# are currently assigned in seq/Makefile and pipe/Makefile.
all:
	(cd misc; make all)
	(cd hcl; make all)
	(cd pipe; make all GUIMODE=$(GUIMODE) TKLIBS="$(TKLIBS)" TKINC="$(TKINC)")
	(cd seq; make all GUIMODE=$(GUIMODE) TKLIBS="$(TKLIBS)" TKINC="$(TKINC)")
	(cd y86-code; make all)
#	(cd verilog; make all)

# Use this rule (make dist) to build a student distribution of the Y86-64 tools
# (typically only called by archlab/Makefile)
dist:
	rm -rf $(DISTDIR)
	mkdir $(DISTDIR)
	mkdir $(DISTDIR)/misc
	mkdir  $(DISTDIR)/seq 
	mkdir $(DISTDIR)/pipe 
	mkdir $(DISTDIR)/y86-code
	mkdir $(DISTDIR)/ptest
	cp -p Makefile-sim $(DISTDIR)/Makefile
	cp -p README-sim $(DISTDIR)/README
	(cd pipe; make dist DISTDIR=$(DISTDIR))
	(cd ptest; make dist DISTDIR=$(DISTDIR))
	(cd seq; make dist DISTDIR=$(DISTDIR))
	(cd misc; make dist DISTDIR=$(DISTDIR))
	(cd y86-code; make dist DISTDIR=$(DISTDIR))

clean:
	rm -f *~ core
	(cd misc; make clean)
	(cd pipe; make clean)
	(cd seq; make clean)
	(cd y86-code; make clean)
	(cd ptest; make clean)
	(cd verilog; make clean)
