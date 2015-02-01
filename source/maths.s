/*******************************************************************************
* maths.s
* Contains mathematical functions
* Dom Jackson's Pi OS
* @domjacko
*******************************************************************************/

/*
* Binary long division. Shift the divisor as far right as possible without
* exceeding the dividen, and then output a 1 accoridng to the position
* and then subtract the number
*/
.globl DivideU32
DivideU32:
	result .req r0
	remainder .req r1
	shift .req r2
	current .req r3

	clz shift,r1 /* Count leading zeroes */
	clz r3,r0
	subs shift,r3
	lsl current,r1,shift
	mov remainder,r0
	mov result,#0
	blt divideU32Return$

	divideU32Loop$:
		cmp remainder,current
		blt divideU32LoopContinue$

		add result,result,#1
		subs remainder,current
		lsleq result,shift 
		beq divideU32Return$
		divideU32LoopContinue$:
		subs shift,#1
		lsrge current,#1
		lslge result,#1
		bge divideU32Loop$

	divideU32Return$:
		.unreq current
		mov pc,lr

	.unreq result
	.unreq remainder
	.unreq shift
