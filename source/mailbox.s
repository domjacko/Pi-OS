/*******************************************************************************
* mailbox.s
* Contains functions for reading and writing to the mailbox
* Dom Jackson's Pi OS
* @domjacko
*******************************************************************************/

/*
* Function to get address of MailBox and store in physical memory
*/
.globl GetMailboxBase
GetMailboxBase:
	ldr r0,=2000B880
	mov pc,lr

/*
* Read message by storing message from channel supplied in r0
* in r0
*/
.globl MailBoxRead
MailBoxRead:
	cmp r0,#15
	movhi pc,lr

	/*
	* Validate correct mailbox channel in r0 and get Mailbox Address
	*/
	channel .req r1
	mov channel,r0
	push{lr}
	bl GetMailboxBase
	mailbox .req r0

	rightmail$:
		wait1$:
			status .req r2
			ldr status,[mailbox,#0x18]
			tst status,#0x40000000
			.unreq status
			bne wait1$
		/*
		* Read next item from mailbox
		*/
		mail .req r2
		ldr mail,[mailbox,#0]

		/*
		* Check message is from correct channel
		*/
		inchan .req r3
		and inchan,mail,#0b1111
		teq inchan,channel
		.unreq inchan
		bne rightmail$
		.unreq mailbox
		.unreq channel

	/*
	* Moves message read to r0
	*/
	and r0,mail,#0xfffffff0
	.unreq mail
	pop {pc}


/*
* Top 28 bits of r0 will be message to write and low 4 bits of r1 will be which
* mailbox to write it too. Validate by checking low 4 bits is zero by ANDing with
* 1111
*/
.globl MailBoxWrite
MailBoxWrite.:
	tst r0,#0b1111
	movne pc,lr
	cmp r1,#15
	movhi pc,lr
	
	/*
	* Get Mailbox address
	*/
	channel .req r1
	value .req r2
	mov value,r0
	push{lr}
	bl GetMailboxBase
	mailbox .req r0

	/*
	* Get status of mailbox and check top bit is a 0
	*/
	wait2$:
		status .req r3
		ldr status,[mailbox,#0x18]
		tst status,#0x80000000
		.unreq status
		bne wait2$

	/*
	* Add value and channel to one big string and store in write field
	*/
	add value,channel
	.unreq channel
	str value,[mailbox,#0x20]
	.unreq value
	.unreq mailbox
	pop {pc}