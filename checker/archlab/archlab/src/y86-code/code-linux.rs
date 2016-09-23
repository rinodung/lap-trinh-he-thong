	.file	"code-linux.c"
	.text
	.globl	sum
	.type	sum, @function
sum:
.LFB34:
	.cfi_startproc
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
	.cfi_endproc
.LFE34:
	.size	sum, .-sum
	.globl	rsum
	.type	rsum, @function
rsum:
.LFB35:
	.cfi_startproc
	movl	$0, %eax
	testq	%rsi, %rsi
	jle	.L9
	pushq	%rbx
	.cfi_def_cfa_offset 16
	.cfi_offset 3, -16
	movq	(%rdi), %rbx
	subq	$1, %rsi
	addq	$8, %rdi
	call	rsum
	addq	%rbx, %rax
	popq	%rbx
	.cfi_restore 3
	.cfi_def_cfa_offset 8
.L9:
	rep; ret
	.cfi_endproc
.LFE35:
	.size	rsum, .-rsum
	.section	.rodata.str1.1,"aMS",@progbits,1
.LC0:
	.string	"0x%lx\n"
	.text
	.globl	prog
	.type	prog, @function
prog:
.LFB36:
	.cfi_startproc
	subq	$8, %rsp
	.cfi_def_cfa_offset 16
	movl	$4, %esi
	movl	$array, %edi
	call	sum
	movq	%rax, %rdx
	movl	$.LC0, %esi
	movl	$1, %edi
	movl	$0, %eax
	call	__printf_chk
	movl	$0, %edi
	call	exit
	.cfi_endproc
.LFE36:
	.size	prog, .-prog
	.globl	main
	.type	main, @function
main:
.LFB37:
	.cfi_startproc
	subq	$8, %rsp
	.cfi_def_cfa_offset 16
	movl	$0, %eax
	call	prog
	.cfi_endproc
.LFE37:
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
