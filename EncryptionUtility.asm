# Who:  Meetkumar Patel
# What: EncryptionUtility.asm
# Why:  Project 4
# When: Created: 04/24/19 Due: 05/05/19
# How:  Registers used: t0, t1, t2, t3

.data

.eqv	Src_Path_sz								256
		Src_Buffer:				.space			Src_Path_sz
		Dst_Buffer:				.space			Src_Path_sz
		
.eqv	Passphrase_sz							257
		Passphrase_Buffer:		.space			Passphrase_sz

		Ask_Src_File_Name:		.asciiz			"Please enter the source file name: "
		Ask_Dst_File_Name:		.asciiz			"Please enter the destination file name: "
		Ask_Passphrase:			.asciiz			"Plese open MMIO Simulator under Tools, and enter passphrase after connecting to MIPS: "

.align 2

.text
.globl main


main:	# program entry

	# get_String subroutine
	li $v0, 4
	la $a0, Ask_Src_File_Name
	syscall												# prompt to enter source file name
	la $a0, Src_Buffer									# pass in Src_Buffer into argument a0
	jal get_String

	li $v0, 4
	la $a0, Ask_Dst_File_Name
	syscall												# prompt to enter destination file name
	la $a0, Dst_Buffer									# pass in Dst_Buffer into argument a0
	jal get_String
	
	
	# get_Passphrase subroutine
	li $v0, 4
	la $a0, Ask_Passphrase
	syscall												# prompt to enter the passphrase
	la $a1, Passphrase_Buffer							# pass in Passphrase_Buffer into argument a1
	jal get_Passphrase
	
	
	# encrypt_File subroutine
	la $a0, Src_Buffer									# pass in Src_Buffer into argument a0
	la $a1, Dst_Buffer									# pass in Dst_Buffer into argument a1
	la $a2, Passphrase_Buffer							# pass in Passphrase_Buffer into argument a2
	jal encrypt_File


	li $v0, 10											# terminate the program
	syscall





# leaf subroutine for retrieving for file's information
.text
get_String:

	li $v0, 8
	la $a1, Src_Path_sz
	syscall												# read string. a0 contains the buffer, a1 has the size.
	
	removeNewLine:
	
		lbu $t0, 0($a0)
		beq $t0, $0, nullTerminated						# good, exit
	
		beq 	$t0, '\n', foundNewLine					# jump to remove appropriately
		addiu 	$a0, $a0, 1								# increment the character in the string
	
		j removeNewLine
	
	foundNewLine:
	sb $0, 0($a0)										# remove by storing zero

	nullTerminated:
	
	jr $ra												# return back to main
	




# leaf subroutine for retrieving the passphrase
.text
get_Passphrase:
	
	.data	
	.eqv	newLine								0xA

	# Receiver control.  1 in bit 0 means new char has arrived.  This bit
	# is read-only, and resets to 0 when CONSOLE_RECEIVER_DATA is read.
	# 1 in bit 1 enables hardware interrupt at interrupt level 1.
	# Interrupts must also be enabled in the coprocessor 0 status register.	
	.eqv	CONSOLE_RECEIVER_CONTROL           	0xffff0000
	.eqv	CONSOLE_RECEIVER_READY_MASK        	0x00000001
	.eqv	CONSOLE_RECEIVER_DATA              	0xffff0004
	
	.text
	# Spin-wait for key to be pressed
    key_wait:

	    lw      $t0, CONSOLE_RECEIVER_CONTROL
	    andi    $t0, $t0, CONSOLE_RECEIVER_READY_MASK  	# Isolate ready bit
	    beq     $t0, $0, key_wait
    
	    # Read in new character from keyboard to low byte of $t3
	    # and clear other 3 bytes of $t3
	    lbu     $t3, CONSOLE_RECEIVER_DATA
	    sb		$t3, 0($a1)								# store the character
		addiu 	$a1, $a1, 1								# increment
		beq		$t3, newLine, EXIT						# exit when press enter

		lui 	$t0, 0xffff								# make upper immediate all one's
		lw 		$t1, 8($t0)
		andi 	$t1, $t1, 1								# and t1 with 1

		ori 	$t2, $0, '*'							# display '*' for each character typed
		sw 		$t2, 12($t0)
		li 		$t1, newLine
		beq 	$t3, $t1, EXIT							# exit when press enter
		
	b key_wait
	
	EXIT:
	jr $ra												# return back to main





# leaf subroutine for encryting the file
.text
encrypt_File:

	.data
	.eqv 				FileRead						14
	.eqv				FileWrite						15
	.eqv 				FileOpen						13
	.eqv 				FileClose						16
	.eqv 				File_Buffer_sz					1024
	File_Buffer:		.space							File_Buffer_sz
	
	.text
	ManipFile:
		addiu $sp, $sp, -16								# stack
		sw $ra, 12($sp)									# return address
		sw $a0, 8($sp)									# src buffer
		sw $a1, 4($sp)									# dst buffer
		sw $a2, 0($sp)									# passphrase buffer

		# open sorce Path
		li $a1, 0
		li $a2, 0
		li $v0, FileOpen
		syscall
	
		# Test the descriptor for fault
		bltz $v0, exit
		sw $v0, 8($sp)
	
		# open Desination Path
		lw $a0, 4($sp)
		li $a1, 1
		li $a2, 0
		li $v0, FileOpen
		syscall
	
		# Test the descriptor for fault
		bltz $v0, closeSource
		sw $v0, 4($sp)
	
		Copy_Loop:
			# read buffer load of information
			li $v0, FileRead 							# read file
			lw $a0, 8($sp)								# load the src file
			la $a1, File_Buffer
			li $a2, File_Buffer_sz
			syscall										# read from src file
	
			addu $t2, $v0, 0
		
			blez 	$v0, Close_Resources
			lw 		$a2, 0($sp)							# load passphrse
			xor 	$a1, $a1, $a1
		
			xorLoop:
				lbu 	$t0, File_Buffer($a1)			# load to t0 with beginning of file buffer offset
				lbu 	$t1, 0($a2)						# load passphrase
				bne 	$t1, $0, encryptChar			# check for condition
				lw 		$a2, 0($sp)						# load passphrase
				lbu 	$t1, 0($a2)						# load passphrase with no offset
		
				encryptChar:
				xor 	$t0, $t1, $t0					# do the encryption by xor
				sb 		$t0, File_Buffer($a1)			# and then store in same buffer
				addiu 	$a1, $a1, 1						# increment in buffer
				addiu 	$a2, $a2, 1						# increment passphrase
				beq 	$t2, $a1, writeBuffer			# condition check to exit
		
			j xorLoop
		
			writeBuffer:
			lw 	$a0, 4($sp)								# load the dst buffer
			la 	$a1, File_Buffer
			li 	$v0, FileWrite
			xor $a2, $t2, $0
			syscall										# write to the dst buffer
	
			j Copy_Loop									# repeat until exit condition not met

		Close_Resources:
			li $v0, FileClose
			lw $a0, 4($sp)
			syscall										# close destination
		
		closeSource:	
			li $v0, FileClose
			lw $a0, 8($sp)
			syscall										# close source


		exit:
		lw 		$ra, 12($sp)							# retrieve the return address
		addiu 	$sp, $sp, 16							# deallocate the stack
	
		jr $ra											# return to main
