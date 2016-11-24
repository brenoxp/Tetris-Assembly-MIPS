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
.eqv OFFSET_NUMBER_OF_PLAYERS  000	# 000 - 004
.eqv OFFSET_REGISTERED_KEYS   -004	# 004 - 068
.eqv OFFSET_OF_NEW_SP         -68	


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
	# Update $sp
	addi $sp, $sp, OFFSET_OF_NEW_SP

	# Inicializa a tela
	la $t0, VGA
	li $t1, TAMX
	li $t5, 0x00  # cor 0x00000000
	
	jal PRINT_MENU

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
	
	li $t2, 90
	jal PRINT_MENU_OPTION
	
	lw   $ra, 0($sp)
	addi $sp, $sp, 4 
	
	jr $ra


## Imprime seta que seleciona o jogador
## $t2 : posicao Y da seta
PRINT_MENU_OPTION:  
	li $v0, 104
	la $a0, SELECT_OPTION
	move $a1, $t2
	li $a2, PLAYERS_3_MENU_PY
	li $a3, 0x00FF
	syscall

#READ_MENU_OPTION_INPUT:
#	li   $v0, 12       
#  	syscall            # Read Character
#  	addiu $a0, $v0, 0  # $a0 gets the next char
#  	
#  	li $t1, 83
#  	beq $t1, $a0 PRESS_MENU_S
#  	j PRESS_MENU_NOTHING
  	
#PRESS_MENU_S:
#	li $t2 120
#	jal PRINT_MENU_OPTION
	
#PRESS_MENU_NOTHING:
#  	li $v0, 11       
#  	syscall            # Write Character
#  	b READ_MENU_OPTION_INPUT
#  	nop

#######################
##  End menu screen  ##
#######################
