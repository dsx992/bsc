	.file	"arena.c"
	.option nopic
	.attribute arch, "rv32i2p1_m2p0_a2p1_f2p2_d2p2_c2p0_zicsr2p0_zifencei2p0_zmmul1p0_zaamo1p0_zalrsc1p0_zca1p0_zcd1p0_zcf1p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.globl	scratch_arena
	.data
	.align	2
	.type	scratch_arena, @object
	.size	scratch_arena, 12
scratch_arena:
	.word	4096
	.word	8192
	.word	0
	.text
	.align	1
	.globl	main
	.type	main, @function
main:
	addi	sp,sp,-16
	sw	ra,12(sp)
	sw	s0,8(sp)

	addi	s0,sp,16

	lui	a5,%hi(scratch_arena)
	addi	a5,a5,%lo(scratch_arena)

	lw	a5,8(a5)
	addi	a4,a5,16
	lui	a5,%hi(scratch_arena)
	addi	a5,a5,%lo(scratch_arena)
	sw	a4,8(a5)

	li	a5,0
	mv	a0,a5
	lw	ra,12(sp)
	lw	s0,8(sp)
	addi	sp,sp,16
	jr	ra
	.size	main, .-main
	.ident	"GCC: (g5115c7e44) 15.2.0"
	.section	.note.GNU-stack,"",@progbits
