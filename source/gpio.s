/*******************************************************************************
* gpio.s
* Contains all functions related to the GPIO controller
* Dom Jackson's Pi OS
* @domjacko
*******************************************************************************/
/*
* Sets function as globally accessible to everything
*/
.globl GetGpioAddress

/*
* Function to get GPIO Address
*/
GetGpioAddress:
	/*
	* Loads base GPIO controller address as physical address into r0
	*/
	ldr r0,=0x20200000

	/*
	* Copy value of link register into pc which always holds value
	* of next instruction. This just changes the next line to be run
	* to be the line after where the call to the function was
	*/
	mov pc,lr

/*
* Given a pin and a function, set the function of the pin to the value
* of the function
*/
.globl SetGpioFunction
SetGpioFunction:
	/*
	* Make sure pin number is 53 or below and pin function is 7 or below
	*/
	cmp r0,#53
	cmpls r1,#7
	movhi pc,lr

	/*
	* Push value of lr onto stack to preserve it
	* Move value of r0 into r2 and then branches to GetGpioAddress
	* updating lr to the 
	*/
	push {lr}
	mov r2,r0
	bl GetGpioAddress

	/*
	* Because division is slow, this loop compares the number to 9
	* and if it is higher, it subtracts 10 and then adds 4 to the GPIO controller.
	* This gets us the block of ten that the pin belongs to
	*/
	functionLoop$:
		cmp r2,#9
		subhi r2,#10
		addhi r0,#4
		bhi functionLoop$

	/*
	* Because multiplication is slow and we are simply multiplying by 3, it
	* is quicker to multiply my 2 and then add one of itself.
	* Shift value in r1 by value in r2 which is now 3 times larger because each pin
	* is three bits each. 
	*/
	add r2, r2,lsl #1
	lsl r1,r2
	str r1,[r0]
	pop {pc}

/*
* Given a pin and a value to turn the pin on or off
*/
.globl SetGpio
SetGpio:
	/*
	* .req sets an alias for a register name
	*/
	pinNum .req r0
	pinVal .req r1

	/*
	* Call GetGpioAddress so push lr onto stack and set r2 to value in r0.
	* Remove alias from r0 and reaasign to r2
	*/
	cmp pinNum,#53
	movhi pc,lr
	push {lr}
	mov r2,pinNum
	.unreq pinNum
	pinNum .req r2
	bl GetGpioAddress
	gpioAddr .req r0

	/*
	* GPIO controller has two sets of 4 bytes each for turning pins 
	* on and off. The first set of 4 bytes controls the first 32 pins
	* and the second set controls the remaining 22 pins.
	* We need to figure out which set the pin is in we need to divide by 32
	* which is same as shifting right by 5 places. Because its a set of 4
	* bytes we need to multiply by 4 which is the same as shifting left
	* by 2 places
	*/
	pinBank .req r3
	lsr pinBank,pinNum,#5
	lsl pinBank,#2
	add gpioAddr,pinBank
	.unreq pinBank

	/*
	* AND calculates remainder of doing the calculation of pin number
	* divided by 32. Then shifts by one place to the left to get value.
	*/
	and pinNum,#31
	setBit .req r3
	mov setBit,#1
	lsl setBit,pinNum
	.unreq pinNum

	/*
	* If the vale is 0, we turn th pin off by storing setBit in memory
	* location calculated by adding 40 to GPIO address. Else, we turn
	* pin on by storing setBit in memory location calculated by adding
	* 28 to GPIO address.
	* Finally pop pc 
	*/
	teq pinVal,#0
	.unreq pinVal
	streq setBit,[gpioAddr,#40]
	strne setBit,[gpioAddr,#28]
	.unreq setBit
	.unreq gpioAddr
	pop {pc}
