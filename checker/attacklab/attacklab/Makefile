#####################################################################
# CS:APP Attack Lab
# Main makefile 
######################################################################

all: 
	@echo "Please specify a rule"

# Start the lab by running the main attacklab daemon, which nannies the
# request and result servers and the report deamon.
start:
	@touch log.txt
	@./attacklab.pl -q &
	@ sleep 1

# Stops the attack lab by killing all attacklab daemons
stop:
	@killall -q -9 attacklab.pl attacklab-requestd.pl attacklab-reportd.pl \
	attacklab-resultd.pl ; true

# Cleans soft state from the directory. You can do this at any time
# without hurting anything.
clean:
	rm -f *~
	rm -f attacklab-scoreboard.html scores.csv
	(cd src; make clean)
	(cd writeup; make clean)

#
# Cleans the entire directory tree of all soft state, as well as the
# hard state releated to a specific instance of the course, such as
# targets and log files. 
#
# Do this whenver you need a fresh directory, for example while you're
# getting the lab set up and just testing things out for yourself, or
# at the beginning of the term when you need to reset the lab.
#
# DON'T DO THIS UNLESS YOU'RE REALLY SURE!  
#
cleanallfiles:
	rm -rf *~ scores.csv reports/* targets/target* log.txt log-status.txt *.html
	(cd src; make clean)
	(cd writeup; make clean)



