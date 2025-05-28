.section __DATA,__data
	.balign 16
	buffer: .fill 16, 1, 0
	buffer_len = .-buffer

	.balign 16
	title: .asciz "Blackjack"
	.equ title_len, 9

	.balign 8
	chips_str: .asciz "chips: $"
	.equ chips_str_len, 8

	.balign 8
	placeBet: .asciz "Place your bet (0 < Bet <= 500): "
	.equ placeBet_len, 33
	
	.balign 8
	betPlaced: .asciz "Bet placed: "
	.equ betPlaced_len, 12 

	.balign 8
	dealOrExit: .asciz "Deal (d) or Exit (e): "
	.equ dealOrExit_len, 22

	.balign 8
	dealerShows: .asciz "Dealer shows: "
	.equ dealer_shows_len, 14

	.balign 8
	yourHand: .asciz "Your hand: "
	.equ your_hand_len, 11

	.balign 8
	splitPrompt: .asciz "Do you want to split? (y/n): "
	.equ split_prompt_len, 29

	.balign 8
	secondSplitHand: .asciz "Second split hand: "
	.equ second_split_hand_len, 19

	.balign 8
	doubleDownHand: .asciz "You double down and draw: "
	.equ double_down_hand_len, 26
	
	.balign 8
	hitOrStand: .asciz "Hit (h) or Stand (s): "
	.equ hit_or_stand_len, 22

	.balign 8
	hitStandOrDoubleDown: .asciz "Hit (h), Stand (s), or Double Down (d): "
	.equ hit_stand_or_double_down_len, 40

	.balign 8
	bust: .asciz "Bust! Dealer wins."
	.equ bust_len, 18

	.balign 8
	dealersTurn: .asciz "Dealer's turn:"
	.equ dealers_turn_len, 14

	.balign 8
	playerWins: .asciz "You win!"
	.equ player_wins_len, 8

	.balign 8
	dealerWins: .asciz "Dealer wins!"
	.equ dealer_wins_len, 12

	.balign 8
	tie: .asciz "Push! It's a tie."
	.equ tie_len, 17

	.balign 8
	nochips: .asciz "No more spending money!"
	.equ no_chips_len, 23

	.balign 8
	chips: .quad 2500

	.balign 8
	bet1: .hword 1

	.balign 8
	bet2: .hword 1

	.balign 8
	numHands: .byte 1

	.balign 8
	playerHand: .fill 12, 1, 0 // 12 1-byte card-indices
	playerCardCount: .byte 0

	.balign 8
	playerHand2: .fill 12, 1, 0 // for split
	playerCardCount2: .byte 0

	.balign 8
	dealerHand: .fill 12, 1, 0 // 12 1-byte card-indices
	dealerCount: .byte 0
	
	.balign 8
	deck: .fill 52, 1, 0 // 52 1-byte card-indices
	deckIndex: .byte 0

	.balign 8
	.equ BET_MIN, 0
	.equ BET_MAX, 500
	.equ DEALER_MAX, 17
	.equ BLACKJACK, 21


.text 
.include "utilmacro.s"
.extern _init_deck
.extern _shuffle_deck
.extern _reset_deck_index
.extern _get_random_number
.extern _draw_card
.extern _printDeck
.extern _print_hand
.extern _calc_total
.extern _get_card_value
.extern _get_card_rank

// Input: None
// Output: x0='d'|'e' 
get_deal_or_exit:
	stp fp, lr, [sp, #-16]!
	mov fp, sp
	sub sp, sp, #16

	str x19, [fp, #-8]

	deal_or_exit_loop:
		mov x3, dealOrExit_len

		PRINT_STR dealOrExit, X3 // print deal or exit prompt
		GET_STR buffer, buffer_len // get user input 

		cmp x0, #2 // make sure input is only 1 char
		bgt deal_or_exit_loop

		adrp x0, buffer@PAGE
		add x0, x0, buffer@PAGEOFF
		ldrb w0, [x0] // w0 = value at x0
		mov x19, x0 // save char val in x19

		cmp w0, #'e'
		beq deal_or_exit_exit // if 'e', then return... 
		cmp w0, #'d'
		beq deal_or_exit_exit // if d', then return... 

		b deal_or_exit_loop // else, try again...

	deal_or_exit_exit:
		mov x0, x19 // restore char val from x19 to x0

		ldr x19, [fp, #-8]
		
		add sp, sp, #16
		ldp fp, lr, [sp], #16
		ret

// Input: None
// Output: None
print_chips:
	stp fp, lr, [sp, #-16]!
	mov fp, sp

	mov x3, chips_str_len
	PRINT_STR chips_str, X3

	adrp x5, chips@PAGE
	add x5, x5, chips@PAGEOFF
	ldr X5, [X5] // X5 = value of chips variable 

	INT_TO_STR X5, buffer, buffer_len // buffer = str(x5)

	mov X3, x0 // x0 = num bytes returned
	PRINT_FROM_REG x1, X3 // x1 = addr at start of str, X3 = num bytes

	ldp fp, lr, [sp], #16
	ret

// Input: None
// Output: x0=bet
get_bet:
	stp fp, lr, [sp, #-16]!
	mov fp, sp

	getBetLoop:
		mov x3, placeBet_len
		PRINT_STR placeBet, x3 // print place bet prompt

		GET_STR buffer, buffer_len // user input into buffer 
		mov x1, buffer_len
		sub x1, x1, #1
		cmp x0, x1
		bgt handleOverflow 

		STR_TO_INT buffer // x0=int result, x1=num digits 

		cmp w0, BET_MIN 
		ble getBetLoop // retry if bet <= 0
		cmp w0, BET_MAX
		bgt getBetLoop // retry if bet > 500

		b getBetExit

	handleOverflow:
		SET_NON_BLOCK
		CLEAR_STDIN
		SET_BLOCK
		b getBetLoop
	
	getBetExit:
		ldp fp, lr, [sp], #16
		ret

// Input: x0=bet,x1=num digits in bet
// Output: None
print_bet:
	stp fp, lr, [sp, #-16]!
	mov fp, sp
	sub sp, sp, #16

	str x27, [fp, #-8]
	str x19, [fp, #-16]

	mov x27, x0 // x27 = bet
	mov x19, x1 // x19 = num digits

	mov x3, betPlaced_len
	PRINT_STR betPlaced, X3 // print bet placed text 	

	INT_TO_STR x27, buffer, x19 // bet int to str
	mov X3, x0 // num bytes returned in x0
	PRINT_STR buffer, X3  // print bet placed
	ENDL

	ldr x19, [fp, #-16]
	ldr x27, [fp, #-8]

	add sp, sp, #16
	ldp fp, lr, [sp], #16
	ret

// Input: x0=addr of byte array filled with 0s (cards), x1=addr of card count byte(=0)
// Output: cards array with first 2 elements populated; card count byte=2
init_hand: 
	stp fp, lr, [sp, #-16]!
	mov fp, sp
	sub sp, sp, #32

	str x20, [fp, #-8]
	str x21, [fp, #-16]
	str x22, [fp, #-24]

	mov x20, x0 // x20 = addr of cards array
	mov x21, x1 // x21 = addr of card count byte 
	ldrb w22, [x1] // w22 = val of card count byte

	adrp x0, deck@PAGE
	add x0, x0, deck@PAGEOFF
	adrp x1, deckIndex@PAGE
	add x1, x1, deckIndex@PAGEOFF
	bl _draw_card // w0 = _draw_card(x0, x1)

	strb w0, [x20, x22] // cards[cardCount] = w0
	add w22, w22, #1 // cardCount++

	adrp x0, deck@PAGE
	add x0, x0, deck@PAGEOFF
	adrp x1, deckIndex@PAGE
	add x1, x1, deckIndex@PAGEOFF
	bl _draw_card // w0 = _draw_card(x0, x1)

	strb w0, [x20, x22] // cards[cardCount] = w0
	add w22, w22, #1 // cardCount++

	strb w22, [x21] // cardCount = w22

	ldr x22, [fp, #-24]
	ldr x21, [fp, #-16]
	ldr x20, [fp, #-8]

	add sp, sp, #32
	ldp fp, lr, [sp], #16
	ret

// Input: x0=addr of playerHand, x1=addr of playerCardCount, x2=addr of bet
// Output: x0=player's total 
player_play:
	stp fp, lr, [sp, #-16]!
	mov fp, sp
	sub sp, sp, #32

	str x19, [fp, #-8]
	str x20, [fp, #-16]
	str x21, [fp, #-24]
	str x27, [fp, #-32]

	mov x20, x0 // x20 = addr of playerHand
	mov x21, x1 // x21 = addr of playerCardCount
	ldrb w19, [x21] // w19 = value of playerCardCount
	mov x27, x2 // x27 = addr of bet

	playerPlayLoop:
		cmp w19, #2
		bne printHS // if cardCount != 2, then no double down chance

		printHSD:
			PRINT_STR hitStandOrDoubleDown, hit_stand_or_double_down_len
			GET_STR buffer, buffer_len // get user input
			mov x1, x0 // x1 = num bytes written
		
			cmp w1, #2 // Make sure input is 1 char + '\n'
			bgt printHSD

			adrp x0, buffer@PAGE
			add x0, x0, buffer@PAGEOFF
			ldrb w0, [x0] // w0 = value at (byte)buffer[0]

			cmp w0, #'d' // if 'd' not entered, then check for hit or stand
			bne hitOrStandCase

			// handle double down here
			adrp x0, deck@PAGE
			add x0, x0, deck@PAGEOFF
			adrp x1, deckIndex@PAGE
			add x1, x1, deckIndex@PAGEOFF
			bl _draw_card // w0 = _draw_card(x0, x1)

			strb w0, [x20, x19] // playerHand[playerCardCount] = w0 
			add w19, w19, #1 // playerCardCount++

			PRINT_STR doubleDownHand, double_down_hand_len
			mov x0, x20 // x0 = addr of playerHand
			mov x1, x19  // x1 = playerCardCount
			bl _print_hand

			// double bet
			mov x0, #2
			ldrh w1, [x27]
			mul x1, x1, x0
			strh w1, [x27]

			B playerPlayExit

		printHS:
			PRINT_STR hitOrStand, hit_or_stand_len
			GET_STR buffer, buffer_len // get user input
			mov x1, x0 // x1 = num bytes written

		hitOrStandCase:
			cmp x1, #2 // make sure input is only 1 char + '\n'
			bgt playerPlayLoop

			adrp x0, buffer@PAGE
			add x0, x0, buffer@PAGEOFF
			ldrb w0, [x0] // w0 = value at (byte)buffer[0]

			cmp w0, #'s'
			beq playerPlayExit // if 's', then exit 

			cmp w0, #'h'
			bne playerPlayLoop // if not 'h', try again... 

			adrp x0, deck@PAGE
			add x0, x0, deck@PAGEOFF
			adrp x1, deckIndex@PAGE
			add x1, x1, deckIndex@PAGEOFF
			bl _draw_card // w0 = _draw_card(x0, x1)

			strb w0, [x20, x19] // playerHand[playerCardCount] = w0 
			add w19, w19, #1 // playerCardCount++

			PRINT_STR dealerShows, dealer_shows_len
			mov x0, x24
			mov x1, #1 // only show dealer's first card
			bl _print_hand 

			PRINT_STR yourHand, your_hand_len
			mov x0, x20 // x0 = addr of playerHand
			mov x1, x19  // x1 = playerCardCount
			bl _print_hand

			mov x0, x20 // x0 = addr of playerHand 
			mov x1, x19 // x1 = playerCardCount
			bl _calc_total // x0 = _calc_total(x0, x1)

			cmp x0, BLACKJACK
			BGE playerPlayExit // if total >= 21, then exit...
			
			ENDL
			B playerPlayLoop

	playerPlayExit:
		ENDL

		strb w19, [x21] // playerCardCount = w19

		mov x0, x20 // x0 = addr of playerHand 
		ldrb w1, [x21] // w1 = value of playerCardCount
		bl _calc_total // x0 = _calc_total(x0, x1)

		ldr x27, [fp, #-32]
		ldr x21, [fp, #-24]
		ldr x20, [fp, #-16]
		ldr x19, [fp, #-8]

		add sp, sp, #32
		ldp fp, lr, [sp], #16
		ret

// Input: x0=addr of dealerHand, x1=addr of dealerCardCount
// Output: x0=dealer's total 
dealer_play:
	stp fp, lr, [sp, #-16]!
	mov fp, sp
	sub sp, sp, #32

	str x19, [fp, #-8]
	str x24, [fp, #-16]
	str x25, [fp, #-24]

	mov x24, x0 // x24 = addr of dealerHand
	mov x25, x1 // x25 = addr of dealerCardCount
	ldrb w19, [x25] // w19 = value of dealerCardCount

	PRINT_STR dealersTurn, dealers_turn_len
	ENDL

	dealerPlayLoop:
		mov x0, x24 // x0 = addr of dealerHand
		mov x1, x19
		bl _calc_total // x0 = _calc_total(x0, x1) 

		// if total >= dealer max, then compare hands
		mov x1, DEALER_MAX
		cmp x0, x1 
		BGE dealerPlayExit 

		adrp x0, deck@PAGE
		add x0, x0, deck@PAGEOFF
		adrp x1, deckIndex@PAGE
		add x1, x1, deckIndex@PAGEOFF
		bl _draw_card // w0 = _draw_card(x0, x1)

		strb w0, [x24, x19] // dealerHand[dealerCardCount] = w0 
		add w19, w19, #1 // dealerCardCount++

		B dealerPlayLoop
	
	dealerPlayExit:
		strb w19, [x25] // w19 = dealerCardCount

		ldr x25, [fp, #-24]
		ldr x24, [fp, #-16]
		ldr x19, [fp, #-8]

		add sp, sp, #32
		ldp fp, lr, [sp], #16
		ret

// Input: x0=addr of bet variable
// Output: global "chips" variable incremented by value at x0
handle_player_win:
	stp fp, lr, [sp, #-16]!
	mov fp, sp
	sub sp, sp, #16

	str x27, [fp, #-8]

	mov x27, x0 // x27 = addr of bet variable

	PRINT_STR playerWins, player_wins_len
	ENDL
	ENDL

	ldrh w1, [x27] // w1 = 2-byte value from addr in x27
	adrp x0, chips@PAGE
	add x0, x0, chips@PAGEOFF
	bl _add_chips

	ldr x27, [fp, #-8]

	add sp, sp, #16
	ldp fp, lr, [sp], #16
	ret

// Input: x0=addr of bet variable
// Output: global "chips" variable decremented by value at x0
handle_dealer_win:
	stp fp, lr, [sp, #-16]!
	mov fp, sp
	sub sp, sp, #16

	str x27, [fp, #-8]

	mov x27, x0 // x27 = addr of bet variable

	PRINT_STR dealerWins, dealer_wins_len
	ENDL
	ENDL 

	ldrh w1, [x27] // w1 = 2-byte value from addr in x27
	adrp x0, chips@PAGE
	add x0, x0, chips@PAGEOFF
	bl _sub_chips

	ldr x27, [fp, #-8]

	add sp, sp, #16
	ldp fp, lr, [sp], #16
	ret

// Input: None
// Output: None
handle_push:
	stp fp, lr, [sp, #-16]!
	mov fp, sp

	PRINT_STR tie, tie_len
	ENDL
	ENDL

	ldp fp, lr, [sp], #16
	ret


.global _main
_main:
		mov x3, title_len
		PRINT_STR title, x3 
		ENDL
		ENDL

		adrp x27, bet1@PAGE
		add x27, x27, bet1@PAGEOFF
		adrp x28, bet2@PAGE
		add x28, x28, bet2@PAGEOFF

		deal:
			adrp x0, chips@PAGE
			add x0, x0, chips@PAGEOFF
			ldr x0, [x0]
			cmp x0, #0
			ble noMoney 

			bl get_deal_or_exit // x0 = 'd' or 'e'
			cmp w0, #'e'
			beq exit // if user entered 'e', then exit

			bl print_chips
			bl get_bet
			strh w0, [x27] // store 2-byte bet resut at addr of x27
			bl print_bet

			initDeck:
				adrp x0, deck@PAGE
				add x0, x0, deck@PAGEOFF
				bl _init_deck 

			shuffleDeck:
				bl _shuffle_deck

				adrp x0, deckIndex@PAGE
				add x0, x0, deckIndex@PAGEOFF
				bl _reset_deck_index

			mov x2, #0
			// init callee-saved registers
			loadPlayerHand:
				adrp x20, playerHand@PAGE
				add x20, x20, playerHand@PAGEOFF // x20 = address of playerHand
				adrp x21, playerCardCount@PAGE
				add x21, x21, playerCardCount@PAGEOFF // x21 = address of playerCardCount
				strb w2, [x21] // playerCardCount = 0

			loadPlayerHand2: // for split case
				adrp x22, playerHand2@PAGE
				add x22, x22, playerHand2@PAGEOFF // x22 = address of playerHand2
				adrp x23, playerCardCount2@PAGE
				add x23, x23, playerCardCount2@PAGEOFF // x23 = address of playerCardCount2
				strb w2, [x23] // playerCardCount = 0

			loadDealerHand:
				adrp x24, dealerHand@PAGE
				add x24, x24, dealerHand@PAGEOFF // x24 = address of dealerHand

				adrp x25, dealerCount@PAGE
				add x25, x25, dealerCount@PAGEOFF // x25 = address of dealerCardCount
				strb w2, [x25] // dealerCardCount = 0

			loadNumHands:
				adrp x26, numHands@PAGE
				add x26, x26, numHands@PAGEOFF

			initHands:
				mov x0, x20 // x0 = addr of playerHand
				mov x1, x21 // x1 = addr of playerCardCount
				bl init_hand

				mov x0, x24 // x0 = addr of dealerHand
				mov x1, x25 // x1 = addr of dealerCardCount
				bl init_hand

			printDealerHand: // hide 2nd card
				PRINT_STR dealerShows, dealer_shows_len
				mov x0, x22 // x0 = address of dealerHand
				mov x1, #1 // only show dealer's first card
				bl _print_hand 

			printPlayerHand:
				PRINT_STR yourHand, your_hand_len
				mov x0, x20 // x0 = address of playerHand
				mov x1, #2 // show player's starting hand
				bl _print_hand
				ENDL

			checkInitialBlackjack:
				mov x0, x20 
				ldrb w1, [x21]
				bl _calc_total // x0 = _calc_total(x0, x1)
				cmp x0, BLACKJACK 
				bne check_for_split // if not 21, then continue...
				
				mov x0, x27 // x0 = addr of bet1
				bl handle_player_win // else, player has blackjack
				b deal

			check_for_split:
				ldrb w0, [x20]
				bl _get_card_rank
				mov w2, w0 // w2 = 1st card value

				ldrb w0, [x20, #1]
				bl _get_card_rank
				mov w3, w0 // w3 = 2nd card value

				cmp w2, w3
				bne playerTurn // if 1st card != 2nd card, then no split chance

			handle_split:
				PRINT_STR splitPrompt, split_prompt_len
				GET_STR buffer, buffer_len // get user input 

				cmp x0, #2 // make sure input is only 1 char + '\n'
				bgt handle_split 

				adrp x0, buffer@PAGE
				add x0, x0, buffer@PAGEOFF
				ldrb w0, [x0]

				cmp w0, #'n'
				beq playerTurn

				cmp w0, #'y'
				bne handle_split

				ldrb w1, [x20, #1] // load 2nd card in 1st hand
				mov w2, #0
				strb w2, [x20, #1] // remove 2nd card in 1st hand
				strb w1, [x22] // store 2nd card in 1st hand to 1st card in 2nd hand

				add w2, w2, #1
				strb w2, [x21] // playerCardCount = 1
				strb w2, [x23] // playerCardCount2 = 1

				add w2, w2, #1
				strb w2, [x26] // numHands = 2

				ldrh w0, [x27] // x0 = bet1
				strh w0, [x28] // bet2 = x0

				PRINT_STR dealerShows, dealer_shows_len
				mov x0, x24 // x0 = addr of dealerHand
				mov x1, #1 // only show dealer's first card
				bl _print_hand 

				PRINT_STR yourHand, your_hand_len
				mov x0, x20 // x0 = addr of playerHand
				ldrb w1, [x21] // x1 = playerCardCount
				bl _print_hand
				ENDL

			playerTurn:
				play1stHand:
					mov x0, x20 // x0 = addr of playerHand
					mov x1, x21 // x1 = addr of playerCardCount
					mov x2, x27 // x2 = addr of bet1
					bl player_play

				ldrb w19, [x26] // w19 = numHands
				cmp w19, #2 // check if player split
				bne dealerTurn // if numHands != 2, then dealer's turn

				PRINT_STR dealerShows, dealer_shows_len
				mov x0, x24 // x0 = addr of dealerHand
				mov x1, #1 // only show dealer's first card
				bl _print_hand 

				print2ndHand:
					PRINT_STR secondSplitHand, second_split_hand_len
					mov x0, x22 // x0 = addr of playerHand2
					ldrb w1, [x23]
					bl _print_hand
					ENDL

				play2ndHand:
					mov x0, x22 // x0 = addr of playerHand2
					mov x1, x23 // x1 = addr of playerCardCount2
					mov x2, x28 // x2 = addr of bet2
					bl player_play

			// Dealer's turn
			dealerTurn:
				mov X0, X24 // X0 = addr of dealerHand
				mov X1, X25 // X1 = addr of dealerCardCount
				bl dealer_play

		compare:
			// Get dealer total
			mov x0, x24 // x0 = addr of dealerHand
			ldrb w1, [x25] // w1 = dealerCardCount
			bl _calc_total // x0 = _calc_total(x0, x1)

			mov x11, x0 // x11 = dealer total

			// Print dealer's hand
			PRINT_STR dealerShows, dealer_shows_len
			mov x0, x24 // x0 = addr of dealerHand
			ldrb w1, [x25] // w1 = dealerCardCount
			bl _print_hand 

			// Get player total
			mov x0, x20 // x0 = addr of playerHand
			ldrb w1, [x21] // w1 = playerCardCount
			bl _calc_total // x0 = calc_total(x0, x1)

			mov x10, x0 // X10 = player total

			// Print player's hand
			PRINT_STR yourHand, your_hand_len
			mov x0, x20 // x0 = addr of playerHand
			ldrb w1, [x21] // w1 = playerCardCount
			bl _print_hand

			checkPlayerHand:
				cmp x10, BLACKJACK
				ble checkDealerHand // if player total <= 21, then check dealer's hand

				mov x0, x27 // x0 = addr of bet1
				bl handle_dealer_win // else player total > 21; dealer wins
				b compare2ndHand
		
			checkDealerHand:
				cmp x11, BLACKJACK
				ble compare1stHand // f dealer total <= 21, then compare 1st hand
				
				mov x0, x27 // x0 = addr of bet1
				bl handle_player_win // else dealer total > 21; player wins
				b compare2ndHand

			compare1stHand:
				cmp x10, x11
				bgt pWin1 
				blt dWin1 
				beq push1 

				pWin1:
					mov x0, x27 // X0 = addr of bet1
					bl handle_player_win
					b compare2ndHand
				dWin1:
					mov x0, x27 // x0 = addr of bet1
					bl handle_dealer_win
					b compare2ndHand
				push1:
					bl handle_push
					b compare2ndHand

			compare2ndHand:
				cmp w19, #2
				bne deal // if numhands != 2, then play again

				sub w19, w19, #1
				strb w19, [x26] // numHands -= 1

				mov x0, x22 // x0 = addr of playerHand2
				ldrb w1, [x23] // w1 = playerCardCount2
				bl _calc_total

				mov x10, x0 // x10 = player total 2

				// print dealer's hand
				PRINT_STR dealerShows, dealer_shows_len
				mov x0, x24 // x0 = addr of dealerHand
				ldrb w1, [x25] // w1 = dealerCardCount
				bl _print_hand 

				// print player's 2nd hand
				PRINT_STR yourHand, your_hand_len
				mov x0, x22 // x0 = addr of playerHand2
				ldrb w1, [x23] // w1 = playerCardCount2
				bl _print_hand

				cmp x10, BLACKJACK
				ble compare2ndCont // if player total <= 21, then compare

				mov x0, x28 // x0 = addr of bet2
				bl handle_dealer_win // else player total > 21; dealer wins
				b deal
	
				compare2ndCont:
					cmp X11, BLACKJACK
					bgt pWin2 // if dealer total > 21, then player wins

					cmp X10, X11
					bgt pWin2 
					blt dWin2 
					beq push2 

					pWin2:
						mov X0, X28 // X0 = addr of bet2
						bl handle_player_win
						b deal
					dWin2:
						mov X0, X28 // X0 = addr of bet2
						bl handle_dealer_win
						b deal
					push2:
						bl handle_push
						b deal



	noMoney:
		PRINT_STR nochips, no_chips_len
		ENDL

	exit:
		mov x0, #0
		mov x16, #1
		svc #0
