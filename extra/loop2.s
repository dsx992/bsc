	.file	"loop.c"
	.option nopic
	.attribute arch, "rv32i2p1_m2p0_a2p1_f2p2_d2p2_c2p0_zicsr2p0_zifencei2p0_zmmul1p0_zaamo1p0_zalrsc1p0_zca1p0_zcd1p0_zcf1p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.section	.rodata
	.align	2
.LC0:
	.word	1
	.word	2
	.word	3
	.word	4
	.text
	.align	1
	.globl	main
	.type	main, @function
main:
	addi	sp,sp,-48
	sw	ra,44(sp)
	sw	s0,40(sp)
	addi	s0,sp,48
	lui	a5,%hi(.LC0)
	addi	a5,a5,%lo(.LC0)
	lw	a2,0(a5)
	lw	a3,4(a5)
	lw	a4,8(a5)
	sw	a2,-40(s0)
	sw	a3,-36(s0)
	sw	a4,-32(s0)
	lw	a5,12(a5)
	sw	a5,-28(s0)
	sw	zero,-20(s0)
	sw	zero,-24(s0)
	j	.L2

.L3:    (i, sum, len, mt)
        {sum: int, i: nat, len: nat | i < len}
        [s0: int(i) :: int(sum) :: int array(len) :: [noget stack type idk]]
        ->
        [a4: int(i * 2 * 2), a5: mt ptr(int array(len)), s0: mt ptr(int(i) :: int(sum) :: int array(len))]
	lw	a4,-24(s0)      ; i             loads from mt memory a value of type int(i) and kills a4
	addi	a5,s0,-40       ; arr
	slli	a4,a4,2         ; i * 4

	add	a5,a4,a5        ; &arr[i]
	lw	a5,0(a5)        ; arr[i]
	lw	a4,-20(s0)
	add	a5,a4,a5
	sw	a5,-20(s0)
	lw	a5,-24(s0)
	addi	a5,a5,1
	sw	a5,-24(s0)
.L2:
	lw	a4,-24(s0)      ; i
	li	a5,3            ; ARRAY_LEN-ish
	ble	a4,a5,.L3       ; loop
	lw	a5,-20(s0)
	mv	a0,a5
	lw	ra,44(sp)
	lw	s0,40(sp)
	addi	sp,sp,48
	jr	ra
	.size	main, .-main
	.ident	"GCC: (g5115c7e44) 15.2.0"
	.section	.note.GNU-stack,"",@progbits
