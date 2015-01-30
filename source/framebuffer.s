/*******************************************************************************
* framebuffer.s
* Format for messages to be sent to/from the CPU to GPU
* Dom Jackson's Pi OS
* @domjacko
*******************************************************************************/

.section .data
.align 4
.globl FrameBufferInfo 
FrameBufferInfo:
.int 1024 /* #0 Physical Width */
.int 768 /* #4 Physical Height */
.int 1024 /* #8 Virtual Width */
.int 768 /* #12 Virtual Height */
.int 0 /* #16 GPU - Pitch */
.int 16 /* #20 Bit Depth */
.int 0 /* #24 X */
.int 0 /* #28 Y */
.int 0 /* #32 GPU - Pointer */
.int 0 /* #36 GPU - Size */

.section .text
.globl IntitialiseFrameBuffer
IntitialiseFrameBuffer:
	/*
	* Validates that width and height are less than or equal to 4096
	* and the bit depth is less than or equal to 32 bits.
	*/
	width .req r0
	height .req r1
	bitDepth .req r2
	cmp width,#4096
	cmpls height,#4096
	cmpls bitDepth,#32
	result .req r0
	movhi result,#0
	movhi pc,lr

	/*
	* Write into Frame Buffer format as above
	*/
	fbInfoAddr .req r4
	push {r4,lr}
	ldr fbInfoAddr,=FrameBufferInfo
	str width,[r4,#0]
	str height,[r4,#4]
	str width,[r4,#8]
	str height,[r4,#12]
	str bitDepth,[r4,#20]
	.unreq width
	.unreq height
	.unreq bitDepth

	/*
	* Use MailboxWrite method to write message to mailbox 1
	*/
	mov r0,fbInfoAddr
	add r0,#0x40000000 mov r1,#1
	bl MailboxWrite

	/*
	* We send the channel (1) we want to read from to the MailboxRead function
	* and then check if the message it returns is a 0.
	*/
	mov r0,#1
	bl MailboxRead
	teq result,#0
	movne result,#0
	popne {r4,pc}

	/*
	* Return Frame Buffer info address
	*/
	mov result,fbInfoAddr
	pop {r4,pc}
	.unreq result
	.unreq fbInfoAdd