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

/*
* Loads base GPIO address as physical address into register0
*/
ldr r0,=0x20200000

/*
* Enable output to pin 16
* Moves value 1 into register1 and shifts by 18 places to make a value which
* represents enabling output to pin 16
* Stores value of register1 into memory address calculated by adding 4 to
* value held in register0 which represents second set of 10 GPIO pins
*/
mov r1,#1
lsl r1,#18
str r1,[r0,#4]

/*
* Turn pin 16 off, turning LED on
* Moves value 1 into register1 and shifts by 16 places to represent pin 16
* Store value of register1 into memory address calculated by adding 40 to value
* held in register0 which is address to turn pin off
*/
mov r1,#1
lsl r1,#16
str r1,[r0,#40]

/*
* Infinite Loop
*/
loop$:
b loop$
