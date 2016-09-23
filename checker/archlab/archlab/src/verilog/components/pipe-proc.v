
// The processor can run in 5 different modes:
// RUN:      Normal operation
// RESET:    Sets PC to 0, clears all pipe registers;
//	     Initializes condition codes
// DOWNLOAD: Download bytes from controller into memory
// UPLOAD:   Upload bytes from memory to controller
// STATUS:   Upload other status information to controller

// Processor module
//* $begin processor-decl-verilog */
module processor(mode, udaddr, idata, odata, stat, clock);
  input  [ 2:0] mode;   // Signal operating mode to processor
  input  [63:0] udaddr; // Upload/download address
  input  [63:0] idata;  // Download data word
  output [63:0] odata;  // Upload data word
  output [ 2:0] stat;   // Status
  input         clock;  // Clock input
//* $end processor-decl-verilog */

// Define modes
  parameter RUN_MODE = 0;      // Normal operation
  parameter RESET_MODE = 1;    // Resetting processor;
  parameter DOWNLOAD_MODE = 2; // Transfering to memory
  parameter UPLOAD_MODE = 3;   // Reading from memory
  // Uploading register & other status information
  parameter STATUS_MODE = 4;   

// Constant values

  // Instruction codes
  parameter IHALT   = 4'h0;
  parameter INOP    = 4'h1;
  parameter IRRMOVQ = 4'h2;
  parameter IIRMOVQ = 4'h3;
  parameter IRMMOVQ = 4'h4;
  parameter IMRMOVQ = 4'h5;
  parameter IOPQ    = 4'h6;
  parameter IJXX    = 4'h7;
  parameter ICALL   = 4'h8;
  parameter IRET    = 4'h9;
  parameter IPUSHQ  = 4'hA;
  parameter IPOPQ   = 4'hB;
  parameter IIADDQ  = 4'hC;
  parameter ILEAVE  = 4'hD;
  parameter IPOP2   = 4'hE;

  // Function codes
  parameter FNONE   = 4'h0;

  // Jump conditions
  parameter UNCOND  = 4'h0;

  // Register IDs
  parameter RRSP    = 4'h4;
  parameter RRBP    = 4'h5;
  parameter RNONE   = 4'hF;

  // ALU operations
  parameter ALUADD  = 4'h0;

  // Status conditions
  parameter SBUB    = 3'h0;
  parameter SAOK    = 3'h1;
  parameter SHLT    = 3'h2;
  parameter SADR    = 3'h3;
  parameter SINS    = 3'h4;
  parameter SPIP    = 3'h5;

// Fetch stage signals
//* $begin fetch-signals-verilog */
  wire [63:0] f_predPC, F_predPC, f_pc;
  wire        f_ok;
  wire        imem_error;
  wire [ 2:0]  f_stat;
  wire [79:0] f_instr;
  wire [ 3:0] imem_icode;
  wire [ 3:0] imem_ifun;
  wire [ 3:0] f_icode;
  wire [ 3:0] f_ifun;
  wire [ 3:0] f_rA;
  wire [ 3:0] f_rB;
  wire [63:0] f_valC;
  wire [63:0] f_valP;
  wire        need_regids;
  wire        need_valC;
  wire        instr_valid;
  wire        F_stall, F_bubble;
//* $end fetch-signals-verilog */

// Decode stage signals
  wire [ 2:0] D_stat;
  wire [63:0] D_pc;
  wire [ 3:0] D_icode;
  wire [ 3:0] D_ifun;
  wire [ 3:0] D_rA;
  wire [ 3:0] D_rB;
  wire [63:0] D_valC;
  wire [63:0] D_valP;

  wire [63:0] d_valA;
  wire [63:0] d_valB;
  wire [63:0] d_rvalA;
  wire [63:0] d_rvalB;
  wire [ 3:0] d_dstE;
  wire [ 3:0] d_dstM;
  wire [ 3:0] d_srcA;
  wire [ 3:0] d_srcB;
  wire        D_stall, D_bubble;

// Execute stage signals
  wire [ 2:0] E_stat;
  wire [63:0] E_pc;
  wire [ 3:0] E_icode;
  wire [ 3:0] E_ifun;
  wire [63:0] E_valC;
  wire [63:0] E_valA;
  wire [63:0] E_valB;
  wire [ 3:0] E_dstE;
  wire [ 3:0] E_dstM;
  wire [ 3:0] E_srcA;
  wire [ 3:0] E_srcB;

  wire [63:0] aluA;
  wire [63:0] aluB;
  wire        set_cc;
  wire [ 2:0] cc;
  wire [ 2:0] new_cc;
  wire [ 3:0] alufun;
  wire        e_Cnd;
  wire [63:0] e_valE;
  wire [63:0] e_valA;
  wire [ 3:0] e_dstE;
  wire        E_stall, E_bubble;

// Memory stage
  wire [ 2:0] M_stat;
  wire [63:0] M_pc;
  wire [ 3:0] M_icode;
  wire [ 3:0] M_ifun;
  wire        M_Cnd;
  wire [63:0] M_valE;
  wire [63:0] M_valA;
  wire [ 3:0] M_dstE;
  wire [ 3:0] M_dstM;

  wire [ 2:0] m_stat;
  wire [63:0] mem_addr;
  wire [63:0] mem_data;
  wire        mem_read;
  wire        mem_write;
  wire [63:0] m_valM;
  wire        M_stall, M_bubble;
  wire        m_ok;

// Write-back stage
  wire [ 2:0] W_stat;
  wire [63:0] W_pc;
  wire [ 3:0] W_icode;
  wire [63:0] W_valE;
  wire [63:0] W_valM;
  wire [ 3:0] W_dstE;
  wire [ 3:0] W_dstM;
  wire [63:0] w_valE;
  wire [63:0] w_valM;
  wire [ 3:0] w_dstE;
  wire [ 3:0] w_dstM;
  wire        W_stall, W_bubble;

  // Global status
  wire [ 2:0] Stat;

// Debugging logic
  wire [63:0] rax, rcx, rdx, rbx, rsp, rbp, rsi, rdi,
              r8, r9, r10, r11, r12, r13, r14;
  wire zf = cc[2];
  wire sf = cc[1];
  wire of = cc[0];

// Control signals
//* $begin fetch-control-verilog */
  wire resetting = (mode == RESET_MODE);
//* $end fetch-control-verilog */
  wire uploading = (mode == UPLOAD_MODE);
  wire downloading = (mode == DOWNLOAD_MODE);
  wire running = (mode == RUN_MODE);
  wire getting_info = (mode == STATUS_MODE);
// Logic to control resetting of pipeline registers
//* $begin fetch-control-verilog */
  wire F_reset = F_bubble | resetting;
  wire D_reset = D_bubble | resetting;
//* $end fetch-control-verilog */
  wire E_reset = E_bubble | resetting;
  wire M_reset = M_bubble | resetting;
  wire W_reset = W_bubble | resetting;

  // Processor status
  assign stat = Stat;
  // Output data
  assign odata = 
   // When getting status, get either register or special status value
    getting_info ?  
     (udaddr ==   0 ? rax  :
      udaddr ==   8 ? rcx  :
      udaddr ==  16 ? rdx  :
      udaddr ==  24 ? rbx  :
      udaddr ==  32 ? rsp  :
      udaddr ==  40 ? rbp  :
      udaddr ==  48 ? rsi  :
      udaddr ==  56 ? rdi  :
      udaddr ==  64 ? r8   :
      udaddr ==  72 ? r9   :
      udaddr ==  80 ? r10  :
      udaddr ==  88 ? r11  :
      udaddr ==  96 ? r12  :
      udaddr == 104 ? r13  :
      udaddr == 112 ? r14  :
      udaddr == 120 ? cc   :
      udaddr == 128 ? W_pc : 0)
    : m_valM;

// Pipeline registers

//* $begin fetch-reg-verilog */
// All pipeline registers are implemented with module
//    preg(out, in, stall, bubble, bubbleval, clock)
// F Register
  preg #(64) F_predPC_reg(F_predPC, f_predPC, F_stall, F_reset, 64'b0, clock);
// D Register
  preg #(3)  D_stat_reg(D_stat, f_stat, D_stall, D_reset, SBUB, clock);
  preg #(64) D_pc_reg(D_pc, f_pc, D_stall, D_reset, 64'b0, clock);
  preg #(4)  D_icode_reg(D_icode, f_icode, D_stall, D_reset, INOP, clock);
  preg #(4)  D_ifun_reg(D_ifun, f_ifun, D_stall, D_reset, FNONE, clock);
  preg #(4)  D_rA_reg(D_rA, f_rA, D_stall, D_reset, RNONE, clock);
  preg #(4)  D_rB_reg(D_rB, f_rB, D_stall, D_reset, RNONE, clock);
  preg #(64) D_valC_reg(D_valC, f_valC, D_stall, D_reset, 64'b0, clock);
  preg #(64) D_valP_reg(D_valP, f_valP, D_stall, D_reset, 64'b0, clock);
//* $end fetch-reg-verilog */
// E Register
  preg #(3)  E_stat_reg(E_stat, D_stat, E_stall, E_reset, SBUB, clock);
  preg #(64) E_pc_reg(E_pc, D_pc, E_stall, E_reset, 64'b0, clock);
  preg #(4)  E_icode_reg(E_icode, D_icode, E_stall, E_reset, INOP, clock);
  preg #(4)  E_ifun_reg(E_ifun, D_ifun, E_stall, E_reset, FNONE, clock);
  preg #(64) E_valC_reg(E_valC, D_valC, E_stall, E_reset, 64'b0, clock);
  preg #(64) E_valA_reg(E_valA, d_valA, E_stall, E_reset, 64'b0, clock);
  preg #(64) E_valB_reg(E_valB, d_valB, E_stall, E_reset, 64'b0, clock);
  preg #(4)  E_dstE_reg(E_dstE, d_dstE, E_stall, E_reset, RNONE, clock);
  preg #(4)  E_dstM_reg(E_dstM, d_dstM, E_stall, E_reset, RNONE, clock);
  preg #(4)  E_srcA_reg(E_srcA, d_srcA, E_stall, E_reset, RNONE, clock);
  preg #(4)  E_srcB_reg(E_srcB, d_srcB, E_stall, E_reset, RNONE, clock);
// M Register
  preg #(3)  M_stat_reg(M_stat, E_stat, M_stall, M_reset, SBUB, clock);
  preg #(64) M_pc_reg(M_pc, E_pc, M_stall, M_reset, 64'b0, clock);
  preg #(4)  M_icode_reg(M_icode, E_icode, M_stall, M_reset, INOP, clock);
  preg #(4)  M_ifun_reg(M_ifun, E_ifun, M_stall, M_reset, FNONE, clock);
  preg #(1)  M_Cnd_reg(M_Cnd, e_Cnd, M_stall, M_reset, 1'b0, clock);
  preg #(64) M_valE_reg(M_valE, e_valE, M_stall, M_reset, 64'b0, clock);
  preg #(64) M_valA_reg(M_valA, e_valA, M_stall, M_reset, 64'b0, clock);
  preg #(4)  M_dstE_reg(M_dstE, e_dstE, M_stall, M_reset, RNONE, clock);
  preg #(4)  M_dstM_reg(M_dstM, E_dstM, M_stall, M_reset, RNONE, clock);
// W Register
  preg #(3)  W_stat_reg(W_stat, m_stat, W_stall, W_reset, SBUB, clock);
  preg #(64) W_pc_reg(W_pc, M_pc, W_stall, W_reset, 64'b0, clock);
  preg #(4)  W_icode_reg(W_icode, M_icode, W_stall, W_reset, INOP, clock);
  preg #(64) W_valE_reg(W_valE, M_valE, W_stall, W_reset, 64'b0, clock);
  preg #(64) W_valM_reg(W_valM, m_valM, W_stall, W_reset, 64'b0, clock);
  preg #(4)  W_dstE_reg(W_dstE, M_dstE, W_stall, W_reset, RNONE, clock);
  preg #(4)  W_dstM_reg(W_dstM, M_dstM, W_stall, W_reset, RNONE, clock);

// Fetch stage logic
//* $begin fetch-logic-verilog */
  split split(f_instr[7:0], imem_icode, imem_ifun);
  align align(f_instr[79:8], need_regids, f_rA, f_rB, f_valC);
  pc_increment pci(f_pc, need_regids, need_valC, f_valP);
//* $end fetch-logic-verilog */

// Decode stage
  regfile regf(w_dstE, w_valE, w_dstM, w_valM, 
               d_srcA, d_rvalA, d_srcB, d_rvalB, resetting, clock,
               rax, rcx, rdx, rbx, rsp, rbp, rsi, rdi,
               r8, r9, r10, r11, r12, r13, r14);


// Execute stage
  alu alu(aluA, aluB, alufun, e_valE, new_cc);
  cc  ccreg(cc, new_cc, 
	    // Only update CC when everything is running normally
            running & set_cc,
            resetting, clock);
  cond cond_check(E_ifun, cc, e_Cnd);

// Memory stage
  bmemory m(
    // Only update memory when everything is running normally 
    // or when downloading
    (downloading | uploading) ? udaddr : mem_addr, // Read/Write address
    (running & mem_write) | downloading,  // When to write to memory
    downloading ? idata : M_valA,         // Write data
    (running & mem_read) | uploading,     // When to read memory
    m_valM,                               // Read data
    m_ok,
    f_pc, f_instr, f_ok, clock);          // Instruction memory access

   assign imem_error = ~f_ok;
   assign dmem_error = ~m_ok;

// Write-back stage logic

// Control logic
// --------------------------------------------------------------------
// The following code is generated from the HCL description of the
// pipeline control using the hcl2v program
// --------------------------------------------------------------------
// INSERT_LOGIC_HERE
// --------------------------------------------------------------------
// End of code generated by hcl2v
// --------------------------------------------------------------------
endmodule

