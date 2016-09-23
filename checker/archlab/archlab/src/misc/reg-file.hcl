## HCL description of write-before read register file



## declarations
wordsig valW 'valW'
wordsig dstW 'dstW'
wordsig ivalR 'ivalR'
wordsig srcR 'srcR'
wordsig RNONE 'RNONE'

#/* $begin reg-file-hcl */
## Read port data
word valR = [
	srcR == dstW : valW;
	1 : ivalR;
];

## Internal read address
word isrcR = [
	srcR == dstW : RNONE;
	1 : srcR;
];
#/* $end reg-file-hcl */
