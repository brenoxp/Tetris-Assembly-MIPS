.eqv VGA 0xFF000000
.eqv TAMX 320
.eqv TAMY 240
.eqv PLAYERS_1_MENU_PY 100
.eqv PLAYERS_2_MENU_PY 130
.eqv PLAYERS_3_MENU_PY 160
.eqv PLAYERS_4_MENU_PY 190

######################
##  Memory offsets  ##
######################
.eqv OFFSET_NUMBER_OF_PLAYERS 000	# 000 - 004
.eqv OFFSET_REGISTERED_KEYS   4	# 004 - 068
.eqv OFFSET_OF_NEW_SP         68	


.data
	NUM:   .float  160.0
	
	TETRIS_STRING: .asciiz "TETRIS\n"
	PLAYERS_1:     .asciiz "1 Jogador\n"
	PLAYERS_2:     .asciiz "2 Jogadores\n"
	PLAYERS_3:     .asciiz "3 Jogadores\n"
	PLAYERS_4:     .asciiz "4 Jogadores\n"
	SELECT_OPTION: .asciiz "->\n"
	
.text
# ------  INÍCIO DA MAIN ------
MAIN:
	# Save $sp value into $s7
	move $s7, $sp

	# Update $sp
	subi $sp, $sp, OFFSET_OF_NEW_SP

	# Save number of users (Default 1)
	subi $t0, $s7, OFFSET_NUMBER_OF_PLAYERS
	li $t1, 1
	sw $t1, ($t0)

	# Inicializa a tela
	la $t0, VGA
	li $t1, TAMX
	li $t5, 0x00  # cor 0x00000000
	
	jal PRINT_MENU
	jal READ_MENU_OPTION_INPUT

	li $v0 10
	syscall

###################
##  Menu screen  ##
###################
PRINT_MENU:
	addi $sp, $sp, -4 
	sw   $ra, 0($sp)

	li $a0, 0x0000
	li $v0, 48
	syscall
	
	li $v0, 104	
	la $a0, TETRIS_STRING
	li $a1, 135	
	li $a2, 30	
	li $a3, 0x00FF	
	syscall

	li $v0, 104	
	la $a0, PLAYERS_1
	li $a1, 120	
	li $a2, PLAYERS_1_MENU_PY	
	li $a3, 0x00FF	
	syscall
	
	li $v0, 104	
	la $a0, PLAYERS_2
	li $a1, 120	
	li $a2, PLAYERS_2_MENU_PY	
	li $a3, 0x00FF	
	syscall
	
	li $v0, 104	
	la $a0, PLAYERS_3
	li $a1, 120
	li $a2, PLAYERS_3_MENU_PY	
	li $a3, 0x00FF	
	syscall
	
	li $v0, 104	
	la $a0, PLAYERS_4
	li $a1, 120
	li $a2, PLAYERS_4_MENU_PY
	li $a3, 0x00FF
	syscall
	
	li $a3, 0x00FF
	jal PRINT_MENU_OPTION
	
	lw   $ra, 0($sp)
	addi $sp, $sp, 4 
	
	jr $ra


## Imprime seta que seleciona o jogador
## OFFSET_NUMBER_OF_PLAYERS : posicao Y da seta
## $a3 : Color 
PRINT_MENU_OPTION:  
	addi $sp, $sp, -4 
	sw   $ra, 0($sp)

	li $v0, 104
	la $a0, SELECT_OPTION
	li $a1, 90

	# Load number of users
	subi $t0, $s7, OFFSET_NUMBER_OF_PLAYERS
	lw $t1, ($t0)
	
	bne $t1, 1, MENU_OPT_2
	li $a2, PLAYERS_1_MENU_PY
	j MENU_OUT
MENU_OPT_2:
	bne $t1, 2, MENU_OPT_3
	li $a2, PLAYERS_2_MENU_PY
	j MENU_OUT
MENU_OPT_3:
	bne $t1, 3, MENU_OPT_4
	li $a2, PLAYERS_3_MENU_PY
	j MENU_OUT
MENU_OPT_4:
	bne $t1, 4, MENU_OUT
	li $a2, PLAYERS_4_MENU_PY
	
MENU_OUT:
	syscall
	
	lw   $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
## Fim imprime seta que seleciona o jogador

READ_MENU_OPTION_INPUT:
	addi $sp, $sp, -4 
	sw $ra, 0($sp)
	
	li $v0, 12       
  	syscall            # Read Character
  	addi $a0, $v0, 0
  	
  	li $t1, 115
  	bne $t1, $v0, NOT_AN_S
  	jal PRESS_MENU_DOWN
NOT_AN_S:

	li $t1, 119
	bne $t1, $v0, NOT_AN_W
  	jal PRESS_MENU_UP
NOT_AN_W:

  	j PRESS_MENU_NOTHING
  	
  	lw   $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
  	
PRESS_MENU_DOWN:
	addi $sp, $sp, -4 
	sw   $ra, 0($sp)

	li $a3, 0x0000
	jal PRINT_MENU_OPTION

	# Load number of users
	subi $t0, $s7, OFFSET_NUMBER_OF_PLAYERS
	lw $t1, ($t0)
	move $t0, $t1
	
	bne $t1, 1, PRESS_MENU_DOWN_OP2
	li $t0, 2
	j PRESS_MENU_DOWN_OUT
PRESS_MENU_DOWN_OP2:
	bne $t1, 2, PRESS_MENU_DOWN_OP3
	li $t0, 3
	j PRESS_MENU_DOWN_OUT
PRESS_MENU_DOWN_OP3:
	bne $t1, 3, PRESS_MENU_DOWN_OUT
	li $t0, 4

PRESS_MENU_DOWN_OUT:
	subi $t1, $s7, OFFSET_NUMBER_OF_PLAYERS
	sw $t0, ($t1)

	li $a3, 0x00FF
	jal PRINT_MENU_OPTION
	
	lw   $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
# Fim PRESS_MENU_DOWN_OUT

PRESS_MENU_UP:
	addi $sp, $sp, -4 
	sw   $ra, 0($sp)

	li $a3, 0x0000
	jal PRINT_MENU_OPTION

	# Load number of users
	subi $t0, $s7, OFFSET_NUMBER_OF_PLAYERS
	lw $t1, ($t0)
	move $t0, $t1
	
	bne $t1, 2, PRESS_MENU_UP_OP2
	li $t0, 1
	j PRESS_MENU_UP_OUT
PRESS_MENU_UP_OP2:
	bne $t1, 3, PRESS_MENU_UP_OP3
	li $t0, 2
	j PRESS_MENU_UP_OUT
PRESS_MENU_UP_OP3:
	bne $t1, 4, PRESS_MENU_UP_OUT
	li $t0, 3

PRESS_MENU_UP_OUT:
	subi $t1, $s7, OFFSET_NUMBER_OF_PLAYERS
	sw $t0, ($t1)

	li $a3, 0x00FF
	jal PRINT_MENU_OPTION
	
	lw   $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
# Fim PRESS_MENU_UP_OUT
	
PRESS_MENU_NOTHING:
  	li $v0, 11       
  	syscall            # Write Character
  	j READ_MENU_OPTION_INPUT
  	nop

#######################
##  End menu screen  ##
#######################
