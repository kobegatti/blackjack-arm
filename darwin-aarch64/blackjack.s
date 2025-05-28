.section __DATA,__data
	.balign 16
	VALUES:
		.asciz "A23456789TJQKA23456789TJQKA23456789TJQKA23456789TJQK"

	.balign 16
	SUITS:
		.asciz "HHHHHHHHHHHHHDDDDDDDDDDDDDCCCCCCCCCCCCCSSSSSSSSSSSSS"

	.balign 16
	buffer: .skip 16
	buffer_len = .-buffer

	.equ DECK_SIZE, 52


.text 
.include "utilmacro.s"

.macro PRINT_CARD_VALUE index
	adrp x1, VALUES@PAGE
	add x1, x1, VALUES@PAGEOFF

	mov x0, #1 // stdout
	add x1, x1, \index // address of value at index
	mov x2, #1 // strlen
	mov x16, #4 // macOS write syscall
	svc #0
.endmacro

.macro PRINT_CARD_SUIT index
	adrp x1, SUITS@PAGE
	add x1, x1, SUITS@PAGEOFF

	mov x0, #1 // stdout
	add x1, x1, \index // address of value at index
	mov x2, #1 // strlen
	mov x16, #4 // macOS write syscall
	svc #0
.endmacro

.extern _getentropy

.global _init_deck
.global _shuffle_deck
.global _reset_deck_index
.global _get_random_number
.global _draw_card
.global _print_hand
.global _calc_total
.global _get_card_value
.global _get_card_rank
.global _sub_chips
.global _add_chips

// Input: x0=address of 52-byte array
// Output: x0=same address with values initialized from 0 to 51
_init_deck:
	stp fp, lr, [sp, #-16]!
	mov fp, sp

	mov x1, #0 // loop counter (i)
	new_deck_loop:
		strb w1, [x0, x1] // array[i] = i
		
		add x1, x1, #1 // i++
		cmp x1, DECK_SIZE
		blt new_deck_loop // if x0 < 52, then loop... else exit

	ldp fp, lr, [sp], #16
	ret

// Input: x0=address of 52-byte array where each value
// 			   is between 0 and 51 
// Output: x0=same address with elements shuffled
_shuffle_deck:
	stp fp, lr, [sp, #-16]!
	mov fp, sp
	sub sp, sp, #16 // bl expects 16-byte stack alignment

	str x0, [fp, #-8] // Store array address onto stack

	mov x19, x0 // x19 = array address
	mov x20, #0 // loop counter (i)
	shuffle_deck_loop:
		mov x0, DECK_SIZE
		sub x0, x0, #1 // x0 = randNum from 0 to 51
		bl _get_random_number // x0 = get_random_number(x0)

		ldrb W2, [x19, x0] // x2 = array[randNum]
		ldrb W3, [x19, x20] // X3 = array[i]
		strb W2, [x19, x20] // array[i] = x2
		strb W3, [x19, x0] // array[randNum] = X3

		add x20, x20, #1 // i++
		cmp x20, DECK_SIZE
		blt shuffle_deck_loop // if i < 52, then loop... else exit

	ldr x0, [fp, #-8]

	add sp, sp, #16
	ldp fp, lr, [sp], #16
	ret

// Input x0=address of deckIndex
// Output x0=address of deckIndex
_reset_deck_index:
	stp fp, lr, [sp, #-16]!
	mov fp, sp

	ldrb w1, [x0] // w1 = value of deckIndex
	mov x1, #0 // x1 = 0
	strb w1, [x0] // deckIndex = w1

	ldp fp, lr, [sp], #16
	ret

// Input: x0=upper limit
// Output: x0=random number from 0 to upper limit inclusive
_get_random_number:
	stp fp, lr, [sp, #-16]!
	mov fp, sp

	mov X3, #0
	// increment X3 by 1 (0 to upper limit - 1 for rand syscall)
	add X3, x0, #1 

	adrp x0, buffer@PAGE
	add x0, x0, buffer@PAGEOFF // x0 = address of dest buffer
	mov x9, x0 // save dest buffer in x9
	mov x1, #8 // 8-byte random num

	bl _getentropy

	ldr x0, [x9] // x0 = value at address of x0

	// x1 = x0 % X3
	udiv x1, x0, X3 // x1 = x0 / X3
	msub x0, x1, X3, x0 // x0 = x0 - (x1 * X3)

	ldp fp, lr, [sp], #16
	ret	

// Input: x0=address of deck, x1=address of deckIndex
// Output: x0=card index value at top of deck
_draw_card:
	stp fp, lr, [sp, #-16]!
	mov fp, sp

	ldrb W2, [x1] // W2 = byte value at address of deckIndex
	ldrb w0, [x0, x2] // w0 = array[deckIndex]
	
	add x2, x2, #1
	strb W2, [x1] // deckIndex = deckIndex + 1

	ldp fp, lr, [sp], #16
	ret

// Input: x0=address of deck, x1=num cards to print 
// Output: Prints x1 cards from x0 array
_print_hand:
	stp fp, lr, [sp, #-16]!
	mov fp, sp
	sub sp, sp, #32

	str x19, [fp, #-8]
	str x20, [fp, #-16]
	str x21, [fp, #-24]
	str x22, [fp, #-32]
	
	mov x19, x0 // x19 = address of array
	mov x20, #0 // loop counter	i
	mov x22, x1 // x22 = number of cards to print
	print_hand_loop:
		ldrb w21, [x19, x20] // W21 = array[i] 
		PRINT_CARD_VALUE x21
		PRINT_CARD_SUIT x21
		SPACE
		
		add x20, x20, #1
		cmp x20, x22
		blt print_hand_loop

	UNDERSCORE
	ENDL

	ldr x22, [fp, #-32]
	ldr x21, [fp, #-24]
	ldr x20, [fp, #-16]
	ldr x19, [fp, #-8]

	add sp, sp, #32
	ldp fp, lr, [sp], #16
	ret

// Input: x0=address of hand (12-byte array), x1=num cards to count
// Output: x0=total of x1 cards from 12-byte array 
_calc_total:
	stp fp, lr, [sp, #-16]!
	mov fp, sp
	sub sp, sp, #32
	
	str x25, [fp, #-8]
	str x26, [fp, #-16]
	str x27, [fp, #-24]
	str x28, [fp, #-32]

	mov x25, #0 // total
	mov x26, #0 // aces
	mov x27, #0 // loop counter
	mov x28, x0 // x28=address of hand

	adrp x2, VALUES@PAGE
	add x2, x2, VALUES@PAGEOFF
	mov x10, x1
	calc_total_loop:
		ldrb w3, [x28, x27] // W3 = hand[i]
		ldrb w4, [x2, X3] // W4 = values[hand[i]]
		mov w0, w3
		bl _get_card_value
		
		add x25, x25, x0 // total += _get_card_value x0 
		cmp w4, #'A'
		bne increment_calc_total_loop // if ace, increment ace count
		
		add x26, x26, #1 // aces += 1
		
		increment_calc_total_loop:
			add x27, x27, #1
			cmp x27, x10
			blt calc_total_loop

	consider_aces:
		cmp x25, #21 // if total <= 21, then exit
		ble calc_total_epilogue
		cmp x26, #0 // if aces <= 0, then exit
		ble calc_total_epilogue 
		
		sub x25, x25, #10 // total -= 10
		sub x26, x26, #1 // aces -= 1
		b consider_aces

	calc_total_epilogue:
		mov x0, x25 // x0 = total

		ldr x28, [fp, #-32]
		ldr x27, [fp, #-24]
		ldr x26, [fp, #-16]
		ldr x25, [fp, #-8]

	add sp, sp, #32
	ldp fp, lr, [sp], #16
	ret

// Input: x0=(char)card_value
// Output: x0=(int)card_value
_get_card_value:
	stp fp, lr, [sp, #-16]!
	mov fp, sp
	sub sp, sp, #16

	str x10, [fp, #-8]
	str x11, [fp, #-16]

	adrp x11, VALUES@PAGE
	add x11, x11, VALUES@PAGEOFF
	ldrb w10, [x11, x0]

	cmp w10, #'A'
	beq is_ace
	cmp w10, #'T'
	beq is_face
	cmp w10, #'J'
	beq is_face
	cmp w10, #'Q'
	beq is_face
	cmp w10, #'K'
	beq is_face

	sub w0, w10, #'0'
	b card_value_epilogue 

	is_ace:
		mov w0, #11
		b card_value_epilogue
	is_face:
		mov w0, #10

	card_value_epilogue:
		ldr x11, [fp, #-16]
		ldr x10, [fp, #-8]

		add sp, sp, #16
		ldp fp, lr, [sp], #16
		ret

// Input: X0=(int)card_value_index
// Output: X0=(int)card_value in VALUES array at card_value_index
_get_card_rank:
	stp fp, lr, [sp, #-16]!
	mov fp, sp

	adrp x1, VALUES@PAGE
	add x1, x1, VALUES@PAGEOFF
	ldrb w0, [x1, x0]

	ldp fp, lr, [sp], #16
	ret

// Input: x0=address of "chips" variable, x1=val to subtract from x0
// Output: x0=same address with updated val, x1=same val to subtract
_sub_chips:
	stp fp, lr, [sp, #-16]!
	mov fp, sp

	ldr x2, [x0] // x2 = chips 
	sub x2, x2, x1 // x2 = x2 - val
	str x2, [x0] // chips = x2

	ldp fp, lr, [sp], #16
	ret

// Input: x0=address of "chips" variable, x1=val to add to x0
// Output: x0=same address with updated val, x1=same val to add 
_add_chips:
	stp fp, lr, [sp, #-16]!
	mov fp, sp

	ldr x2, [x0] // x2 = chips 
	add x2, x2, x1 // x2 = x2 + val
	str x2, [x0] // chips = x2

	ldp fp, lr, [sp], #16
	ret
