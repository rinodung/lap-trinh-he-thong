// Basic building blocks for constructing a Y86-64 processor.

// Different types of registers, all derivatives of module cenrreg

//* $begin cenrreg-verilog */
// Clocked register with enable signal and synchronous reset
// Default width is 8, but can be overriden
module cenrreg(out, in, enable, reset, resetval, clock);
   parameter width = 8;
   output [width-1:0] out;
   reg    [width-1:0] out;
   input  [width-1:0] in;
   input 	      enable;
   input 	      reset;
   input  [width-1:0] resetval;
   input 	      clock;

   always
     @(posedge clock) 
     begin
	if (reset)
	  out <= resetval;
	else if (enable) 
	  out <= in;
     end
endmodule
//* $end cenrreg-verilog */

// Clocked register with enable signal.
// Default width is 8, but can be overriden
module cenreg(out, in, enable, clock);
   parameter width = 8;
   output [width-1:0] out;
   input  [width-1:0] in;
   input 	      enable;
   input 	      clock;

   cenrreg #(width) c(out, in, enable, 1'b0, 8'b0, clock);
endmodule

// Basic clocked register.  Default width is 8.
module creg(out, in, clock);
   parameter width = 8;
   output [width-1:0] out;
   input  [width-1:0] in;
   input 	      clock;

   cenreg #(width) r(out, in, 1'b1, clock);
endmodule

//* $begin preg-verilog */
// Pipeline register.  Uses reset signal to inject bubble
// When bubbling, must specify value that will be loaded
module preg(out, in, stall, bubble, bubbleval, clock);
   parameter width = 8;
   output [width-1:0] out;
   input  [width-1:0] in;
   input 	      stall, bubble;
   input  [width-1:0] bubbleval;
   input 	      clock;

   cenrreg #(width) r(out, in, ~stall, bubble, bubbleval, clock);
endmodule
//* $end preg-verilog */

// Register file /// line:arch:verilog:regfile_start
module regfile(dstE, valE, dstM, valM, srcA, valA, srcB, valB, reset, clock,
       	       rax, rcx, rdx, rbx, rsp, rbp, rsi, rdi,
	       r8, r9, r10, r11, r12, r13, r14);
   input  [ 3:0] dstE;
   input  [63:0] valE;
   input  [ 3:0] dstM;
   input  [63:0] valM;
   input  [ 3:0] srcA;
   output [63:0] valA;
   input  [ 3:0] srcB;
   output [63:0] valB;
   input 	reset;  // Set registers to 0
   input        clock;
   // Make individual registers visible for debugging
   output [63:0] rax, rcx, rdx, rbx, rsp, rbp, rsi, rdi,
                 r8, r9, r10, r11, r12, r13, r14;

   // Define names for registers used in HCL code
   parameter 	 RRAX =  4'h0;
   parameter 	 RRCX =  4'h1;
   parameter 	 RRDX =  4'h2;
   parameter 	 RRBX =  4'h3;
   parameter 	 RRSP =  4'h4;
   parameter 	 RRBP =  4'h5;
   parameter 	 RRSI =  4'h6;
   parameter 	 RRDI =  4'h7;
   parameter 	 R8   =  4'h8;
   parameter 	 R9   =  4'h9;
   parameter 	 R10  =  4'ha;
   parameter 	 R11  =  4'hb;
   parameter 	 R12  =  4'hc;
   parameter 	 R13  =  4'hd;
   parameter 	 R14  =  4'he;
   parameter 	 RNONE = 4'hf;

   // Input data for each register
   wire [63:0] 	 rax_dat, rcx_dat, rdx_dat, rbx_dat, 
		 rsp_dat, rbp_dat, rsi_dat, rdi_dat,
		 r8_dat, r9_dat, r10_dat, r11_dat,
		 r12_dat, r13_dat, r14_dat; 

   // Input write controls for each register
   wire 	 rax_wrt, rcx_wrt, rdx_wrt, rbx_wrt, 
		 rsp_wrt, rbp_wrt, rsi_wrt, rdi_wrt,
		 r8_wrt, r9_wrt, r10_wrt, r11_wrt,
		 r12_wrt, r13_wrt, r14_wrt; 


   // Implement with clocked registers
   cenrreg #(64) rax_reg(rax, rax_dat, rax_wrt, reset, 64'b0, clock);
   cenrreg #(64) rcx_reg(rcx, rcx_dat, rcx_wrt, reset, 64'b0, clock);
   cenrreg #(64) rdx_reg(rdx, rdx_dat, rdx_wrt, reset, 64'b0, clock);
   cenrreg #(64) rbx_reg(rbx, rbx_dat, rbx_wrt, reset, 64'b0, clock);
   cenrreg #(64) rsp_reg(rsp, rsp_dat, rsp_wrt, reset, 64'b0, clock);
   cenrreg #(64) rbp_reg(rbp, rbp_dat, rbp_wrt, reset, 64'b0, clock);
   cenrreg #(64) rsi_reg(rsi, rsi_dat, rsi_wrt, reset, 64'b0, clock);
   cenrreg #(64) rdi_reg(rdi, rdi_dat, rdi_wrt, reset, 64'b0, clock);
   cenrreg #(64)  r8_reg(r8,   r8_dat,  r8_wrt, reset, 64'b0, clock);
   cenrreg #(64)  r9_reg(r9,   r9_dat,  r9_wrt, reset, 64'b0, clock);
   cenrreg #(64) r10_reg(r10, r10_dat, r10_wrt, reset, 64'b0, clock);
   cenrreg #(64) r11_reg(r11, r11_dat, r11_wrt, reset, 64'b0, clock);
   cenrreg #(64) r12_reg(r12, r12_dat, r12_wrt, reset, 64'b0, clock);
   cenrreg #(64) r13_reg(r13, r13_dat, r13_wrt, reset, 64'b0, clock);
   cenrreg #(64) r14_reg(r14, r14_dat, r14_wrt, reset, 64'b0, clock);

   // Reads occur like combinational logic
   assign 	 valA =
		 srcA == RRAX ? rax :
		 srcA == RRCX ? rcx :
		 srcA == RRDX ? rdx :
		 srcA == RRBX ? rbx :
		 srcA == RRSP ? rsp :
		 srcA == RRBP ? rbp :
		 srcA == RRSI ? rsi :
		 srcA == RRDI ? rdi :
		 srcA == R8   ? r8  :
		 srcA == R9   ? r9  :
		 srcA == R10  ? r10 :
		 srcA == R11  ? r11 :
		 srcA == R12  ? r12 :
		 srcA == R13  ? r13 :
		 srcA == R14  ? r14 :
		 0;

   assign 	 valB =
		 srcB == RRAX ? rax :
		 srcB == RRCX ? rcx :
		 srcB == RRDX ? rdx :
		 srcB == RRBX ? rbx :
		 srcB == RRSP ? rsp :
		 srcB == RRBP ? rbp :
		 srcB == RRSI ? rsi :
		 srcB == RRDI ? rdi :
		 srcB == R8   ? r8  :
		 srcB == R9   ? r9  :
		 srcB == R10  ? r10 :
		 srcB == R11  ? r11 :
		 srcB == R12  ? r12 :
		 srcB == R13  ? r13 :
		 srcB == R14  ? r14 :
		 0;

   assign 	 rax_dat = dstM == RRAX ? valM : valE;
   assign 	 rcx_dat = dstM == RRCX ? valM : valE;
   assign 	 rdx_dat = dstM == RRDX ? valM : valE;
   assign 	 rbx_dat = dstM == RRBX ? valM : valE;
   assign 	 rsp_dat = dstM == RRSP ? valM : valE;
   assign 	 rbp_dat = dstM == RRBP ? valM : valE;
   assign 	 rsi_dat = dstM == RRSI ? valM : valE;
   assign 	 rdi_dat = dstM == RRDI ? valM : valE;
   assign 	  r8_dat = dstM == R8   ? valM : valE;
   assign 	  r9_dat = dstM == R9   ? valM : valE;
   assign 	 r10_dat = dstM == R10  ? valM : valE;
   assign 	 r11_dat = dstM == R11  ? valM : valE;
   assign 	 r12_dat = dstM == R12  ? valM : valE;
   assign 	 r13_dat = dstM == R13  ? valM : valE;
   assign 	 r14_dat = dstM == R14  ? valM : valE;

   assign 	 rax_wrt = dstM == RRAX | dstE == RRAX;
   assign 	 rcx_wrt = dstM == RRCX | dstE == RRCX;
   assign 	 rdx_wrt = dstM == RRDX | dstE == RRDX;
   assign 	 rbx_wrt = dstM == RRBX | dstE == RRBX;
   assign 	 rsp_wrt = dstM == RRSP | dstE == RRSP;
   assign 	 rbp_wrt = dstM == RRBP | dstE == RRBP;
   assign 	 rsi_wrt = dstM == RRSI | dstE == RRSI;
   assign 	 rdi_wrt = dstM == RRDI | dstE == RRDI;
   assign 	  r8_wrt = dstM == R8   | dstE == R8;
   assign 	  r9_wrt = dstM == R9   | dstE == R9;
   assign 	 r10_wrt = dstM == R10  | dstE == R10;
   assign 	 r11_wrt = dstM == R11  | dstE == R11;
   assign 	 r12_wrt = dstM == R12  | dstE == R12;
   assign 	 r13_wrt = dstM == R13  | dstE == R13;
   assign 	 r14_wrt = dstM == R14  | dstE == R14;


endmodule /// line:arch:verilog:regfile_end

// Memory.  This memory design uses 16 memory banks, each ///line:arch:verilog:bmemory_start
// of which is one byte wide.  Banking allows us to select an
// arbitrary set of 10 contiguous bytes for instruction reading
// and an arbitrary set of 8 contiguous bytes 
// for data reading & writing.
// It uses an external RAM module from either the file
// combram.v (using combinational reads) 
// or synchram.v (using clocked reads)
// The SEQ & SEQ+ processors only work with combram.v.
// PIPE works with either.

//* $begin memory-decl-verilog */
module bmemory(maddr, wenable, wdata, renable, rdata, m_ok, 
               iaddr, instr, i_ok, clock);
   parameter memsize = 8192; // Number of bytes in memory
   input  [63:0] maddr;     // Read/Write address
   input         wenable;   // Write enable
   input  [63:0] wdata;     // Write data
   input 	 renable;   // Read enable
   output [63:0] rdata;     // Read data
   output 	 m_ok;      // Read & write addresses within range
   input  [63:0] iaddr;     // Instruction address
   output [79:0] instr;     // 10 bytes of instruction
   output 	 i_ok;      // Instruction address within range
   input 	 clock;
//* $end memory-decl-verilog */

   // Instruction bytes
   wire [ 7:0]	 ib0, ib1, ib2, ib3, ib4, ib5, ib6, ib7, ib8, ib9;
  // Data bytes
   wire [ 7:0]   db0, db1, db2, db3, db4, db5, db6, db7;

   wire [ 3:0]   ibid   = iaddr[3:0];   // Instruction Bank ID
   wire [59:0] 	 iindex = iaddr[63:4];  // Address within bank
   wire [59:0] 	 iip1   = iindex+1;     // Next address within bank

   wire [ 3:0] 	 mbid   = maddr[3:0];   // Data Bank ID
   wire [59:0] 	 mindex = maddr[63:4];  // Address within bank
   wire [59:0] 	 mip1   = mindex+1;     // Next address within bank

   // Instruction addresses for each bank
   wire [59:0] 	 addrI0, addrI1, addrI2, addrI3, addrI4, addrI5, addrI6, addrI7,
   		 addrI8, addrI9, addrI10, addrI11, addrI12, addrI13, addrI14,
		 addrI15;
   // Instruction data for each bank
   wire [ 7:0] 	 outI0, outI1, outI2, outI3, outI4, outI5, outI6, outI7,
   		 outI8, outI9, outI10, outI11, outI12, outI13, outI14, outI15;

   // Data addresses for each bank
   wire [59:0] 	 addrD0, addrD1, addrD2, addrD3, addrD4, addrD5, addrD6, addrD7,
   		 addrD8, addrD9, addrD10, addrD11, addrD12, addrD13, addrD14,
		 addrD15;

   // Data output for each bank
   wire [ 7:0] 	 outD0, outD1, outD2, outD3, outD4, outD5, outD6, outD7,
   		 outD8, outD9, outD10, outD11, outD12, outD13, outD14, outD15;

   // Data input for each bank
   wire [ 7:0] 	 inD0, inD1, inD2, inD3, inD4, inD5, inD6, inD7,
   		 inD8, inD9, inD10, inD11, inD12, inD13, inD14, inD15;

   // Data write enable signals for each bank
   wire 	 dwEn0, dwEn1, dwEn2, dwEn3, dwEn4, dwEn5, dwEn6, dwEn7,
   		 dwEn8, dwEn9, dwEn10, dwEn11, dwEn12, dwEn13, dwEn14, dwEn15;

   // The bank memories
   ram #(8, memsize/16, 60) bank0(clock,
       	    		          addrI0, 1'b0, 8'b0, 1'b1, outI0, // Instruction
                                  addrD0, dwEn0, inD0, renable, outD0); // Data

   ram #(8, memsize/16, 60) bank1(clock,
      	    		           addrI1, 1'b0, 8'b0, 1'b1, outI1, // Instruction
                                  addrD1, dwEn1, inD1, renable, outD1); // Data

   ram #(8, memsize/16, 60) bank2(clock,
      	    		           addrI2, 1'b0, 8'b0, 1'b1, outI2, // Instruction
                                  addrD2, dwEn2, inD2, renable, outD2); // Data

   ram #(8, memsize/16, 60) bank3(clock,
      	    		           addrI3, 1'b0, 8'b0, 1'b1, outI3, // Instruction
                                   addrD3, dwEn3, inD3, renable, outD3); // Data

   ram #(8, memsize/16, 60) bank4(clock,
      	    		           addrI4, 1'b0, 8'b0, 1'b1, outI4, // Instruction
                                   addrD4, dwEn4, inD4, renable, outD4); // Data

   ram #(8, memsize/16, 60) bank5(clock,
      	    		           addrI5, 1'b0, 8'b0, 1'b1, outI5, // Instruction
                                   addrD5, dwEn5, inD5, renable, outD5); // Data

   ram #(8, memsize/16, 60) bank6(clock,
      	    		           addrI6, 1'b0, 8'b0, 1'b1, outI6, // Instruction
                                   addrD6, dwEn6, inD6, renable, outD6); // Data

   ram #(8, memsize/16, 60) bank7(clock,
      	    		           addrI7, 1'b0, 8'b0, 1'b1, outI7, // Instruction
                                   addrD7, dwEn7, inD7, renable, outD7); // Data

   ram #(8, memsize/16, 60) bank8(clock,
      	    		           addrI8, 1'b0, 8'b0, 1'b1, outI8, // Instruction
                                   addrD8, dwEn8, inD8, renable, outD8); // Data

   ram #(8, memsize/16, 60) bank9(clock,
      	    		           addrI9, 1'b0, 8'b0, 1'b1, outI9, // Instruction
                                   addrD9, dwEn9, inD9, renable, outD9); // Data

   ram #(8, memsize/16, 60) bank10(clock,
      	    		           addrI10, 1'b0, 8'b0, 1'b1, outI10, // Instruction
                                   addrD10, dwEn10, inD10, renable, outD10); // Data

   ram #(8, memsize/16, 60) bank11(clock,
      	    		           addrI11, 1'b0, 8'b0, 1'b1, outI11, // Instruction
                                   addrD11, dwEn11, inD11, renable, outD11); // Data

   ram #(8, memsize/16, 60) bank12(clock,
      	    		           addrI12, 1'b0, 8'b0, 1'b1, outI12, // Instruction
                                   addrD12, dwEn12, inD12, renable, outD12); // Data

   ram #(8, memsize/16, 60) bank13(clock,
      	    		           addrI13, 1'b0, 8'b0, 1'b1, outI13, // Instruction
                                   addrD13, dwEn13, inD13, renable, outD13); // Data

   ram #(8, memsize/16, 60) bank14(clock,
      	    		           addrI14, 1'b0, 8'b0, 1'b1, outI14, // Instruction
                                   addrD14, dwEn14, inD14, renable, outD14); // Data

   ram #(8, memsize/16, 60) bank15(clock,
      	    		           addrI15, 1'b0, 8'b0, 1'b1, outI15, // Instruction
                                   addrD15, dwEn15, inD15, renable, outD15); // Data


   // Determine the instruction addresses for the banks
   assign 	 addrI0 =  ibid >= 7 ? iip1 : iindex;
   assign 	 addrI1 =  ibid >= 8 ? iip1 : iindex;
   assign 	 addrI2 =  ibid >= 9 ? iip1 : iindex;
   assign 	 addrI3 =  ibid >= 10 ? iip1 : iindex;
   assign 	 addrI4 =  ibid >= 11 ? iip1 : iindex;
   assign 	 addrI5 =  ibid >= 12 ? iip1 : iindex;
   assign 	 addrI6 =  ibid >= 13 ? iip1 : iindex;
   assign 	 addrI7 =  ibid >= 14 ? iip1 : iindex;
   assign 	 addrI8 =  ibid >= 15 ? iip1 : iindex;
   assign 	 addrI9 =  iindex;
   assign 	 addrI10 = iindex;
   assign 	 addrI11 = iindex;
   assign 	 addrI12 = iindex;
   assign 	 addrI13 = iindex;
   assign 	 addrI14 = iindex;
   assign 	 addrI15 = iindex;


   // Get the bytes of the instruction
   assign 	 i_ok = 
		 (iaddr + 9) < memsize;

   assign 	 ib0 = !i_ok ? 0 :
		 ibid == 0 ? outI0 :
		 ibid == 1 ? outI1 :
		 ibid == 2 ? outI2 :
		 ibid == 3 ? outI3 :
		 ibid == 4 ? outI4 :
		 ibid == 5 ? outI5 :
		 ibid == 6 ? outI6 :
		 ibid == 7 ? outI7 :
		 ibid == 8 ? outI8 :
		 ibid == 9 ? outI9 :
		 ibid == 10 ? outI10 :
		 ibid == 11 ? outI11 :
		 ibid == 12 ? outI12 :
		 ibid == 13 ? outI13 :
		 ibid == 14 ? outI14 :
		 outI15;
   assign 	 ib1 = !i_ok ? 0 :
		 ibid == 0  ? outI1 :
		 ibid == 1  ? outI2 :
		 ibid == 2  ? outI3 :
		 ibid == 3  ? outI4 :
		 ibid == 4  ? outI5 :
		 ibid == 5  ? outI6 :
		 ibid == 6  ? outI7 :
		 ibid == 7  ? outI8 :
		 ibid == 8  ? outI9 :
		 ibid == 9  ? outI10 :
		 ibid == 10 ? outI11 :
		 ibid == 11 ? outI12 :
		 ibid == 12 ? outI13 :
		 ibid == 13 ? outI14 :
		 ibid == 14 ? outI15 :
		 outI0;
   assign 	 ib2 = !i_ok ? 0 :
		 ibid == 0  ? outI2 :
		 ibid == 1  ? outI3 :
		 ibid == 2  ? outI4 :
		 ibid == 3  ? outI5 :
		 ibid == 4  ? outI6 :
		 ibid == 5  ? outI7 :
		 ibid == 6  ? outI8 :
		 ibid == 7  ? outI9 :
		 ibid == 8  ? outI10 :
		 ibid == 9  ? outI11 :
		 ibid == 10 ? outI12 :
		 ibid == 11 ? outI13 :
		 ibid == 12 ? outI14 :
		 ibid == 13 ? outI15 :
		 ibid == 14 ? outI0 :
		 outI1;
   assign 	 ib3 = !i_ok ? 0 :
		 ibid == 0  ? outI3 :
		 ibid == 1  ? outI4 :
		 ibid == 2  ? outI5 :
		 ibid == 3  ? outI6 :
		 ibid == 4  ? outI7 :
		 ibid == 5  ? outI8 :
		 ibid == 6  ? outI9 :
		 ibid == 7  ? outI10 :
		 ibid == 8  ? outI11 :
		 ibid == 9  ? outI12 :
		 ibid == 10 ? outI13 :
		 ibid == 11 ? outI14 :
		 ibid == 12 ? outI15 :
		 ibid == 13 ? outI0 :
		 ibid == 14 ? outI1 :
		 outI2;
   assign 	 ib4 = !i_ok ? 0 :
		 ibid == 0  ? outI4 :
		 ibid == 1  ? outI5 :
		 ibid == 2  ? outI6 :
		 ibid == 3  ? outI7 :
		 ibid == 4  ? outI8 :
		 ibid == 5  ? outI9 :
		 ibid == 6  ? outI10 :
		 ibid == 7  ? outI11 :
		 ibid == 8  ? outI12 :
		 ibid == 9  ? outI13 :
		 ibid == 10 ? outI14 :
		 ibid == 11 ? outI15 :
		 ibid == 12 ? outI0 :
		 ibid == 13 ? outI1 :
		 ibid == 14 ? outI2 :
		 outI3;
   assign 	 ib5 = !i_ok ? 0 :
		 ibid == 0  ? outI5 :
		 ibid == 1  ? outI6 :
		 ibid == 2  ? outI7 :
		 ibid == 3  ? outI8 :
		 ibid == 4  ? outI9 :
		 ibid == 5  ? outI10 :
		 ibid == 6  ? outI11 :
		 ibid == 7  ? outI12 :
		 ibid == 8  ? outI13 :
		 ibid == 9  ? outI14 :
		 ibid == 10 ? outI15 :
		 ibid == 11 ? outI0 :
		 ibid == 12 ? outI1 :
		 ibid == 13 ? outI2 :
		 ibid == 14 ? outI3 :
		 outI4;
   assign 	 ib6 = !i_ok ? 0 :
		 ibid == 0  ? outI6 :
		 ibid == 1  ? outI7 :
		 ibid == 2  ? outI8 :
		 ibid == 3  ? outI9 :
		 ibid == 4  ? outI10 :
		 ibid == 5  ? outI11 :
		 ibid == 6  ? outI12 :
		 ibid == 7  ? outI13 :
		 ibid == 8  ? outI14 :
		 ibid == 9  ? outI15 :
		 ibid == 10 ? outI0 :
		 ibid == 11 ? outI1 :
		 ibid == 12 ? outI2 :
		 ibid == 13 ? outI3 :
		 ibid == 14 ? outI4 :
		 outI5;
   assign 	 ib7 = !i_ok ? 0 :
		 ibid == 0  ? outI7 :
		 ibid == 1  ? outI8 :
		 ibid == 2  ? outI9 :
		 ibid == 3  ? outI10 :
		 ibid == 4  ? outI11 :
		 ibid == 5  ? outI12 :
		 ibid == 6  ? outI13 :
		 ibid == 7  ? outI14 :
		 ibid == 8  ? outI15 :
		 ibid == 9  ? outI0 :
		 ibid == 10 ? outI1 :
		 ibid == 11 ? outI2 :
		 ibid == 12 ? outI3 :
		 ibid == 13 ? outI4 :
		 ibid == 14 ? outI5 :
		 outI6;
   assign 	 ib8 = !i_ok ? 0 :
		 ibid == 0  ? outI8 :
		 ibid == 1  ? outI9 :
		 ibid == 2  ? outI10 :
		 ibid == 3  ? outI11 :
		 ibid == 4  ? outI12 :
		 ibid == 5  ? outI13 :
		 ibid == 6  ? outI14 :
		 ibid == 7  ? outI15 :
		 ibid == 8  ? outI0 :
		 ibid == 9  ? outI1 :
		 ibid == 10 ? outI2 :
		 ibid == 11 ? outI3 :
		 ibid == 12 ? outI4 :
		 ibid == 13 ? outI5 :
		 ibid == 14 ? outI6 :
		 outI7;
   assign 	 ib9 = !i_ok ? 0 :
		 ibid == 0  ? outI9 :
		 ibid == 1  ? outI10 :
		 ibid == 2  ? outI11 :
		 ibid == 3  ? outI12 :
		 ibid == 4  ? outI13 :
		 ibid == 5  ? outI14 :
		 ibid == 6  ? outI15 :
		 ibid == 7  ? outI0 :
		 ibid == 8  ? outI1 :
		 ibid == 9  ? outI2 :
		 ibid == 10 ? outI3 :
		 ibid == 11 ? outI4 :
		 ibid == 12 ? outI5 :
		 ibid == 13 ? outI6 :
		 ibid == 14 ? outI7 :
		 outI8;

   assign 	 instr[ 7: 0] = ib0;
   assign 	 instr[15: 8] = ib1;
   assign 	 instr[23:16] = ib2;
   assign 	 instr[31:24] = ib3;
   assign 	 instr[39:32] = ib4;
   assign 	 instr[47:40] = ib5;
   assign 	 instr[55:48] = ib6;
   assign 	 instr[63:56] = ib7;
   assign 	 instr[71:64] = ib8;
   assign 	 instr[79:72] = ib9;

   assign 	 m_ok = 
		 (!renable & !wenable | (maddr + 7) < memsize);

   assign 	 addrD0 = mbid >=  9 ? mip1 : mindex;
   assign 	 addrD1 = mbid >= 10 ? mip1 : mindex;
   assign 	 addrD2 = mbid >= 11 ? mip1 : mindex;
   assign 	 addrD3 = mbid >= 12 ? mip1 : mindex;
   assign 	 addrD4 = mbid >= 13 ? mip1 : mindex;
   assign 	 addrD5 = mbid >= 14 ? mip1 : mindex;
   assign 	 addrD6 = mbid >= 15 ? mip1 : mindex;
   assign 	 addrD7 = mindex;
   assign 	 addrD8 = mindex;
   assign 	 addrD9 = mindex;
   assign 	 addrD10 = mindex;
   assign 	 addrD11 = mindex;
   assign 	 addrD12 = mindex;
   assign 	 addrD13 = mindex;
   assign 	 addrD14 = mindex;
   assign 	 addrD15 = mindex;

   // Get the bytes of data;
   assign 	 db0 = !m_ok ? 0     :
		 mbid == 0  ? outD0  :
		 mbid == 1  ? outD1  :
		 mbid == 2  ? outD2  :
		 mbid == 3  ? outD3  :
		 mbid == 4  ? outD4  :
		 mbid == 5  ? outD5  :
		 mbid == 6  ? outD6  :
		 mbid == 7  ? outD7  :
		 mbid == 8  ? outD8  :
		 mbid == 9  ? outD9  :
		 mbid == 10 ? outD10 :
		 mbid == 11 ? outD11 :
		 mbid == 12 ? outD12 :
		 mbid == 13 ? outD13 :
		 mbid == 14 ? outD14 :
		 outD15;
   assign 	 db1 = !m_ok ? 0     :
		 mbid == 0  ? outD1  :
		 mbid == 1  ? outD2  :
		 mbid == 2  ? outD3  :
		 mbid == 3  ? outD4  :
		 mbid == 4  ? outD5  :
		 mbid == 5  ? outD6  :
		 mbid == 6  ? outD7  :
		 mbid == 7  ? outD8  :
		 mbid == 8  ? outD9  :
		 mbid == 9  ? outD10 :
		 mbid == 10 ? outD11 :
		 mbid == 11 ? outD12 :
		 mbid == 12 ? outD13 :
		 mbid == 13 ? outD14 :
		 mbid == 14 ? outD15 :
		 outD0;
   assign 	 db2 = !m_ok ? 0     :
		 mbid == 0  ? outD2  :
		 mbid == 1  ? outD3  :
		 mbid == 2  ? outD4  :
		 mbid == 3  ? outD5  :
		 mbid == 4  ? outD6  :
		 mbid == 5  ? outD7  :
		 mbid == 6  ? outD8  :
		 mbid == 7  ? outD9  :
		 mbid == 8  ? outD10 :
		 mbid == 9  ? outD11 :
		 mbid == 10 ? outD12 :
		 mbid == 11 ? outD13 :
		 mbid == 12 ? outD14 :
		 mbid == 13 ? outD15 :
		 mbid == 14 ? outD0  :
		 outD1;
   assign 	 db3 = !m_ok ? 0     :
		 mbid == 0  ? outD3  :
		 mbid == 1  ? outD4  :
		 mbid == 2  ? outD5  :
		 mbid == 3  ? outD6  :
		 mbid == 4  ? outD7  :
		 mbid == 5  ? outD8  :
		 mbid == 6  ? outD9  :
		 mbid == 7  ? outD10 :
		 mbid == 8  ? outD11 :
		 mbid == 9  ? outD12 :
		 mbid == 10 ? outD13 :
		 mbid == 11 ? outD14 :
		 mbid == 12 ? outD15 :
		 mbid == 13 ? outD0  :
		 mbid == 14 ? outD1  :
		 outD2;
   assign 	 db4 = !m_ok ? 0     :
		 mbid == 0  ? outD4  :
		 mbid == 1  ? outD5  :
		 mbid == 2  ? outD6  :
		 mbid == 3  ? outD7  :
		 mbid == 4  ? outD8  :
		 mbid == 5  ? outD9  :
		 mbid == 6  ? outD10 :
		 mbid == 7  ? outD11 :
		 mbid == 8  ? outD12 :
		 mbid == 9  ? outD13 :
		 mbid == 10 ? outD14 :
		 mbid == 11 ? outD15 :
		 mbid == 12 ? outD0  :
		 mbid == 13 ? outD1  :
		 mbid == 14 ? outD2  :
		 outD3;
   assign 	 db5 = !m_ok ? 0 :
		 mbid == 0  ? outD5  :
		 mbid == 1  ? outD6  :
		 mbid == 2  ? outD7  :
		 mbid == 3  ? outD8  :
		 mbid == 4  ? outD9  :
		 mbid == 5  ? outD10 :
		 mbid == 6  ? outD11 :
		 mbid == 7  ? outD12 :
		 mbid == 8  ? outD13 :
		 mbid == 9  ? outD14 :
		 mbid == 10 ? outD15 :
		 mbid == 11 ? outD0  :
		 mbid == 12 ? outD1  :
		 mbid == 13 ? outD2  :
		 mbid == 14 ? outD3  :
		 outD4;
   assign 	 db6 = !m_ok ? 0     :
		 mbid == 0  ? outD6  :
		 mbid == 1  ? outD7  :
		 mbid == 2  ? outD8  :
		 mbid == 3  ? outD9  :
		 mbid == 4  ? outD10 :
		 mbid == 5  ? outD11 :
		 mbid == 6  ? outD12 :
		 mbid == 7  ? outD13 :
		 mbid == 8  ? outD14 :
		 mbid == 9  ? outD15 :
		 mbid == 10 ? outD0  :
		 mbid == 11 ? outD1  :
		 mbid == 12 ? outD2  :
		 mbid == 13 ? outD3  :
		 mbid == 14 ? outD4  :
		 outD5;
   assign 	 db7 = !m_ok ? 0     :
		 mbid == 0  ? outD7  :
		 mbid == 1  ? outD8  :
		 mbid == 2  ? outD9  :
		 mbid == 3  ? outD10 :
		 mbid == 4  ? outD11 :
		 mbid == 5  ? outD12 :
		 mbid == 6  ? outD13 :
		 mbid == 7  ? outD14 :
		 mbid == 8  ? outD15 :
		 mbid == 9  ? outD0  :
		 mbid == 10 ? outD1  :
		 mbid == 11 ? outD2  :
		 mbid == 12 ? outD3  :
		 mbid == 13 ? outD4  :
		 mbid == 14 ? outD5  :
		 outD6;

   assign 	 rdata[ 7: 0] = db0;
   assign 	 rdata[15: 8] = db1;
   assign 	 rdata[23:16] = db2;
   assign 	 rdata[31:24] = db3;
   assign 	 rdata[39:32] = db4;
   assign 	 rdata[47:40] = db5;
   assign 	 rdata[55:48] = db6;
   assign 	 rdata[63:56] = db7;

   wire [7:0] 	 wd0 = wdata[ 7: 0];
   wire [7:0] 	 wd1 = wdata[15: 8];
   wire [7:0] 	 wd2 = wdata[23:16];
   wire [7:0] 	 wd3 = wdata[31:24];
   wire [7:0] 	 wd4 = wdata[39:32];
   wire [7:0] 	 wd5 = wdata[47:40];
   wire [7:0] 	 wd6 = wdata[55:48];
   wire [7:0] 	 wd7 = wdata[63:56];

   assign 	 inD0 =
   		 mbid == 9  ? wd7 :
   		 mbid == 10 ? wd6 :
   		 mbid == 11 ? wd5 :
   		 mbid == 12 ? wd4 :
		 mbid == 13 ? wd3 :
		 mbid == 14 ? wd2 :
		 mbid == 15 ? wd1 :
		 mbid == 0  ? wd0 :
		 0;

   assign 	 inD1 =
   		 mbid == 10 ? wd7 :
   		 mbid == 11 ? wd6 :
   		 mbid == 12 ? wd5 :
   		 mbid == 13 ? wd4 :
		 mbid == 14 ? wd3 :
		 mbid == 15 ? wd2 :
		 mbid == 0  ? wd1 :
		 mbid == 1  ? wd0 :
		 0;

   assign 	 inD2 =
   		 mbid == 11 ? wd7 :
   		 mbid == 12 ? wd6 :
   		 mbid == 13 ? wd5 :
   		 mbid == 14 ? wd4 :
		 mbid == 15 ? wd3 :
		 mbid == 0  ? wd2 :
		 mbid == 1  ? wd1 :
		 mbid == 2  ? wd0 :
		 0;

   assign 	 inD3 =
   		 mbid == 12 ? wd7 :
   		 mbid == 13 ? wd6 :
   		 mbid == 14 ? wd5 :
   		 mbid == 15 ? wd4 :
		 mbid == 0 ? wd3  :
		 mbid == 1 ? wd2  :
		 mbid == 2 ? wd1  :
		 mbid == 3 ? wd0  :
		 0;

   assign 	 inD4 =
   		 mbid == 13 ? wd7 :
   		 mbid == 14 ? wd6 :
   		 mbid == 15 ? wd5 :
   		 mbid == 0 ? wd4  :
		 mbid == 1 ? wd3  :
		 mbid == 2 ? wd2  :
		 mbid == 3 ? wd1  :
		 mbid == 4 ? wd0  :
		 0;

   assign 	 inD5 =
   		 mbid == 14 ? wd7 :
   		 mbid == 15 ? wd6 :
   		 mbid == 0 ? wd5  :
   		 mbid == 1 ? wd4  :
		 mbid == 2 ? wd3  :
		 mbid == 3 ? wd2  :
		 mbid == 4 ? wd1  :
		 mbid == 5 ? wd0  :
		 0;

   assign 	 inD6 =
   		 mbid == 15 ? wd7 :
   		 mbid == 0 ? wd6  :
   		 mbid == 1 ? wd5  :
   		 mbid == 2 ? wd4  :
		 mbid == 3 ? wd3  :
		 mbid == 4 ? wd2  :
		 mbid == 5 ? wd1  :
		 mbid == 6 ? wd0  :
		 0;

   assign 	 inD7 =
   		 mbid == 0 ? wd7  :
   		 mbid == 1 ? wd6  :
   		 mbid == 2 ? wd5  :
   		 mbid == 3 ? wd4  :
		 mbid == 4 ? wd3  :
		 mbid == 5 ? wd2  :
		 mbid == 6 ? wd1  :
		 mbid == 7 ? wd0  :
		 0;

   assign 	 inD8 =
   		 mbid == 1 ? wd7  :
   		 mbid == 2 ? wd6  :
   		 mbid == 3 ? wd5  :
   		 mbid == 4 ? wd4  :
		 mbid == 5 ? wd3  :
		 mbid == 6 ? wd2  :
		 mbid == 7 ? wd1  :
		 mbid == 8 ? wd0  :
		 0;

   assign 	 inD9 =
   		 mbid == 2 ? wd7  :
   		 mbid == 3 ? wd6  :
   		 mbid == 4 ? wd5  :
   		 mbid == 5 ? wd4  :
		 mbid == 6 ? wd3  :
		 mbid == 7 ? wd2  :
		 mbid == 8 ? wd1  :
		 mbid == 9 ? wd0  :
		 0;

   assign 	 inD10 =
   		 mbid == 3 ? wd7  :
   		 mbid == 4 ? wd6  :
   		 mbid == 5 ? wd5  :
   		 mbid == 6 ? wd4  :
		 mbid == 7 ? wd3  :
		 mbid == 8 ? wd2  :
		 mbid == 9 ? wd1  :
		 mbid == 10 ? wd0 :
		 0;

   assign 	 inD11 =
   		 mbid == 4 ? wd7  :
   		 mbid == 5 ? wd6  :
   		 mbid == 6 ? wd5  :
   		 mbid == 7 ? wd4  :
		 mbid == 8 ? wd3  :
		 mbid == 9 ? wd2  :
		 mbid == 10 ? wd1 :
		 mbid == 11 ? wd0 :
		 0;

   assign 	 inD12 =
   		 mbid == 5 ? wd7  :
   		 mbid == 6 ? wd6  :
   		 mbid == 7 ? wd5  :
   		 mbid == 8 ? wd4  :
		 mbid == 9 ? wd3  :
		 mbid == 10 ? wd2 :
		 mbid == 11 ? wd1 :
		 mbid == 12 ? wd0 :
		 0;

   assign 	 inD13 =
   		 mbid == 6 ? wd7  :
   		 mbid == 7 ? wd6  :
   		 mbid == 8 ? wd5  :
   		 mbid == 9 ? wd4  :
		 mbid == 10 ? wd3 :
		 mbid == 11 ? wd2 :
		 mbid == 12 ? wd1 :
		 mbid == 13 ? wd0 :
		 0;

   assign 	 inD14 =
   		 mbid == 7 ? wd7  :
   		 mbid == 8 ? wd6  :
   		 mbid == 9 ? wd5  :
   		 mbid == 10 ? wd4 :
		 mbid == 11 ? wd3 :
		 mbid == 12 ? wd2 :
		 mbid == 13 ? wd1 :
		 mbid == 14 ? wd0 :
		 0;

   assign 	 inD15 =
   		 mbid == 8 ? wd7  :
   		 mbid == 9 ? wd6  :
   		 mbid == 10 ? wd5 :
   		 mbid == 11 ? wd4 :
		 mbid == 12 ? wd3 :
		 mbid == 13 ? wd2 :
		 mbid == 14 ? wd1 :
		 mbid == 15 ? wd0 :
		 0;

   // Which banks get written
   assign 	 dwEn0 = wenable & (mbid <= 0 | mbid >= 9);  
   assign 	 dwEn1 = wenable & (mbid <= 1 | mbid >= 10);  
   assign 	 dwEn2 = wenable & (mbid <= 2 | mbid >= 11);  
   assign 	 dwEn3 = wenable & (mbid <= 3 | mbid >= 12);
   assign 	 dwEn4 = wenable & (mbid <= 4 | mbid >= 13);
   assign 	 dwEn5 = wenable & (mbid <= 5 | mbid >= 14);
   assign 	 dwEn6 = wenable & (mbid <= 6 | mbid >= 15);
   assign 	 dwEn7 = wenable & (mbid <= 7);
   assign 	 dwEn8 = wenable & (mbid >= 1 & mbid <= 8);
   assign 	 dwEn9 = wenable & (mbid >= 2 & mbid <= 9);
   assign 	 dwEn10 = wenable & (mbid >= 3 & mbid <= 10);
   assign 	 dwEn11 = wenable & (mbid >= 4 & mbid <= 11);
   assign 	 dwEn12 = wenable & (mbid >= 5 & mbid <= 12);
   assign 	 dwEn13 = wenable & (mbid >= 6 & mbid <= 13);
   assign 	 dwEn14 = wenable & (mbid >= 7 & mbid <= 14);
   assign 	 dwEn15 = wenable & (mbid >= 8);

endmodule ///line:arch:verilog:bmemory_end


// Combinational blocks

// Fetch stage

//* $begin fetch-blocks-verilog */
// Split instruction byte into icode and ifun fields
module split(ibyte, icode, ifun);
   input  [7:0] ibyte;
   output [3:0] icode;
   output [3:0] ifun;

   assign 	icode = ibyte[7:4];
   assign 	ifun  = ibyte[3:0];
endmodule

// Extract immediate word from 9 bytes of instruction
module align(ibytes, need_regids, rA, rB, valC);
   input  [71:0] ibytes;
   input 	 need_regids;
   output [ 3:0] rA;
   output [ 3:0] rB;
   output [63:0] valC;
   assign 	 rA = ibytes[7:4];
   assign 	 rB = ibytes[3:0];
   assign 	 valC = need_regids ? ibytes[71:8] : ibytes[63:0];
endmodule

// PC incrementer
module pc_increment(pc, need_regids, need_valC, valP);
   input  [63:0] pc;
   input 	 need_regids;
   input 	 need_valC;
   output [63:0] valP;
   assign 	 valP = pc + 1 + 8*need_valC + need_regids;
endmodule
//* $end fetch-blocks-verilog */

// Execute Stage

// ALU
//* $begin alu-verilog */
module alu(aluA, aluB, alufun, valE, new_cc);
   input  [63:0] aluA, aluB;	// Data inputs
   input  [ 3:0] alufun;	// ALU function
   output [63:0] valE;		// Data Output
   output [ 2:0] new_cc; 	// New values for ZF, SF, OF

   parameter 	 ALUADD = 4'h0;
   parameter 	 ALUSUB = 4'h1;
   parameter 	 ALUAND = 4'h2;
   parameter 	 ALUXOR = 4'h3;

   assign 	 valE = 
		 alufun == ALUSUB ? aluB - aluA :
		 alufun == ALUAND ? aluB & aluA :
		 alufun == ALUXOR ? aluB ^ aluA :
		 aluB + aluA;
   assign 	 new_cc[2] = (valE == 0);  // ZF
   assign 	 new_cc[1] = valE[63];     // SF
   assign 	 new_cc[0] =		   // OF
		   alufun == ALUADD ?
		      (aluA[63] == aluB[63])  & (aluA[63] != valE[63]) :
		   alufun == ALUSUB ?
		      (~aluA[63] == aluB[63]) & (aluB[63] != valE[63]) :
		   0;
endmodule
//* $end alu-verilog */


// Condition code register
module cc(cc, new_cc, set_cc, reset, clock);
   output[2:0] cc;
   input [2:0] new_cc;
   input       set_cc;
   input       reset;
   input       clock;

   cenrreg #(3) c(cc, new_cc, set_cc, reset, 3'b100, clock);
endmodule

// branch condition logic
module cond(ifun, cc, Cnd);
   input [3:0] ifun;
   input [2:0] cc;
   output      Cnd;

   wire        zf = cc[2];
   wire        sf = cc[1];
   wire        of = cc[0];

   // Jump & move conditions.
   parameter   C_YES  = 4'h0;
   parameter   C_LE   = 4'h1;
   parameter   C_L    = 4'h2;
   parameter   C_E    = 4'h3;
   parameter   C_NE   = 4'h4;
   parameter   C_GE   = 4'h5;
   parameter   C_G    = 4'h6;

   assign      Cnd = 
	       (ifun == C_YES) |               //
	       (ifun == C_LE & ((sf^of)|zf)) | // <=
	       (ifun == C_L  & (sf^of)) |      // <
	       (ifun == C_E  & zf) |           // ==
	       (ifun == C_NE & ~zf) |          // !=
	       (ifun == C_GE & (~sf^of)) |     // >=
	       (ifun == C_G  & (~sf^of)&~zf);  // >

endmodule
