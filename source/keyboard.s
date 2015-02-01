/*******************************************************************************
* keyboard.s
* Compliments functions provided by keyboard driver
* Dom Jackson's Pi OS
* @domjacko
*******************************************************************************/

.section .data
/*
* The address of the keyboard we're reading from
*/
.align 2
KeyboardAddress:
	.int 0

/*
* Scan codes that were down before the current set on the keyboard
*/
KeyboardOldDown:
	.rept 6
	.hword 0
	.endr

/*
* Lookup table for keys
*/
.align 3
KeysNormal:
	.byte 0x0, 0x0, 0x0, 0x0, 'a', 'b', 'c', 'd'
	.byte 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l'
	.byte 'm', 'n', 'o', 'p', 'q', 'r', 's', 't'
	.byte 'u', 'v', 'w', 'x', 'y', 'z', '1', '2'
	.byte '3', '4', '5', '6', '7', '8', '9', '0'
	.byte '\n', 0x0, '\b', '\t', ' ', '-', '=', '['
	.byte ']', '\\', '#', ';', '\'', '`', ',', '.'
	.byte '/', 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0
	.byte 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0
	.byte 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0
	.byte 0x0, 0x0, 0x0, 0x0, '/', '*', '-', '+'
	.byte '\n', '1', '2', '3', '4', '5', '6', '7'
	.byte '8', '9', '0', '.', '\\', 0x0, 0x0, '='

/*
* Lookup table for keys when shift key is held
*/
.align 3
KeysShift:
	.byte 0x0, 0x0, 0x0, 0x0, 'A', 'B', 'C', 'D'
	.byte 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L'
	.byte 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T'
	.byte 'U', 'V', 'W', 'X', 'Y', 'Z', '!', '"'
	.byte '£', '$', '%', '^', '&', '*', '(', ')'
	.byte '\n', 0x0, '\b', '\t', ' ', '_', '+', '{'
	.byte '}', '|', '~', ':', '@', '¬', '<', '>'
	.byte '?', 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0
	.byte 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0
	.byte 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0
	.byte 0x0, 0x0, 0x0, 0x0, '/', '*', '-', '+'
	.byte '\n', '1', '2', '3', '4', '5', '6', '7'
	.byte '8', '9', '0', '.', '|', 0x0, 0x0, '='

/*
* Detects a keyboard and uses poll method to get current input
*/
.section .text
.globl KeyboardUpdate
KeyboardUpdate:
	push {r4,r5,lr}

	/*
	* Load keyboard address
	*/
	kbd .req r4
	ldr r0,=KeyboardAddress
	ldr kbd,[r0]

	/*
	* Check keyboard address is nonzero to check one is there
	*/
	teq kbd,#0
	bne haveKeyboard$

	/*
	* If no keyboard, check if one now there and get address
	*/
	getKeyboard$:
		bl UsbCheckForChange
		bl KeyboardCount
		teq r0,#0
		ldreq r1,=KeyboardAddress
		streq r0,[r1]
		beq return$

		mov r0,#0
		bl KeyboardGetAddress
		ldr r1,=KeyboardAddress
		str r0,[r1] /* Store keyboard address */
		teq r0,#0
		beq return$
		mov kbd,r0

	/*
	* If a keyboard is present
	*/
	haveKeyboard$:
		mov r5,#0
		/* 
		* Loop 6 times as that's number of keys that can be pressed
		* at same time. 
		*/
		saveKeys$:
			mov r0,kbd
			mov r1,r5
			bl KeyboardGetKeyDown

			ldr r1,=KeyboardOldDown
			add r1,r5,lsl #1
			strh r0,[r1]
			add r5,#1
			cmp r5,#6
			blt saveKeys$

		/*
		* Get all the new keys
		*/ 
		mov r0,kbd
		bl KeyboardPoll
		teq r0,#0 /* Check KeyboardPoll worked by checking result code */
		bne getKeyboard$

	return$:
		pop {r4,r5,pc}
		.unreq kbd

/*
* Returns r0=0 if a key in r1 key was not pressed before the current scan, and r0
* not 0 otherwise.
*/
.globl KeyWasDown
KeyWasDown:
	ldr r1,=KeyboardOldDown
	mov r2,#0

	keySearch$:
		ldrh r3,[r1]
		teq r3,r0
		moveq r0,#1
		moveq pc,lr

		add r1,#2
		add r2,#1
		cmp r2,#6
		blt keySearch$

	mov r0,#0
	mov pc,lr

/*
* Returns ASCII character last typed on the keyboard
*/
.globl KeyboardGetChar
KeyboardGetChar:
	push {r4}
	/*
	* Load keyboard address
	*/
	kbd .req r4
	ldr r0,=KeyboardAddress
	ldr kbd,[r0]

	/*
	* Check keyboard address is nonzero to check one is there
	*/
	teq kbd,#0
	moveq r0,#0
	moveq pc,lr

	push {r5,r6,lr}

	/*
	* r4 holds keyboard address and r6 holds index of key
	*/
	key .req r5
	mov r4,r1
	mov r6,#0
	keyLoop$:
		/*
		* Get key that is down
		*/
		mov r0,kbd
		mov r1,r6
		bl KeyboardGetKeyDown

		/*
		* Test if keyboard scan code is 0 showing no more keys down
		* and return if so
		*/
		teq r0,#0
		beq keyLoopReturn$

		/*
		* If key was already down, ignore it as we only care about
		* key presses
		*/
		mov key,r0
		bl KeyWasDown
		teq r0,#0
		bne keyLoopContinue$

		/*
		* If key scan code is above 104, it is not in lookup table
		*/
		cmp key,#104
		bge keyLoopContinue$

		/*
		* Need to find out if a modifier key is pressed. If so, use
		* modifier lookup table, else use normal lookup table
		*/
		mov r0,kbd
		bl KeyboardGetModifiers
		tst r0,#0b00100010
		ldreq r0,=KeysNormal
		ldrne r0,=KeysShift

		ldrb r0,[r0,key] /* Load in key from lookup table */

		teq r0,#0
		bne keyboardGetCharReturn$

	/*
	* If lookup table returns a 0 for the code we continue by
	* incremeting the index and checking if we've reached 6
	*/
	keyLoopContinue$:
		add r6,#1
		cmp r6,#6
		blt keyLoop$

	/*
	* Leave loop if no key is held so return 0
	*/
	keyLoopReturn$:
		mov r0,#0

	/*
	* Return key
	*/
	keyboardGetCharReturn$:
		pop {r4,r5,r6,pc}
		.unreq kbd
		.unreq key
