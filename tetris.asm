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

######################
##      IRDA 		##
######################
.eqv IRDA_READ_ADDRESS 0xFFFF0504

.data
	NUM:   .float  160.0
	
	TETRIS_STRING: .asciiz "TETRIS\n"
	PLAYERS_1:     .asciiz "1 Jogador\n"
	PLAYERS_2:     .asciiz "2 Jogadores\n"
	PLAYERS_3:     .asciiz "3 Jogadores\n"
	PLAYERS_4:     .asciiz "4 Jogadores\n"
	SELECT_OPTION: .asciiz "->\n"
	CONFIG_P: 	   .asciiz "Config. das Keys do Jogador "
	CONFIG_T0:	   .asciiz "Escolha a tecla <<"
	CONFIG_T1:     .asciiz "Escolha a tecla >>"
	CONFIG_T2:	   .asciiz "Escolha a tecla v"
	CONFIG_T3:	   .asciiz "Escolha a tecla rotacao."
	
.text
# ------  INÃ?CIO DA MAIN ------
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
	
	# Printa o menu e lê a opção escolhida
	jal PRINT_MENU
	jal READ_MENU_OPTION_INPUT
	
	# Configura os controles escolhidos, se $s1 = 0 => TECLADO, $s1 = 1 => IRDA
	move $s1, $zero
	jal CONTROL_CONFIG
	
	li $v0 10
	syscall

###################
##  Menu screen  ##
###################
PRINT_MENU:
	addi $sp, $sp, -4 
	sw   $ra, 0($sp)

	li $v0, 48
	li $a0, 0x0000
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
	li $t1, 10
	bne $t1, $v0, NOT_AN_ENTER
  	
  	lw   $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
NOT_AN_ENTER:

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

#######################
##  Control Config   ##
#######################
# Pega o número de jogadores da memória e configura as teclas do IrDA para cada um e as coloca na memória.
CONTROL_CONFIG: 
	addi $sp, $sp, -4 
	sw   $ra, 0($sp)
	
	# Load number of users
	subi $t0, $s7, OFFSET_NUMBER_OF_PLAYERS
	lw $t1, ($t0)
	move $s0, $t1
	
	# Pointer to keys allocation in memory	
	subi $t1, $s7, OFFSET_REGISTERED_KEYS
	
	# IrDA Read Address 
	la $t2, IRDA_READ_ADDRESS
	
	# Number of players counter
	addi $t3, $zero, 1
	
# Loop: while(players): get keys 
LOOP_CONTROL:
	
	# Limpa a tela 
	li $v0, 48
	li $a0, 0x0000
	syscall
	
	# PRINT CONFIG STRING + PLAYER NUMBER
	li $v0, 104	
	la $a0, CONFIG_P
	li $a1, 10
	li $a2, 30	
	li $a3, 0x00FF	
	syscall
	
	li $v0, 101
	move $a0, $t3
	li $a1, 300
	li $a2, 30
	li $a3, 0x00BB
	syscall
	
	# GET KEY 0
	li $v0, 104	
	la $a0, CONFIG_T0 
	li $a1, 120	
	li $a2, PLAYERS_1_MENU_PY	
	li $a3, 0x00FF	
	syscall
	jal GET_KEY 
	subi $t1, $t1, -4
	
	# GET KEY 1	
	li $v0, 104	
	la $a0, CONFIG_T1
	li $a1, 120	
	li $a2, PLAYERS_2_MENU_PY	
	li $a3, 0x00FF	
	syscall
	jal GET_KEY 
	subi $t1, $t1, -4
	
	# GET KEY 2
	li $v0, 104	
	la $a0, CONFIG_T2
	li $a1, 120
	li $a2, PLAYERS_3_MENU_PY	
	li $a3, 0x00FF	
	syscall
	jal GET_KEY 
	subi $t1, $t1, -4
	
	# GET KEY 3	
	li $v0, 104	
	la $a0, CONFIG_T3
	li $a1, 120
	li $a2, PLAYERS_4_MENU_PY
	li $a3, 0x00FF
	syscall
	jal GET_KEY 
	subi $t1, $t1, -4
	
	beq $s0, $t3, END_IRDA
	addi $t3, $t3, 1
	j LOOP_CONTROL

# Get key = 0 - Teclado
# Get key = 1 - IrDA
GET_KEY:
	beq $s1, $t9, TECLADO_GET_KEY
	addi $t9, $t9, 1
	beq $s1, $t9, IRDA_GET_KEY
	
# Read character and saves ASCII code
TECLADO_GET_KEY:
	li $v0, 12
	syscall
	
	# saves value
	sw $v0, ($t1) 
	jr $ra

# Keeps IrDA on loop until it reads something from the receiver addres
IRDA_GET_KEY:
	# Keeps searching until IrDA different than zero
	lw $t4, 0($t2) # $t2 = IRDA_READ_ADDRESS
	bne $t4, $zero, IRDA_GET_KEY
	
	# IrDA different than zero, save value and return
	sw $t4, 0($t1)
	move $t4, $zero
	jr $ra
	
END_IRDA:	 	 
	lw   $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
#######################
## End Control Config##
#######################













