.data
	endl: .asciz "\n"
	space: .asciz " "
	underscore: .asciz "_"

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
	MOV X2, \buffer_len // length of dest buffer
	MOV W8, #63 // linux read syscall
	SVC #0
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
// Output: X0=converted int
.MACRO STR_TO_INT str
	MOV W0, #0
	LDR X1, =\str

	1:
		// Load char from str and increment pointer
		LDRB W2, [X1], #1 		
		CMP W2, #10
		BEQ 2f // Exit if new line
		CMP W2, #'0' 
		BLT 2f // Exit if byte less than '0'
		CMP W2, #'9'
		BGT 2f // Exit if byte greater than '9'
		
		SUB W2, W2, #'0' // Convert char to int
		MOV W3, #10
		MUL W0, W0, W3 // left shift for current digit
		ADD W0, W0, W2 // append current digit
		b 1b
	2:
.ENDM

// Input: reg=int, buffer=dest, buffer_len=num bytes
// Output: X0=num bytes written, X1=starting address of string
.MACRO INT_TO_STR reg, buffer, buffer_len
	MOV X0, #1 // number of bytes in return value (1 for '\n')
	MOV X1, \reg
	LDR X2, =\buffer

	// Move pointer to end - 1 (considering null char)
	ADD X2, X2, \buffer_len - 1 

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
