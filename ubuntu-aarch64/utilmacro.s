.data
	endl: .asciz "\n"
	space: .asciz " "
	underscore: .asciz "_"
	miniBuf: .skip 1

.text
.MACRO ENDL
	MOV X0, #1 // stdout
	LDR X1, =endl // address of "\n"
	MOV X2, #1 // strlen
	MOV X8, #64 // linux write syscall
	SVC #0
.ENDM

.MACRO GET_STR buffer, buffer_len
	MOV W0, #0 // stdin
	LDR X1, =\buffer // address of dest buffer
	MOV X2, \buffer_len - 1 // read at most buffer_len - 1 bytes
	MOV W8, #63 // linux read syscall
	SVC #0

	ADD X1, X1, X0 // X1 = buffer + num bytes read
	MOV W2, #0
	STRB W2, [X1] // buffer[X0] = '\0'
.ENDM

.MACRO PRINT_STR str, len
	MOV W0, #1 // stdout
	LDR X1, =\str // address of string
	MOV X2, \len // length of string
	MOV W8, #64 // linux write syscall
	SVC #0
.ENDM

.MACRO PRINT_FROM_REG reg, len
	MOV W0, #1 // stdout
	MOV X1, \reg // address of string in reg
	MOV X2, \len // length of string
	MOV W8, #64 // linux write syscall
	SVC #0
.ENDM

// Input: str=address of string to convert
// Output: X0=converted int, X1=num digits
.MACRO STR_TO_INT str
	MOV W0, #0
	LDR X1, =\str
	MOV W4, #0

	// Remove leading 0s
	1:
		LDRB W2, [X1] // load char in str
		CMP W2, #'0'
		BNE 2f
		ADD X1, X1, #1 // increment addr by 1 byte
		B 1b

	2:
		LDRB W2, [X1], #1 // load char in str and post-increment 		
		CMP W2, #'\n'
		BEQ 3f // Exit if new line
		CMP W2, #'0' 
		BLT 3f // Exit if byte less than '0'
		CMP W2, #'9'
		BGT 3f // Exit if byte greater than '9'
		
		SUB W2, W2, #'0' // Convert char to int
		MOV W3, #10
		MUL W0, W0, W3 // left shift for current digit
		ADD W0, W0, W2 // append current digit
		ADD W4, W4, #1 // increment byte count
		b 2b
	3:
		ADD W4, W4, #1 // for '\n'
		MOV W1, W4 // num bytes
.ENDM

// Input: reg=register containing int, buffer=dest, buffer_len=num bytes
// Output: X0=num bytes written, X1=starting address of string
.MACRO INT_TO_STR reg, buffer, buffer_len
	MOV X1, \reg
	LDR X2, =\buffer
	MOV X3, \buffer_len
	SUB X3, X3, #1

	MOV X0, #1 // number of bytes in return value (1 for '\n')

	// Move pointer to end - 1 (considering null char)
	ADD X2, X2, X3 

	MOV W3, #0x0A // ASCII newline
	STRB W3, [X2], #-1 // Store newline at end

	MOV W4, #10 // divisor

	1:
		CMP X1, #0
		BEQ 2f	

		UDIV X5, X1, X4 // X5 = X1 / 10
		MUL X6, X5, X4 // X6 = X5 * 10
		SUB X6, X1, X6 // X6 = X1 % 10
		ADD X6, X6, #'0' // Convert to ASCII
		STRB W6, [X2], #-1

		MOV X1, X5
		ADD X0, X0, #1
		b 1b
	2:
		ADD X2, X2, #1
		MOV X1, X2

.ENDM

.MACRO SPACE
	MOV X0, #1 // fd 1 = stdout
	LDR X1, =space // address of " "
	MOV X2, #1 // strlen
	MOV X8, #64 // linux write syscall
	SVC #0
.ENDM

.MACRO UNDERSCORE
	MOV X0, #1 // fd 1 = stdout
	LDR X1, =underscore // address of "\n"
	MOV X2, #1 // strlen
	MOV X8, #64 // linux write syscall
	SVC #0
.ENDM

.MACRO CLEAR_STDIN
	1:
		MOV X0, #0 // fd 0 = stdin
		LDR X1, =miniBuf
		MOV X2, #1 // 1 byte buffer
		MOV X8, #63 // linux read syscall
		SVC #0	
	
		CMP X0, #1 // byte read?
		//BLT 2f // if no byte read, exit
		BLT 2f // if no byte read, exit

		LDRB W3, [X1]
		CMP W3, #'\n'
		//CMP W3, #'0'
		//BNE 1b // if not null terminator, read again
		BNE 1b // if not '\n', read again
	2:
.ENDM

.MACRO SET_NON_BLOCK
	1:
		MOV X0, #0 // STDIN
		MOV X1, #3 // F_GETFL
		MOV X8, #25 // fcntl syscall
		SVC 0

		CMP X0, #0
		BLT 2f

		ORR X2, X0, #0x800 // X2 = current flags | O_NONBLOCK	
	
		MOV X0, #0 // STDIN
		MOV X1, #4 // F_SETFL
		// X2 = current flags | O_NONBLOCK
		MOV X8, #25 // fcntl syscall
		SVC 0
	2:
.ENDM

.MACRO SET_BLOCK
	1:
		MOV X0, #0 // STDIN
		MOV X1, #3 // F_GETFL
		MOV X8, #25 // fcntl syscall
		SVC 0

		CMP X0, #0
		BLT 2f

		AND X2, X0, #~0x800 // X2 = current flags & ~O_NONBLOCK	
	
		MOV X0, #0 // STDIN
		MOV X1, #4 // F_SETFL
		// X2 = current flags & ~O_NONBLOCK
		MOV X8, #25 // fcntl syscall
		SVC 0
	2:
.ENDM
