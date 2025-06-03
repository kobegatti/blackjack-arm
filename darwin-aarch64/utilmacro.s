.data
	endl: .asciz "\n"
	space: .asciz " "
	underscore: .asciz "_"
	miniBuf: .skip 1

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
	mov x2, \buffer_len
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
// Output: X0=converted int, X1=num digits
.macro STR_TO_INT str
	mov W0, #0
	adrp x1, \str@PAGE
	add x1, x1, \str@PAGEOFF
	mov W4, #0

	// Remove leading 0s
	1:
		ldrb W2, [X1] // load char in str
		cmp W2, #'0'
		bne 2f
		add X1, X1, #1 // increment addr by 1 byte
		B 1b

	2:
		ldrb W2, [X1], #1 // load char in str and post-increment 		
		cmp W2, #'\n'
		BEQ 3f // Exit if new line
		cmp W2, #'0' 
		blt 3f // Exit if byte less than '0'
		cmp W2, #'9'
		BGT 3f // Exit if byte greater than '9'
		
		SUB W2, W2, #'0' // Convert char to int
		mov W3, #10
		MUL W0, W0, W3 // left shift for current digit
		add W0, W0, W2 // append current digit
		add W4, W4, #1 // increment byte count
		b 2b

	3:
		add W4, W4, #1 // for '\n'
		mov W1, W4 // num bytes
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

	mov w3, #0x0A // ASCII newline
	strb w3, [x2], #-1 // Store newline at end

	mov w4, #10 // divisor

	1:
		cmp x1, #0
		beq 2f	

		udiv x5, x1, x4 // x5 = x1 / 10
		mul x6, x5, x4 // x6 = x5 * 10
		sub x6, x1, x6 // x6 = x1 % 10
		add x6, x6, #'0' // Convert to ASCII
		strb w6, [x2], #-1

		mov x1, x5
		add x0, x0, #1
		b 1b

	2:
		add x2, x2, #1
		mov x1, x2

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

.macro CLEAR_STDIN
	1:
		mov x0, #0 // stdin
		adrp x1, miniBuf@PAGE
		add x1, x1, miniBuf@PAGEOFF
		mov x2, #1 // 1 byte buffer
		mov x16, #3 // macOS read syscall
		svc #0	
	
		cmp x0, #1 // byte read?
		beq 2f
		cmp x0, #0x23 // errno EAGAIN? (no available data for non-blocking I/O)
		beq 3f // if errno == EAGAIN, then done
		b 1b // else try again
		
	2:
		adrp x1, miniBuf@PAGE
		add x1, x1, miniBuf@PAGEOFF
		ldrb w3, [x1]
		cmp w3, #'\n'
		bne 1b // if not '\n', read again

	3:
.endmacro

.macro SET_NON_BLOCK
	1:
		mov x0, #0 // STDIN
		mov x1, #3 // F_GETFL
		mov x16, #92 // macOS fcntl syscall
		SVC 0

		cmp x0, #0
		blt 2f

		ORR x2, x0, #0x0004 // X2 = current flags | O_NONBLOCK	
	
		mov x0, #0 // STDIN
		mov x1, #4 // F_SETFL
		mov x16, #92 // macOS fcntl syscall
		SVC 0

	2:
.endmacro

.macro SET_BLOCK
	1:
		mov x0, #0 // STDIN
		mov x1, #3 // F_GETFL
		mov x16, #92 // macOS fcntl syscall
		SVC 0

		cmp x0, #0
		blt 2f

		AND x2, x0, #~0x0004 // X2 = current flags & ~O_NONBLOCK	
	
		mov x0, #0 // STDIN
		mov x1, #4 // F_SETFL
		// x2 = current flags & ~O_NONBLOCK
		mov x16, #92 // macOS fcntl syscall
		SVC 0

	2:
.endmacro
