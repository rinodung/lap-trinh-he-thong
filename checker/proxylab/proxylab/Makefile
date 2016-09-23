# Instructor: Change DEST to the public directory where you want 
# the handout files copied to, and where the students will access them 
# from. Or you can set it when you invoke make: "make dist DEST=/foo/bar"
DEST = <site specific>

LABNAME = proxylab

all: lab-writeup handout handout-tarfile

handout:
	###################################################
	# Copy the necessary files to the handout directory
	###################################################
	rm -rf proxylab-handout
	mkdir ./proxylab-handout
	(cd src; make clean; make)
	cp src/Makefile-handout proxylab-handout/Makefile
	cp src/README-handout proxylab-handout/README
	cp src/proxy-handout.c proxylab-handout/proxy.c
	cp src/csapp.c proxylab-handout
	cp src/csapp.h proxylab-handout

handout-tarfile: 
	########################################
	# Build tarfile of the handout directory
	########################################
	(cd proxylab-handout; tar cvf ../$(LABNAME)-handout.tar *)

lab-writeup:
	########################
	# Format the lab writeup
	########################
	(cd writeup; make)

dist:
	########################################	
	# Update distribution
	########################################
	cp -p $(LABNAME)-handout.tar $(DEST)
	cp -p writeup/proxylab.ps $(DEST)/$(LABNAME).ps
	cp -p writeup/proxylab.pdf $(DEST)/$(LABNAME).pdf

clean:
	#################################
	# Clean the entire directory tree
	#################################
	rm -f *~ *.tar
	(cd src; make clean)
	(rm -rf proxylab-handout)
	(cd writeup; make clean)

