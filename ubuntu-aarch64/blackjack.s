.bss
	buffer: .skip 16
	buffer_len = .-buffer

.data
	VALUES:
		.asciz "A23456789TJQKA23456789TJQKA23456789TJQKA23456789TJQK"
	SUITS:
		.asciz "HHHHHHHHHHHHHDDDDDDDDDDDDDCCCCCCCCCCCCCSSSSSSSSSSSSS"

	.equ DECK_SIZE, 52


.text 
.include "utilmacro.s"

.MACRO PRINT_CARD_VALUE index
	LDR X1, =VALUES

	MOV X0, #1 // stdout
	ADD X1, X1, \index // address of value at index
	MOV X2, #1 // strlen
	MOV X8, #64 // linux write syscall
	SVC #0
.ENDM

.MACRO PRINT_CARD_SUIT index
	LDR X1, =SUITS

	MOV X0, #1 // stdout
	ADD X1, X1, \index // address of value at index
	MOV X2, #1 // strlen
	MOV X8, #64 // linux write syscall
	SVC #0
.ENDM

.global init_deck
.global shuffle_deck
.global reset_deck_index
.global get_random_number
.global draw_card
.global print_hand
.global calc_total
.global get_card_value
.global get_card_rank
.global sub_chips
.global add_chips

// Input: X0=address of 52-byte array
// Output: X0=same address with values initialized from 0 to 51
init_deck:
	STP FP, LR, [SP, #-16]!
	MOV FP, SP

	MOV X1, #0 // loop counter (i)
	new_deck_loop:
		STRB W1, [X0, X1] // array[i] = i
		
		ADD X1, X1, #1 // i++
		CMP X1, DECK_SIZE
		BLT new_deck_loop // if X0 < 52, then loop... else exit

	LDP FP, LR, [SP], #16
	RET

// Input: X0=address of 52-byte array where each value
// 			   is between 0 and 51 
// Output: X0=same address with elements shuffled
shuffle_deck:
	STP FP, LR, [SP, #-16]!
	MOV FP, SP
	SUB SP, SP, #16 // BL expects 16-byte stack alignment
	STR X0, [FP, #-8] // Store array address onto stack

	MOV X19, X0 // X19 = array address
	MOV X20, #0 // loop counter (i)
	shuffle_deck_loop:
		LDR X0, =DECK_SIZE - 1 // X0 = randNum from 0 to 51
		BL get_random_number // X0 = get_random_number(X0)

		LDRB W2, [X19, X0] // X2 = array[randNum]
		LDRB W3, [X19, X20] // X3 = array[i]
		STRB W2, [X19, X20] // array[i] = X2
		STRB W3, [X19, X0] // array[randNum] = X3

		ADD X20, X20, #1 // i++
		CMP X20, DECK_SIZE
		BLT shuffle_deck_loop // if i < 52, then loop... else exit

	LDR X0, [FP, #-8]
	ADD SP, SP, #16
	LDP FP, LR, [SP], #16
	RET

// Input X0=address of deckIndex
// Output X0=address of deckIndex
reset_deck_index:
	STP FP, LR, [SP, #-16]!
	MOV FP, SP

	LDRB W1, [X0] // W1 = value of deckIndex
	MOV X1, #0 // X1 = 0
	STRB W1, [X0] // deckIndex = W1

	LDP FP, LR, [SP], #16
	RET

// Input: X0=upper limit
// Output: X0=random number from 0 to upper limit inclusive
get_random_number:
	STP FP, LR, [SP, #-16]!
	MOV FP, SP

	MOV X3, #0
	// increment X3 by 1 (0 to upper limit - 1 for rand syscall)
	ADD X3, X0, #1 

	LDR X0, =buffer // X0 = address of dest buffer
	MOV X1, #8 // 8-byte random num
	MOV X2, #0 // flags
	MOV X8, #0x116 // rand syscall
	SVC #0

	LDR X0, =buffer // X0 = address of dest buffer
	LDR X0, [X0] // X0 = value at address of X0

	// X1 = X0 % X3
	UDIV X1, X0, X3 // X1 = X0 / X3
	MSUB X0, X1, X3, X0 // X0 = X0 - (X1 * X3)

	LDP FP, LR, [SP], #16
	RET	

// Input: X0=address of deck, X1=address of deckIndex
// Output: X0=card index value at top of deck
draw_card:
	STP FP, LR, [SP, #-16]!
	MOV FP, SP

	LDRB W2, [X1] // W2 = byte value at address of deckIndex
	LDRB W0, [X0, X2] // W0 = array[deckIndex]
	
	ADD X2, X2, #1
	STRB W2, [X1] // deckIndex = deckIndex + 1

	LDP FP, LR, [SP], #16
	RET

// Input: X0=address of deck, X1=num cards to print 
// Output: Prints X1 cards from X0 array
print_hand:
	STP FP, LR, [SP, #-16]!
	MOV FP, SP
	SUB SP, SP, #32

	STR X19, [FP, #-8]
	STR X20, [FP, #-16]
	STR X21, [FP, #-24]
	STR X22, [FP, #-32]
	
	MOV X19, X0 // X19 = address of array
	MOV X20, #0 // loop counter	i
	MOV X22, X1 // X22 = number of cards to print
	print_hand_loop:
		LDRB W21, [X19, X20] // W21 = array[i] 
		PRINT_CARD_VALUE X21
		PRINT_CARD_SUIT X21
		SPACE
		
		ADD X20, X20, #1
		CMP X20, X22
		BLT print_hand_loop
	UNDERSCORE
	ENDL

	LDR X22, [FP, #-32]
	LDR X21, [FP, #-24]
	LDR X20, [FP, #-16]
	LDR X19, [FP, #-8]

	ADD SP, SP, #32
	LDP FP, LR, [SP], #16
	RET

// Input: X0=address of hand (12-byte array), X1=num cards to count
// Output: X0=total of X1 cards from 12-byte array 
calc_total:
	STP FP, LR, [SP, #-16]!
	MOV FP, SP
	SUB SP, SP, #32
	
	STR X25, [FP, #-8]
	STR X26, [FP, #-16]
	STR X27, [FP, #-24]
	STR X28, [FP, #-32]

	MOV X25, #0 // total
	MOV X26, #0 // aces
	MOV X27, #0 // loop counter
	MOV X28, X0 // X28=address of hand
	LDR X2, =VALUES
	MOV X10, X1
	calc_total_loop:
		LDRB W3, [X28, X27] // W3 = hand[i]
		LDRB W4, [X2, X3] // W4 = values[hand[i]]
		MOV W0, W3
		BL get_card_value // X0 = get_card_value(hand[i])
		
		ADD X25, X25, X0 // total += get_card_value X0 
		CMP W4, #'A'
		BNE increment_calc_total_loop // if ace, increment ace count
		
		ADD X26, X26, #1 // aces += 1
		
		increment_calc_total_loop:
			ADD X27, X27, #1
			CMP X27, X10
			BLT calc_total_loop

	consider_aces:
		CMP X25, #21 // if total <= 21, then exit
		BLE calc_total_epilogue
		CMP X26, #0 // if aces <= 0, then exit
		BLE calc_total_epilogue 
		
		SUB X25, X25, #10 // total -= 10
		SUB X26, X26, #1 // aces -= 1
		B consider_aces

	calc_total_epilogue:
		MOV X0, X25 // X0 = total
		LDR X28, [FP, #-32]
		LDR X27, [FP, #-24]
		LDR X26, [FP, #-16]
		LDR X25, [FP, #-8]

	ADD SP, SP, #32
	LDP FP, LR, [SP], #16
	RET

// Input: X0=(char)card index
// Output: X0=(int)card_value
get_card_value:
	STP FP, LR, [SP, #-16]!
	MOV FP, SP
	SUB SP, SP, #16

	STR X10, [FP, #-8]
	STR X11, [FP, #-16]

	LDR X11, =VALUES
	LDRB W10, [X11, X0]

	CMP W10, #'A'
	BEQ is_ace
	CMP W10, #'T'
	BEQ is_face
	CMP W10, #'J'
	BEQ is_face
	CMP W10, #'Q'
	BEQ is_face
	CMP W10, #'K'
	BEQ is_face

	SUB W0, W10, #'0'
	B card_value_epilogue 

	is_ace:
		MOV W0, #11
		B card_value_epilogue
	is_face:
		MOV W0, #10

	card_value_epilogue:
		LDR X11, [FP, #-16]
		LDR X10, [FP, #-8]

		ADD SP, SP, #16
		LDP FP, LR, [SP], #16
		RET

// Input: X0=(char)card_value
// Output: X0=(int)card_value
get_card_rank:
	STP FP, LR, [SP, #-16]!
	MOV FP, SP

	LDR X1, =VALUES
	LDRB W0, [X1, X0]

	LDP FP, LR, [SP], #16
	RET

// Input: X0=address of "chips" variable, X1=val to subtract from X0
// Output: X0=same address with updated val, X1=same val to subtract
sub_chips:
	STP FP, LR, [SP, #-16]!
	MOV FP, SP

	LDR X2, [X0] // X2 = chips 
	SUB X2, X2, X1 // X2 = X2 - val
	STR X2, [X0] // chips = X2

	LDP FP, LR, [SP], #16
	RET

// Input: X0=address of "chips" variable, X1=val to add to X0
// Output: X0=same address with updated val, X1=same val to add 
add_chips:
	STP FP, LR, [SP, #-16]!
	MOV FP, SP

	LDR X2, [X0] // X2 = chips 
	ADD X2, X2, X1 // X2 = X2 + val
	STR X2, [X0] // chips = X2

	LDP FP, LR, [SP], #16
	RET
