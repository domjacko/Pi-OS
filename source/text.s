/*******************************************************************************
* text.s
* Contains functions for manipulating text
* Dom Jackson's Pi OS
* @domjacko
*******************************************************************************/

/*
* Convert Signed string in r0, base in r2 and store in address given in r1
* Return length of string in r0
*/
.globl SignedString
SignedString:
	value .req r0
	dest .req r1
	cmp value,#0
	bge UnsignedString

	rsb value,#0
	teq dest,#0
	movne r3,#'-'
	strneb r3,[dest]
	addne dest,#1
	push {lr}
	bl UnsignedString
	add r0,#1
	pop {pc}
	.unreq value
	.unreq dest

/*
* Convert Unsigned string in r0, base in r2 and store in address given in r1
* Return length of string in r0
*/
.globl UnsignedString
UnsignedString:
	value .req r0
	dest .req r5
	base .req r6
	length .req r7
	push {r4,r5,r6,r7,lr}

	mov dest,r1
	mov base,r2
	mov length,#0

	charLoop$:
		mov r1,base
		bl DivideU32
		cmp r1,#9
		addls r1,#'0'
		addhi r1,#'a'-10
		teq dest,#0
		strneb r1,[dest,length]
		add length,#1
		teq value,#0
		bne charLoop$
		
	.unreq value
	.unreq base
	teq dest,#0
	movne r0,dest
	movne r1,length
	blne ReverseString
	mov r0,length

	pop {r4,r5,r6,r7,pc}
	.unreq dest
	.unreq length

/*
* Reverses a string and stores in address given in r0 and length in r1
*/
.globl ReverseString
ReverseString:
	start .req r0
	end .req r1

	add end,start
	sub end,#1
	revLoop$:
		cmp end,start
		movls pc,lr

		ldrb r2,[start]
		ldrb r3,[end]
		strb r3,[start]
		strb r2,[end]
		add start,#1
		sub end,#1
		b revLoop$

/*
* Format String given the address in r0 with length of the string in r1
* and store in the destination in r2. There can be a variable amount of
* arguments with format being:
*  %% outputs a '%'
*  %c outputs the next argument as a character.
*  %s outputs the string in the next argument, length in the one after.
*  %d outputs the next argument as a signed base 10 number.
*  %u outputs the next argument as an unsigned base 10 number.
*  %x outputs the next argument as a hexadecimal number.
*  %b outputs the next argument as a binary number.
*  %o outputs the next argument as a octal number.
*/ 
.globl StringFormat
StringFormat:
	format .req r4
	formatLength .req r5
	dest .req r6
	nextArg .req r7
	argList .req r8
	length .req r9

	/*
	* Manage list of arguments
	*/
	push {r4,r5,r6,r7,r8,r9,lr}
	mov format,r0
	mov formatLength,r1
	mov dest,r2
	mov nextArg,r3
	add argList,sp,#7*4
	mov length,#0

	/*
	* Find any occurences of the '%' symbol and branch to
	* relevant format loop
	*/
	formatLoop$:
		subs formatLength,#1
		movlt r0,length
		poplt {r4,r5,r6,r7,r8,r9,pc}

		ldrb r0,[format]
		add format,#1
		teq r0,#'%'
		beq formatArg$

	/*
	* If '%c' found, use Char format
	*/ 
	formatChar$:
		teq dest,#0
		strneb r0,[dest]
		addne dest,#1
		add length,#1
		b formatLoop$

	formatArg$:
		subs formatLength,#1
		movlt r0,length
		poplt {r4,r5,r6,r7,r8,r9,pc}
		
		/* 
		* If '%%' found, write a '%' to output
		*/
		ldrb r0,[format]
		add format,#1
		teq r0,#'%'
		beq formatChar$
				
		teq r0,#'c'
		moveq r0,nextArg
		ldreq nextArg,[argList]
		addeq argList,#4
		beq formatChar$

		teq r0,#'s'
		beq formatString$
				
		teq r0,#'d'
		beq formatSigned$
				
		teq r0,#'u'
		teqne r0,#'x'
		teqne r0,#'b'
		teqne r0,#'o'
		beq formatUnsigned$

		b formatLoop$

	/*
	* If '%s' found, use null terminated String format
	*/
	formatString$:
		ldrb r0,[nextArg]
		teq r0,#'\0'		
		ldreq nextArg,[argList]
		addeq argList,#4
		beq formatLoop$
		add length,#1
		teq dest,#0
		strneb r0,[dest]
		addne dest,#1
		add nextArg,#1		
		b formatString$

	/*
	* If '%d' found, use Signed format
	*/
	formatSigned$:
		mov r0,nextArg
		ldr nextArg,[argList]
		add argList,#4
		mov r1,dest
		mov r2,#10
		bl SignedString
		teq dest,#0
		addne dest,r0
		add length,r0
		b formatLoop$

	/*
	* If '%u', '%x', '%b' or '%o' found, use Unsigned format
	*/
	formatUnsigned$:
		teq r0,#'u'  /* Base 10 Unsigned */
		moveq r2,#10
		teq r0,#'x'  /* Base 16 Unsigned */
		moveq r2,#16
		teq r0,#'b'  /* Base 2 Unsigned */
		moveq r2,#2
		teq r0,#'o'  /* Base 8 Unsigned */
		moveq r2,#8

		mov r0,nextArg
		ldr nextArg,[argList]
		add argList,#4
		mov r1,dest
		bl UnsignedString
		teq dest,#0
		addne dest,r0
		add length,r0
		b formatLoop$
