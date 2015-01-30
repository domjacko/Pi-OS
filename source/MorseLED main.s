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
	* Use SetGpioFunction function from gpio.s to set the function
	* of GPIO port 16 (OK LED) to 001 (binary)
	*/
	pinNum .req r0
	pinFunc .req r1
	mov pinNum,#16
	mov pinFunc,#1
	bl SetGpioFunction
	.unreq pinNum
	.unreq pinFunc

	/*
	* Load data pattern into r4 and 0 into r5 which will act as our
	* sequence position to keep track of how much pattern we have displayed
	*/
	ptrn .req r4
	ldr ptrn,=pattern
	ldr ptrn,[ptrn]
	seq .req r5
	mov seq,#0

	/*
	* Use SetGpio function from gpio.s to set GPIO 16 to low (on) if the
	* pattern is a 0 and high (off) if it is a non-zero
	*/
	loop$:
		pinNum .req r0
		pinVal .req r1
		mov pinNum,#16
		mov pinVal,#1
		lsl pinVal,seq
		and pinVal,ptrn
		bl SetGpio
		.unreq pinNum
		.unreq pinVal

		/*
		* Use Wait function to wait for 100000 milliseconds
		*/
		ldr r0,=250000
		bl Wait

		/*
		* Increment sequence by 1. If sequence gets to 32 bits,
		* AND with 11111 to reset it back to 0
		*/
		add seq,#1
		and seq,#0b11111
		/* 
		* Possible less efficient way
		*   cmp seq,#0b100000
		*   mov seq,#0
		*/

	/*
	* Loop over the code forevermore
	*/
	b loop$

/*
* Store the data we supply in the data section of the kernel image
*/
.section .data
.align 2
pattern:
.int 0b11111111101010100010001000101010
