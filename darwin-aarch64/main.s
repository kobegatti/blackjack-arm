.section __DATA,__data
	.balign 16
	buffer: .fill 16, 1, 0
	buffer_len = .-buffer

	.balign 16
	title: .asciz "Blackjack"
	.equ title_len, 9
	//title_len = .-title

	.balign 8
	chips_str: .asciz "chips: $"
	//chips_str_len = .-chips_str
	.equ chips_str_len, 8

	.balign 8
	placeBet: .asciz "Place your bet (0 < Bet <= 500): "
	//placeBet_len = .-placeBet
	.equ placeBet_len, 33
	
	.balign 8
	betPlaced: .asciz "Bet placed: "
	//betPlaced_len = .-betPlaced
	.equ betPlaced_len, 12 

	.balign 8
	dealOrExit: .asciz "Deal (d) or Exit (e): "
	//dealOrExit_len = .-dealOrExit
	.equ dealOrExit_len, 22

	.balign 8
	dealerShows: .asciz "Dealer shows: "
	//dealer_shows_len = .-dealerShows
	.equ dealer_shows_len, 14

	.balign 8
	yourHand: .asciz "Your hand: "
	//your_hand_len = .-yourHand
	.equ your_hand_len, 11

	.balign 8
	hitOrStand: .asciz "Hit (h) or Stand (s): "
	//hit_or_stand_len = .-hitOrStand
	.equ hit_or_stand_len, 22

	.balign 8
	bust: .asciz "Bust! Dealer wins."
	//bust_len = .-bust
	.equ bust_len, 18

	.balign 8
	dealersTurn: .asciz "Dealer's turn:"
	//dealers_turn_len = .-dealersTurn
	.equ dealers_turn_len, 14

	.balign 8
	playerWins: .asciz "You win!"
	//player_wins_len = .-playerWins
	.equ player_wins_len, 8

	.balign 8
	dealerWins: .asciz "Dealer wins!"
	//dealer_wins_len = .-dealerWins
	.equ dealer_wins_len, 12

	.balign 8
	tie: .asciz "Push! It's a tie."
	//tie_len = .-tie
	.equ tie_len, 17

	.balign 8
	nochips: .asciz "No more spending money!"
	//no_chips_len = .-nochips
	.equ no_chips_len, 23

	.balign 8
	chips: .quad 2500

	.balign 8
	bet: .byte 1

	.balign 8
	playerHand: .fill 12, 1, 0 // 12 1-byte card-indices
	playerCount: .byte 0

	.balign 8
	dealerHand: .fill 12, 1, 0 // 12 1-byte card-indices
	dealerCount: .byte 0
	
	.balign 8
	deck: .fill 52, 1, 0 // 52 1-byte card-indices
	deckIndex: .byte 0

	.balign 8
	.equ BET_MIN, 0
	.equ BET_MAX, 500
	.equ BLACKJACK, 21

.text 
.include "utilmacro.s"
.extern _initDeck
.extern _shuffleDeck
.extern _resetDeckIndex
.extern _getRandomNumber
.extern _drawCard
.extern _printDeck
.extern _printHand
.extern _calcTotal
.extern _getCardValue

.global _main

_main:
		mov x3, title_len
		PRINT_STR title, x3 
		ENDL
		ENDL

		deal:
			adrp x0, chips@PAGE
			add x0, x0, chips@PAGEOFF
			ldr x0, [x0]
			cmp x0, #0
			ble noMoney 

			mov x3, dealOrExit_len
			PRINT_STR dealOrExit, x3 // print deal or exit prompt
			GET_STR buffer, buffer_len // get user input 

			cmp x0, #2 // make sure input is only 1 char
			bgt deal

			adrp x0, buffer@PAGE
			add x0, x0, buffer@PAGEOFF 
			ldrb w0, [x0] // w0 = value at x0

			cmp w0, #'e'
			beq exit // if 'e', then exit
			cmp w0, #'d'
			bne deal // if not 'd', try again... 
			ENDL


		printchips:
			mov x3, chips_str_len
			PRINT_STR chips_str, x3

			adrp x10, chips@PAGE
			add x10, x10, chips@PAGEOFF
			ldr x10, [x10] // x10 = value at x10
			INT_TO_STR x10, buffer, buffer_len // buffer = str(x10)
			mov x3, x0 // x0 = num chars
			PRINT_FROM_REG x1, x3 // x1 = address at start of str


		getBet:
			mov x3, placeBet_len 
			PRINT_STR placeBet, x3 // print place bet prompt

			GET_STR buffer, buffer_len // user input into buffer 
			STR_TO_INT buffer // int result in x0

			cmp w0, BET_MIN 
			ble getBet // retry if bet <= 0
			cmp w0, BET_MAX
			bgt getBet // retry if bet > 500
		

		printBet:
			mov x28, x0 // move bet result to x28
			mov x3, betPlaced_len
			PRINT_STR betPlaced, x3 // print bet placed text 	

			INT_TO_STR x28, buffer, buffer_len // bet int to str
			mov x3, x0 // num bytes returned in x0
			PRINT_STR buffer, x3  // print bet placed
			ENDL
						

		initialDeal:	
			adrp x0, deck@PAGE
			add x0, x0, deck@PAGEOFF
			bl _initDeck 
			bl _shuffleDeck

			adrp x0, deckIndex@PAGE
			add x0, x0, deckIndex@PAGEOFF
			bl _resetDeckIndex

			mov x2, #0
			// init callee-saved registers
			adrp x20, playerHand@PAGE
			add x20, x20, playerHand@PAGEOFF // x20 = address of playerHand

			adrp x21, playerCount@PAGE
			add x21, x21, playerCount@PAGEOFF // x21 = address of playerCardCount
			strb w2, [x21] // playerCardCount = 0

			adrp x22, dealerHand@PAGE
			add x22, x22, dealerHand@PAGEOFF // x22 = address of dealerHand

			adrp x23, dealerCount@PAGE
			add x23, x23, dealerCount@PAGEOFF // x23 = address of dealerCardCount
			strb w2, [x23] // dealerCardCount = 0

			// init playerHand and playerCardCount
			ldrb w24, [x21] // w24 = value of playerCardCount

			adrp x0, deck@PAGE
			add x0, x0, deck@PAGEOFF
			adrp x1, deckIndex@PAGE
			add x1, x1, deckIndex@PAGEOFF
			bl _drawCard // w0 = drawCard(x0, x1)

			strb w0, [x20, x24] // playerHand[playerCardCount] = w0 
			add w24, w24, #1 // w24 += 1

			adrp x0, deck@PAGE
			add x0, x0, deck@PAGEOFF
			adrp x1, deckIndex@PAGE
			add x1, x1, deckIndex@PAGEOFF
			bl _drawCard // w0 = drawCard(x0, x1)

			strb w0, [x20, x24] // playerHand[playerCardCount] = w0 
			add w24, w24, #1 // w24 += 1

			strb w24, [x21] // playerCardCount = w24

			// init dealerHand and dealerCardCount
			ldrb w24, [x23] // w24 = dealerCardCount

			adrp x0, deck@PAGE
			add x0, x0, deck@PAGEOFF
			adrp x1, deckIndex@PAGE
			add x1, x1, deckIndex@PAGEOFF
			bl _drawCard // w0 = drawCard(x0, x1)

			strb w0, [x22, x24] // dealerHand[dealerCount] = w0 
			add x24, x24, #1 // w24 += 1

			adrp x0, deck@PAGE
			add x0, x0, deck@PAGEOFF
			adrp x1, deckIndex@PAGE
			add x1, x1, deckIndex@PAGEOFF
			bl _drawCard // w0 = drawCard(x0, x1)

			strb w0, [x22, x24] // dealerHand[dealerCardCount] = w0 
			add x24, x24, #1 // w24 += 1

			strb w24, [x23] // dealerCardCount = w24


			PRINT_STR dealerShows, dealer_shows_len
			mov x0, x22 // x0 = address of dealerHand
			mov x1, #1 // only show dealer's first card
			bl _printHand 

			PRINT_STR yourHand, your_hand_len
			mov x0, x20 // x0 = address of playerHand
			mov x1, #2 // show player's starting hand
			bl _printHand
			ENDL


			mov x0, x20 // x0 = address of playerHand
			ldrb w24, [x21]
			mov x1, x24 // x1 = playerCardCount
			bl _calcTotal // x0 = calcTotal(x0, x1)

			cmp x0, BLACKJACK 
			beq playerWin


		playerPlay:
			PRINT_STR hitOrStand, hit_or_stand_len
			GET_STR buffer, buffer_len // get user input
			cmp x0, #2 // make sure input is only 1 char
			bgt playerPlay

			adrp x0, buffer@PAGE
			add x0, x0, buffer@PAGEOFF // x0 = address of buffer
			ldrb w0, [x0] // w0 = value at x0

			cmp w0, #'s'
			beq dealerPlay // if 's', then dealer's turn 
			cmp w0, #'h'
			bne playerPlay// if not 'h', try again... 


			ldrb w24, [x21] // w24 = value of playerCount

			adrp x0, deck@PAGE
			add x0, x0, deck@PAGEOFF
			adrp x1, deckIndex@PAGE
			add x1, x1, deckIndex@PAGEOFF
			bl _drawCard // w0 = drawCard(x0, x1)

			strb w0, [x20, x24] // playerHand[playerCardCount] = w0 
			add w24, w24, #1 // w24 += 1
			strb w24, [x21] // playerCardCount = w24

			PRINT_STR dealerShows, dealer_shows_len
			mov x0, x22
			mov x1, #1 // only show dealer's first card
			bl _printHand 

			PRINT_STR yourHand, your_hand_len
			mov x0, x20 // x0 = address of playerHand
			mov x1, x24  // x1 = playerCardCount
			bl _printHand
			ENDL

			mov x0, x20 // x0 = address of playerHand 
			mov x1, x24 // x1 = playerCardCount
			bl _calcTotal // x0 = calcTotal(x0, x1)

			cmp x0, BLACKJACK
			blt playerPlay // if total < 21, then cont...
			beq playerWin // if total == 21, then win...

			// if total > 21, then bust...
			PRINT_STR bust, bust_len
			ENDL
			ENDL

			adrp x0, chips@PAGE
			add x0, x0, chips@PAGEOFF
			mov x1, x28 // x1 = bet
			bl _subChips
			b deal


		dealerPlay:
			ENDL
			PRINT_STR dealersTurn, dealers_turn_len
			ENDL
		
			dealerLoop:
				mov x0, x22 // x0 = address of dealerHand
				ldrb w24, [x23] 
				mov x1, x24 // x1 = dealerCardCount
				bl _calcTotal // x0 = calcTotal(x0, x1) 

				// if total >= dealer max, then compare hands
				cmp x0, #17 
				bge compare

				adrp x0, deck@PAGE
				add x0, x0, deck@PAGEOFF
				adrp x1, deckIndex@PAGE
				add x1, x1, deckIndex@PAGEOFF
				bl _drawCard // w0 = drawCard(x0, x1)

				strb w0, [x22, x24] // dealerHand[dealerCardCount] = w0 
				add w24, w24, #1
				strb w24, [x23] // dealerCardCount++

				b dealerLoop


		compare:
			mov x0, x22 // x0 = address of dealerHand
			ldrb w24, [x23] 
			mov x1, x24 // x1 = dealerCardCount
			bl _calcTotal // x0 = calcTotal(x0, x1)

			mov x11, x0 // x11 = dealer total

			PRINT_STR dealerShows, dealer_shows_len
			mov x0, x22
			mov x1, x24 
			bl _printHand 

			mov x0, x20 // x0 = address of playerHand
			ldrb w24, [x21] 
			mov x1, x24 // x1 = playerCardCount
			bl _calcTotal // x0 = calcTotal(x0, x1)

			mov x10, x0 // x10 = player total

			PRINT_STR yourHand, your_hand_len
			mov x0, x20
			mov x1, x24 
			bl _printHand

			// if dealer total > 21, then player wins...
			cmp x11, BLACKJACK 			
			bgt playerWin

			cmp x10, x11
			bgt playerWin
			blt dealerWin
			beq push

		playerWin:
			PRINT_STR playerWins, player_wins_len
			ENDL
			ENDL

			adrp x0, chips@PAGE
			add x0, x0, chips@PAGEOFF
			mov x1, x28 // x1 = bet
			bl _addChips
			B deal
			
		dealerWin:
			PRINT_STR dealerWins, dealer_wins_len
			ENDL
			ENDL 

			adrp x0, chips@PAGE
			add x0, x0, chips@PAGEOFF
			mov x1, x28 // x1 = bet
			bl _subChips
			b deal

		push:
			PRINT_STR tie, tie_len
			ENDL
			ENDL

			b deal

	noMoney:
		PRINT_STR nochips, no_chips_len
		ENDL

	exit:
		mov x0, #0
		mov x16, #1
		svc #0
