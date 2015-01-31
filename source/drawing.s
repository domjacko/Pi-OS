/*******************************************************************************
* drawing.s
* Contains functions for drawing to the screen
* Dom Jackson's Pi OS
* @domjacko
*******************************************************************************/

.section .data
.align 1
foreColour:
	.hword 0xFFFF

.align 2
graphicsAddress:
	.int 0

.align 4
font:
	.incbin "font.bin"

/*
* Sets the current 16 bit drawing colour given in r0
*/
.section .text
.globl SetForeColour
SetForeColour:
	cmp r0,#0x10000
	movhi pc,lr
	moveq pc,lr
	ldr r1,=foreColour
	strh r0,[r1]
	mov pc,lr

/*
* Stores the address of where to draw to
*/
.globl SetGraphicsAddress
SetGraphicsAddress:
	ldr r1,=graphicsAddress
	str r0,[r1]
	mov pc,lr

/*
* Draw particular pixel given it's x and y coordinates
*/
.globl DrawPixel
DrawPixel:
	/*
	* Get the graphics address
	*/
	px .req r0
	py .req r1
	addr .req r2
	ldr addr,=graphicsAddress
	ldr addr,[addr]

	/*
	* Check x and y coords are on screen by checking less than width and height
	*/
	height .req r3
	ldr height,[addr,#4]
	sub height,#1
	cmp py,height
	movhi pc,lr
	.unreq height

	width .req r3
	ldr width,[addr,#0]
	sub width,#1
	cmp px, width
	movhi pc,lr

	/*
	* Compute address of pixel to draw. frameBufferAddress + (x + y * width) * pixel size
	*/
	ldr addr,[addr,#32]
	add width,#1
	mla px,py,width,px
	.unreq width
	.unreq py
	add addr, px,lsl #1
	.unreq px

	/*
	* Set the Fore Colour
	*/
	fore .req r3
	ldr fore,=foreColour
	ldrh fore,[fore]

	/*
	* Store at address
	*/
	strh fore,[addr]
	.unreq fore
	.unreq addr
	mov pc,lr

/*
* Draw a line using Bresenham's algorithm which doesn't use division which is slow
*/
.globl DrawLine
DrawLine:
	push {r4,r5,r6,r7,r8,r9,r10,r11,r12,lr}
	x0 .req r9
	x1 .req r10
	y0 .req r11
	y1 .req r12

	mov x0,r0
	mov x1,r2
	mov y0,r1
	mov y1,r3

	dx .req r4
	dyn .req r5 /* Use a negative number for dy so use dyn */
	sx .req r6
	sy .req r7
	err .req r8

	cmp x0,x1
	subgt dx,x0,x1
	movgt sx,#-1
	suble dx,x1,x0
	movle sx,#1
	
	cmp y0,y1
	subgt dyn,y1,y0
	movgt sy,#-1
	suble dyn,y0,y1
	movle sy,#1

	add err,dx,dyn /* Add dy because it's negative */
	add x1,sx
	add y1,sy

	pixelLoop$:
		teq x0,x1
		teqne y0,y1
		popeq {r4,r5,r6,r7,r8,r9,r10,r11,r12,pc}

		mov r0,x0
		mov r1,y0
		bl DrawPixel

		cmp dyn, err,lsl #1
		addle err,dyn
		addle x0,sx

		cmp dx, err,lsl #1
		addge err,dx
		addge y0,sy

		b pixelLoop$

	.unreq x0
	.unreq x1
	.unreq y0
	.unreq y1
	.unreq dx
	.unreq dyn
	.unreq sx
	.unreq sy
	.unreq err

/*
* Draw a character to the screen
*/
.globl DrawCharacter
DrawCharacter:
	/*
	* Check is character is less than 127
	*/
	cmp r0,#127
	movhi r0,#0
	movhi r1,#0
	movhi pc,lr

	push {r4,r5,r6,r7,r8,lr}
	x .req r4
	y .req r5
	charAddress .req r6
	mov x,r1
	mov y,r2

	/*
	* Set Character Address to font and then add character x 16
	*/
	ldr charAddress,=font
	add charAddress, r0,lsl #4

	/*
	* Loop across line drawing each character
	*/
	lineLoop$:
		bits .req r7
		bit .req r8
		ldrb bits,[charAddress]
		mov bit,#8

		/*
		* Loop around character setting pixel colour
		*/
		charPixelLoop$:
			subs bit,#1
			blt charPixelLoopEnd$
			lsl bits,#1
			tst bits,#0x100
			beq charPixelLoop$

			add r0,x,bit
			mov r1,y
			bl DrawPixel

			teq bit,#0
			bne charPixelLoop$

		charPixelLoopEnd$: /* Branch here as a way to end the loop */

		.unreq bit
		.unreq bits
		add y,#1
		add charAddress,#1
		tst charAddress,#0b1111
		bne lineLoop$

	.unreq x
	.unreq y
	.unreq charAddress

	/*
	* Return width as 8 and height as 16 for 8x16 character
	*/
	width .req r0
	height .req r1
	mov width,#8
	mov height,#16

	pop {r4,r5,r6,r7,r8,pc}
	.unreq width
	.unreq height

/*
* Draw String of various characters
*/
.globl DrawString
DrawString:
	push {r4,r5,r6,r7,r8,lr}
	x .req r4
	y .req r5
	x0 .req r6
	string .req r7
	length .req r8
	char .req r9

	mov string,r0
	mov length,r1
	mov x,r2
	mov y,r3
	mov x0,x

	stringLoop$:
		subs length,#1 /* Subtracts one number from the other and checks if result is 0 */
		blt stringLoopEnd$

		ldrb char,[string]
		add string,#1

		/*
		* Run DrawCharacter giving char, x and y
		*/
		mov r0,char
		mov r1,x
		mov r2,y
		bl DrawCharacter
		charWidth .req r0
		charHeight .req r1

		/*
		* Check if newline character and moves down a line if so
		*/
		teq char,#'\n'
		moveq x,x0
		addeq y,charHeight
		beq stringLoop$

		/*
		* Check if tab character and moves across 5 character lengths if so
		*/
		teq char,#'\t'
		addne x,charWidth
		bne stringLoop$

		add charWidth, charWidth,lsl #2
		x1 .req r1
		mov x1,x0

		/*
		* Loop to control moving 5 character lengths along for each character
		*/
		stringLoopTab$:
			add x1,charWidth
			cmp x,x1
			bge stringLoopTab$

		mov x,x1
		.unreq x1
		b stringLoop$

	stringLoopEnd$: /* Branch here as a way to end the loop */

	.unreq charWidth
	.unreq charHeight

	pop {r4,r5,r6,r7,r8,r9,pc}
	.unreq x
	.unreq y
	.unreq x0
	.unreq string
	.unreq length
