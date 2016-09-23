$c	This is the master version of the .hcl code for the pipeline.
$c	The Perl script ../hcl/vextract.pl extracts the different versions
$c	depending on the options shown in the first characters of each line.
$c	vextract.pl is given a set of single-character version names.
$c	Any line beginning with $[a-zA-Z]*\t is included only if
$c	one of the characters matches one of the version names.
$c	Any line beginning with $![a-zA-Z]*\t is included unless
$c	one of the characters matches one of the version names.
$c	
$c	Options:
$c	c: Comments (won't show up in any extracted version)
$c	a: Add annotations (used for generating .tex files)
$c	b: Broken pipeline.  Does not handle any hazards
$c	f: iaddq problem
$c	F: iaddq solution
$c	l: Load forward problem
$c	L: Load forward solution
$c	n: Branches not-taken problem
$c	N: Branches not-taken solution
$c	t: Backward taken, forward-not taken problem
$c	T: Backward taken, forward-not taken solution
$c	w: Single write port problem
$c	W: Single write port solution
$c	s: Stall-based pipeline control problem
$c	S: Stall-based pipeline control solution
#/* $begin pipe-all-hcl */
####################################################################
#    HCL Description of Control for Pipelined Y86-64 Processor     #
#    Copyright (C) Randal E. Bryant, David R. O'Hallaron, 2014     #
####################################################################
$fF	
$f	## Your task is to implement the iaddq instruction
$f	## The file contains a declaration of the icodes
$f	## for iaddq (IIADDQ)
$f	## Your job is to add the rest of the logic to make it work
$F	## This is the solution for the iaddq problem
$lL	
$l	## Your task is to implement load-forwarding, where a value
$l	## read from memory can be stored to memory by the immediately
$l	## following instruction without stalling
$l	## This requires modifying the definition of e_valA
$l	## and relaxing the stall conditions.  Relevant sections to change
$l	## are shown in comments containing the keyword "LB"
$L	## This is the solution to the load-forwarding problem
$nN	
$n	## Your task is to modify the design so that conditional branches are
$n	## predicted as being not-taken.  The code here is nearly identical
$n	## to that for the normal pipeline.  
$n	## Comments starting with keyword "BNT" have been added at places
$n	## relevant to the exercise.
$N	## This is the solution for the branches not-taken problem
$tT	
$t	## Your task is to modify the design so that conditional branches are
$t	## predicted as being taken when backward and not-taken when forward
$t	## The code here is nearly identical to that for the normal pipeline.  
$t	## Comments starting with keyword "BBTFNT" have been added at places
$t	## relevant to the exercise.
$T	## BBTFNT: This is the solution for the backward taken, forward
$T	## not-taken branch prediction problem
$wW	
$w	## Your task is to modify the design so that on any cycle, only
$w	## one of the two possible (valE and valM) register writes will occur.
$w	## This requires special handling of the popq instruction.
$W	## This is a solution to the single write port problem
$wW	## Overall strategy:  IPOPQ passes through pipe, 
$wW	## treated as stack pointer increment, but not incrementing the PC
$wW	## On refetch, modify fetched icode to indicate an instruction "IPOP2",
$wW	## which reads from memory.
$w	## This requires modifying the definition of f_icode
$w	## and lots of other changes.  Relevant positions to change
$w	## are indicated by comments starting with keyword "1W".
$sS	
$s	## Your task is to make the pipeline work without using any forwarding
$s	## The normal bypassing logic in the file is disabled.
$s	## You can only change the pipeline control logic at the end of this file.
$s	## The trick is to make the pipeline stall whenever there is a data hazard.
$S	## This is the solution for the stall-based pipeline control problem.
$b	## This version does not detect or handle any hazards

####################################################################
#    C Include's.  Don't alter these                               #
####################################################################

quote '#include <stdio.h>'
quote '#include "isa.h"'
quote '#include "pipeline.h"'
quote '#include "stages.h"'
quote '#include "sim.h"'
quote 'int sim_main(int argc, char *argv[]);'
quote 'int main(int argc, char *argv[]){return sim_main(argc,argv);}'

####################################################################
#    Declarations.  Do not change/remove/delete any of these       #
####################################################################

$a	#/* $begin pipe-fetch-all-hcl */
##### Symbolic representation of Y86-64 Instruction Codes #############
wordsig INOP 	'I_NOP'
wordsig IHALT	'I_HALT'
wordsig IRRMOVQ	'I_RRMOVQ'
wordsig IIRMOVQ	'I_IRMOVQ'
wordsig IRMMOVQ	'I_RMMOVQ'
wordsig IMRMOVQ	'I_MRMOVQ'
wordsig IOPQ	'I_ALU'
wordsig IJXX	'I_JMP'
wordsig ICALL	'I_CALL'
wordsig IRET	'I_RET'
wordsig IPUSHQ	'I_PUSHQ'
wordsig IPOPQ	'I_POPQ'
$fF	# Instruction code for iaddq instruction
$fF	wordsig IIADDQ	'I_IADDQ'
$wW	# 1W: Special instruction code for second try of popq
$wW	wordsig IPOP2	'I_POP2'

##### Symbolic represenations of Y86-64 function codes            #####
wordsig FNONE    'F_NONE'        # Default function code

##### Symbolic representation of Y86-64 Registers referenced      #####
wordsig RRSP     'REG_RSP'    	     # Stack Pointer
wordsig RNONE    'REG_NONE'   	     # Special value indicating "no register"

##### ALU Functions referenced explicitly ##########################
wordsig ALUADD	'A_ADD'		     # ALU should add its arguments
$nNtT
$nN	## BNT: For modified branch prediction, need to distinguish
$tT	## BBTFNT: For modified branch prediction, need to distinguish
$nNtT	## conditional vs. unconditional branches
$nNtT	##### Jump conditions referenced explicitly
$nNtT	wordsig UNCOND 'C_YES'       	     # Unconditional transfer

##### Possible instruction status values                       #####
wordsig SBUB	'STAT_BUB'	# Bubble in stage
wordsig SAOK	'STAT_AOK'	# Normal execution
wordsig SADR	'STAT_ADR'	# Invalid memory address
wordsig SINS	'STAT_INS'	# Invalid instruction
wordsig SHLT	'STAT_HLT'	# Halt instruction encountered

##### Signals that can be referenced by control logic ##############

##### Pipeline Register F ##########################################

wordsig F_predPC 'pc_curr->pc'	     # Predicted value of PC

##### Intermediate Values in Fetch Stage ###########################

wordsig imem_icode  'imem_icode'      # icode field from instruction memory
wordsig imem_ifun   'imem_ifun'       # ifun  field from instruction memory
wordsig f_icode	'if_id_next->icode'  # (Possibly modified) instruction code
wordsig f_ifun	'if_id_next->ifun'   # Fetched instruction function
wordsig f_valC	'if_id_next->valc'   # Constant data of fetched instruction
wordsig f_valP	'if_id_next->valp'   # Address of following instruction
$wW	## 1W: Provide access to the PC value for the current instruction
$wW	wordsig f_pc	'f_pc'               # Address of fetched instruction
boolsig imem_error 'imem_error'	     # Error signal from instruction memory
boolsig instr_valid 'instr_valid'    # Is fetched instruction valid?

##### Pipeline Register D ##########################################
wordsig D_icode 'if_id_curr->icode'   # Instruction code
wordsig D_rA 'if_id_curr->ra'	     # rA field from instruction
wordsig D_rB 'if_id_curr->rb'	     # rB field from instruction
wordsig D_valP 'if_id_curr->valp'     # Incremented PC

##### Intermediate Values in Decode Stage  #########################

wordsig d_srcA	 'id_ex_next->srca'  # srcA from decoded instruction
wordsig d_srcB	 'id_ex_next->srcb'  # srcB from decoded instruction
wordsig d_rvalA 'd_regvala'	     # valA read from register file
wordsig d_rvalB 'd_regvalb'	     # valB read from register file

##### Pipeline Register E ##########################################
wordsig E_icode 'id_ex_curr->icode'   # Instruction code
wordsig E_ifun  'id_ex_curr->ifun'    # Instruction function
wordsig E_valC  'id_ex_curr->valc'    # Constant data
wordsig E_srcA  'id_ex_curr->srca'    # Source A register ID
wordsig E_valA  'id_ex_curr->vala'    # Source A value
wordsig E_srcB  'id_ex_curr->srcb'    # Source B register ID
wordsig E_valB  'id_ex_curr->valb'    # Source B value
wordsig E_dstE 'id_ex_curr->deste'    # Destination E register ID
wordsig E_dstM 'id_ex_curr->destm'    # Destination M register ID

##### Intermediate Values in Execute Stage #########################
wordsig e_valE 'ex_mem_next->vale'	# valE generated by ALU
boolsig e_Cnd 'ex_mem_next->takebranch' # Does condition hold?
wordsig e_dstE 'ex_mem_next->deste'      # dstE (possibly modified to be RNONE)

##### Pipeline Register M                  #########################
wordsig M_stat 'ex_mem_curr->status'     # Instruction status
wordsig M_icode 'ex_mem_curr->icode'	# Instruction code
wordsig M_ifun  'ex_mem_curr->ifun'	# Instruction function
wordsig M_valA  'ex_mem_curr->vala'      # Source A value
wordsig M_dstE 'ex_mem_curr->deste'	# Destination E register ID
wordsig M_valE  'ex_mem_curr->vale'      # ALU E value
wordsig M_dstM 'ex_mem_curr->destm'	# Destination M register ID
boolsig M_Cnd 'ex_mem_curr->takebranch'	# Condition flag
boolsig dmem_error 'dmem_error'	        # Error signal from instruction memory
$lL	## LF: Carry srcA up to pipeline register M
$lL	wordsig M_srcA 'ex_mem_curr->srca'	# Source A register ID

##### Intermediate Values in Memory Stage ##########################
wordsig m_valM 'mem_wb_next->valm'	# valM generated by memory
wordsig m_stat 'mem_wb_next->status'	# stat (possibly modified to be SADR)

##### Pipeline Register W ##########################################
wordsig W_stat 'mem_wb_curr->status'     # Instruction status
wordsig W_icode 'mem_wb_curr->icode'	# Instruction code
wordsig W_dstE 'mem_wb_curr->deste'	# Destination E register ID
wordsig W_valE  'mem_wb_curr->vale'      # ALU E value
wordsig W_dstM 'mem_wb_curr->destm'	# Destination M register ID
wordsig W_valM  'mem_wb_curr->valm'	# Memory M value

####################################################################
#    Control Signal Definitions.                                   #
####################################################################

################ Fetch Stage     ###################################

$a	#/* $begin pipe-fetch-logic-hcl */
## What address should instruction be fetched at
$a	#/* $begin pipe-f_pc-hcl */
word f_pc = [
	# Mispredicted branch.  Fetch at incremented PC
$!NT		M_icode == IJXX && !M_Cnd : M_valA;
$N		# BNT: Changed misprediction condition
$N		M_icode == IJXX && M_ifun != UNCOND && M_Cnd : M_valE;
$T		# BBTFNT: Mispredicted forward branch.  Fetch at target (now in valE)
$T	        M_icode == IJXX && M_ifun != UNCOND && M_valE >= M_valA
$T	   	   && M_Cnd : M_valE;
$T		# BBTFNT: Mispredicted backward branch.
$T		#    Fetch at incremented PC (now in valE)
$T	 	M_icode == IJXX && M_ifun != UNCOND && M_valE < M_valA
$T		  && !M_Cnd : M_valA;
	# Completion of RET instruction
	W_icode == IRET : W_valM;
	# Default: Use predicted value of PC
	1 : F_predPC;
];
$a	#/* $end pipe-f_pc-hcl */

## Determine icode of fetched instruction
$wW	## 1W: To split ipopq into two cycles, need to be able to 
$wW	## modify value of icode,
$wW	## so that it will be IPOP2 when fetched for second time.
word f_icode = [
	imem_error : INOP;
$W		## Can detected refetch of ipopq, since now have
$W		## IPOPQ as icode for instruction in decode.
$W		imem_icode == IPOPQ && D_icode == IPOPQ : IPOP2;
	1: imem_icode;
];

# Determine ifun
word f_ifun = [
	imem_error : FNONE;
	1: imem_ifun;
];

# Is instruction valid?
bool instr_valid = f_icode in 
	{ INOP, IHALT, IRRMOVQ, IIRMOVQ, IRMMOVQ, IMRMOVQ,
$!FW		  IOPQ, IJXX, ICALL, IRET, IPUSHQ, IPOPQ };
$F		  IOPQ, IJXX, ICALL, IRET, IPUSHQ, IPOPQ, IIADDQ };
$W		  IOPQ, IJXX, ICALL, IRET, IPUSHQ, IPOPQ, IPOP2 };

$a	#/* $begin pipe-f_stat-hcl */
# Determine status code for fetched instruction
word f_stat = [
	imem_error: SADR;
	!instr_valid : SINS;
	f_icode == IHALT : SHLT;
	1 : SAOK;
];
$a	#/* $end pipe-f_stat-hcl */

# Does fetched instruction require a regid byte?
bool need_regids =
	f_icode in { IRRMOVQ, IOPQ, IPUSHQ, IPOPQ, 
$W			     IPOP2,
$!F			     IIRMOVQ, IRMMOVQ, IMRMOVQ };
$F			     IIRMOVQ, IRMMOVQ, IMRMOVQ, IIADDQ };

# Does fetched instruction require a constant word?
bool need_valC =
$!F		f_icode in { IIRMOVQ, IRMMOVQ, IMRMOVQ, IJXX, ICALL };
$F		f_icode in { IIRMOVQ, IRMMOVQ, IMRMOVQ, IJXX, ICALL, IIADDQ };

# Predict next value of PC
$a	#/* $begin pipe-f_predPC-hcl */
word f_predPC = [
$n		# BNT: This is where you'll change the branch prediction rule
$t		# BBTFNT: This is where you'll change the branch prediction rule
$!TN		f_icode in { IJXX, ICALL } : f_valC;
$N		# BNT: Revised branch prediction rule:
$N		#   Unconditional branch is taken, others not taken
$N		f_icode == IJXX && f_ifun == UNCOND : f_valC;
$NT		f_icode in { ICALL } : f_valC;
$T		f_icode == IJXX && f_ifun == UNCOND : f_valC; # Unconditional branch
$T		f_icode == IJXX && f_valC < f_valP : f_valC; # Backward branch
$Ww		## 1W: Want to refetch popq one time
$W		# (on second time f_icode will be IPOP2). Refetch popq
$W		f_icode == IPOPQ : f_pc;  
$T		# BBTFNT: Forward conditional branches will default to valP
	1 : f_valP;
];
$a	#/* $end pipe-f_predPC-hcl */
$a	#/* $end pipe-fetch-logic-hcl */
$a	#/* $end pipe-fetch-all-hcl */

################ Decode Stage ######################################

$wW	## W1: Strategy.  Decoding of popq rA should be treated the same
$wW	## as would iaddq $8, %rsp
$wW	## Decoding of pop2 rA treated same as mrmovq -8(%rsp), rA

## What register should be used as the A source?
$a	#/* $begin pipe-d_srcA-hcl */
word d_srcA = [
	D_icode in { IRRMOVQ, IRMMOVQ, IOPQ, IPUSHQ  } : D_rA;
	D_icode in { IPOPQ, IRET } : RRSP;
	1 : RNONE; # Don't need register
];
$a	#/* $end pipe-d_srcA-hcl */

## What register should be used as the B source?
word d_srcB = [
$!F		D_icode in { IOPQ, IRMMOVQ, IMRMOVQ  } : D_rB;
$F		D_icode in { IOPQ, IRMMOVQ, IMRMOVQ, IIADDQ  } : D_rB;
$!W		D_icode in { IPUSHQ, IPOPQ, ICALL, IRET } : RRSP;
$W		D_icode in { IPUSHQ, IPOPQ, ICALL, IRET, IPOP2 } : RRSP;
	1 : RNONE;  # Don't need register
];

## What register should be used as the E destination?
$a	#/* $begin pipe-d_dstE-hcl */
word d_dstE = [
$!F		D_icode in { IRRMOVQ, IIRMOVQ, IOPQ} : D_rB;
$F		D_icode in { IRRMOVQ, IIRMOVQ, IOPQ, IIADDQ } : D_rB;
$!F		D_icode in { IPUSHQ, IPOPQ, ICALL, IRET } : RRSP;
$F		D_icode in { IPUSHQ, IPOPQ, ICALL, IRET } : RRSP;
	1 : RNONE;  # Don't write any register
];
$a	#/* $end pipe-d_dstE-hcl */

## What register should be used as the M destination?
word d_dstM = [
$!W		D_icode in { IMRMOVQ, IPOPQ } : D_rA;
$W		D_icode in { IMRMOVQ, IPOP2 } : D_rA;
	1 : RNONE;  # Don't write any register
];

## What should be the A value?
$!bsS	## Forward into decode stage for valA
$a	#/* $begin pipe-nobypass-hcl */
$a	#/* $begin pipe-d_valA-hcl */
$sS	##  DO NOT MODIFY THE FOLLOWING CODE.
$bsS	## No forwarding.  valA is either valP or value from register file
word d_valA = [
	D_icode in { ICALL, IJXX } : D_valP; # Use incremented PC
$!bsS		d_srcA == e_dstE : e_valE;    # Forward valE from execute
$!bsS		d_srcA == M_dstM : m_valM;    # Forward valM from memory
$!bsS		d_srcA == M_dstE : M_valE;    # Forward valE from memory
$!bsS		d_srcA == W_dstM : W_valM;    # Forward valM from write back
$!bsS		d_srcA == W_dstE : W_valE;    # Forward valE from write back
	1 : d_rvalA;  # Use value read from register file
];
$a	#/* $end pipe-d_valA-hcl */

$!bsS## Forward into decode stage for valB
$a	#/* $begin pipe-d_valB-hcl */
$!bsS	word d_valB = [
$!bsS		d_srcB == e_dstE : e_valE;    # Forward valE from execute
$!bsS		d_srcB == M_dstM : m_valM;    # Forward valM from memory
$!bsS		d_srcB == M_dstE : M_valE;    # Forward valE from memory
$!bsS		d_srcB == W_dstM : W_valM;    # Forward valM from write back
$!bsS		d_srcB == W_dstE : W_valE;    # Forward valE from write back
$!bsS		1 : d_rvalB;  # Use value read from register file
$!bsS	];
$bsS	## No forwarding.  valB is value from register file
$bsS	word d_valB = d_rvalB;
$a	#/* $end pipe-d_valB-hcl */
$a	#/* $end pipe-nobypass-hcl */

################ Execute Stage #####################################
$nNtT	
$nN	# BNT: When some branches are predicted as not-taken, you need some
$tT	# BBTFNT: When some branches are predicted as not-taken, you need some
$ntNT	# way to get valC into pipeline register M, so that
$ntNT	# you can correct for a mispredicted branch.
$NT	# One way to do this is to run valC through the ALU, adding 0
$NT	# so that valC will end up in M_valE

## Select input A to ALU
word aluA = [
	E_icode in { IRRMOVQ, IOPQ } : E_valA;
$!FNT		E_icode in { IIRMOVQ, IRMMOVQ, IMRMOVQ } : E_valC;
$F		E_icode in { IIRMOVQ, IRMMOVQ, IMRMOVQ, IIADDQ } : E_valC;
$N		# BNT: Use ALU to pass E_valC to M_valE
$T		# BBTFNT: Use ALU to pass E_valC to M_valE
$NT		E_icode in { IIRMOVQ, IRMMOVQ, IMRMOVQ, IJXX } : E_valC;
$!W		E_icode in { ICALL, IPUSHQ } : -8;
$W		E_icode in { ICALL, IPUSHQ, IPOP2 } : -8;
$!F		E_icode in { IRET, IPOPQ } : 8;
$F		E_icode in { IRET, IPOPQ } : 8;
	# Other instructions don't need ALU
];

## Select input B to ALU
word aluB = [
	E_icode in { IRMMOVQ, IMRMOVQ, IOPQ, ICALL, 
$!FW			     IPUSHQ, IRET, IPOPQ } : E_valB;
$F			     IPUSHQ, IRET, IPOPQ, IIADDQ } : E_valB;
$W			     IPUSHQ, IRET, IPOPQ, IPOP2 } : E_valB;
$N		# BNT: Add 0 to valC
$T		# BBTFNT: Add 0 to valC
$!NT		E_icode in { IRRMOVQ, IIRMOVQ } : 0;
$NT		E_icode in { IRRMOVQ, IIRMOVQ, IJXX } : 0;
	# Other instructions don't need ALU
];

## Set the ALU function
word alufun = [
	E_icode == IOPQ : E_ifun;
	1 : ALUADD;
];

$a	#/* $begin pipe-set_cc-hcl */
## Should the condition codes be updated?
$!F	bool set_cc = E_icode == IOPQ &&
$F	bool set_cc = E_icode in { IOPQ, IIADDQ } &&
	# State changes only during normal operation
	!m_stat in { SADR, SINS, SHLT } && !W_stat in { SADR, SINS, SHLT };
$a	#/* $end pipe-set_cc-hcl */

## Generate valA in execute stage
$!lL	word e_valA = E_valA;    # Pass valA through stage
$lL	## LB: With load forwarding, want to insert valM 
$lL	##   from memory stage when appropriate
$l	## Here it is set to the default used in the normal pipeline
$Ll	word e_valA = [
$L		# Forwarding Condition
$L		M_dstM == E_srcA && E_icode in { IPUSHQ, IRMMOVQ } : m_valM;
$lL		1 : E_valA;  # Use valA from stage pipe register
$lL	];

$a	/* $begin pipe-e_dstE-hcl */
## Set dstE to RNONE in event of not-taken conditional move
word e_dstE = [
	E_icode == IRRMOVQ && !e_Cnd : RNONE;
	1 : E_dstE;
];
$a	/* $end pipe-e_dstE-hcl */

################ Memory Stage ######################################

## Select memory address
word mem_addr = [
$!W		M_icode in { IRMMOVQ, IPUSHQ, ICALL, IMRMOVQ } : M_valE;
$W		M_icode in { IRMMOVQ, IPUSHQ, ICALL, IMRMOVQ, IPOP2 } : M_valE;
$!FW		M_icode in { IPOPQ, IRET } : M_valA;
$F		M_icode in { IPOPQ, IRET } : M_valA;
$W		M_icode in { IRET } : M_valA;
	# Other instructions don't need address
];

## Set read control signal
$!FW	bool mem_read = M_icode in { IMRMOVQ, IPOPQ, IRET };
$F	bool mem_read = M_icode in { IMRMOVQ, IPOPQ, IRET };
$W	bool mem_read = M_icode in { IMRMOVQ, IPOP2, IRET };

## Set write control signal
bool mem_write = M_icode in { IRMMOVQ, IPUSHQ, ICALL };

#/* $begin pipe-m_stat-hcl */
## Update the status
word m_stat = [
	dmem_error : SADR;
	1 : M_stat;
];
#/* $end pipe-m_stat-hcl */

$wW	################ Write back stage ##################################
$wW	
$wW	## 1W: For this problem, we introduce a multiplexor that merges
$wW	## valE and valM into a single value for writing to register port E.
$wW	## DO NOT CHANGE THIS LOGIC
$wW
$wW	## Merge both write back sources onto register port E 
$a	/* $begin pipe-1w-wbe-hcl */
## Set E port register ID
$!wW	word w_dstE = W_dstE;
$wW	word w_dstE = [
$wW		## writing from valM
$wW		W_dstM != RNONE : W_dstM;
$wW		1: W_dstE;
$wW	];

## Set E port value
$!wW	word w_valE = W_valE;
$wW	word w_valE = [
$wW		W_dstM != RNONE : W_valM;
$wW		1: W_valE;
$wW	];
$a	/* $end pipe-1w-wbe-hcl */

$a	/* $begin pipe-1w-wbm-hcl */
$wW	## Disable register port M
## Set M port register ID
$!wW	word w_dstM = W_dstM;
$wW	word w_dstM = RNONE;

## Set M port value
$!wW	word w_valM = W_valM;
$wW	word w_valM = 0;
$a	/* $end pipe-1w-wbm-hcl */

## Update processor status
$a	#/* $begin pipe-Stat-hcl */
word Stat = [
	W_stat == SBUB : SAOK;
	1 : W_stat;
];
$a	#/* $end pipe-Stat-hcl */

################ Pipeline Register Control #########################

$S	#/* $begin pipe-nobypass-cntl-hcl */
# Should I stall or inject a bubble into Pipeline Register F?
# At most one of these can be true.
bool F_bubble = 0;
$a	#/* $begin pipe-F-cntl-hcl */
bool F_stall =
$b		0;
$!bsS		# Conditions for a load/use hazard
$l		## Set this to the new load/use condition
$l		0 ||
$!FlLWbsS		E_icode in { IMRMOVQ, IPOPQ } &&
$F		E_icode in { IMRMOVQ, IPOPQ } &&
$L		E_icode in { IMRMOVQ, IPOPQ } &&
$L		 (E_dstM == d_srcB ||
$L	          (E_dstM == d_srcA && !D_icode in { IRMMOVQ, IPUSHQ })) ||
$W		E_icode in { IMRMOVQ, IPOP2 } &&
$!lLbsS		 E_dstM in { d_srcA, d_srcB } ||
$s		# Modify the following to stall the update of pipeline register F
$s		0 ||
$S		# Stall if either operand source is destination of 
$S		# instruction in execute, memory, or write-back stages
$S		d_srcA != RNONE && d_srcA in 
$S		  { E_dstM, e_dstE, M_dstM, M_dstE, W_dstM, W_dstE } ||
$S		d_srcB != RNONE && d_srcB in 
$S		  { E_dstM, e_dstE, M_dstM, M_dstE, W_dstM, W_dstE } ||
$!b		# Stalling at fetch while ret passes through pipeline
$!b		IRET in { D_icode, E_icode, M_icode };
$a	#/* $end pipe-F-cntl-hcl */

# Should I stall or inject a bubble into Pipeline Register D?
# At most one of these can be true.
$a	#/* $begin pipe-D-stall-hcl */
bool D_stall = 
$b		0;
$!bsS		# Conditions for a load/use hazard
$l		## Set this to the new load/use condition
$l		0; 
$!lFBWbsS		E_icode in { IMRMOVQ, IPOPQ } &&
$F		E_icode in { IMRMOVQ, IPOPQ } &&
$L		E_icode in { IMRMOVQ, IPOPQ } &&
$L		 (E_dstM == d_srcB ||
$L	          (E_dstM == d_srcA && !D_icode in { IRMMOVQ, IPUSHQ }));
$W		E_icode in { IMRMOVQ, IPOP2 } &&
$!bsSlL		 E_dstM in { d_srcA, d_srcB };
$s		# Modify the following to stall the instruction in decode
$s		0;
$S		# Stall if either operand source is destination of 
$S		# instruction in execute, memory, or write-back stages
$S		# but not part of mispredicted branch
$S		!(E_icode == IJXX && !e_Cnd) &&
$S		 (d_srcA != RNONE && d_srcA in 
$S		    { E_dstM, e_dstE, M_dstM, M_dstE, W_dstM, W_dstE } ||
$S		  d_srcB != RNONE && d_srcB in 
$S		    { E_dstM, e_dstE, M_dstM, M_dstE, W_dstM, W_dstE });
$a	#/* $end pipe-D-stall-hcl */

$a	#/* $begin pipe-D-bubble-hcl */
bool D_bubble =
$b		0;
$!b		# Mispredicted branch
$N		# BNT: Changed misprediction condition
$!bNT		(E_icode == IJXX && !e_Cnd) ||
$N		(E_icode == IJXX && E_ifun != UNCOND && e_Cnd) ||
$t		# BBTFNT: This condition will change
$T		# BBTFNT: Changed misprediction condition
$T		(E_icode == IJXX && E_ifun != UNCOND &&
$T	          (E_valC < E_valA && !e_Cnd || E_valC >= E_valA && e_Cnd)) ||
$!b		# Stalling at fetch while ret passes through pipeline
$!bsS		# but not condition for a load/use hazard
$!bFW		!(E_icode in { IMRMOVQ, IPOPQ } && E_dstM in { d_srcA, d_srcB }) &&
$w		# 1W: This condition will change
$W		# 1W: Changed Load/Use condition
$W		!(E_icode in { IMRMOVQ, IPOP2 } && E_dstM in { d_srcA, d_srcB }) &&
$F		!(E_icode in { IMRMOVQ, IPOPQ } && E_dstM in { d_srcA, d_srcB }) &&
$sS		# but not condition for a generate/use hazard
$s		!0 &&
$S		!(d_srcA != RNONE && d_srcA in 
$S		   { E_dstM, e_dstE, M_dstM, M_dstE, W_dstM, W_dstE } ||
$S		  d_srcB != RNONE && d_srcB in 
$S		   { E_dstM, e_dstE, M_dstM, M_dstE, W_dstM, W_dstE }) &&
$!b		  IRET in { D_icode, E_icode, M_icode };
$a	#/* $end pipe-D-bubble-hcl */

# Should I stall or inject a bubble into Pipeline Register E?
# At most one of these can be true.
bool E_stall = 0;
$a	#/* $begin pipe-E-bubble-hcl */
bool E_bubble =
$b		0;
$!b		# Mispredicted branch
$N		# BNT: Changed misprediction condition
$!bNT		(E_icode == IJXX && !e_Cnd) ||
$N		(E_icode == IJXX && E_ifun != UNCOND && e_Cnd) ||
$t		# BBTFNT: This condition will change
$T		# BBTFNT: Changed misprediction condition
$T		(E_icode == IJXX && E_ifun != UNCOND &&
$T	          (E_valC < E_valA && !e_Cnd || E_valC >= E_valA && e_Cnd)) ||
$!bsS		# Conditions for a load/use hazard
$l		## Set this to the new load/use condition
$l		0;
$!FlLWbsS		E_icode in { IMRMOVQ, IPOPQ } &&
$F		E_icode in { IMRMOVQ, IPOPQ } &&
$L		E_icode in { IMRMOVQ, IPOPQ } &&
$L		 (E_dstM == d_srcB ||
$L	          (E_dstM == d_srcA && !D_icode in { IRMMOVQ, IPUSHQ }));
$W		E_icode in { IMRMOVQ, IPOP2 } &&
$!lLbsS		 E_dstM in { d_srcA, d_srcB};
$s		# Modify the following to inject bubble into the execute stage
$s		0;
$S		  # Inject bubble if either operand source is destination of 
$S		  # instruction in execute, memory, or write back stages
$S		  d_srcA != RNONE && 
$S		    d_srcA in { E_dstM, e_dstE, M_dstM, M_dstE, W_dstM, W_dstE } ||
$S		  d_srcB != RNONE && 
$S		    d_srcB in { E_dstM, e_dstE, M_dstM, M_dstE, W_dstM, W_dstE };
$a	#/* $end pipe-E-bubble-hcl */

# Should I stall or inject a bubble into Pipeline Register M?
# At most one of these can be true.
bool M_stall = 0;
$a	#/* $begin pipe-M-bubble-hcl */
# Start injecting bubbles as soon as exception passes through memory stage
bool M_bubble = m_stat in { SADR, SINS, SHLT } || W_stat in { SADR, SINS, SHLT };
$a	#/* $end pipe-M-bubble-hcl */

# Should I stall or inject a bubble into Pipeline Register W?
$a	#/* $begin pipe-W-stall-hcl */
bool W_stall = W_stat in { SADR, SINS, SHLT };
$a	#/* $end pipe-W-stall-hcl */
bool W_bubble = 0;
$S	#/* $end pipe-nobypass-cntl-hcl */
$a	#/* $end pipe--hcl */
#/* $end pipe-all-hcl */
