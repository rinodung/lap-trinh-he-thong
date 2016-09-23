CC = gcc
OFLAGS = -Og
CFLAGS = $(OFLAGS) -Wall -g

# Directory for functions that are common to the builder and the solver
COMMON = ../common


# The following address is used for locating the runtime stack at a fixed address
# This one has been determined empirically to work with many Linux systems,
# but you may need to experiment with other values
STACK = 0x55586000

# Minimum number of bytes for scrambler.  This can be tweaked to move generated
# code away from addresses containing '0xa'
BYTES = 1000

# Should we enable sending results to the server? */
NOTIFY = 1

# Lab parameters
# Id of target program.  Used to generate cookie, and to randomize the code in various ways
TARGET_ID = 100
# Identify of user
USER_ID = "NoOne"

TFLAGS = -DNOTIFY=$(NOTIFY) -DSTACK=$(STACK) -DTARGET_ID=$(TARGET_ID) -DUSER_ID='$(USER_ID)'

# Gadget Farm parameters
REDCNT = 2
REP2CNT = 4
REP3CNT = 8

all: genfarm genscramble makecookie hex2raw

targets: ctarget-$(TARGET_ID) rtarget-$(TARGET_ID) ctarget-check-$(TARGET_ID) rtarget-check-$(TARGET_ID)

genfarm: genfarm.c $(COMMON)/gencode.o
	$(CC) $(CFLAGS) -I$(COMMON) -o genfarm genfarm.c $(COMMON)/gencode.o

genscramble: genscramble.c
	$(CC) $(CFLAGS) -o genscramble genscramble.c

makecookie: makecookie.c $(COMMON)/gencookie.o
	$(CC) $(CFLAGS) -I$(COMMON) -o makecookie makecookie.c $(COMMON)/gencookie.o

hex2raw: hex2raw.c
	$(CC) $(CFLAGS) -I$(COMMON) -o hex2raw hex2raw.c

farm-$(TARGET_ID).c: genfarm
	./genfarm -p -s $(TARGET_ID) -2 $(REP2CNT) -3 $(REP3CNT) -r $(REDCNT) -o farm-$(TARGET_ID).c

farm-$(TARGET_ID).o: farm-$(TARGET_ID).c
	$(CC) $(OFLAGS) -c farm-$(TARGET_ID).c 

scramble-$(TARGET_ID).c: genscramble
	./genscramble -s $(TARGET_ID) -b $(BYTES) -o scramble-$(TARGET_ID).c

buf-$(TARGET_ID).o: buf.c target.h config.h
	$(CC) $(CFLAGS) $(TFLAGS) -fno-stack-protector -c buf.c -o buf-$(TARGET_ID).o

config-$(TARGET_ID).o: config.h config.c
	$(CC) $(CFLAGS) $(TFLAGS) -c config.c -o config-$(TARGET_ID).o

support.o: support.c target.h config.h 
	$(CC) $(CFLAGS) $(TFLAGS) -c support.c

support-check.o: support.c target.h config.h 
	$(CC) $(CFLAGS) $(TFLAGS) -DIS_CHECKER -c support.c -o support-check.o

visible.o: visible.c target.h config.h 
	$(CC) $(CFLAGS) -I$(COMMON) -c visible.c

driverlib.o: driverlib.c driverlib.h driverhdrs.h
	$(CC) $(CFLAGS) -I$(COMMON) -c driverlib.c

ctarget-$(TARGET_ID): main.c scramble-$(TARGET_ID).c \
		buf-$(TARGET_ID).o config-$(TARGET_ID).o \
		visible.o support.o driverlib.o $(COMMON)/gencookie.o
	$(CC) $(CFLAGS) -DRANDOMSTACK=0 -DIS_CTARGET=1 -DTARGET_ID=$(TARGET_ID) -I$(COMMON) \
		main.c scramble-$(TARGET_ID).c \
		buf-$(TARGET_ID).o config-$(TARGET_ID).o \
		visible.o support.o driverlib.o $(COMMON)/gencookie.o \
		-o ctarget-$(TARGET_ID)
	objdump -d ctarget-$(TARGET_ID) > ctarget-$(TARGET_ID).d

rtarget-$(TARGET_ID): main.c scramble-$(TARGET_ID).c \
		buf-$(TARGET_ID).o config-$(TARGET_ID).o visible.o \
		farm-$(TARGET_ID).o support.o driverlib.o $(COMMON)/gencookie.o
	$(CC) $(CFLAGS) -DRANDOMSTACK=1 -DIS_CTARGET=0 -DTARGET_ID=$(TARGET_ID) -I$(COMMON) \
		main.c scramble-$(TARGET_ID).c \
		buf-$(TARGET_ID).o config-$(TARGET_ID).o visible.o \
		farm-$(TARGET_ID).o support.o driverlib.o $(COMMON)/gencookie.o \
		-o rtarget-$(TARGET_ID)
	objdump -d rtarget-$(TARGET_ID) > rtarget-$(TARGET_ID).d

ctarget-check-$(TARGET_ID): main.c scramble-$(TARGET_ID).c \
		buf-$(TARGET_ID).o config-$(TARGET_ID).o \
		visible.o support-check.o driverlib.o $(COMMON)/gencookie.o
	$(CC) $(CFLAGS) -DRANDOMSTACK=0 -DIS_CTARGET=1 -DTARGET_ID=$(TARGET_ID) -I$(COMMON) \
		main.c scramble-$(TARGET_ID).c \
		buf-$(TARGET_ID).o config-$(TARGET_ID).o \
		visible.o support-check.o driverlib.o $(COMMON)/gencookie.o \
		-o ctarget-check-$(TARGET_ID)

rtarget-check-$(TARGET_ID): main.c scramble-$(TARGET_ID).c \
		buf-$(TARGET_ID).o config-$(TARGET_ID).o visible.o \
		farm-$(TARGET_ID).o support-check.o driverlib.o $(COMMON)/gencookie.o
	$(CC) $(CFLAGS) -DRANDOMSTACK=1 -DIS_CTARGET=0 -DTARGET_ID=$(TARGET_ID) -I$(COMMON) \
		main.c scramble-$(TARGET_ID).c \
		buf-$(TARGET_ID).o config-$(TARGET_ID).o visible.o \
		farm-$(TARGET_ID).o support-check.o driverlib.o $(COMMON)/gencookie.o \
		-o rtarget-check-$(TARGET_ID)

clean:
	rm -f *~ *.o *.d *.b *.g *.s *.tar *.gdb
	rm -f farm-*.c scramble-*.c
	rm -f genfarm hex2raw makecookie genscramble 
	rm -f rtarget-* ctarget-*
