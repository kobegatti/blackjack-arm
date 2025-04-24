#include <stdint.h>
#include <stdio.h>

#define DECK_SIZE 52
#define HAND_SIZE 12

// globals to this file
//static const uint8_t* VALUES = "A23456789TJQKA23456789TJQKA23456789TJQKA23456789TJQK";
//static const uint8_t* SUITS = "HHHHHHHHHHHHHDDDDDDDDDDDDDCCCCCCCCCCCCCSSSSSSSSSSSSS";

// blackjack.s functions
extern uint8_t* initDeck(uint8_t* deck);
extern uint8_t* shuffleDeck(uint8_t* deck);
extern uint8_t* resetDeckIndex(uint8_t* deckIndex);
extern uint8_t getRandomNumber(uint8_t upperLimit);
extern uint8_t drawCard(uint8_t* deck, uint8_t* deckIndex);
extern void printHand(uint8_t* deck, uint8_t numCards);
extern uint8_t calcTotal(uint8_t* deck, uint8_t numCards);
extern uint8_t getCardValue(char str);
extern long long* subChips(long long* chips, int val);
extern long long* addChips(long long* chips, int val);

// c test functions
void testInitDeck(uint8_t* deck)
{
	uint8_t ret = 1;

	deck = initDeck(deck);

	for (int i = 0; i < DECK_SIZE; i++)
	{
		if (deck[i] != i) { ret = 0; }
	}

	printf("%s passed: %s\n", __func__, ret ? "true" : "false");
}

void testShuffleDeck(uint8_t* deck)
{
	uint8_t ret = 1;

	deck = shuffleDeck(deck);

	for (int i = 0; i < DECK_SIZE; i++)
	{
		if (deck[i] < 0 || deck[i] >= DECK_SIZE) { ret = 0; }
	}

	printf("%s passed: %s\n", __func__, ret ? "true" : "false");
}

void testResetDeckIndex(uint8_t* deckIndex)
{
	uint8_t ret = 1;
	
	deckIndex = resetDeckIndex(deckIndex);

	ret = (*deckIndex == 0);

	printf("%s passed: %s\n", __func__, ret ? "true" : "false");
}

void testGetRandomNumber(uint8_t upperLimit)
{
	uint8_t ret = 1;
	uint8_t randomNum = getRandomNumber(upperLimit);

	if (randomNum < 0 || randomNum > upperLimit)
	{
		ret = 0;
	}

	printf("%s passed: %s\n", __func__, ret ? "true" : "false");
}

void testDrawCard(uint8_t* deck, uint8_t* deckIndex)
{
	uint8_t ret1 = 1;
	uint8_t ret2 = 1;
	uint8_t expected = drawCard(deck, deckIndex);

	if (expected != deck[*deckIndex - 1])
	{
		ret1 = 0;
	}

	expected = drawCard(deck, deckIndex);

	if (expected != deck[*deckIndex - 1])
	{
		ret2 = 0;
	}

	printf("%s passed: %s\n", __func__, ret1 & ret2 ? "true" : "false");
}

void testPrintHand(uint8_t* deck, uint8_t numCards)
{
	uint8_t ret = 1;

	printHand(deck, numCards);

	printf("%s passed: %s\n", __func__, ret ? "true" : "false");
}

void testCalcTotal(uint8_t* hand, uint8_t count, uint8_t expected)
{
	uint8_t ret = 1;
	uint8_t actualTotal = calcTotal(hand, count);

	if (actualTotal != expected) { ret = 0; }

	printf("%s passed: %s\n", __func__, ret ? "true" : "false");
}

void testGetCardValue(char c, int expected)
{
	uint8_t ret = 1;
	uint8_t actual = getCardValue(c);

	if (actual != expected) { ret = 0; }

	printf("%s passed: %s\n", __func__, ret ? "true" : "false");
}

void testSubChips(long long* chips, int val, long long expected)
{
	uint8_t ret = 1;
	long long* actual = subChips(chips, val);

	if (*actual != expected) { ret = 0; }

	printf("%s passed: %s\n", __func__, ret ? "true" : "false");
}

void testAddChips(long long* chips, int val, long long expected)
{
	uint8_t ret = 1;
	long long* actual = addChips(chips, val);

	if (*actual != expected) { ret = 0; }

	printf("%s passed: %s\n", __func__, ret ? "true" : "false");
}

int main(void)
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

	testGetCardValue('A', 11);
	testGetCardValue('K', 10);
	testGetCardValue('Q', 10);
	testGetCardValue('J', 10);
	testGetCardValue('5', 5);

	testSubChips(&chips, 500, 2000);
	testSubChips(&chips, 1, 1999);
	testSubChips(&chips, 2000, -1);

	testAddChips(&chips, 1, 0);
	testAddChips(&chips, 100, 100);
	testAddChips(&chips, 233, 333);

	return 0;
}
