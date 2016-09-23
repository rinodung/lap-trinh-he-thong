$c	This is the master .hcl code for the single cycle processor.
$c	It includes both SEQ and SEQ+
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
$c	+: HCL code for SEQ+
$c	f: iaddq problem
$c	F: iaddq solution
$c	r: Conditional move not implemented
#/* $begin seq-all-hcl */
####################################################################
$!+	#  HCL Description of Control for Single Cycle Y86-64 Processor SEQ   #
$+	#  HCL Description of Control for Single Cycle Y86-64 Processor SEQ+  #
#  Copyright (C) Randal E. Bryant, David R. O'Hallaron, 2010       #
####################################################################
$fF	
$f	## Your task is to implement the iaddq instruction
$f	## The file contains a declaration of the icodes
$f	## for iaddq (IIADDQ)
$f	## Your job is to add the rest of the logic to make it work
$F	## This is the solution for the iaddq problem

####################################################################
#    C Include's.  Don't alter these                               #
####################################################################

quote '#include <stdio.h>'
quote '#include "isa.h"'
quote '#include "sim.h"'
quote 'int sim_main(int argc, char *argv[]);'
$!+	quote 'word_t gen_pc(){return 0;}'
$!+	quote 'int main(int argc, char *argv[])'
$!+	quote '  {plusmode=0;return sim_main(argc,argv);}'
$+	quote 'word_t gen_new_pc(){return 0;}'
$+	quote 'int main(int argc, char *argv[])'
$+	quote '  {plusmode=1;return sim_main(argc,argv);}'

####################################################################
#    Declarations.  Do not change/remove/delete any of these       #
####################################################################

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

##### Symbolic represenations of Y86-64 function codes                  #####
wordsig FNONE    'F_NONE'        # Default function code

##### Symbolic representation of Y86-64 Registers referenced explicitly #####
wordsig RRSP     'REG_RSP'    	# Stack Pointer
wordsig RNONE    'REG_NONE'   	# Special value indicating "no register"

##### ALU Functions referenced explicitly                            #####
wordsig ALUADD	'A_ADD'		# ALU should add its arguments

##### Possible instruction status values                             #####
wordsig SAOK	'STAT_AOK'	# Normal execution
wordsig SADR	'STAT_ADR'	# Invalid memory address
wordsig SINS	'STAT_INS'	# Invalid instruction
wordsig SHLT	'STAT_HLT'	# Halt instruction encountered

##### Signals that can be referenced by control logic ####################

$+	##### PC stage inputs			#####
$+	
$+	## All of these values are based on those from previous instruction
$+	wordsig  pIcode 'prev_icode'		# Instr. control code
$+	wordsig  pValC  'prev_valc'		# Constant from instruction
$+	wordsig  pValM  'prev_valm'		# Value read from memory
$+	wordsig  pValP  'prev_valp'		# Incremented program counter
$+	boolsig pCnd 'prev_bcond'		# Condition flag
$+	
$!+	##### Fetch stage inputs		#####
$!+	wordsig pc 'pc'				# Program counter
##### Fetch stage computations		#####
wordsig imem_icode 'imem_icode'		# icode field from instruction memory
wordsig imem_ifun  'imem_ifun' 		# ifun field from instruction memory
wordsig icode	  'icode'		# Instruction control code
wordsig ifun	  'ifun'		# Instruction function
wordsig rA	  'ra'			# rA field from instruction
wordsig rB	  'rb'			# rB field from instruction
wordsig valC	  'valc'		# Constant from instruction
wordsig valP	  'valp'		# Address of following instruction
boolsig imem_error 'imem_error'		# Error signal from instruction memory
boolsig instr_valid 'instr_valid'	# Is fetched instruction valid?

##### Decode stage computations		#####
wordsig valA	'vala'			# Value from register A port
wordsig valB	'valb'			# Value from register B port

##### Execute stage computations	#####
wordsig valE	'vale'			# Value computed by ALU
boolsig Cnd	'cond'			# Branch test

##### Memory stage computations		#####
wordsig valM	'valm'			# Value read from memory
boolsig dmem_error 'dmem_error'		# Error signal from data memory


####################################################################
#    Control Signal Definitions.                                   #
####################################################################

$+	################ Program Counter Computation #######################
$+	
$+	# Compute fetch location for this instruction based on results from
$+	# previous instruction.
$+	
$a	#/* $begin seq-plus-pc-hcl */
$+	word pc = [
$+		# Call.  Use instruction constant
$+		pIcode == ICALL : pValC;
$+		# Taken branch.  Use instruction constant
$+		pIcode == IJXX && pCnd : pValC;
$+		# Completion of RET instruction.  Use value from stack
$+		pIcode == IRET : pValM;
$+		# Default: Use incremented PC
$+		1 : pValP;
$+	];
$+	#/* $end seq-plus-pc-hcl */
$+	
################ Fetch Stage     ###################################

# Determine instruction code
word icode = [
	imem_error: INOP;
	1: imem_icode;		# Default: get from instruction memory
];

# Determine instruction function
word ifun = [
	imem_error: FNONE;
	1: imem_ifun;		# Default: get from instruction memory
];

bool instr_valid = icode in 
	{ INOP, IHALT, IRRMOVQ, IIRMOVQ, IRMMOVQ, IMRMOVQ,
$F		       IIADDQ,
	       IOPQ, IJXX, ICALL, IRET, IPUSHQ, IPOPQ };

# Does fetched instruction require a regid byte?
$a	#/* $begin seq-need_regids-hcl */
bool need_regids =
	icode in { IRRMOVQ, IOPQ, IPUSHQ, IPOPQ, 
$F			     IIADDQ,
		     IIRMOVQ, IRMMOVQ, IMRMOVQ };
$a	#/* $end seq-need_regids-hcl */

# Does fetched instruction require a constant word?
$a	#/* $begin seq-need_valC-hcl */
bool need_valC =
$!F		icode in { IIRMOVQ, IRMMOVQ, IMRMOVQ, IJXX, ICALL };
$F		icode in { IIRMOVQ, IRMMOVQ, IMRMOVQ, IJXX, ICALL, IIADDQ };
$a	#/* $end seq-need_valC-hcl */

################ Decode Stage    ###################################

## What register should be used as the A source?
$a	#/* $begin seq-srcA-hcl */
word srcA = [
	icode in { IRRMOVQ, IRMMOVQ, IOPQ, IPUSHQ  } : rA;
	icode in { IPOPQ, IRET } : RRSP;
	1 : RNONE; # Don't need register
];
$a	#/* $end seq-srcA-hcl */

## What register should be used as the B source?
$a	#/* $begin seq-srcB-hcl */
word srcB = [
	icode in { IOPQ, IRMMOVQ, IMRMOVQ  } : rB;
$F		icode in { IIADDQ  } : rB;	
	icode in { IPUSHQ, IPOPQ, ICALL, IRET } : RRSP;
	1 : RNONE;  # Don't need register
];
$a	#/* $end seq-srcB-hcl */

## What register should be used as the E destination?
$a	#/* $begin seq-dstE-nocmov-hcl */
$a	#/* $begin seq-dstE-cmov-hcl */
$r	# WARNING: Conditional move not implemented correctly here
word dstE = [
$!r		icode in { IRRMOVQ } && Cnd : rB;
$!r		icode in { IIRMOVQ, IOPQ} : rB;
$r		icode in { IRRMOVQ } : rB;
$r		icode in { IIRMOVQ, IOPQ} : rB;
$F		icode in { IIADDQ } : rB;
	icode in { IPUSHQ, IPOPQ, ICALL, IRET } : RRSP;
	1 : RNONE;  # Don't write any register
];
$a	#/* $end seq-dstE-cmov-hcl */
$a	#/* $end seq-dstE-nocmov-hcl */

## What register should be used as the M destination?
$a	#/* $begin seq-dstM-hcl */
word dstM = [
	icode in { IMRMOVQ, IPOPQ } : rA;
	1 : RNONE;  # Don't write any register
];
$a	#/* $end seq-dstM-hcl */

################ Execute Stage   ###################################

## Select input A to ALU
$a	#/* $begin seq-aluA-hcl */
word aluA = [
	icode in { IRRMOVQ, IOPQ } : valA;
	icode in { IIRMOVQ, IRMMOVQ, IMRMOVQ } : valC;
$F		icode in { IIADDQ } : valC;
	icode in { ICALL, IPUSHQ } : -8;
	icode in { IRET, IPOPQ } : 8;
	# Other instructions don't need ALU
];
$a	#/* $end seq-aluA-hcl */

## Select input B to ALU
$a	#/* $begin seq-aluB-hcl */
word aluB = [
	icode in { IRMMOVQ, IMRMOVQ, IOPQ, ICALL, 
		      IPUSHQ, IRET, IPOPQ } : valB;
$F		icode in { IIADDQ } : valB;
	icode in { IRRMOVQ, IIRMOVQ } : 0;
	# Other instructions don't need ALU
];
$a	#/* $end seq-aluB-hcl */

## Set the ALU function
$a	#/* $begin seq-alufun-hcl */
word alufun = [
	icode == IOPQ : ifun;
	1 : ALUADD;
];
$a	#/* $end seq-alufun-hcl */

## Should the condition codes be updated?
$a	#/* $begin seq-set_cc-hcl */
$!F	bool set_cc = icode in { IOPQ };
$F	bool set_cc = icode in { IOPQ, IIADDQ };
$a	#/* $end seq-set_cc-hcl */

################ Memory Stage    ###################################

## Set read control signal
$a	#/* $begin seq-mem_read-hcl */
$!F	bool mem_read = icode in { IMRMOVQ, IPOPQ, IRET };
$F	bool mem_read = icode in { IMRMOVQ, IPOPQ, IRET};
$a	#/* $end seq-mem_read-hcl */

## Set write control signal
$a	#/* $begin seq-mem_write-hcl */
bool mem_write = icode in { IRMMOVQ, IPUSHQ, ICALL };
$a	#/* $end seq-mem_write-hcl */

## Select memory address
$a	#/* $begin seq-mem_addr-hcl */
word mem_addr = [
	icode in { IRMMOVQ, IPUSHQ, ICALL, IMRMOVQ } : valE;
	icode in { IPOPQ, IRET } : valA;
	# Other instructions don't need address
];
$a	#/* $end seq-mem_addr-hcl */

## Select memory input data
$a	#/* $begin seq-mem_data-hcl */
word mem_data = [
	# Value from register
	icode in { IRMMOVQ, IPUSHQ } : valA;
	# Return PC
	icode == ICALL : valP;
	# Default: Don't write anything
];
$a	#/* $end seq-mem_data-hcl */

$a	#/* $begin seq-stat-hcl */
## Determine instruction status
word Stat = [
	imem_error || dmem_error : SADR;
	!instr_valid: SINS;
	icode == IHALT : SHLT;
	1 : SAOK;
];
$a	#/* $end seq-stat-hcl */
$!+	
$!+	################ Program Counter Update ############################
$!+	
$!+	## What address should instruction be fetched at
$!+	
$a	#/* $begin seq-new_pc-hcl */
$!+	word new_pc = [
$!+		# Call.  Use instruction constant
$!+		icode == ICALL : valC;
$!+		# Taken branch.  Use instruction constant
$!+		icode == IJXX && Cnd : valC;
$!+		# Completion of RET instruction.  Use value from stack
$!+		icode == IRET : valM;
$!+		# Default: Use incremented PC
$!+		1 : valP;
$!+	];
$a	#/* $end seq-new_pc-hcl */
#/* $end seq-all-hcl */
