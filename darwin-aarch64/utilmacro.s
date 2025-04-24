.data
	endl: .asciz "\n"
	space: .asciz " "
	underscore: .asciz "_"

.text
.macro ENDL
	mov x0, #1 // stdout
	adrp x1, endl@PAGE
	add x1, x1, endl@PAGEOFF // address of "\n"
	mov x2, #1 // strlen
	mov x16, #4 // macOS write syscall
	svc #0
.endmacro

.macro GET_STR buffer, buffer_len
	mov x0, #0 // stdin
	adrp x1, \buffer@PAGE
	add x1, x1, \buffer@PAGEOFF // address of dest buffer
	mov x2, \buffer_len // length of dest buffer
	mov x16, #3 // macOS read syscall
	svc #0
.endmacro

.macro PRINT_STR str, len
	mov x0, #1 // stdout
	adrp x1, \str@PAGE
	add x1, x1, \str@PAGEOFF // address of string
	mov X2, \len // length of string
	mov x16, #4 // macOS write syscall
	svc #0
.endmacro

.macro PRINT_FROM_REG reg, len
	mov x0, #1 // stdout
	mov x1, \reg // address of string in reg
	mov x2, \len // length of string
	mov x16, #4 // macOS write syscall
	svc #0
.endmacro

// Input: str=address of string to convert
// Output: X0=converted int
.macro STR_TO_INT str
	mov x0, #0
	adrp x1, \str@PAGE
	add x1, x1, \str@PAGEOFF

	1:
		// Load char from str and increment pointer
		ldrb W2, [X1], #1 		
		cmp W2, #10
		beq 2f // Exit if new line
		cmp W2, #'0' 
		blt 2f // Exit if byte less than '0'
		cmp W2, #'9'
		bgt 2f // Exit if byte greater than '9'
		
		sub W2, W2, #'0' // Convert char to int
		mov W3, #10
		mul W0, W0, W3 // left shift for current digit
		add W0, W0, W2 // append current digit
		b 1b
	2:
.endmacro

// Input: reg=int, buffer=dest, buffer_len=num bytes
// Output: X0=num bytes written, X1=starting address of string
.macro INT_TO_STR reg, buffer, buffer_len
	mov x0, #1 // number of bytes in return value (1 for '\n')
	mov x1, \reg
	adrp x2, \buffer@PAGE
	add x2, x2, \buffer@PAGEOFF

	// Move pointer to end - 1 (considering null char)
	mov x7, \buffer_len
	sub x7, x7, #1
	add x2, x2, x7

	mov W3, #0x0A // ASCII newline
	strb W3, [X2], #-1 // Store newline at end

	mov W4, #10 // divisor

	1:
		cmp X1, #0
		beq 2f	

		udiv X5, X1, X4 // X5 = X1 / 10
		mul X6, X5, X4 // X6 = X5 * 10
		sub X6, X1, X6 // X6 = X1 % 10
		add X6, X6, #'0' // Convert to ASCII
		strb W6, [X2], #-1

		mov X1, X5
		add X0, X0, #1
		b 1b
	2:
		add X2, X2, #1
		mov X1, X2

.endmacro

.macro SPACE
	mov x0, #1 // fd 1 = stdout
	adrp x1, space@PAGE
	add x1, x1, space@PAGEOFF // address of ' '
	mov x2, #1 // strlen
	mov x16, #4 // macOS write syscall
	svc #0
.endmacro

.macro UNDERSCORE
	mov x0, #1 // fd 1 = stdout
	adrp x1, underscore@PAGE
	add x1, x1, underscore@PAGEOFF // address of '\n'
	mov x2, #1 // strlen
	mov x16, #4 // macOS write syscall
	svc #0
.endmacro
