# Read keyboard input and print on "Enter / Return"
# Handles: backspace, character sizes 32 bits or smaller, strings upto 250 characters long
.data
.align 2
input:	.space 1000
	
.text
.globl main

# s0 = location of current character to input
# s1 = location to read from
main:

next_line:
	la		$s0, input

read_line:
	jal		read_keyboard
	
	sw		$v0, 0($s0)				# Save character into buffer
	or		$s1, $0, $v0			# Preserve across subroutine

	or		$a0, $0, $v0			
	jal 	debug_print
	
	# Remove last character if backspace (0x8) is seen
	bne		$s1, 8, line_increment
	
	# Remove the backspace character
	lw		$0, 0($s0)
	# Set the index back 1 for the preceding character (we have not incremented for the baskspace)
	addiu	$s0, $s0, -4			
	j 		read_line
	
line_increment:	
	addiu	$s0, $s0, 4
	bne		$s1, '\n', read_line	# Start printing only if the last character read was a newline
	
start_print:
	la		$s1, input	
	
print_line:	
	lw 		$a0, 0($s1)
	sw		$0, 0($s1)				# Erase the buffer as we print it out
	
	beq		$a0, $0, next_char
	jal 	display_char

next_char:		
	addiu	$s1, $s1, 4
	bleu	$s1, $s0, print_line

	j 		next_line
			
terminate:
	ori		$v0, $0, 10
	syscall							# Terminate correctly

# SUBROUTINE SECTION START

# Read a single character from the keyboard
# v0 = value loaded from keyboard
# t0 = base address, $t1 = ready bit
.text
read_keyboard:

	lui		$t0, 0xFFFF

keyboard_ready:

# Get the keyboard ready bit
	lbu		$t1, 0($t0)
	andi	$t1, $t1, 1
	beq		$t1, $0, keyboard_ready	# 0 = not ready

	lw		$v0, 4($t0)		# v0 = keyboard input

	jr 		$ra

# Print content of a0 to display
# a0 = ASCII value to display
# t0 = base address, t1 = ready bit
.text
display_char:

	lui		$t0, 0xFFFF

display_ready:
# Get the display ready bit
	lbu		$t1, 8($t0)
	andi	$t1, $t1, 1
	beq		$t1, $0, display_ready

	sw		$a0, 12($t0)
	
	jr 		$ra

# Print, with the [DEBUG] prefix, the hex number passed in
# a0 = hex value to print
.data

debug_msg: .asciiz "[DEBUG] "	

.text
debug_print:

	or		$t0, $0, $a0		# t0 = value to print

	ori		$v0, $0, 4
	la		$a0, debug_msg
	syscall						# Print the debug prefix
	
	ori		$v0, $0, 34
	or		$a0, $0, $t0
	syscall						# Print out the hex value

	ori		$v0, $0, 11
	ori		$a0, $0, '\n'
	syscall						# Print out a newline
	
	jr 		$ra
