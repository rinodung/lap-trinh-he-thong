# Builds the CS:APP Cache Lab
#
# Instructor: Change DEST to the public directory where you want 
# the handout files copied to, and where the students will access them 
# from. Or you can set DEST when you invoke make: "make dist DEST=/foo/bar"
DEST = 

LABNAME = cachelab

all: lab-writeup driver handout-tarfile 

lab-writeup:
	(cd writeup; make)

driver:
	(cd src; make)

handout-tarfile:
	rm -rf $(LABNAME)-handout
	mkdir $(LABNAME)-handout
	cp -p src/$(LABNAME).c $(LABNAME)-handout/
	cp -p src/$(LABNAME).h $(LABNAME)-handout/
	cp -p -r src/traces $(LABNAME)-handout/
	cp -p src/csim-ref $(LABNAME)-handout/
	cp -p src/test-csim $(LABNAME)-handout/
	cp -p src/test-trans.c $(LABNAME)-handout/
	cp -p src/tracegen.c $(LABNAME)-handout/
	cp -p src/driver.py $(LABNAME)-handout/
	cp -p src/Makefile-handout $(LABNAME)-handout/Makefile
	cp -p src/csim-handout.c $(LABNAME)-handout/csim.c
	cp -p src/trans-handout.c $(LABNAME)-handout/trans.c
	cp -p src/README-handout $(LABNAME)-handout/README
	tar cvf $(LABNAME)-handout.tar $(LABNAME)-handout

dist: 
	########################################	
	# Update distribution
	########################################
	cp -p $(LABNAME)-handout.tar $(DEST)
	cp -p writeup/$(LABNAME).ps $(DEST)
	cp -p writeup/$(LABNAME).pdf $(DEST)

clean:
	rm -rf $(LABNAME)-handout/*
	rm -rf $(LABNAME)-handout.tar
	(cd src; make clean)
	(cd writeup; make clean)

