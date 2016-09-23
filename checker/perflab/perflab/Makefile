# Builds the CS:APP Performance Lab

# Instructor: Change DEST to the public directory where you want 
# the handout files copied to, and where the students will access them 
# from. Or you can set DEST when you invoke make: "make dist DEST=/foo/bar"
DEST = 

LABNAME = perflab
DRIVEROBJS = driver.o,fcyc.o,clock.o

all: driver-code lab-writeup handout handout-tarfile

driver-code:
	##########################
	# Build the driver program
	##########################
	(cd src; make clean; make)

lab-writeup:
	########################
	# Format the lab writeup
	########################
	(cd writeup; make LABNAME=$(LABNAME))

handout: driver-code lab-writeup
	###################################################
	# Copy the necessary files to the handout directory
	###################################################
	rm -f $(LABNAME)-handout/*
	cp -p src/{driver.c,fcyc.c,clock.c,defs.h,clock.h,fcyc.h,config.h} $(LABNAME)-handout
	cp -p src/kernels-naive.c $(LABNAME)-handout/kernels.c
	cp -p src/Makefile-handout $(LABNAME)-handout/Makefile
	cp -p src/README-handout $(LABNAME)-handout/README

handout-tarfile: handout
	########################################
	# Build tarfile of the handout directory
	########################################
	(cd $(LABNAME)-handout; tar cvf ../$(LABNAME)-handout.tar *)

dist: 
	########################################	
	# Update distribution
	########################################
	cp -p $(LABNAME)-handout.tar $(DEST)
	cp -p writeup/$(LABNAME).ps $(DEST)
	cp -p writeup/$(LABNAME).pdf $(DEST)

clean:
	#########################################
	# Clean the entire perflab directory tree
	#########################################
	rm -f *.tar *~
	(cd src; make clean)
	(cd writeup; make clean)
	rm -f $(LABNAME)-handout/*

