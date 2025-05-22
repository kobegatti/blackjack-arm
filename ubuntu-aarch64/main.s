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

	splitPrompt: .asciz "Do you want to split? (y/n): "
	split_prompt_len = .-splitPrompt

	secondSplitHand: .asciz "Second split hand: "
	second_split_hand_len = .-secondSplitHand

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
	numHands: .byte 1

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
.extern init_deck
.extern shuffle_deck
.extern reset_deck_index
.extern get_random_number
.extern draw_card
.extern print_deck
.extern print_hand
.extern calc_total
.extern get_card_value
.extern get_card_rank


// Input: None
// Output: X0='d'|'e' 
get_deal_or_exit:
	STP FP, LR, [SP, #-16]!
	MOV FP, SP
	SUB SP, SP, #16

	STR X19, [FP, #-8]

	deal_or_exit_loop:
		LDR X3, =dealOrExit_len
		PRINT_STR dealOrExit, X3 // print deal or exit prompt
		GET_STR buffer, buffer_len // get user input 

		CMP X0, #2 // make sure input is only 1 char
		BGT deal_or_exit_loop

		LDR X0, =buffer // X0 = addr of buffer
		LDRB W0, [X0] // W0 = value at X0
		MOV X19, X0 // save char val in X19

		CMP W0, #'e'
		BEQ deal_or_exit_exit // if 'e', then return... 
		CMP W0, #'d'
		BEQ deal_or_exit_exit // if d', then return... 

		B deal_or_exit_loop // else, try again...

	deal_or_exit_exit:
		MOV X0, X19 // restore char val from X19 to X0

		LDR X19, [FP, #-8]
		
		ADD SP, SP, #16
		LDP FP, LR, [SP], #16
		RET

// Input: None
// Output: None
print_chips:
	STP FP, LR, [SP, #-16]!
	MOV FP, SP

	LDR X3, =chips_str_len
	PRINT_STR chips_str, X3

	LDR X5, =chips // X10 = addr of chips variable
	LDR X5, [X5] // X10 = value of chips variable 
	INT_TO_STR X5, buffer, buffer_len // buffer = str(X10)
	MOV X3, X0 // X0 = num bytes returned
	PRINT_FROM_REG X1, X3 // X1 = addr at start of str, X3 = num bytes

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

// Input: X0=addr of byte array filled with 0s (cards), X1=addr of card count byte(=0)
// Output: cards array with first 2 elements populated; card count byte=2
init_hand: 
	STP FP, LR, [SP, #-16]!
	MOV FP, SP
	SUB SP, SP, #32

	STR X20, [FP, #-8]
	STR X21, [FP, #-16]
	STR X22, [FP, #-24]

	MOV X20, X0 // X20 = addr of cards array
	MOV X21, X1 // X21 = addr of card count byte 
	LDRB W22, [X1] // W22 = val of card count byte

	LDR X0, =deck
	LDR X1, =deckIndex
	BL draw_card // W0 = draw_card(X0, X1)

	STRB W0, [X20, X22] // cards[cardCount] = W0
	ADD W22, W22, #1 // cardCount++

	LDR X0, =deck
	LDR X1, =deckIndex
	BL draw_card // W0 = draw_card(X0, X1)

	STRB W0, [X20, X22] // cards[cardCount] = W0
	ADD W22, W22, #1 // cardCount++

	STRB W22, [X21] // cardCount = W22

	LDR X22, [FP, #-24]
	LDR X21, [FP, #-16]
	LDR X20, [FP, #-8]

	ADD SP, SP, #32
	LDP FP, LR, [SP], #16
	RET

// Input: X0=addr of playerHand, X1=addr of playerCardCount
// Output: X0=player's total 
player_play:
	STP FP, LR, [SP, #-16]!
	MOV FP, SP
	SUB SP, SP, #32

	STR X19, [FP, #-8]
	STR X20, [FP, #-16]
	STR X21, [FP, #-24]

	MOV X20, X0 // X20 = addr of playerHand
	MOV X21, X1 // X21 = addr of playerCardCount
	LDRB W19, [X21] // W19 = value of playerCardCount

	player_play_loop:
		PRINT_STR hitOrStand, hit_or_stand_len
		GET_STR buffer, buffer_len // get user input

		CMP X0, #2 // make sure input is only 1 char
		BGT player_play_loop

		LDR X0, =buffer // X0 = addr of buffer
		LDRB W0, [X0] // W0 = value at (byte)buffer[0]

		CMP W0, #'s'
		BEQ player_play_exit // if 's', then exit 
		CMP W0, #'h'
		BNE player_play_loop // if not 'h', try again... 

		LDR X0, =deck
		LDR X1, =deckIndex
		BL draw_card // W0 = draw_card(X0, X1)

		STRB W0, [X20, X19] // playerHand[playerCardCount] = W0 
		ADD W19, W19, #1 // playerCardCount++

		PRINT_STR dealerShows, dealer_shows_len
		MOV X0, X24
		MOV X1, #1 // only show dealer's first card
		BL print_hand 

		PRINT_STR yourHand, your_hand_len
		MOV X0, X20 // X0 = addr of playerHand
		MOV X1, X19  // X1 = playerCardCount
		BL print_hand

		MOV X0, X20 // X0 = addr of playerHand 
		MOV X1, X19 // X1 = playerCardCount
		BL calc_total // X0 = calc_total(X0, X1)

		CMP X0, BLACKJACK
		BGE player_play_exit // if total >= 21, then exit...
		
		ENDL
		B player_play_loop

	player_play_exit:
		ENDL

		STRB W19, [X21] // playerCardCount = W19

		MOV X0, X20 // X0 = addr of playerHand 
		LDRB W1, [X21] // W1 = value of playerCardCount
		BL calc_total // X0 = calc_total(X0, X1)

		LDR X21, [FP, #-24]
		LDR X20, [FP, #-16]
		LDR X19, [FP, #-8]

		ADD SP, SP, #32
		LDP FP, LR, [SP], #16
		RET

// Input: X0=addr of dealerHand, X1=addr of dealerCardCount
// Output: X0=dealer's total 
dealer_play:
	STP FP, LR, [SP, #-16]!
	MOV FP, SP
	SUB SP, SP, #32

	STR X19, [FP, #-8]
	STR X24, [FP, #-16]
	STR X25, [FP, #-24]

	MOV X24, X0 // X24 = addr of dealerHand
	MOV X25, X1 // X25 = addr of dealerCardCount
	LDRB W19, [X25] // W19 = value of dealerCardCount

	PRINT_STR dealersTurn, dealers_turn_len
	ENDL

	dealer_play_loop:
		MOV X0, X24 // X0 = addr of dealerHand
		MOV X1, X19
		BL calc_total // X0 = calc_total(X0, X1) 

		// if total >= dealer max, then compare hands
		CMP X0, DEALER_MAX 
		BGE dealer_play_exit 

		LDR X0, =deck
		LDR X1, =deckIndex
		BL draw_card // W0 = draw_card(X0, X1)

		STRB W0, [X24, X19] // dealerHand[dealerCardCount] = W0 
		ADD W19, W19, #1 // dealerCardCount++

		B dealer_play_loop
	
	dealer_play_exit:
		STRB W19, [X25] // W19 = dealerCardCount

		LDR X25, [FP, #-24]
		LDR X24, [FP, #-16]
		LDR X19, [FP, #-8]

		ADD SP, SP, #32
		LDP FP, LR, [SP], #16
		RET

handle_bust:
	STP FP, LR, [SP, #-16]!
	MOV FP, SP

	PRINT_STR bust, bust_len
	ENDL
	ENDL

	LDR X0, =chips
	MOV X1, X28 // X1 = bet
	BL sub_chips

	LDP FP, LR, [SP], #16
	RET

handle_player_win:
	STP FP, LR, [SP, #-16]!
	MOV FP, SP

	PRINT_STR playerWins, player_wins_len
	ENDL
	ENDL

	LDR X0, =chips
	MOV X1, X28 // X1 = bet
	BL add_chips

	LDP FP, LR, [SP], #16
	RET

handle_dealer_win:
	STP FP, LR, [SP, #-16]!
	MOV FP, SP

	PRINT_STR dealerWins, dealer_wins_len
	ENDL
	ENDL 

	LDR X0, =chips
	MOV X1, X28 // X1 = bet
	BL sub_chips

	LDP FP, LR, [SP], #16
	RET

handle_push:
	STP FP, LR, [SP, #-16]!
	MOV FP, SP

	PRINT_STR tie, tie_len
	ENDL
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

			BL get_deal_or_exit // X0 = 'd' or 'e'
			CMP W0, #'e'
			BEQ exit // if user entered 'e', then exit

			BL print_chips
			BL get_bet
			MOV X28, X0 // move bet result to X28
			BL print_bet

			initDeck:
				LDR X0, =deck	
				BL init_deck 

			shuffleDeck:
				BL shuffle_deck

				LDR X0, =deckIndex
				BL reset_deck_index

			MOV X2, #0
			// init callee-saved registers
			loadPlayerHand:
				LDR X20, =playerHand // X20 = addr of playerHand
				LDR X21, =playerCardCount // X21 = addr of playerCardCount
				STRB W2, [X21] // playerCardCount = 0

			loadPlayerHand2: // for split case
				LDR X22, =playerHand2 // X22 = addr of playerHand2
				LDR X23, =playerCardCount2 // X23 = addr of playerCardCount2
				STRB W2, [X23] // playerCardCount = 0

			loadDealerHand:
				LDR X24, =dealerHand // X24 = addr of dealerHand
				LDR X25, =dealerCardCount // X25 = addr of dealerCardCount
				STRB W2, [X25] // dealerCardCount = 0

			loadNumHands:
				LDR X26, =numHands

			initHands:
				MOV X0, X20 // X0 = addr of playerHand
				MOV X1, X21 // X1 = addr of playerCardCount
				BL init_hand

				MOV X0, X24 // X0 = addr of dealerHand
				MOV X1, X25 // X1 = addr of dealerCardCount
				BL init_hand

			printDealerHand: // hide 2nd card
				PRINT_STR dealerShows, dealer_shows_len
				MOV X0, X24 // X0 = X24 = addr of dealerHand
				MOV X1, #1 // only show dealer's first card
				BL print_hand 

			printPlayerHand: 
				PRINT_STR yourHand, your_hand_len
				MOV X0, X20 // X0 = X20 = addr of playerHand
				LDRB W1, [X21]
				BL print_hand
				ENDL

			// Check if player got blackjack initially
			MOV X0, X20 
			LDRB W1, [X21]
			BL calc_total // X0 = calc_total(X0, X1)
			CMP X0, BLACKJACK 
			BNE check_for_split // if not 21, then continue...
			
			BL handle_player_win // else, player has blackjack
			B deal

			check_for_split:
				LDRB W0, [X20]
				BL get_card_rank
				MOV W2, W0 // W2 = 1st card value

				LDRB W0, [X20, #1]
				BL get_card_rank
				MOV W3, W0 // W3 = 2nd card value

				CMP W2, W3
				BNE players_turn
	
			handle_split:
				PRINT_STR splitPrompt, split_prompt_len
				GET_STR buffer, buffer_len // get user input 

				CMP X0, #2 // make sure input is only 1 char
				BGT handle_split 

				LDR X0, =buffer
				LDRB W0, [X0]

				CMP W0, #'n'
				BEQ players_turn

				CMP W0, #'y'
				BNE handle_split

				LDRB W1, [X20, #1] // W1 = player's 2nd card
				MOV W2, #0
				STRB W2, [X20, #1] // remove 2nd card from 1st hand
				STRB W1, [X22] // load 2nd card from 1st hand to 2nd hand

				ADD W2, W2, #1
				STRB W2, [X21] // playerCardCount = 1
				STRB W2, [X23] // playerCardCount2 = 1

				ADD W2, W2, #1
				STRB W2, [X26] // numHands = 2

				PRINT_STR dealerShows, dealer_shows_len
				MOV X0, X24 // X0 = X24 = addr of dealerHand
				MOV X1, #1 // only show dealer's first card
				BL print_hand 

				print1stHand:
					PRINT_STR yourHand, your_hand_len
					MOV X0, X20 // X0 = X20 = addr of playerHand
					LDRB W1, [X21]
					BL print_hand
					ENDL
				
			// Player's turn
			players_turn:
				play1stHand:
					MOV X0, X20
					MOV X1, X21
					BL player_play

				LDRB W19, [X26] // W19 = numHands
				CMP W19, #2 // check if player split (numHands = 2)
				BNE dealers_turn // if not, then dealer's turn

				PRINT_STR dealerShows, dealer_shows_len
				MOV X0, X24 // X0 = X24 = addr of dealerHand
				MOV X1, #1 // only show dealer's first card
				BL print_hand 

				print2ndHand:
					PRINT_STR secondSplitHand, second_split_hand_len
					MOV X0, X22 // X0 = X22 = addr of playerHand2
					MOV X1, #1
					BL print_hand
					ENDL

				play2ndHand:
					MOV X0, X22
					MOV X1, X23
					BL player_play

			// Dealer's turn
			dealers_turn:
				MOV X0, X24 // X0 = addr of dealerHand
				MOV X1, X25 // X1 = addr of dealerCardCount
				BL dealer_play

		compare:
			// Get dealer total
			MOV X0, X24 // X0 = addr of dealerHand
			LDRB W1, [X25] // W1 = dealerCardCount
			BL calc_total // X0 = calc_total(X0, X1)

			MOV X11, X0 // X11 = dealer total

			// Print dealer's hand
			PRINT_STR dealerShows, dealer_shows_len
			MOV X0, X24 // X0 = addr of dealerHand
			LDRB W1, [X25] // W1 = dealerCardCount
			BL print_hand 

			// Get player total
			MOV X0, X20 // X0 = addr of playerHand
			LDRB W1, [X21] // W1 = playerCardCount
			BL calc_total // X0 = calc_total(X0, X1)

			MOV X10, X0 // X10 = player total

			// Print player's hand
			PRINT_STR yourHand, your_hand_len
			MOV X0, X20 // X0 = addr of playerHand
			LDRB W1, [X21] // W1 = playerCardCount
			BL print_hand

			checkPlayerHand:
				// if player total > 21, then dealer wins
				CMP X10, BLACKJACK
				BLE checkDealerHand // else player total <= 21; compare hands

				BL handle_dealer_win // else player total > 21; dealer wins
				B compare2ndHand
		
			checkDealerHand:
				// if dealer total > 21, then player wins
				CMP X11, BLACKJACK
				BLE compare1stHand // else check player's hand

				BL handle_player_win // else dealer total > 21; player wins
				B compare2ndHand

			compare1stHand:
				CMP X10, X11
				BGT pWin1 
				BLT dWin1 
				BEQ push1 

				pWin1:
					BL handle_player_win
					B compare2ndHand
				dWin1:
					BL handle_dealer_win
					B compare2ndHand
				push1:
					BL handle_push
					B compare2ndHand

			compare2ndHand:
				CMP W19, #2
				BNE deal

				SUB W19, W19, #1
				STRB W19, [X26] // numHands -= 1

				MOV X0, X22 // X0 = addr of playerHand2
				LDRB W1, [X23] // W1 = playerCardCount2
				BL calc_total

				MOV X10, X0 // X10 = player total 2

				// print dealer's hand
				PRINT_STR dealerShows, dealer_shows_len
				MOV X0, X24 // X0 = addr of dealerHand
				LDRB W1, [X25] // W1 = dealerCardCount
				BL print_hand 

				// print player's 2nd hand
				PRINT_STR yourHand, your_hand_len
				MOV X0, X22 // X0 = addr of playerHand2
				LDRB W1, [X23] // W1 = playerCardCount2
				BL print_hand

				CMP X10, BLACKJACK
				BLE compare2ndCont // if player total <= 21, then compare

				BL handle_dealer_win // else player total > 21; dealer wins
				B deal
	
				compare2ndCont:
					CMP X11, BLACKJACK
					BGT pWin2 // if dealer total > 21, then player wins

					CMP X10, X11
					BGT pWin2 
					BLT dWin2 
					BEQ push2 

					pWin2:
						BL handle_player_win
						B deal
					dWin2:
						BL handle_dealer_win
						B deal
					push2:
						BL handle_push
						B deal

	noMoney:
		PRINT_STR nochips, no_chips_len
		ENDL

	exit:
		MOV W0, #0
		MOV W8, #93
		SVC 0
