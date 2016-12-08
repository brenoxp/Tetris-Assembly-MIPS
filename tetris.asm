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
.eqv OFFSET_NUMBER_OF_PLAYERS 0   	# 000 - 004
.eqv OFFSET_REGISTERED_KEYS   4	        # 004 - 068
.eqv OFFSET_BOARD_POSITIONS   68 	# 068 - 084
.eqv OFFSET_MATRICES	      84	# 084 - 1084
.eqv OFFSET_SCORES	      5000      # 5000 - 5016
.eqv OFFSET_USER_CLOCK	      5016      # 5016 - 5032
.eqv OFFSET_OF_NEW_SP         5032


######################
##      IRDA 	    ##
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
	CONFIG_P:      .asciiz "Config. das Keys do Jogador "
	CONFIG_T0:     .asciiz "Escolha a tecla <<"
	CONFIG_T1:     .asciiz "Escolha a tecla >>"
	CONFIG_T2:     .asciiz "Escolha a tecla v"
	CONFIG_T3:     .asciiz "Escolha a tecla rotacao."
	SCORE_P1:      .asciiz "SCORE P1: "
	SCORE_P2:      .asciiz "SCORE P2: "
	SCORE_P3:      .asciiz "SCORE P3: "
	SCORE_P4:      .asciiz "SCORE P4: " 
	
.text
# ------  IN�?CIO DA MAIN ------
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
	
	# Printa o menu e l� a op��o escolhida
	jal PRINT_MENU
		
	jal READ_MENU_OPTION_INPUT
	
	# Configura os controles escolhidos, se $s1 = 0 => TECLADO, $s1 = 1 => IRDA
	#move $s1, $zero
	#jal CONTROL_CONFIG
	
	# Erase Screen
	li $a0, 0x00
	li $v0, 48
	syscall
	
	jal INIT_MAIN_LOOP

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
# Pega o n�mero de jogadores da mem�ria e configura as teclas do IrDA para cada um e as coloca na mem�ria.
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


#######################
##    Print pixel    ##
#######################
# $a0 = X
# $a1 = Y
# $a2 = Color

PLOT_PIXEL:
	addi $sp, $sp, -4 
	sw   $ra, 0($sp)	

	li $v0, 45
	syscall
	
	lw   $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
#######################
##  End Print pixel  ##
#######################

########################
## Print static board ##
########################
# $a0 = Amount of players

PRINT_STATIC_BOARDS:
	addi $sp, $sp, -4 
	sw   $ra, 0($sp)

	subi $t0, $s7, OFFSET_NUMBER_OF_PLAYERS
	lw $t1, ($t0)
	
	li $a2, 0xFF
	
	bne $t1, 1, IF_NOT_1_PLAYER
	subi $t0, $s7, OFFSET_BOARD_POSITIONS
	li $a0, 125
	sw $a0, ($t0)
	jal PRINT_ONE_BOARD
IF_NOT_1_PLAYER:
	bne $t1, 2, IF_NOT_2_PLAYERS
	subi $t0, $s7, OFFSET_BOARD_POSITIONS
	li $a0, 65
	sw $a0, ($t0)
	jal PRINT_ONE_BOARD
	
	subi $t0, $s7, OFFSET_BOARD_POSITIONS
	subi $t0, $t0, 4
	li $a0, 200
	sw $a0, ($t0)
	
	jal PRINT_ONE_BOARD
IF_NOT_2_PLAYERS:
	bne $t1, 3, IF_NOT_3_PLAYERS
	subi $t0, $s7, OFFSET_BOARD_POSITIONS
	li $a0, 30
	sw $a0, ($t0)
	jal PRINT_ONE_BOARD
	
	subi $t0, $s7, OFFSET_BOARD_POSITIONS
	subi $t0, $t0, 4
	li $a0, 130
	sw $a0, ($t0)
	jal PRINT_ONE_BOARD
	
	subi $t0, $s7, OFFSET_BOARD_POSITIONS
	subi $t0, $t0, 8
	li $a0, 230
	sw $a0, ($t0)
	jal PRINT_ONE_BOARD
IF_NOT_3_PLAYERS:
	bne $t1, 4, IF_NOT_4_PLAYERS
	subi $t0, $s7, OFFSET_BOARD_POSITIONS
	li $a0, 4
	sw $a0, ($t0)
	jal PRINT_ONE_BOARD
	
	subi $t0, $s7, OFFSET_BOARD_POSITIONS
	subi $t0, $t0, 4
	li $a0, 84
	sw $a0, ($t0)
	jal PRINT_ONE_BOARD
	
	subi $t0, $s7, OFFSET_BOARD_POSITIONS
	subi $t0, $t0, 8
	li $a0, 164
	sw $a0, ($t0)
	jal PRINT_ONE_BOARD
	
	subi $t0, $s7, OFFSET_BOARD_POSITIONS
	subi $t0, $t0, 12
	li $a0, 244
	sw $a0, ($t0)
	jal PRINT_ONE_BOARD
IF_NOT_4_PLAYERS:	
	

	lw   $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
############################
## End print static board ##
############################


########################
## Print one board    ##
########################
# $a0 = X position
# $a2 = color
PRINT_ONE_BOARD:
	addi $sp, $sp, -4 
	sw   $ra, 0($sp)

	li $a1, 50
	#for 0 -> 140
	li $t0, 0
PRINT_ONE_BOARD_LOOP_1:
	jal PLOT_PIXEL
	
	addi $a0, $a0, 72
	jal PLOT_PIXEL
	addi $a0, $a0, -72
	
	addi $a1, $a1, 1
	addi $t0, $t0, 1
	bne $t0, 142, PRINT_ONE_BOARD_LOOP_1
	
	#li $a1, 0
	#for 0 -> 70
	li $t0, 20
PRINT_ONE_BOARD_LOOP_2:
	
	jal PLOT_PIXEL
	addi $a1, $a1, -142
	jal PLOT_PIXEL
	addi $a1, $a1, 142
	
	addi $a0, $a0, 1
	addi $t0, $t0, 1
	bne $t0, 93, PRINT_ONE_BOARD_LOOP_2


	lw   $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

##########################
## End print one board  ##
##########################


########################
## Print Square       ##
########################
# $a0 = X position
# $a1 = Y position
# $a2 = color
# $a3 = Player {0, 1, 2, 3}

PRINT_SQUARE:
	addi $sp, $sp, -4 
	sw   $ra, 0($sp)

	mul $a3, $a3, 4
	
	subi $t0, $s7, OFFSET_BOARD_POSITIONS
	sub $t0, $t0, $a3
	lw $t1, ($t0)
	
	
	move $t2, $t1	# nesta linha $t2 tem o x indicando o incio do campo de jogo
	# offset de x
	mul $a0, $a0, 7
	add $t2, $t2, $a0
	addi $t2, $t2, 2	# Pula dois pixel para mostrar vazio entre dois quadrados
	
	addi $t4, $t2, 6	# end x
	
	
	#li $t3, 50		#inicio de y
	#addi $t5, $t3, 6	# end y
	
	li $t3, 50	# nesta linha $t3 tem o y indicando o incio do campo de jogo
	# offset de y
	mul $a1, $a1, 7
	add $t3, $t3, $a1
	addi $t3, $t3, 2	# Pula dois pixel para mostrar vazio entre dois quadrados
	move $t6, $t3		#salva valor de $t3 em $t6
	
	addi $t5, $t3, 6	# end y
	
	
PRINT_SQUARE_LOOP1:
	move $t3, $t6
PRINT_SQUARE_LOOP2:
	
	move $a0, $t2
	move $a1, $t3
	jal PLOT_PIXEL
	
	addi $t3, $t3, 1
	
	bne $t3, $t5, PRINT_SQUARE_LOOP2
	addi $t2, $t2, 1
	bne $t2, $t4, PRINT_SQUARE_LOOP1
			
	lw   $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
########################
## end print Square   ##
########################


########################
##    Init Matrices   ##
########################
INIT_MATRICES:
	addi $sp, $sp, -4 
	sw   $ra, 0($sp)

	
	# $t0 position of memory to save color
	# $t1 Amount of Players
	# $t2 count 0 -> $t1
	# $t4 end position of memory to save color
	# $t5 color
	# $t6 INIT MATRICES OFFSET
	
	subi $t0, $s7, OFFSET_NUMBER_OF_PLAYERS
	lw $t1, ($t0)
	li $t2, 0
	
	subi $t0, $s7, OFFSET_MATRICES

INIT_MATRICES_MAIN_LOOP:
		
	subi $t4, $t0, 160
INIT_MATRICES_LOOP2:
	li $t5, 0x00
	sw $t5, ($t0)
	subi $t0, $t0, 1
	bne $t0, $t4, INIT_MATRICES_LOOP2
	
	
	subi $t4, $t0, 800
INIT_MATRICES_LOOP1:
	li $t5, 0x00
	sw $t5, ($t0)
	subi $t0, $t0, 1
	bne $t0, $t4, INIT_MATRICES_LOOP1
	
	subi $t4, $t0, 40
INIT_MATRICES_LOOP3:
	li $t5, 0xFF
	sw $t5, ($t0)
	subi $t0, $t0, 1
	bne $t0, $t4, INIT_MATRICES_LOOP3
	
	addi $t2, $t2, 1
	bne $t1, $t2, INIT_MATRICES_MAIN_LOOP
	
	
	lw   $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
########################
## end Init Matrices  ##
########################


########################
##    Print Boards    ##
########################
PRINT_BOARDS:
	addi $sp, $sp, -4 
	sw   $ra, 0($sp)
	addi $sp, $sp, -4 
	sw   $s0, 0($sp)
	addi $sp, $sp, -4 
	sw   $s1, 0($sp)

	li $s5, 0
LOOP_PRINT_BOARDS:
	subi $s0, $s7, OFFSET_NUMBER_OF_PLAYERS
	lw $s0, ($s0)
	move $a3, $s1
	jal PRINT_BOARD
	addi $s1, $s1, 1
	bne $s1, $s0, LOOP_PRINT_BOARDS
	
	lw   $s1, 0($sp)
	addi $sp, $sp, 4
	lw   $s0, 0($sp)
	addi $sp, $sp, 4
	lw   $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
########################
##  End Print Boards  ##
########################



########################
##    Print Board     ##
########################
# $a3 player = {0, 1, 2, 3}
PRINT_BOARD:
	addi $sp, $sp, -4 
	sw   $ra, 0($sp)
	addi $sp, $sp, -4 
	sw   $s0, ($sp)
	addi $sp, $sp, -4 
	sw   $s1, ($sp)
	addi $sp, $sp, -4 
	sw   $s2, ($sp)
	addi $sp, $sp, -4 
	sw   $s3, ($sp)
	addi $sp, $sp, -4 
	sw   $s4, ($sp)
	
	move $s4, $a3
	mul $s3, $a3, 1000
	
	subi $s2, $s7, OFFSET_MATRICES
	sub $s2, $s2, $s3
	
	li $s0, 0
	li $s1, -4
PRINT_BOARD_LOOP1:
	li $s0, 0
PRINT_BOARD_LOOP2:
	move $a0, $s0
	move $a1, $s1
	lw $a2, ($s2)
	move $a3, $s4
	jal PRINT_SQUARE
	
	subi $s2, $s2, 4
	
	addi $s0, $s0, 1
	bne $s0, 10, PRINT_BOARD_LOOP2
	addi $s1, $s1, 1
	bne $s1, 21, PRINT_BOARD_LOOP1

	lw   $s4, ($sp)
	addi $sp, $sp, 4
	lw   $s3, ($sp)
	addi $sp, $sp, 4
	lw   $s2, ($sp)
	addi $sp, $sp, 4
	lw   $s1, ($sp)
	addi $sp, $sp, 4
	lw   $s0, ($sp)
	addi $sp, $sp, 4
	lw   $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

########################
## Init Score         ##
########################
INIT_SCORE:
	addi $sp, $sp, -4 
	sw   $ra, 0($sp)
	
	li $t0, 0
	subi $t1, $s7, OFFSET_SCORES
	sw $t0, ($t1)
	subi $t1, $t1, 4
	sw $t0, ($t1)
	subi $t1, $t1, 4
	sw $t0, ($t1)
	subi $t1, $t1, 4
	sw $t0, ($t1)
	
	lw   $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
########################
## End Init Score     ##
########################


########################
## Update Score       ##
########################
# $a0 = Player {0, 1, 2, 3}
# $a1 = Score to be added
UPDATE_SCORE:
	addi $sp, $sp, -4 
	sw   $ra, 0($sp)
	
	move $t2, $a1
	
	subi $t0, $s7, OFFSET_BOARD_POSITIONS
	
	mul $t1, $a0, 4
	sub $t0, $t0, $t1
	lw $a1, ($t0)		# $a1 = X Position to print
	addi $a1, $a1, 8
	
	subi $t0, $s7, OFFSET_SCORES
	sub $t0, $t0, $t1
	lw $a0, ($t0)		# $a0 = Value to print
	
	add $a0, $a0, $t2
	sw $a0, ($t0)
	
	li $v0, 101
	li $a2, 200
	li $a3, 0xFF
	syscall
	
	lw   $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
########################
##  End update Score  ##
########################

	
########################
##    Main Loop       ##
########################
INIT_MAIN_LOOP:
	addi $sp, $sp, -4 
	sw   $ra, 0($sp)
	addi $sp, $sp, -4 
	sw   $s0, 0($sp)	# $s0 = Amount of users
	addi $sp, $sp, -4 
	sw   $s1, 0($sp)	# $s1 = Count amount of users
	
	jal INIT_MATRICES
	
	jal PRINT_STATIC_BOARDS
	
	jal PRINT_BOARDS
	
	jal INIT_SCORE
	
	li $s1, 0		# Count amount of users = 0
	
MAIN_LOOP:
	
	subi $s0, $s7, OFFSET_NUMBER_OF_PLAYERS
	lw $s0, ($s0)
	
MAIN_LOOP_PLAYER:
	
	move $a0, $s1
	jal PLAYER_LOOP
	addi $s1, $s1, 1
	ble $s0, $s1,  MAIN_LOOP_PLAYER
	
EXIT_MAIN_LOOP:
	#lw   $s2, 0($sp)
	#addi $sp, $sp, 4
	lw   $s1, 0($sp)
	addi $sp, $sp, 4
	lw   $s0, 0($sp)
	addi $sp, $sp, 4
	lw   $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
########################
##    End Main Loop   ##
########################
	
########################
##    Player Loop     ##
########################
# $a0 = Current Player
PLAYER_LOOP:
	addi $sp, $sp, -4 
	sw   $ra, 0($sp)
	
	
	li $v0, 1
	syscall

	lw   $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
########################
##   End player Loop  ##
########################