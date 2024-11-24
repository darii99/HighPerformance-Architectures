	.arch armv8-a
	.file	"multiply.c"
	.text
	.align	2
	.p2align 3,,7
	.global	mult_std
	.type	mult_std, %function
mult_std:
	cmp	w3, 0
	ble	.L1
	add	x5, x0, 16
	add	x4, x2, 16
	cmp	x2, x5
	add	x5, x1, 16
	ccmp	x0, x4, 2, cc
	ccmp	w3, 7, 0, cs
	cset	w6, hi
	cmp	x5, x2
	ccmp	x1, x4, 2, hi
	cset	w4, cs
	tst	w6, w4
	beq	.L9
	neg	x5, x0, lsr 2
	mov	w7, 0
	ands	w5, w5, 3
	beq	.L4
	ldr	s0, [x0]
	mov	w7, 1
	ldr	s1, [x1]
	cmp	w5, w7
	fmul	s0, s0, s1
	str	s0, [x2]
	beq	.L4
	ldr	s0, [x0, 4]
	mov	w7, 2
	ldr	s1, [x1, 4]
	cmp	w5, 3
	fmul	s0, s0, s1
	str	s0, [x2, 4]
	bne	.L4
	ldr	s0, [x0, 8]
	mov	w7, w5
	ldr	s1, [x1, 8]
	fmul	s0, s0, s1
	str	s0, [x2, 8]
.L4:
	sub	w11, w3, w5
	ubfiz	x5, x5, 2, 2
	add	x10, x0, x5
	add	x9, x1, x5
	lsr	w8, w11, 2
	add	x5, x2, x5
	mov	x4, 0
	mov	w6, 0
	.p2align 3
.L6:
	ldr	q0, [x9, x4]
	add	w6, w6, 1
	ldr	q1, [x10, x4]
	cmp	w8, w6
	fmul	v0.4s, v0.4s, v1.4s
	str	q0, [x5, x4]
	add	x4, x4, 16
	bhi	.L6
	and	w5, w11, -4
	add	w4, w5, w7
	cmp	w11, w5
	beq	.L1
	sxtw	x6, w4
	add	w5, w4, 1
	cmp	w3, w5
	lsl	x5, x6, 2
	ldr	s0, [x0, x6, lsl 2]
	ldr	s1, [x1, x6, lsl 2]
	fmul	s0, s0, s1
	str	s0, [x2, x6, lsl 2]
	ble	.L1
	add	x6, x5, 4
	add	w7, w4, 2
	cmp	w3, w7
	ldr	s0, [x0, x6]
	ldr	s1, [x1, x6]
	fmul	s0, s0, s1
	str	s0, [x2, x6]
	ble	.L1
	add	x6, x5, 8
	add	w7, w4, 3
	cmp	w3, w7
	ldr	s0, [x0, x6]
	ldr	s1, [x1, x6]
	fmul	s0, s0, s1
	str	s0, [x2, x6]
	ble	.L1
	add	x6, x5, 12
	add	w7, w4, 4
	cmp	w3, w7
	ldr	s0, [x0, x6]
	ldr	s1, [x1, x6]
	fmul	s0, s0, s1
	str	s0, [x2, x6]
	ble	.L1
	add	x6, x5, 16
	add	w4, w4, 5
	cmp	w3, w4
	ldr	s0, [x0, x6]
	ldr	s1, [x1, x6]
	fmul	s0, s0, s1
	str	s0, [x2, x6]
	ble	.L1
	add	x5, x5, 20
	ldr	s0, [x0, x5]
	ldr	s1, [x1, x5]
	fmul	s0, s0, s1
	str	s0, [x2, x5]
.L1:
	ret
	.p2align 2
.L9:
	mov	x4, 0
	.p2align 3
.L3:
	ldr	s0, [x0, x4, lsl 2]
	ldr	s1, [x1, x4, lsl 2]
	fmul	s0, s0, s1
	str	s0, [x2, x4, lsl 2]
	add	x4, x4, 1
	cmp	w3, w4
	bgt	.L3
	ret
	.size	mult_std, .-mult_std
	.align	2
	.p2align 3,,7
	.global	mult_vect
	.type	mult_vect, %function
mult_vect:
	cmp	w3, 0
	ble	.L18
	sub	w3, w3, #1
	add	x4, x0, 16
	lsr	w3, w3, 2
	add	x3, x4, x3, uxtw 4
	.p2align 3
.L20:
	ldr	q1, [x0], 16
	ldr	q0, [x1], 16
	cmp	x0, x3
	fmul	v0.4s, v0.4s, v1.4s
	str	q0, [x2], 16
	bne	.L20
.L18:
	ret
	.size	mult_vect, .-mult_vect
	.section	.text.startup,"ax",@progbits
	.align	2
	.p2align 3,,7
	.global	main
	.type	main, %function
main:
	stp	x29, x30, [sp, -144]!
	mov	x0, 16
	add	x29, sp, 0
	stp	x21, x22, [sp, 32]
	adrp	x21, :got:__stack_chk_guard
	stp	x23, x24, [sp, 48]
	adrp	x23, .LANCHOR0
	ldr	x1, [x21, #:got_lo12:__stack_chk_guard]
	ldr	w24, [x23, #:lo12:.LANCHOR0]
	ldr	x2, [x1]
	str	x2, [x29, 136]
	mov	x2,0
	stp	x19, x20, [sp, 16]
	str	d8, [sp, 64]
	sbfiz	x22, x24, 2, 32
	mov	x1, x22
	bl	aligned_alloc
	mov	x1, x22
	mov	x19, x0
	mov	x0, 16
	bl	aligned_alloc
	mov	x1, x22
	mov	x20, x0
	mov	x0, 16
	bl	aligned_alloc
	cmp	w24, 0
	mov	x22, x0
	ble	.L23
	sub	w0, w24, #1
	cmp	w0, 2
	bls	.L34
	adrp	x5, .LC0
	adrp	x4, .LC1
	adrp	x3, .LC2
	adrp	x2, .LC3
	adrp	x1, .LC4
	adrp	x0, .LC5
	ldr	q1, [x5, #:lo12:.LC0]
	movi	v17.4s, 0x4
	ldr	q5, [x4, #:lo12:.LC1]
	ldr	q16, [x3, #:lo12:.LC2]
	ldr	q4, [x2, #:lo12:.LC3]
	lsr	w2, w24, 2
	ldr	q8, [x1, #:lo12:.LC4]
	mov	w1, 0
	ldr	q7, [x0, #:lo12:.LC5]
	mov	x0, 0
	.p2align 3
.L25:
	smull2	v2.2d, v1.4s, v5.4s
	add	w1, w1, 1
	smull	v0.2d, v1.2s, v5.2s
	cmp	w2, w1
	smull	v3.2d, v1.2s, v4.2s
	smull2	v6.2d, v1.4s, v4.4s
	uzp2	v0.4s, v0.4s, v2.4s
	uzp2	v3.4s, v3.4s, v6.4s
	add	v0.4s, v0.4s, v1.4s
	sshr	v3.4s, v3.4s, 6
	sshr	v2.4s, v0.4s, 6
	mov	v0.16b, v1.16b
	mls	v0.4s, v3.4s, v8.4s
	mov	v3.16b, v0.16b
	shl	v0.4s, v2.4s, 7
	scvtf	v3.4s, v3.4s
	sub	v0.4s, v0.4s, v2.4s
	fmul	v2.4s, v3.4s, v7.4s
	sub	v0.4s, v1.4s, v0.4s
	add	v1.4s, v1.4s, v17.4s
	str	q2, [x20, x0]
	scvtf	v0.4s, v0.4s
	fmul	v0.4s, v0.4s, v16.4s
	str	q0, [x19, x0]
	add	x0, x0, 16
	bhi	.L25
	and	w0, w24, -4
	cmp	w24, w0
	beq	.L23
.L24:
	mov	w5, 127
	mov	w4, 331
	mov	w6, 12897
	mov	w3, 7130
	udiv	w2, w0, w5
	movk	w6, 0x3e15, lsl 16
	movk	w3, 0x3dfc, lsl 16
	fmov	s3, w6
	udiv	w1, w0, w4
	fmov	s2, w3
	sbfiz	x3, x0, 2, 32
	add	w6, w0, 1
	msub	w2, w2, w5, w0
	cmp	w24, w6
	msub	w1, w1, w4, w0
	scvtf	s1, w2
	scvtf	s0, w1
	fmul	s1, s1, s3
	fmul	s0, s0, s2
	str	s1, [x19, x3]
	str	s0, [x20, x3]
	ble	.L23
	udiv	w2, w6, w5
	add	x7, x3, 4
	add	w0, w0, 2
	udiv	w1, w6, w4
	cmp	w24, w0
	msub	w2, w2, w5, w6
	msub	w1, w1, w4, w6
	scvtf	s1, w2
	scvtf	s0, w1
	fmul	s1, s1, s3
	fmul	s0, s0, s2
	str	s1, [x19, x7]
	str	s0, [x20, x7]
	ble	.L23
	udiv	w2, w0, w5
	add	x3, x3, 8
	udiv	w1, w0, w4
	msub	w5, w2, w5, w0
	msub	w0, w1, w4, w0
	scvtf	s1, w5
	scvtf	s0, w0
	fmul	s1, s1, s3
	fmul	s0, s0, s2
	str	s1, [x19, x3]
	str	s0, [x20, x3]
.L23:
	add	x1, x29, 88
	mov	w0, 1
	bl	clock_gettime
	ldr	w2, [x23, #:lo12:.LANCHOR0]
	cmp	w2, 0
	ble	.L27
	sub	w0, w2, #1
	cmp	w0, 2
	bls	.L35
	lsr	w3, w2, 2
	mov	x0, 0
	mov	w1, 0
	.p2align 3
.L29:
	ldr	q0, [x20, x0]
	add	w1, w1, 1
	ldr	q1, [x19, x0]
	cmp	w3, w1
	fmul	v0.4s, v0.4s, v1.4s
	str	q0, [x22, x0]
	add	x0, x0, 16
	bhi	.L29
	and	w1, w2, -4
	cmp	w1, w2
	beq	.L27
.L28:
	sbfiz	x0, x1, 2, 32
	add	w3, w1, 1
	cmp	w3, w2
	ldr	s0, [x19, x0]
	ldr	s1, [x20, x0]
	fmul	s0, s0, s1
	str	s0, [x22, x0]
	bge	.L27
	add	x3, x0, 4
	add	w1, w1, 2
	cmp	w2, w1
	ldr	s0, [x19, x3]
	ldr	s1, [x20, x3]
	fmul	s0, s0, s1
	str	s0, [x22, x3]
	ble	.L27
	add	x0, x0, 8
	ldr	s0, [x20, x0]
	ldr	s1, [x19, x0]
	fmul	s0, s0, s1
	str	s0, [x22, x0]
.L27:
	add	x1, x29, 104
	mov	w0, 1
	bl	clock_gettime
	ldr	w0, [x23, #:lo12:.LANCHOR0]
	cmp	w0, 0
	ble	.L31
	sub	w1, w0, #1
	mov	x4, 16
	mov	x0, x19
	mov	x3, x20
	lsr	w1, w1, 2
	mov	x2, x22
	add	x1, x4, x1, uxtw 4
	add	x1, x1, x19
	.p2align 3
.L32:
	ldr	q0, [x0], 16
	ldr	q1, [x3], 16
	cmp	x0, x1
	fmul	v0.4s, v0.4s, v1.4s
	str	q0, [x2], 16
	bne	.L32
.L31:
	add	x1, x29, 120
	mov	w0, 1
	bl	clock_gettime
	ldp	x4, x3, [x29, 104]
	adrp	x5, .LC6
	ldp	x2, x0, [x29, 120]
	ldr	x1, [x29, 88]
	sub	x0, x0, x4
	sub	x2, x2, x4
	sub	x3, x3, x1
	ldr	d3, [x5, #:lo12:.LC6]
	scvtf	d8, x0
	sub	x1, x4, x1
	scvtf	d2, x3
	scvtf	d1, x2
	scvtf	d0, x1
	adrp	x4, .LC7
	mov	w0, 1
	add	x1, x4, :lo12:.LC7
	fmadd	d8, d8, d3, d1
	fmadd	d0, d2, d3, d0
	bl	__printf_chk
	fmov	d0, d8
	adrp	x1, .LC8
	add	x1, x1, :lo12:.LC8
	mov	w0, 1
	bl	__printf_chk
	mov	x0, x19
	bl	free
	mov	x0, x20
	bl	free
	mov	x0, x22
	bl	free
	ldr	x21, [x21, #:got_lo12:__stack_chk_guard]
	mov	w0, 0
	ldr	x2, [x29, 136]
	ldr	x1, [x21]
	eor	x1, x2, x1
	cbnz	x1, .L40
	ldp	x19, x20, [sp, 16]
	ldp	x21, x22, [sp, 32]
	ldp	x23, x24, [sp, 48]
	ldr	d8, [sp, 64]
	ldp	x29, x30, [sp], 144
	ret
.L35:
	mov	w1, 0
	b	.L28
.L34:
	mov	w0, 0
	b	.L24
.L40:
	bl	__stack_chk_fail
	.size	main, .-main
	.section	.rodata.cst16,"aM",@progbits,16
	.align	4
.LC0:
	.word	0
	.word	1
	.word	2
	.word	3
	.align	4
.LC1:
	.word	-2130574327
	.word	-2130574327
	.word	-2130574327
	.word	-2130574327
	.align	4
.LC2:
	.word	1041576545
	.word	1041576545
	.word	1041576545
	.word	1041576545
	.align	4
.LC3:
	.word	830446849
	.word	830446849
	.word	830446849
	.word	830446849
	.align	4
.LC4:
	.word	331
	.word	331
	.word	331
	.word	331
	.align	4
.LC5:
	.word	1039932378
	.word	1039932378
	.word	1039932378
	.word	1039932378
	.section	.rodata.cst8,"aM",@progbits,8
	.align	3
.LC6:
	.word	3894859413
	.word	1041313291
	.section	.text.startup
	.global	num
	.comm	r,8,8
	.comm	b,8,8
	.comm	a,8,8
	.data
	.align	2
	.set	.LANCHOR0,. + 0
	.type	num, %object
	.size	num, 4
num:
	.word	100000000
	.section	.rodata.str1.8,"aMS",@progbits,1
	.align	3
.LC7:
	.string	"Elapsed time std: %f\n"
	.zero	2
.LC8:
	.string	"Elapsed time vec: %f\n"
	.ident	"GCC: (Ubuntu/Linaro 7.5.0-3ubuntu1~18.04) 7.5.0"
	.section	.note.GNU-stack,"",@progbits
