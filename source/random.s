/*******************************************************************************
* random.s
* Creates pseudo random numbers
* Dom Jackson's Pi OS
* @domjacko
*******************************************************************************/

/*
* Using the quadratic congruence generator, take the last number and generate
* a new random number.
* xn+1 = axn2 + bxn + c mod 232
* a = 0xEF00  b = 1  c = 41 
*/
.globl Random
Random:
	xnm .req r0
	a .req r1

	mov a,#0xef00
	mul a,xnm
	mul a,xnm
	add a,xnm
	.unreq xnm
	add r0,a,#73

	.unreq a
	mov pc,lr
	