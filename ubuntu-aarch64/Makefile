AS = as
CC = gcc
CFLAGS = -std=c99 -Wall -Werror -pedantic $(DEBUGFLGS)
LD = ld

ASM_OBJS = blackjack.o
MAIN_OBJ = main.o
TEST_OBJ = test.o

EXEC = blackjack
TEST = test

ifdef DEBUG
DEBUGFLGS = -g
else
DEBUGFLGS = 
endif

all: $(EXEC) $(TEST)

%.o:%.s
	$(AS) $(DEBUGFLGS) $< -o $@

$(EXEC): $(MAIN_OBJ) $(ASM_OBJS)
	$(LD) -o $(EXEC) $(MAIN_OBJ) $(ASM_OBJS)

$(TEST): $(TEST_OBJ) $(ASM_OBJS)
	$(CC) $(CFLAGS) -o $(TEST) $(TEST_OBJ) $(ASM_OBJS)

$(TEST_OBJ): test.c
	$(CC) $(CFLAGS) -c test.c -o $(TEST_OBJ)

clean:
	rm -f *.o $(EXEC) $(TEST)

.PHONY: clean
