.text 


	loop:

	la $t0, 0xFF100004

	nop
	nop
	nop
	nop

	lw $a0, ($t0)
	
	beq $a0, 0, loop
	
	
	li $v0, 1
	syscall
	
	li $v0, 10
	syscall