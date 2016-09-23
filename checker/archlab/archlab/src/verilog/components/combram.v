//* $begin combram-verilog */
// This module implements a dual-ported RAM.
// with clocked write and combinational read operations.
// This version matches the conceptual model presented in the CS:APP book, 

module ram(clock, addrA, wEnA, wDatA, rEnA, rDatA, 
	   addrB, wEnB, wDatB, rEnB, rDatB);

   parameter wordsize = 8;    // Number of bits per word
   parameter wordcount = 512; // Number of words in memory
   // Number of address bits.  Must be >= log wordcount
   parameter addrsize = 9;    

   input     clock;		 // Clock
   // Port A
   input [addrsize-1:0]  addrA;  // Read/write address
   input 		 wEnA;	 // Write enable
   input [wordsize-1:0]  wDatA;	 // Write data
   input 		 rEnA;	 // Read enable
   output [wordsize-1:0] rDatA;	 // Read data
   // Port B
   input [addrsize-1:0]  addrB;  // Read/write address
   input 		 wEnB;	 // Write enable
   input [wordsize-1:0]  wDatB;	 // Write data
   input 		 rEnB;	 // Read enable
   output [wordsize-1:0] rDatB;	 // Read data

   // Actual storage 
   reg [wordsize-1:0] 	 mem[wordcount-1:0];  //= line:arch:combram:memarray

   always @(posedge clock)
     begin
	if (wEnA)
	  begin
	     mem[addrA] <= wDatA; //= line:arch:combram:writeA
	  end
     end
   // Combinational reads
   assign rDatA = mem[addrA]; //= line:arch:combram:readA

   always @(posedge clock)
     begin
	if (wEnB)
	  begin
	     mem[addrB] <= wDatB; //= line:arch:combram:writeB
	  end
     end
   // Combinational reads
   assign rDatB = mem[addrB]; //= line:arch:combram:readB

endmodule
//* $end combram-verilog */
