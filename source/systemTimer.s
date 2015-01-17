/*******************************************************************************
* systemTimer.s
* Contains all functions related to the System Timer
* Dom Jackson's Pi OS
* @domjacko
*******************************************************************************/
/*
* Function to get Timer Address and store in physical memory
* address
*/
.globl GetSystemTimerBase
GetSystemTimerBase:
	ldr r0,=0x20003000
	mov pc,lr

/*
* Use the GetSystemTimerBase to store the current 8 bit counter
* into two registers
*/
.globl GetTimeStamp
GetTimeStamp:
	push {lr}
	bl GetSystemTimerBase
	ldrd r0,r1,[r0,#4]
	pop {pc}

/*
* Wait function takes a time in milliseconds to wait for by getting the
* time elapsed. Does this by subtracting the time the method started
* from the current time and comparing this result to the time requested
*/
.globl Wait
Wait:
	delay .req r2
	mov delay,r0
	push {lr}
	bl GetTimeStamp
	start .req r3
	mov start,r0

	loop$:
		bl GetTimeStamp
		elapsed .req r1
		sub elapsed,r0,start
		cmp elapsed,delay
		.unreq elapsed
		bls loop$

	.unreq delay
	.unreq start
	pop {pc}