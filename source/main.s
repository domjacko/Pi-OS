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
	* Draw pixels along the row and down the column using three loops
	* drawRow loops round each row and draw pixel loops along the pixels
	* in the row. Render renders the whole screen.
	*/
	render$:
		fbAddr .req r3
		ldr fbAddr,[fbInfoAddr,#32]

		colour .req r0
		y .req r1
		mov y,#768
		drawRow$:
			x .req r2
			mov x,#1024
			drawPixel$:
				strh colour,[fbAddr]
				add fbAddr,#2
				sub x,#1
				teq x,#0
				bne drawPixel$

			sub y,#1
			add colour,#1
			teq y,#0
			bne drawRow$

		b render$

	.unreq fbAddr
	.unreq fbInfoAddr
