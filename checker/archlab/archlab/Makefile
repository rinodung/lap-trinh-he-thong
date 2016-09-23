################################################# 
# Makefile to manage the CS:APP Architecture Lab.
#################################################

# The name of the lab at your site (default: archlab)

LABNAME = archlab

# The handout directory at your site where students will retrieve the
# $(LABNAME)-handout.tar file and the lab writeup.  

DEST = <site specific>


##################################################
# You shouldn't need to modify anything below here
##################################################

DISTDIR = $(PWD)/sim

all: labwriteup masterdist studentdist-tarfile handout handout-tarfile

labwriteup:
	###################
	# Building writeup
	###################
	(cd writeup; make; make)

masterdist:
	######################################################
	# Building the master distribution of the Y86-64 tools
	######################################################
	(cd src; make clean; make)

studentdist-tarfile: studentdist
	##############################################
	# Building tarfile of the student distribution
	##############################################
	tar cf sim.tar sim

studentdist:
	###################################################
	# Building student distribution of the Y86-64 tools
	###################################################
	# Build the student's distribution dir and copy it to the handout file
	(cd src; make dist DISTDIR=$(DISTDIR))

handout:
	################################
	# Building the handout directory
	################################
	rm -rf $(LABNAME)-handout
	mkdir $(LABNAME)-handout
	cp -p simguide/simguide.pdf $(LABNAME)-handout/
	cp -p src/Makefile-handout $(LABNAME)-handout/Makefile
	(cd $(LABNAME)-handout; make clean)
	cp -p src/README-handout $(LABNAME)-handout/README
	cp -p writeup/archlab.pdf $(LABNAME)-handout/$(LABNAME).pdf
	cp -p sim.tar $(LABNAME)-handout

handout-tarfile:
	###############################################
	# Building tarfile of the handout directory
	###############################################
	(cd $(LABNAME)-handout; make clean)
	tar cf $(LABNAME)-handout.tar $(LABNAME)-handout

labsimguide:
	###################
	# Building simguide
	###################
	(cd simguide; make)

dist:
	######################
	# Copying handout file 
	######################
#	cp -p $(LABNAME)-handout.tar $(DEST)
#	cp -p writeup/archlab.pdf $(DEST)/$(LABNAME).pdf

clean:
	########################################
	# Cleaning the entire lab directory tree
	########################################
	rm -f *~ *.tar
	rm -rf $(LABNAME)-handout
	rm -rf sim
	(cd src; make clean)
	(cd writeup; make clean)




