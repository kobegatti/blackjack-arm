#include <assert.h>
#include <stdint.h>
#include <stdio.h>

#define DECK_SIZE 52
#define HAND_SIZE 12

// globals to this file
//static const uint8_t* VALUES = "A23456789TJQKA23456789TJQKA23456789TJQKA23456789TJQK";
//static const uint8_t* SUITS =  "HHHHHHHHHHHHHDDDDDDDDDDDDDCCCCCCCCCCCCCSSSSSSSSSSSSS";

// blackjack.s functions
extern uint8_t* init_deck(uint8_t* deck);
extern uint8_t* shuffle_deck(uint8_t* deck);
extern uint8_t* reset_deck_index(uint8_t* deckIndex);
extern uint8_t get_random_number(uint8_t upperLimit);
extern uint8_t draw_card(uint8_t* deck, uint8_t* deckIndex);
extern void print_hand(uint8_t* deck, uint8_t numCards);
extern uint8_t calc_total(uint8_t* deck, uint8_t numCards);
extern uint8_t get_card_value(char str);
extern long long* sub_chips(long long* chips, int val);
extern long long* add_chips(long long* chips, int val);

// c test functions
void testInitDeck(uint8_t* deck)
{
	uint8_t ret = 1;

	deck = init_deck(deck);

	for (int i = 0; i < DECK_SIZE; i++)
	{
		if (deck[i] != i) { ret = 0; }
	}

	assert(ret);
}

void testShuffleDeck(uint8_t* deck)
{
	uint8_t ret = 1;

	deck = shuffle_deck(deck);

	for (int i = 0; i < DECK_SIZE; i++)
	{
		if (deck[i] < 0 || deck[i] >= DECK_SIZE) { ret = 0; }
	}

	assert(ret);
}

void testResetDeckIndex(uint8_t* deckIndex)
{
	uint8_t ret = 1;
	
	deckIndex = reset_deck_index(deckIndex);

	ret = (*deckIndex == 0);

	assert(ret);
}

void testGetRandomNumber(uint8_t upperLimit)
{
	uint8_t ret = 1;
	uint8_t randomNum = get_random_number(upperLimit);

	if (randomNum < 0 || randomNum > upperLimit)
	{
		ret = 0;
	}

	assert(ret);
}

void testDrawCard(uint8_t* deck, uint8_t* deckIndex)
{
	uint8_t ret1 = 1;
	uint8_t ret2 = 1;
	uint8_t expected = draw_card(deck, deckIndex);

	if (expected != deck[*deckIndex - 1])
	{
		ret1 = 0;
	}

	expected = draw_card(deck, deckIndex);

	if (expected != deck[*deckIndex - 1])
	{
		ret2 = 0;
	}

	assert(ret1);
	assert(ret2);
}

void testPrintHand(uint8_t* deck, uint8_t numCards)
{
	print_hand(deck, numCards);
}

void testCalcTotal(uint8_t* hand, uint8_t count, uint8_t expected)
{
	uint8_t ret = 1;
	uint8_t actualTotal = calc_total(hand, count);

	if (actualTotal != expected) { ret = 0; }

	assert(ret);
}

void testGetCardValue(char c, int expected)
{
	uint8_t ret = 1;
	uint8_t actual = get_card_value(c);

	if (actual != expected) { ret = 0; }

	assert(ret);
}

void testSubChips(long long* chips, int val, long long expected)
{
	uint8_t ret = 1;
	long long* actual = sub_chips(chips, val);

	if (*actual != expected) { ret = 0; }

	assert(ret);
}

void testAddChips(long long* chips, int val, long long expected)
{
	uint8_t ret = 1;
	long long* actual = add_chips(chips, val);

	if (*actual != expected) { ret = 0; }

	assert(ret);
}

int main()
{
	uint8_t deck[DECK_SIZE] = {0};
	uint8_t deckIndex = 31;

	uint8_t player1[HAND_SIZE] = {0, 11}; // AH, QH
	uint8_t player1Count = 2;
	uint8_t expectedPlayer1Total = 21;

	uint8_t player2[HAND_SIZE] = {17, 28, 45}; // 5D, 3C, 7S
	uint8_t player2Count = 3;
	uint8_t expectedPlayer2Total = 15;

	uint8_t player3[HAND_SIZE] = {3, 20, 26, 51}; // 4H, 8D, AC, KS
	uint8_t player3Count = 4;
	uint8_t expectedPlayer3Total = 23;

	long long chips = 2500;

	testInitDeck(deck);

	testShuffleDeck(deck);

	testResetDeckIndex(&deckIndex);

	testGetRandomNumber(DECK_SIZE - 1);

	testDrawCard(deck, &deckIndex);

	testPrintHand(deck, DECK_SIZE);

	testCalcTotal(player1, player1Count, expectedPlayer1Total);
	testCalcTotal(player2, player2Count, expectedPlayer2Total);
	testCalcTotal(player3, player3Count, expectedPlayer3Total);

	testGetCardValue(0, 11); // AH
	testGetCardValue(24, 10); // QD
	testGetCardValue(38, 10); // KC
	testGetCardValue(49, 10); // JS
	testGetCardValue(4, 5); // 5H

	testSubChips(&chips, 500, 2000);
	testSubChips(&chips, 1, 1999);
	testSubChips(&chips, 2000, -1);

	testAddChips(&chips, 1, 0);
	testAddChips(&chips, 100, 100);
	testAddChips(&chips, 233, 333);

	return 0;
}
