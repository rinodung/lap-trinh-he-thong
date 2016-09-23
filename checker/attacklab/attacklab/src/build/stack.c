/*
  Attack lab internals.

  Reserve space for runtime stack in attack lab, so that dynamic
  linker will not attempt to map library pages into this region.

  The actual mapping of the stack is performed using embedded assembly code
  in ctarget.c

*/
#include "stack.h"

char _reserved[STACK_SIZE] __attribute__((section("bstack")));
