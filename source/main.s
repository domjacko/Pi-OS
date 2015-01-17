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
	* Use SetGpio function from gpio.s to set GPIO 16 to low,
	* causing the LED to turn on.
	*/
	loop$:
		pinNum .req r0
		pinVal .req r1
		mov pinNum,#16
		mov pinVal,#0
		bl SetGpio
		.unreq pinNum
		.unreq pinVal

		/*
		* Decrement down from 3F0000 to 0 to act as a delay
		*/
		ldr r0,=100000
		bl Wait

		/*
		* Use SetGpio function from gpio.s to set GPIO 16 to high,
		* causing the LED to turn on.
		*/
		pinNum .req r0
		pinVal .req r1
		mov pinNum,#16
		mov pinVal,#1
		bl SetGpio
		.unreq pinNum
		.unreq pinVal

		/*
		* Delay a second time
		*/
		ldr r0,=100000
		bl Wait

	/*
	* Loop over the code continuously
	*/
	b loop$
