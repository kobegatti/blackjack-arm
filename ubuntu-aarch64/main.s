.bss
	buffer: .skip 16
	buffer_len = .-buffer

.data
	title: .asciz "Blackjack"
	title_len = .-title
	chips_str: .asciz "chips: $"
	chips_str_len = .-chips_str
	placeBet: .asciz "Place your bet (0 < Bet <= 500): "
	placeBet_len = .-placeBet

	.equ BET_MIN, 0
	.equ BET_MAX, 500
	.equ DEALER_MAX, 17
	.equ BLACKJACK, 21
	
	betPlaced: .asciz "Bet placed: "
	betPlaced_len = .-betPlaced
	dealOrExit: .asciz "Deal (d) or Exit (e): "
	dealOrExit_len = .-dealOrExit

	dealerShows: .asciz "Dealer shows: "
	dealer_shows_len = .-dealerShows
	yourHand: .asciz "Your hand: "
	your_hand_len = .-yourHand

	hitOrStand: .asciz "Hit (h) or Stand (s): "
	hit_or_stand_len = .-hitOrStand

	bust: .asciz "Bust! Dealer wins."
	bust_len = .-bust

	dealersTurn: .asciz "Dealer's turn:"
	dealers_turn_len = .-dealersTurn

	playerWins: .asciz "You win!"
	player_wins_len = .-playerWins

	dealerWins: .asciz "Dealer wins!"
	dealer_wins_len = .-dealerWins

	tie: .asciz "Push! It's a tie."
	tie_len = .-tie

	nochips: .asciz "No more spending money!"
	no_chips_len = .-nochips

	chips: .quad 2500
	bet: .byte 1

	playerHand: .fill 12, 1, 0 // 12 1-byte card-indices
	playerCardCount: .byte 0
	playerHand2: .fill 12, 1, 0 // for split
	playerCardCount2: .byte 0
	dealerHand: .fill 12, 1, 0 // 12 1-byte card-indices
	dealerCardCount: .byte 0
	
	deck: .fill 52, 1, 0 // 52 1-byte card-indices
	deckIndex: .byte 0


.text 
.include "utilmacro.s"
.extern initDeck
.extern shuffleDeck
.extern resetDeckIndex
.extern getRandomNumber
.extern drawCard
.extern printDeck
.extern printHand
.extern calcTotal
.extern getCardValue

// Input: None
// Output: X0='d'|'e' 
get_deal_or_exit:
	STP FP, LR, [SP, #-16]!
	MOV FP, SP

	deal_or_exit_loop:
		LDR X3, =dealOrExit_len
		PRINT_STR dealOrExit, X3 // print deal or exit prompt
		GET_STR buffer, buffer_len // get user input 

		CMP X0, #2 // make sure input is only 1 char
		BGT deal_or_exit_loop

		LDR X0, =buffer // X0 = address of buffer
		LDRB W0, [X0] // W0 = value at X0
		MOV X7, X0 // save char val in X7

		CMP W0, #'e'
		BEQ deal_or_exit_exit // if 'e', then return... 
		CMP W0, #'d'
		BEQ deal_or_exit_exit // if d', then return... 

		B deal_or_exit_loop // else, try again...

	deal_or_exit_exit:
		ENDL
		MOV X0, X7 // restore char val in X0
		LDP FP, LR, [SP], #16
		RET

// Input: None
// Output: None
print_chips:
	STP FP, LR, [SP, #-16]!
	MOV FP, SP

	LDR X3, =chips_str_len
	PRINT_STR chips_str, X3

	LDR X5, =chips // X10 = address of chips variable
	LDR X5, [X5] // X10 = value of chips variable 
	INT_TO_STR X5, buffer, buffer_len // buffer = str(X10)
	MOV X3, X0 // X0 = num bytes returned
	PRINT_FROM_REG X1, X3 // X1 = address at start of str, X3 = num bytes

	LDP FP, LR, [SP], #16
	RET

// Input: None
// Output: X0=bet
get_bet:
	STP FP, LR, [SP, #-16]!
	MOV FP, SP

	get_bet_loop:
		LDR X3, =placeBet_len
		PRINT_STR placeBet, X3 // print place bet prompt

		GET_STR buffer, buffer_len // user input into buffer 
		STR_TO_INT buffer // int result in X0

		CMP W0, BET_MIN 
		BLE get_bet_loop // retry if bet <= 0
		CMP W0, BET_MAX
		BGT get_bet_loop // retry if bet > 500

	LDP FP, LR, [SP], #16
	RET

// Input: X28=bet
// Output: None
print_bet:
	STP FP, LR, [SP, #-16]!
	MOV FP, SP

	LDR X3, =betPlaced_len
	PRINT_STR betPlaced, X3 // print bet placed text 	

	INT_TO_STR X28, buffer, buffer_len // bet int to str
	MOV X3, X0 // num bytes returned in X0
	PRINT_STR buffer, X3  // print bet placed
	ENDL

	LDP FP, LR, [SP], #16
	RET

// Input: X20=addr of playerHand array, X21=addr of playerCardCount byte
// Output: None
init_player_hand:
	STP FP, LR, [SP, #-16]!
	MOV FP, SP

	LDRB W3, [X21] // W3 = value of playerCardCount

	LDR X0, =deck
	LDR X1, =deckIndex
	BL drawCard // W0 = drawCard(X0, X1)

	STRB W0, [X20, X3] // playerHand[playerCardCount] = W0 
	ADD W3, W3, #1

	LDR X0, =deck
	LDR X1, =deckIndex
	BL drawCard // W0 = drawCard(X0, X1)

	STRB W0, [X20, X3] // playerHand[playerCardCount] = W0 
	ADD W3, W3, #1

	STRB W3, [X21] // playerCardCount = W3

	LDP FP, LR, [SP], #16
	RET

// Input: X24=addr of dealerHand array, X25=addr of dealerCardCount byte
// Output: None
init_dealer_hand:
	STP FP, LR, [SP, #-16]!
	MOV FP, SP

	LDRB W3, [X25] // W3 = dealerCardCount

	LDR X0, =deck
	LDR X1, =deckIndex
	BL drawCard // W0 = drawCard(X0, X1)

	STRB W0, [X24, X3] // dealerHand[dealerCardCount] = W0 
	ADD X3, X3, #1

	LDR X0, =deck
	LDR X1, =deckIndex
	BL drawCard // W0 = drawCard(X0, X1)

	STRB W0, [X24, X3] // dealerHand[dealerCardCount] = W0 
	ADD X3, X3, #1

	STRB W3, [X25] // dealerCardCount = W3

	LDP FP, LR, [SP], #16
	RET

// Input: X0=address of playerHand, X1=address of playerCardCount
// Output: X0=player's total 
player_play:
	STP FP, LR, [SP, #-16]!
	MOV FP, SP
	SUB SP, SP, #16

	STR X19, [FP, #-8]

	player_play_loop:
		PRINT_STR hitOrStand, hit_or_stand_len
		GET_STR buffer, buffer_len // get user input

		CMP X0, #2 // make sure input is only 1 char
		BGT player_play_loop

		LDR X0, =buffer // X0 = address of buffer
		LDRB W0, [X0] // W0 = value at X0

		CMP W0, #'s'
		BEQ player_play_exit // if 's', then exit 
		CMP W0, #'h'
		BNE player_play_loop // if not 'h', try again... 

		LDRB W19, [X21] // W19 = value of playerCardCount

		LDR X0, =deck
		LDR X1, =deckIndex
		BL drawCard // W0 = drawCard(X0, X1)

		STRB W0, [X20, X19] // playerHand[playerCardCount] = W0 
		ADD W19, W19, #1
		STRB W19, [X21] // playerCardCount = W6 + 1

		PRINT_STR dealerShows, dealer_shows_len
		MOV X0, X24
		MOV X1, #1 // only show dealer's first card
		BL printHand 

		PRINT_STR yourHand, your_hand_len
		MOV X0, X20 // X0 = address of playerHand
		MOV X1, X19  // X1 = playerCardCount
		BL printHand
		ENDL

		MOV X0, X20 // X0 = address of playerHand 
		MOV X1, X19 // X1 = playerCardCount
		BL calcTotal // X0 = calcTotal(X0, X1)

		CMP X0, BLACKJACK
		BGE player_play_exit // if total >= 21, then exit...
		
		B player_play_loop

	player_play_exit:
		MOV X0, X20 // X0 = address of playerHand 
		LDRB W1, [X21] // W1 = value of playerCardCount
		BL calcTotal // X0 = calcTotal(X0, X1)

		LDR X19, [FP, #-8]

		ADD SP, SP, #16
		LDP FP, LR, [SP], #16
		RET

// Input: None
// Output: None 
dealer_play:
	STP FP, LR, [SP, #-16]!
	MOV FP, SP
	SUB SP, SP, #16

	STR X19, [FP, #-8]

	ENDL
	PRINT_STR dealersTurn, dealers_turn_len
	ENDL

	dealer_play_loop:
		MOV X0, X24 // X0 = address of dealerHand
		LDRB W19, [X25] 
		MOV X1, X19 // X1 = dealerCardCount
		BL calcTotal // X0 = calcTotal(X0, X1) 

		// if total >= dealer max, then compare hands
		CMP X0, DEALER_MAX 
		BGE dealer_play_exit 

		LDR X0, =deck
		LDR X1, =deckIndex
		BL drawCard // W0 = drawCard(X0, X1)

		STRB W0, [X24, X19] // dealerHand[dealerCardCount] = W0 
		ADD W19, W19, #1
		STRB W19, [X25] // dealerCardCount++

		B dealer_play_loop
	
	dealer_play_exit:
		LDR X19, [FP, #-8]

		ADD SP, SP, #16
		LDP FP, LR, [SP], #16
		RET

.global _start
_start:
		LDR X3, =title_len
		PRINT_STR title, X3 
		ENDL
		ENDL

		deal:
			LDR X0, =chips
			LDR X0, [X0]
			CMP X0, #0
			BLE noMoney 

			BL get_deal_or_exit
			CMP W0, #'e'
			BEQ exit // if 'e', then exit

			BL print_chips
			BL get_bet
			MOV X28, X0 // move bet result to X28
			BL print_bet

			// Init and shuffle deck
			LDR X0, =deck	
			BL initDeck 
			BL shuffleDeck
			LDR X0, =deckIndex
			BL resetDeckIndex

			MOV X2, #0
			// init callee-saved registers
			LDR X20, =playerHand // X20 = address of playerHand
			LDR X21, =playerCardCount // X21 = address of playerCardCount
			STRB W2, [X21] // playerCardCount = 0

			LDR X22, =playerHand2 // X22 = address of playerHand2
			LDR X23, =playerCardCount2 // X23 = address of playerCardCount2
			STRB W2, [X23] // playerCardCount = 0

			LDR X24, =dealerHand // X24 = address of dealerHand
			LDR X25, =dealerCardCount // X25 = address of dealerCardCount
			STRB W2, [X25] // dealerCardCount = 0

			BL init_player_hand
			BL init_dealer_hand

			// Print dealer's hand (hide 2nd card)
			PRINT_STR dealerShows, dealer_shows_len
			MOV X0, X24 // X0 = X24 = address of dealerHand
			MOV X1, #1 // only show dealer's first card
			BL printHand 

			// Print player's entire hand
			PRINT_STR yourHand, your_hand_len
			MOV X0, X20 // X0 = X20 = address of playerHand
			MOV X1, #2 // show player's starting hand
			BL printHand
			ENDL

			// Check if player got blackjack initially
			MOV X0, X20 
			LDRB W1, [X21]
			BL calcTotal // X0 = calcTotal(X0, X1)
			CMP X0, BLACKJACK 
			BEQ playerWin

			// Player's turn
			MOV X0, X20
			MOV X1, X21
			BL player_play
			CMP X0, BLACKJACK
			BEQ playerWin
			BGT busted

			// Dealer's turn
			BL dealer_play

		compare:
			// Get dealer total
			MOV X0, X24 // X0 = address of dealerHand
			LDRB W1, [X25] // W1 = dealerCardCount
			BL calcTotal // X0 = calcTotal(X0, X1)

			MOV X11, X0 // X11 = dealer total

			// Print dealer's hand
			PRINT_STR dealerShows, dealer_shows_len
			MOV X0, X24 // X0 = address of dealerHand
			LDRB W1, [X25] // W1 = dealerCardCount
			BL printHand 

			// Get player total
			MOV X0, X20 // X0 = address of playerHand
			LDRB W1, [X21] // W1 = playerCardCount
			BL calcTotal // X0 = calcTotal(X0, X1)

			MOV X10, X0 // X10 = player total

			// Print player's hand
			PRINT_STR yourHand, your_hand_len
			MOV X0, X20 // X0 = address of playerHand
			LDRB W1, [X21] // W1 = playerCardCount
			BL printHand

			// if dealer total > 21, then player wins...
			CMP X11, BLACKJACK 			
			BGT playerWin

			// else compare player and dealer hands
			CMP X10, X11
			BGT playerWin
			BLT dealerWin
			BEQ push

		busted:
			PRINT_STR bust, bust_len
			ENDL
			ENDL

			LDR X0, =chips // X0 = address of chips
			MOV X1, X28 // X1 = bet
			BL subChips
			B deal

		playerWin:
			PRINT_STR playerWins, player_wins_len
			ENDL
			ENDL

			LDR X0, =chips // X0 = address of chips
			MOV X1, X28 // X1 = bet
			BL addChips
			B deal
			
		dealerWin:
			PRINT_STR dealerWins, dealer_wins_len
			ENDL
			ENDL 

			LDR X0, =chips // X0 = address of chips
			MOV X1, X28 // X1 = bet
			BL subChips
			B deal

		push:
			PRINT_STR tie, tie_len
			ENDL
			ENDL

			B deal

	noMoney:
		PRINT_STR nochips, no_chips_len
		ENDL

	exit:
		MOV W0, #0
		MOV W8, #93
		SVC 0
