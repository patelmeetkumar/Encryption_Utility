	# IO programming 
	# Read chars from keyboard
	# echo them to the console
	# exit if the char = Q or q
	.data

    .eqv	SYS_PRINT_CHAR	0xB
	.eqv	EXIT_Q			0x51
	.eqv	EXIT_q			0x71
    
    # Receiver control.  1 in bit 0 means new char has arrived.  This bit
    # is read-only, and resets to 0 when CONSOLE_RECEIVER_DATA is read.
    # 1 in bit 1 enables hardware interrupt at interrupt level 1.
    # Interrupts must also be enabled in the coprocessor 0 status register.
    
    .eqv	CONSOLE_RECEIVER_CONTROL           0xffff0000
    .eqv	CONSOLE_RECEIVER_READY_MASK        0x00000001
    .eqv	CONSOLE_RECEIVER_DATA              0xffff0004
    
    # Main body
	    .text
    main:
    	li		$t1, EXIT_Q
		li		$t2, EXIT_q
	    
		# Spin-wait for key to be pressed
    key_wait:

	    lw      $t0, CONSOLE_RECEIVER_CONTROL
	    andi    $t0, $t0, CONSOLE_RECEIVER_READY_MASK  # Isolate ready bit
	    beqz    $t0, key_wait
    
	    # Read in new character from keyboard to low byte of $a0
	    # and clear other 3 bytes of $a0
	    lbu     $a0, CONSOLE_RECEIVER_DATA
	    
		beq		$a0, $t1, exit
		beq		$a0, $t2, exit

	   

	    b key_wait	    

	exit:
		li $v0, 10
		syscall