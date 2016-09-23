//* $begin synchram-verilog */
// This module implements a dual-ported RAM.
// with clocked write and read operations.

module ram(clock, addrA, wEnA, wDatA, rEnA, rDatA, 
	   addrB, wEnB, wDatB, rEnB, rDatB);

parameter wordsize = 8;    // Number of bits per word
parameter wordcount = 512; // Number of words in memory
// Number of address bits.  Must be >= log wordcount
parameter addrsize = 9;    
   

  input  clock;			// Clock
  // Port A
  input [addrsize-1:0] addrA;   // Read/write address
  input  wEnA;			// Write enable
  input [wordsize-1:0] wDatA;	// Write data
  input  rEnA;			// Read enable
  output [wordsize-1:0] rDatA;	// Read data
  reg [wordsize-1:0] rDatA; //= line:arch:synchram:rDatA
  // Port B
  input [addrsize-1:0] addrB;   // Read/write address
  input  wEnB;			// Write enable
  input [wordsize-1:0] wDatB;	// Write data
  input  rEnB;			// Read enable
  output [wordsize-1:0] rDatB;	// Read data
  reg [wordsize-1:0] rDatB; //= line:arch:synchram:rDatB

  reg[wordsize-1:0] mem[wordcount-1:0];  // Actual storage

//* $end synchram-verilog */
   // To make the pipeline processor work with synchronous reads, we
   // operate the memory read operations on the negative
   // edge of the clock.  That makes the reading occur in the middle
   // of the clock cycle---after the address inputs have been set
   // and such that the results read from the memory can flow through
   // more combinational logic before reaching the clocked registers

   // For uniformity, we also make the memory write operation 
   // occur on the negative edge of the clock.  That works OK
   // in this design, because the write can occur as soon as the
   // address & data inputs have been set.
//* $begin synchram-verilog */
   always @(negedge clock)
   begin
     if (wEnA)
     begin
       mem[addrA] <= wDatA;
     end
     if (rEnA)
       rDatA <= mem[addrA]; //= line:arch:synchram:readA
   end

   always @(negedge clock)
   begin
     if (wEnB)
     begin
       mem[addrB] <= wDatB;
     end
     if (rEnB)
       rDatB <= mem[addrB]; //= line:arch:synchram:readB
   end
endmodule
//* $end synchram-verilog */
