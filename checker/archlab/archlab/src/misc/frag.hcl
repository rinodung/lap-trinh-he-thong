# Simple HCL expresssions

boolsig a 'a'
boolsig b 'b'

#/* $begin bit-equal-hcl */
bool eq = (a && b) || (!a && !b);
#/* $end bit-equal-hcl */

#/* $begin bit-xor-hcl */
bool xor = (!a && b) || (a && !b);
#/* $end bit-xor-hcl */

boolsig s 's'
#/* $begin bit-mux-hcl */
bool out = (s && a) || (!s && b);
#/* $end bit-mux-hcl */

wordsig A 'A'
wordsig B 'B'

#/* $begin word-equal-hcl */
bool Eq = (A == B);
#/* $end word-equal-hcl */

#/* $begin word-mux-hcl */
word Out = [
	s: A;
	1: B;
];
#/* $end word-mux-hcl */

boolsig s1 's1'
boolsig s0 's0'
wordsig C 'C'
wordsig D 'D'

#/* $begin word-mux4-hcl */
word Out4 = [
	!s1 && !s0 : A;	# 00
	!s1        : B;	# 01
	!s0  	   : C;	# 10
	1          : D;	# 11
];
#/* $end word-mux4-hcl */

#/* $begin word-min3-hcl */
word Min3 = [
	A <= B && A <= C : A;
	B <= A && B <= C : B;
	1                : C;
];
#/* $end word-min3-hcl */


word Min3 = [
	A <= B && A <= C : A;
#/* $begin word-min3-opt-hcl */
	B <= C           : B;
#/* $end word-min3-opt-hcl */
	1                : C;
];


#/* $begin word-med3-hcl */
word Med3 = [
	A <= B && B <= C : B;
	C <= B && B <= A : B;
	B <= A && A <= C : A;
	C <= A && A <= B : A;
	1                : C;
];
#/* $end word-med3-hcl */

wordsig code 'code'

#/* $begin cntl-gene-hcl */
bool s1 = code == 2 || code == 3;

bool s0 = code == 1 || code == 3;
#/* $end cntl-gene-hcl */


#/* $begin cntl-gens-hcl */
bool s1 = code in { 2, 3 };

bool s0 = code in { 1, 3 };
#/* $end cntl-gens-hcl */
