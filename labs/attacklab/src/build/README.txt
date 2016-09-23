Files used to construct attack targets for attack lab

1. FILES  that are compiled as part of the target programs

      config.h, config.c

Contains site and lab-specific information.  This will need to be updated with each semester and each locale

      driverlib.h, driverhdrs.h, driverlib.c

Autolab support

      target.h

Declarations that are common across multiple files.

      getbuf.c

Function with buffer overflow vulnerability.  Provided as separate
file, since this is the only one that needs to be compiled with stack
protection turned off.  Must be custom compiled for each ID.

      visible.c

Code for functions touch1 -- touch3.  This code can be compiled as
part of the target binaries.

      support.c

Support functions.  This could be compiled as a separate library and
dynamically linked.

      main.c

Main function for both targets.  Must be custom compiled for each ID.

      stack.{c,h}

Declarations/code to support diversion of stack into region allocated
by mmap to enable it to be stable and executable.

2. FILES that are used to construct targets.

     genfarm.c

Generates gadget farm for rtarget.

     genscramble.c
      
Generates code for a function scramble() that varies in length, in
order to reposition code to different places for each target.

      buildtarget.pl

Generate all files for a single target

      multibuild.pl

Construct multiple targets
      
3. Other FILES

      README-handout.txt

README file to store with targets.

      makecookie.c

Code for program that generates cookies

      hex2raw.c

Source code for text to byte conversion
