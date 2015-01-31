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
* Tell drawing method where we are drawing tp
*/
	bl SetGraphicsAddress

	lastr .req r7
	lastx .req r8
	lasty .req r9
	colour .req r10

	newx .req r5
	newy .req r6

	mov lastr,#0
	mov lastx,#0
	mov r9,#0
	mov r10,#0

	render$:
		/*
		* Generate new x coord
		*/	
		mov r0,lastr
		bl Random
		mov newx,r0

		/*
		* Generate new y coord using new x coord
		*/
		bl Random
		mov newy,r0
		mov lastr,r0

		/*
		* Set fore colour and then increment colour by 1
		*/
		mov r0,colour
		add colour,#1
		lsl colour,#16
		lsr colour,#16
		bl SetForeColour

		/*
		* Convert newly generated x and y to a number between 0 and 1023 by
		* shifting right 22 places
		*/			
		mov r0,lastx
		mov r1,lasty
		lsr r2,newx,#22
		lsr r3,newy,#22

		/*
		* Check y coordinate is on the screen by checking it's between 0 and 767
		*/
		cmp r3,#768
		bhs render$
		
		/*
		* Draw line between old and new coordinates
		*/
		mov lastx,r2
		mov lasty,r3
		bl DrawLine

		b render$

	.unreq newx
	.unreq newy
	.unreq lastr
	.unreq lastx
	.unreq lasty
	.unreq colour
