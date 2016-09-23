In addition to the files distributed as part of the targets (see
README.txt), this directory contains:

1. Checkers
   ctarget-check, rtarget-check

2. Files used in generating
solutions.

    ctarget.d, rtarget.d

Disassembled version of both targets

    addresses.txt

Stack and offset information for getbuf in ctarget.

    ctarget.b, rtarget.b

Addresses of functions touch1, touch2, touch3.  File rtarget.b also
includes byte code representation of gadget farm.

    rtarget.g

List of gadgets found in rtarget.  If the instruction name contains
'X', this means that the gadget address contains byte 0x0a, and hence
the gadget cannot be used.

    ctarget.l1   
    ctarget.l2   
    ctarget.l3   
    rtarget.l2   
    rtarget.l3   

Exploit strings for the 5 phases.  It should be possible to pipe these
into the target, e.g.,:

cat rtarget.l3 | ./hex2raw | ./rtarget -q

(The -q flag prevents the program from sending a string to the grading server)

3. Other files

   ID.txt

Useful information about this particular target
