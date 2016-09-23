// --------------------------------------------------------------------
// This part of the code was generated by including the file "seq-proc.v"
// --------------------------------------------------------------------
// Verilog representation of SEQ
// This file connects together all of the blocks to create the processor

// The tag INSERT-LOGIC-HERE (but with underscores rather than dashes)
// is used to indicate where the logic derived from the HCL code should be inserted.

// The processor can run in 5 different modes:
// RUN: Normal operation
// RESET: sets PC to 0, clears all pipe registers, initializes condition codes
// DOWNLOAD: Download bytes from controller into memory
// UPLOAD: Upload bytes from memory to controller
// INFO: Upload other status information to controller

// Processor module
module processor(mode, udaddr, idata, odata, stat, clock);
  input  [2:0]  mode;   // Signal operating mode to processor
  input  [63:0] udaddr; // Upload/download address
  input  [63:0] idata;  // Download data word
  output [63:0] odata;  // Upload data word
  output [2:0]  stat;   // Status
  input clock;          // Clock input

// Define modes
  parameter RUN_MODE       = 0; // Normal operation
  parameter RESET_MODE     = 1; // Resetting processor;
  parameter DOWNLOAD_MODE  = 2; // Transfering to memory
  parameter UPLOAD_MODE    = 3; // Reading from memory
  parameter INFO_MODE      = 4; // Uploading register & other status information

// Constant values

  // Instruction functions
  parameter IHALT =   4'h0;
  parameter INOP =    4'h1;
  parameter IRRMOVQ = 4'h2;
  parameter IIRMOVQ = 4'h3;
  parameter IRMMOVQ = 4'h4;
  parameter IMRMOVQ = 4'h5;
  parameter IOPQ =    4'h6;
  parameter IJXX =    4'h7;
  parameter ICALL =   4'h8;
  parameter IRET =    4'h9;
  parameter IPUSHQ =  4'hA;
  parameter IPOPQ =   4'hB;
  parameter IIADDQ =  4'hC;

  // Register IDs
  parameter RRSP =  4'h4;
  parameter RRBP =  4'h5;
  parameter RNONE = 4'hF;

  // ALU operations
  parameter ALUADD = 4'h0;

  // Function codes
  parameter FNONE = 4'h0;

  // Status conditions
  parameter SBUB = 3'h0; // Never happens
  parameter SAOK = 3'h1;
  parameter SHLT = 3'h2;
  parameter SADR = 3'h3;
  parameter SINS = 3'h4;
  parameter SPIP = 3'h5; // Never happens

// Control signals
  wire resetting = (mode == RESET_MODE);
  wire uploading = (mode == UPLOAD_MODE);
  wire downloading = (mode == DOWNLOAD_MODE);
  wire running = (mode == RUN_MODE);
  wire getting_info = (mode == INFO_MODE);

// Fetch stage
  wire f_ok;
  wire imem_error;
  wire [63:0] pc;
  wire [79:0] instr;
  wire [ 3:0] imem_icode;
  wire [ 3:0] imem_ifun;
  wire [ 3:0] icode;
  wire [ 3:0] ifun;
  wire [ 3:0] rA;
  wire [ 3:0] rB;
  wire [63:0] valC;
  wire [63:0] valP;
  wire        need_regids;
  wire        need_valC;
  wire        instr_valid;
// Decode stage
  wire [63:0] valA;
  wire [63:0] valB;
  wire [ 3:0] dstE;
  wire [ 3:0] dstM;
  wire [ 3:0] srcA;
  wire [ 3:0] srcB;
// Execute stage
  wire [63:0] aluA;
  wire [63:0] aluB;
  wire        set_cc;
  wire [ 2:0] cc;
  wire [ 2:0] new_cc;
  wire [ 3:0] alufun;
  wire        Cnd;
  wire [63:0] valE;
// Memory stage
  wire        m_ok;
  wire        dmem_error;
  wire [63:0] mem_addr;
  wire [63:0] mem_data;
  wire        mem_read;
  wire        mem_write;
  wire [63:0] valM;
// PC selection
  wire [63:0] new_pc;
// Global status
  wire [ 2:0] Stat;
   

// Debugging logic
  wire [63:0] rax, rcx, rdx, rbx, rsp, rbp, rsi, rdi, r8, r9, r10, r11, r12, r13, r14;
  wire zf = cc[2];
  wire sf = cc[1];
  wire of = cc[0];

// Processor status
  assign stat = Stat;

// Control signals
  assign odata = 
   // When getting info, get either register or special status value
    getting_info ?  
     (udaddr ==   0 ? rax :
      udaddr ==   8 ? rcx :
      udaddr ==  16 ? rdx :
      udaddr ==  24 ? rbx :
      udaddr ==  32 ? rsp :
      udaddr ==  40 ? rbp :
      udaddr ==  48 ? rsi :
      udaddr ==  56 ? rdi :
      udaddr ==  64 ? r8  :
      udaddr ==  72 ? r9  :
      udaddr ==  80 ? r10 :
      udaddr ==  88 ? r11 :
      udaddr ==  96 ? r12 :
      udaddr == 104 ? r13 :
      udaddr == 112 ? r14 :
      udaddr == 120 ? cc  :
      udaddr == 128 ? pc  : 0)
    : valM;

// The blocks 

// Fetch stage
  cenrreg #(64) p(pc, new_pc, running & stat == SAOK, resetting, 64'b0, clock);  // Program counter
  split splt(instr[7:0], imem_icode, imem_ifun);
  align aln(instr[79:8], need_regids, rA, rB, valC);
  pc_increment pci(pc, need_regids, need_valC, valP);

// Decode stage
  regfile regf(dstE, valE, dstM, valM, srcA, valA, srcB, valB, resetting, clock,
               rax, rcx, rdx, rbx, rsp, rbp, rsi, rdi,
               r8, r9, r10, r11, r12, r13, r14);

// Execute stage
  alu alu(aluA, aluB, alufun, valE, new_cc);
  cc  ccreg(cc, new_cc, running & set_cc & stat == SAOK,
            reset, clock);
  cond cond_check(ifun, cc, Cnd);

// Memory stage
  bmemory m(
	   (downloading | uploading) ? udaddr : mem_addr,
	   running & mem_write | downloading,
           downloading ? idata : mem_data,
           running & mem_read | uploading,
           valM, m_ok, pc, instr, f_ok, clock);

  assign imem_error = ~f_ok;
  assign dmem_error = ~m_ok;

// Operational control

   always
     @(posedge(clock))
      if (running) // disabled
	begin
	   $display("pc = 0x%x, icode = 0x%x, stat = 0b%b",
		    pc, icode, stat);
	   if (icode == IJXX)
	      begin
		 $display("jmp type 0x%x, cc = %b, taken = %d",
			  ifun, cc, Cnd);
	      end
	   if (icode == IRRMOVQ)
	      begin
		 $display("cmove type 0x%x, cc = %b, taken = %d",
			  ifun, cc, Cnd);
	      end
	   if (mem_read)
	     begin
		$display("Reading 0x%x from 0x%x", valM, mem_addr);
	     end
	   if (mem_write)
	     begin
		$display("Writing 0x%x to 0x%x (error = %b)", mem_data, mem_addr, dmem_error);
	     end
	end

// Glue logic
// --------------------------------------------------------------------
// The following code is generated from the HCL description of the
// processor control using a program hcl2v
// --------------------------------------------------------------------
// INSERT_LOGIC_HERE
// --------------------------------------------------------------------
// End of code generated by hcl2v
// --------------------------------------------------------------------
endmodule
// --------------------------------------------------------------------

// End of file "seq-proc.v"
// --------------------------------------------------------------------
