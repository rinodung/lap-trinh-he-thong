	.file	"code-linux.c"
	.text
	.globl	sum
	.type	sum, @function
sum:
	movl	$0, %eax
	jmp	.L2
.L3:
	addq	(%rdi), %rax
	addq	$8, %rdi
	subq	$1, %rsi
.L2:
	testq	%rsi, %rsi
	jne	.L3
	rep; ret
	.size	sum, .-sum
	.globl	rsum
	.type	rsum, @function
rsum:
	movl	$0, %eax
	testq	%rsi, %rsi
	jle	.L9
	pushq	%rbx
	movq	(%rdi), %rbx
	subq	$1, %rsi
	addq	$8, %rdi
	call	rsum
	addq	%rbx, %rax
	popq	%rbx
.L9:
	rep; ret
	.size	rsum, .-rsum
	.section	.rodata.str1.1,"aMS",@progbits,1
	.string	"0x%lx\n"
	.text
	.globl	prog
	.type	prog, @function
prog:
	subq	$8, %rsp
	movl	$4, %esi
	movl	$array, %edi
	call	sum
	movq	%rax, %rdx
	movl	$1, %edi
	movl	$0, %eax
	call	__printf_chk
	movl	$0, %edi
	call	exit
	.size	prog, .-prog
	.globl	main
	.type	main, @function
main:
	subq	$8, %rsp
	movl	$0, %eax
	call	prog
	.size	main, .-main
	.globl	array
	.data
	.align 32
	.type	array, @object
	.size	array, 32
array:
	.quad	55835426829
	.quad	824646303936
	.quad	12094812457728
	.quad	175924544839680
	.ident	"GCC: (Ubuntu 4.8.1-2ubuntu1~12.04) 4.8.1"
	.section	.note.GNU-stack,"",@progbits
