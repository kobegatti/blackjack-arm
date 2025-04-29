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
	playerCount: .byte 0
	dealerHand: .fill 12, 1, 0 // 12 1-byte card-indices
	dealerCount: .byte 0
	
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
// Output: None
print_chips:
	STP FP, LR, [SP, #-16]!
	MOV FP, SP

	LDR X3, =chips_str_len
	PRINT_STR chips_str, X3

	LDR X10, =chips // X10 = address of chips variable
	LDR X10, [X10] // X10 = value of chips variable 
	INT_TO_STR X10, buffer, buffer_len // buffer = str(X10)
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

			LDR X3, =dealOrExit_len
			PRINT_STR dealOrExit, X3 // print deal or exit prompt
			GET_STR buffer, buffer_len // get user input 

			CMP X0, #2 // make sure input is only 1 char
			BGT deal

			LDR X0, =buffer // X0 = address of buffer
			LDRB W0, [X0] // W0 = value at X0

			CMP W0, #'e'
			BEQ exit // if 'e', then exit
			CMP W0, #'d'
			BNE deal // if not 'd', try again... 
			ENDL

			BL print_chips
			BL get_bet

			MOV X28, X0 // move bet result to X28
			BL print_bet

		initialDeal:	
			LDR X0, =deck	
			BL initDeck 
			BL shuffleDeck

			LDR X0, =deckIndex
			BL resetDeckIndex

			// init callee-saved registers
			MOV X2, #0

			LDR X20, =playerHand // X20 = address of playerHand
			LDR X21, =playerCount // X21 = address of playerCardCount
			STRB W2, [X21] // playerCardCount = 0

			LDR X22, =dealerHand // X22 = address of dealerHand
			LDR X23, =dealerCount // X23 = address of dealerCardCount
			STRB W2, [X23] // dealerCardCount = 0

			// init playerHand and playerCardCount
			LDRB W24, [X21] // W24 = value of playerCardCount

			LDR X0, =deck
			LDR X1, =deckIndex
			BL drawCard // W0 = drawCard(X0, X1)

			STRB W0, [X20, X24] // playerHand[playerCardCount] = W0 
			ADD W24, W24, #1 // W24 += 1

			LDR X0, =deck
			LDR X1, =deckIndex
			BL drawCard // W0 = drawCard(X0, X1)

			STRB W0, [X20, X24] // playerHand[playerCardCount] = W0 
			ADD W24, W24, #1 // W24 += 1

			STRB W24, [X21] // playerCardCount = W24

			// init dealerHand and dealerCardCount
			LDRB W24, [X23] // W24 = dealerCardCount

			LDR X0, =deck
			LDR X1, =deckIndex
			BL drawCard // W0 = drawCard(X0, X1)

			STRB W0, [X22, X24] // dealerHand[dealerCount] = W0 
			ADD X24, X24, #1 // W24 += 1

			LDR X0, =deck
			LDR X1, =deckIndex
			BL drawCard // W0 = drawCard(X0, X1)

			STRB W0, [X22, X24] // dealerHand[dealerCardCount] = W0 
			ADD X24, X24, #1 // W24 += 1

			STRB W24, [X23] // dealerCardCount = W24


			PRINT_STR dealerShows, dealer_shows_len
			MOV X0, X22 // X0 = address of dealerHand
			MOV X1, #1 // only show dealer's first card
			BL printHand 

			PRINT_STR yourHand, your_hand_len
			MOV X0, X20 // X0 = address of playerHand
			MOV X1, #2 // show player's starting hand
			BL printHand
			ENDL


			MOV X0, X20 // X0 = address of playerHand
			LDRB W24, [X21]
			MOV X1, X24 // X1 = playerCardCount
			BL calcTotal // X0 = calcTotal(X0, X1)

			CMP X0, BLACKJACK 
			BEQ playerWin


		playerPlay:
			PRINT_STR hitOrStand, hit_or_stand_len
			GET_STR buffer, buffer_len // get user input
			CMP X0, #2 // make sure input is only 1 char
			BGT playerPlay

			LDR X0, =buffer // X0 = address of buffer
			LDRB W0, [X0] // W0 = value at X0

			CMP W0, #'s'
			BEQ dealerPlay // if 's', then dealer's turn 
			CMP W0, #'h'
			BNE playerPlay// if not 'h', try again... 


			LDRB W24, [X21] // W24 = value of playerCount

			LDR X0, =deck
			LDR X1, =deckIndex
			BL drawCard // W0 = drawCard(X0, X1)

			STRB W0, [X20, X24] // playerHand[playerCardCount] = W0 
			ADD W24, W24, #1 // W24 += 1
			STRB W24, [X21] // playerCardCount = W24

			PRINT_STR dealerShows, dealer_shows_len
			MOV X0, X22
			MOV X1, #1 // only show dealer's first card
			BL printHand 

			PRINT_STR yourHand, your_hand_len
			MOV X0, X20 // X0 = address of playerHand
			MOV X1, X24  // X1 = playerCardCount
			BL printHand
			ENDL

			MOV X0, X20 // X0 = address of playerHand 
			MOV X1, X24 // X1 = playerCardCount
			BL calcTotal // X0 = calcTotal(X0, X1)

			CMP X0, BLACKJACK
			BLT playerPlay // if total < 21, then cont...
			BEQ playerWin // if total == 21, then win...

			// if total > 21, then bust...
			PRINT_STR bust, bust_len
			ENDL
			ENDL

			LDR X0, =chips // X0 = address of chips
			MOV X1, X28 // X1 = bet
			BL subChips
			B deal


		dealerPlay:
			ENDL
			PRINT_STR dealersTurn, dealers_turn_len
			ENDL
		
			dealerLoop:
				MOV X0, X22 // X0 = address of dealerHand
				LDRB W24, [X23] 
				MOV X1, X24 // X1 = dealerCardCount
				BL calcTotal // X0 = calcTotal(X0, X1) 

				// if total >= dealer max, then compare hands
				CMP X0, #17 
				BGE compare

				LDR X0, =deck
				LDR X1, =deckIndex
				BL drawCard // W0 = drawCard(X0, X1)

				STRB W0, [X22, X24] // dealerHand[dealerCardCount] = W0 
				ADD W24, W24, #1
				STRB W24, [X23] // dealerCardCount++

				B dealerLoop


		compare:
			MOV X0, X22 // X0 = address of dealerHand
			LDRB W24, [X23] 
			MOV X1, X24 // X1 = dealerCardCount
			BL calcTotal // X0 = calcTotal(X0, X1)

			MOV X11, X0 // X11 = dealer total

			PRINT_STR dealerShows, dealer_shows_len
			MOV X0, X22
			MOV X1, X24 
			BL printHand 

			MOV X0, X20 // X0 = address of playerHand
			LDRB W24, [X21] 
			MOV X1, X24 // X1 = playerCardCount
			BL calcTotal // X0 = calcTotal(X0, X1)

			MOV X10, X0 // X10 = player total

			PRINT_STR yourHand, your_hand_len
			MOV X0, X20
			MOV X1, X24 
			BL printHand

			// if dealer total > 21, then player wins...
			CMP X11, BLACKJACK 			
			BGT playerWin

			CMP X10, X11
			BGT playerWin
			BLT dealerWin
			BEQ push

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
