/*******************************************************************************
* main.s
* Contains main operating system
* Dom Jackson's Pi OS
* @domjacko
*******************************************************************************/

/*
* Instructions for Assembler
* Tells Linker to put code in .init section which is at start of output
* Stops toolchain getting upset by defining a _start point even though
* it is unnecessary to writing an OS as _start is always whatever comes
* first which we set up with .section .init
*/
.section .init
.globl _start
_start:

b main

/* 
* Tells the assembler to put this code with the rest.
*/
.section .text

/*
* Main method
*/
main:
	/*
	* Set the stack point
	*/
	mov sp,#0x8000

	/*
	* Create frame buffer of width 1024, height 768 and bit depth 16
	*/
	mov r0,#1024
	mov r1,#768
	mov r2,#16
	bl InitialiseFrameBuffer

	/*
	* Check that GPU returned a 0 from the mailbox to confirm a framebuffer has
	* been created. If this is the case, turn OK LED to show error.
	*/
	teq r0,#0
	bne noError$

	mov r0,#16
	mov r1,#1
	bl SetGpioFunction
	mov r0,#16
	mov r1,#0
	bl SetGpio

	error$:
		b error$

	noError$:
		fbInfoAddr .req r4
		mov fbInfoAddr,r0

	/*
	* Tell drawing method where we are drawing to
	*/
	bl SetGraphicsAddress

	bl UsbInitialise
	mov r4,#0
	mov r5,#0

	loopKeyboard$:
		bl KeyboardUpdate
		bl KeyboardGetChar

		teq r0,#0
		beq loopKeyboard$

		mov r1,r4
		mov r2,r5
		bl DrawCharacter

		add r4,r0
		
		/*
		* Check on screen
		*/
		teq r4,#1024
		addeq r5,r1
		moveq r4,#0
		
		teqeq r5,#768
		moveq r5,#0

		bl loopKeyboard$
