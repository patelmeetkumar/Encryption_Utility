# Who:  Me
# What: project_template.asm
# Why:  A template to be used for all CS264 labs
# When: Created when? Due when?
# How:  List the uses of registers

.data
.eqv	FileWrite			15
.eqv 	FileRead			14
.eqv 	FileOpen			13
.eqv 	FileClose			16
.eqv 	File_Buffer_sz		1024
		File_Buffer:		.space		File_Buffer_sz
		Src_Path:			.asciiz		"Test.txt"
		Dst_Path:			.asciiz		"Copy.txt"
.align 2

.text
.globl main


main:	# program entry
	
	# open sorce PAth
	la $a0, Src_Path
	li $a1, 0
	li $a2, 0
	li $v0, FileOpen
	syscall
	
	# Test the descriptor for fault
	move $s0, $v0	# save discriptor
	slt $t0, $s0, $0
	bne $t0, $0, Exit
	
	# open Desination Path
	la $a0, Dst_Path
	li $a1, 1
	li $a2, 0
	li $v0, FileOpen
	syscall
	
	# Test the descriptor for fault
	move $s1, $v0	# save discriptor
	slt $t0, $s0, $0
	bne $t0, $0, Exit
	
	
Copy_Loop:
	# read buffer load of information
	li $v0, FileRead # read file
	move $a0, $s0
	la $a1, File_Buffer
	li $a2, File_Buffer_sz
	syscall
	
	beq $0, $v0, Close_Resources
	
	
	
	move $a0, $s1
	la $a1, File_Buffer
	move $a2, $v0
	li $v0, FileWrite # read file
	syscall
	
	j Copy_Loop
	
	
Exit_Copy_Loop:
	
Close_Resources:
# close source
	li $v0, FileClose
	move $a0, $s0
	syscall
# close Dest
	li $v0, FileClose
	move $a0, $s1
	syscall
Exit:
li $v0, 10		# terminate the program
syscall
