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
.eqv OFFSET_NUMBER_OF_PLAYERS 	0   		# 000 - 004
.eqv OFFSET_REGISTERED_KEYS   	4	        # 004 - 068
.eqv OFFSET_BOARD_POSITIONS   	68 			# 068 - 084
.eqv OFFSET_MATRICES	      	84			# 084 - 5084
.eqv OFFSET_SCORES	      		5084		# 5084 - 5100
.eqv OFFSET_SPEED_DOWN	      	5100		# 5100 - 5104
.eqv OFFSET_USER_CLOCK	      	5104		# 5104 - 5120
.eqv OFFSET_TYPE_CURRENT_PIECE 	5120		# 5120 - 5136
.eqv OFFSET_INFO_PIECE 			5136		# 5136 - 5456 ({X, Y, Type, Rotation, [4X4]}) * 4 PLAYERS
.eqv OFFSET_INFO_AUX_PIECE 		5456		# 5456 - 5536 ({X, Y, Type, Rotation, [4X4]})
.eqv OFFSET_OF_NEW_SP         	5536


# Info piece type
#   0 = Straight Polyomino
#   1 = Square Polyomino
#   2 = T-Polyomino
#   3 = J
#   4 = L
#   5 = S
#   6 = Z
#
# See https://en.wikipedia.org/wiki/Tetromino#One-sided_tetrominoes


######################
##      IRDA 	    ##
######################
.eqv IRDA_READ_ADDRESS 0xFFFF0504

.data
	NUM:   .float  160.0
	
	SEED: .word 0x00001015
	
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
	NL:            .asciiz "\n"
	SPACE:         .asciiz " "
	
.text
# ------  IN�?CIO DA MAIN ------
MAIN:
	# Save $sp value into $s7
	move $s7, $sp
	
	# Update $sp
	subi $sp, $sp, OFFSET_OF_NEW_SP
	
	# Configura os controles escolhidos se for IrDA
	#li $s1, 1
	#jal CONTROL_CONFIG

	
	# Save number of users (Default 1)
	subi $t0, $s7, OFFSET_NUMBER_OF_PLAYERS
	li $t1, 2
	sw $t1, ($t0)

	# Inicializa a tela
	la $t0, VGA
	li $t1, TAMX
	li $t5, 0x00  # cor 0x00000000
	
	# Printa o menu e l� a op��o escolhida, se $s1 = 0 => TECLADO, $s1 = 1 => IRDA
	li $s1, 0
	# li $s1, 1  <= IRDA
	jal PRINT_MENU
	
	jal READ_MENU_OPTION_INPUT
	
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

### $s0 = 0 => TECLADO, $s1 = 1 => IRDA
READ_MENU_OPTION_INPUT:
	addi $sp, $sp, -4 
	sw $ra, 0($sp)
	
	beq $s1, $zero, USE_KEYBOARD
	la $t2, IRDA_READ_ADDRESS
	# Pointer to keys allocation in memory	
	subi $s5, $s7, OFFSET_REGISTERED_KEYS

	USE_IRDA: 
	# Keeps IrDA on loop until it reads something from the receiver addres
	jal IRDA_GET_KEY
	move $s2, $t4 # tecla recebida
	
	# Ve se eh um up down ou escolha
	DECODE_KEY: 
	# se for um down
	lw $s6,($s5)
	bne $s6, $s2, NOT_DOWN_IR
	jal PRESS_MENU_DOWN
	
	NOT_DOWN_IR:	
	# se for um up
	lw $s6,-4($s5)
	bne $s6, $s2, NOT_UP_IR
	jal PRESS_MENU_UP
	
	NOT_UP_IR:
	# se for um enter
	lw $s6,-8($s5)
	beq $s6, $s2, ENTER_IR
	#nao eh enter, volta
	j USE_IRDA
	
	ENTER_IR:	  	
  	lw   $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
USE_KEYBOARD:
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
	li $t1, 1
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
	move $t9, $zero
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
	beq $t4, $zero, IRDA_GET_KEY

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
	li $v0, 45
	syscall

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
	sw   $s1, 0($sp)	# $s1 = Count amount of users ($s1 -> $s0) 
	addi $sp, $sp, -4 
	sw   $s2, 0($sp)	# apagar 
	
	li $s2, 0	# apagar 
	
	jal INIT_MATRICES
	
	jal PRINT_STATIC_BOARDS
	
	#jal PRINT_BOARDS
	
	jal INIT_SCORE
	
	jal INIT_USERS_CLOCKS
	
	subi $t0, $s7, OFFSET_SPEED_DOWN
	li $t1, 10
	sw $t1, ($t0)		# save initial difficulty
	
	li $s1, 0		# Count amount of users = 0
	
	subi $s0, $s7, OFFSET_NUMBER_OF_PLAYERS
	lw $s0, ($s0)
	
	li $s2, 0
	
	li $a0, 0
	jal CREATE_PIECE

	li $a0, 1
	jal CREATE_PIECE
	
	MAIN_LOOP:
	
	MAIN_LOOP_PLAYER:
	
	move $a0, $s1
	jal PLAYER_LOOP
	addi $s1, $s1, 1
	bne $s1, $s0,  MAIN_LOOP_PLAYER
	li $s1, 0
	
	addi $s2, $s2, 1
	bne $s2, 1000, MAIN_LOOP
	
	
	EXIT_MAIN_LOOP:
	lw   $s2, 0($sp)
	addi $sp, $sp, 4
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
	addi $sp, $sp, -4 
	sw   $s0, 0($sp)
	addi $sp, $sp, -4 
	sw   $s1, 0($sp)
	addi $sp, $sp, -4 
	sw   $s2, 0($sp)
	
	move $s2, $a0
	
	subi $s0, $s7, OFFSET_USER_CLOCK	# $t0 = offset user clock
	mul $a0, $a0, 4
	sub $s0, $s0, $a0 
	lw $s1, ($s0)						# $t1 = User clock
	
	subi $t2, $s7, OFFSET_SPEED_DOWN	# $t2 = offset speed down
	lw $t3, ($t2)						# $t3 = speed down
	
	bne $s1, $t3, PLAYER_DO_NOTHING
	# down trigger
	move $a0, $s2
	jal CAN_DOWN_CURRENT_PIECE
	beq $v0, 0, CAN_NOT_DOWN_CURRENT_PIECE

	move $a0, $s2
	jal COPY_AUX_PIECE_AND_PRINT

	j DID_DOWN_CURRENT_PIECE
	CAN_NOT_DOWN_CURRENT_PIECE: # If cant down piece, solid current piece and then create new one

	move $a0, $s2
	jal SOLID_PIECE

	move $a0, $s2
	jal CREATE_PIECE
	DID_DOWN_CURRENT_PIECE:
	
	li $s1, 0
	sw $s1, ($s0)						# user clock = 0
	
	PLAYER_DO_NOTHING:
	
	addi $s1, $s1, 1					# User_clock++
	sw $s1, ($s0)

	lw   $s2, 0($sp)
	addi $sp, $sp, 4
	lw   $s1, 0($sp)
	addi $sp, $sp, 4
	lw   $s0, 0($sp)
	addi $sp, $sp, 4
	lw   $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
########################
##   End player Loop  ##
########################

##############################
##      Solid Piece         ##
##############################
# $a0 = player
SOLID_PIECE:
	addi $sp, $sp, -4 
	sw   $s0, 0($sp)	
	addi $sp, $sp, -4 
	sw   $s1, 0($sp)
	addi $sp, $sp, -4 
	sw   $s2, 0($sp)

	subi $t0, $s7, OFFSET_MATRICES
	mul $t1, $a0, 1000
	sub $t0, $t0, $t1 			# $t0 = current matrix
	subi $t0, $t0, 160

	subi $t1, $s7, OFFSET_INFO_PIECE
	mul $t2, $a0, 80
	sub $t1, $t1, $t2 			# $t1 = current piece

	lw $t2, ($t1)				# $t2 = current piece X
	subi $t1, $t1, 4			
	lw $t3, ($t1)				# $t3 = current piece Y

	addi $t4, $t2, 4			# $t4 = Max X

	#({X, Y, Type, Rotation, [4X4]}) * 4 PLAYERS

	subi $t1, $t1, 12

	li $t6, 0					# $t6 = count

	SOLID_PIECE_LOOP:

	lw $t5, ($t1)					# $t5 = load color
	subi $t1, $t1, 4
	
	beq $t5, 0x00, NOT_SOLID_PIECE

	# copy
	
	mul $s0, $t3, 10
	add $s0, $s0, $t2
	mul $s0, $s0, 4

	sub $s0, $t0, $s0
	sw $t5, ($s0)


	NOT_SOLID_PIECE:

	addi $t2, $t2, 1
	bne $t2, $t4, SOLID_PIECE_LOOP_NOT_UPDATE_Y
	subi $t2, $t2, 4
	addi $t3, $t3, 1
	SOLID_PIECE_LOOP_NOT_UPDATE_Y:

	addi $t6, $t6, 1
	bne $t6, 16, SOLID_PIECE_LOOP

	lw   $s2, 0($sp)
	addi $sp, $sp, 4
	lw   $s1, 0($sp)
	addi $sp, $sp, 4
	lw   $s0, 0($sp)
	addi $sp, $sp, 4
	jr $ra
##############################
##   End Solid Piece        ##
##############################


##############################
##  Can down current Piece  ##
##############################
# $a0 = player
# $v0 = (can_down) ? 1 : 0
CAN_DOWN_CURRENT_PIECE:
	addi $sp, $sp, -4 
	sw   $ra, 0($sp)
	addi $sp, $sp, -4 
	sw   $s0, 0($sp)

	move $s0, $a0
	jal COPY_CURRENT_PIECE

	subi $t1, $s7, OFFSET_INFO_AUX_PIECE

	#({X, Y, Type, Rotation, [4X4]})
	subi $t1, $t1, 4 	# $t1 = Y

	lw $t0, ($t1)
	addi $t0, $t0, 1
	sw $t0, ($t1)

	# $a0 = player
	# $v0 = (can_move) ? 1 : 0
	move $a0, $s0
	jal AUX_PIECE_CAN_MOVE

	lw   $s0, 0($sp)
	addi $sp, $sp, 4
	lw   $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
##################################
##  End can down current Piece  ##
##################################

#######################################
##  Copy current piece to aux piece  ##
#######################################
# $a0 = player
COPY_CURRENT_PIECE:
	subi $t0, $s7, OFFSET_INFO_PIECE
	mul $a0, $a0, 80
	sub $t0, $t0, $a0						# $t0 = Current piece

	subi $t1, $s7, OFFSET_INFO_AUX_PIECE 	# $t1 = Aux Piece

	li $t2, 0								# $t2 = Count

	COPY_CURRENT_PIECE_LOOP:
	lw $t3, ($t0)
	sw $t3, ($t1)

	subi $t0, $t0, 4
	subi $t1, $t1, 4
	addi $t2, $t2, 1
	bne $t2, 20, COPY_CURRENT_PIECE_LOOP

	jr $ra
###########################################
##  End copy current piece to aux piece  ##
###########################################

#######################################
##  Copy aux piece to current piece  ##
#######################################
# $a0 = player
COPY_AUX_PIECE_AND_PRINT:
	addi $sp, $sp, -4 
	sw   $ra, 0($sp)
	addi $sp, $sp, -4 
	sw   $s0, 0($sp)

	move $s0, $a0
	li $a1, 1		# print black
	jal PRINT_CURRENT_PIECE

	move $a0, $s0

	subi $t0, $s7, OFFSET_INFO_PIECE
	mul $a0, $a0, 80
	sub $t0, $t0, $a0						# $t0 = Current piece

	subi $t1, $s7, OFFSET_INFO_AUX_PIECE	# $t1 = Aux Piece	

	li $t2, 0								# $t2 = count

	COPY_AUX_PIECE_LOOP:
	lw $t4, ($t1)
	sw $t4, ($t0)

	subi $t0, $t0, 4
	subi $t1, $t1, 4
	addi $t2, $t2, 1
	bne $t2, 20, COPY_AUX_PIECE_LOOP

	move $a0, $s0
	li $a1, 0		# print normal
	jal PRINT_CURRENT_PIECE


	lw   $s0, 0($sp)
	addi $sp, $sp, 4
	lw   $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
###########################################
##  End copy aux piece to current piece  ##
###########################################


##################################
##      Aux piece can move      ##
##################################
# Recieves a piece that mean to be moved, avaliate
# if this piece can visualy appear in this position 
# $a0 = player
# $v0 = (can_move) ? 1 : 0
AUX_PIECE_CAN_MOVE:
	addi $sp, $sp, -4 
	sw   $ra, 0($sp)
	addi $sp, $sp, -4 
	sw   $s0, 0($sp)
	addi $sp, $sp, -4 
	sw   $s1, 0($sp)
	addi $sp, $sp, -4 
	sw   $s2, 0($sp)
	addi $sp, $sp, -4 
	sw   $s3, 0($sp)
	addi $sp, $sp, -4 
	sw   $s4, 0($sp)
	addi $sp, $sp, -4 
	sw   $s5, 0($sp)

	move $s5, $a0
	
	subi $s2, $s7, OFFSET_INFO_AUX_PIECE
	lw $s0, ($s2)				# $s0 = X
	addi $s4, $s0, 4 			# $s4 = Max X

	subi $s2, $s2, 4
	lw $s1, ($s2)				# $s1 = Y
	
	subi $s2, $s2, 12			# $s2 = start matrix
	subi $s3, $s2, 64			# $s3 = end matrix

	# $a0 = player {0, 1, 2, 3}
	# $a1 = X {0 - 20}
	# $a2 = Y {0 -  9}
	# $v0 = (have_piece) ? 1 : 0
	# HAVE_PIECE

	AUX_PIECE_CAN_MOVE_LOOP:

	lw $t0, ($s2)
	beq $t0, 0x00, AUX_PIECE_CAN_MOVE_CONTINUE

	move $a0, $s5
	move $a1, $s0	# X
	move $a2, $s1 	# Y
	jal HAVE_PIECE

	beq $v0, 1, AUX_PIECE_CANT_MOVE

	AUX_PIECE_CAN_MOVE_CONTINUE:

	addi $s0, $s0, 1
	bne $s0, $s4, AUX_PIECE_CAN_MOVE_NOT_UPDATE_X
	addi $s1, $s1, 1	# update Y
	subi $s0, $s0, 4	# restore X
	AUX_PIECE_CAN_MOVE_NOT_UPDATE_X:

	subi $s2, $s2, 4
	bgt $s2, $s3, AUX_PIECE_CAN_MOVE_LOOP

	li $v0, 1
	j AUX_PIECE_CAN_MOVE_EXIT
	AUX_PIECE_CANT_MOVE:
	li $v0, 0
	AUX_PIECE_CAN_MOVE_EXIT:

	lw   $s5, 0($sp)
	addi $sp, $sp, 4
	lw   $s4, 0($sp)
	addi $sp, $sp, 4
	lw   $s3, 0($sp)
	addi $sp, $sp, 4
	lw   $s2, 0($sp)
	addi $sp, $sp, 4
	lw   $s1, 0($sp)
	addi $sp, $sp, 4
	lw   $s0, 0($sp)
	addi $sp, $sp, 4
	lw   $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
######################################
##      End aux piece can move      ##
######################################


##################################
##      Have Piece in place     ##
##################################
# $a0 = player {0, 1, 2, 3}
# $a1 = X {0 - 9}
# $a2 = Y {0 - 20}
# $v0 = (have_piece) ? 1 : 0
HAVE_PIECE:
	move $t0, $a1
	move $a1, $a2
	move $a2, $t0

	mul $a0, $a0, 1000
	
	subi $t0, $s7, OFFSET_MATRICES
	sub $t0, $t0, $a0

	subi $t0, $t0, 160

	mul $a1, $a1, 10
	add $a1, $a1, $a2
	mul $a1, $a1, 4

	sub $t0, $t0, $a1

	lw $t0, ($t0)

	li $v0, 0
	beq $t0, 0x00, HAVE_PIECE_EMPTY
	li $v0, 1
	HAVE_PIECE_EMPTY:

	jr $ra
##################################
##   End Have Piece in place    ##
##################################

##########################
##  Down current Piece  ##
##########################
# $a0 = player
DOWN_CURRENT_PIECE:
	addi $sp, $sp, -4 
	sw   $ra, 0($sp)
	addi $sp, $sp, -4 
	sw   $s0, 0($sp)

	move $s0, $a0

	li $a1, 1
	jal PRINT_CURRENT_PIECE

	subi $t0, $s7, OFFSET_INFO_PIECE
	mul $t1, $s0, 80	# bytes in info matrix
	sub $t0, $t0, $t1
	
	subi $t0, $t0, 4
	lw $t1, ($t0)
	addi $t1, $t1, 1
	sw $t1, ($t0)		#save initial y
	
	move $a0, $s0
	li $a1, 0
	jal PRINT_CURRENT_PIECE

	lw   $s0, 0($sp)
	addi $sp, $sp, 4
	lw   $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
#############################
## End down current Piece  ##
#############################


########################
##    Create Piece    ##
########################
# $a0 = Player to create piece {0, 1, 2, 3}
CREATE_PIECE:
	addi $sp, $sp, -4 
	sw   $ra, 0($sp)
	addi $sp, $sp, -4 
	sw   $s0, 0($sp)
	
	move $s0, $a0	#$save $a0 in $s0
	
	subi $t0, $s7, OFFSET_INFO_PIECE
	mul $t1, $s0, 80	# bytes in info matrix
	sub $t0, $t0, $t1
	
	li $t1, 3
	sw $t1, ($t0)		#save initial x
	
	subi $t0, $t0, 4
	li $t1, -3
	sw $t1, ($t0)		#save initial y
	
	subi $t0, $t0, 4
	move $a1, $t1		 # Send address of Type to bem saved
	
	subi $t0, $t0, 4
	li $t1, 0
	sw $t1, ($t0)		#save rotation
	
	subi $t0, $t0, 4	# now $t0 is on the first position of the matrix
	
	#clear matrix (16 positions)
	move $t1, $t0
	li $t2, 64
	sub $t2, $t1, $t2

	CREATE_PIECE_CLEAR_LOOP:
	li $t3, 0x00
	sw $t3, ($t1)
	subi $t1, $t1, 4
	bne $t1, $t2 CREATE_PIECE_CLEAR_LOOP
	
	# create line test
	move $a0, $t0
	
	jal RANDOM
	#li $v0, 4 
	
	bne $v0, 0, NOT_CREATE_PIECE_0
	jal CREATE_STRAIGHT_POLYMONIO
	NOT_CREATE_PIECE_0:

	bne $v0, 1, NOT_CREATE_PIECE_1
	jal CREATE_SQUARE_POLYMONIO
	NOT_CREATE_PIECE_1:

	bne $v0, 2, NOT_CREATE_PIECE_2
	jal CREATE_T_POLYMONIO
	NOT_CREATE_PIECE_2:

	bne $v0, 3, NOT_CREATE_PIECE_3
	jal CREATE_J_POLYMONIO
	NOT_CREATE_PIECE_3:

	bne $v0, 4, NOT_CREATE_PIECE_4
	jal CREATE_L_POLYMONIO
	NOT_CREATE_PIECE_4:

	bne $v0, 5, NOT_CREATE_PIECE_5
	jal CREATE_S_POLYMONIO
	NOT_CREATE_PIECE_5:

	bne $v0, 6, NOT_CREATE_PIECE_6
	jal CREATE_Z_POLYMONIO
	NOT_CREATE_PIECE_6:
		
	move $a0, $s0
	li $a1, 0
	jal PRINT_CURRENT_PIECE


	lw   $s0, 0($sp)
	addi $sp, $sp, 4
	lw   $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
########################
##   End create Piece ##
########################

#####################################
##    Create Straight Polyomino    ##
#####################################
# $a0 = Start matrix memory position
# $a1 = Type adress
CREATE_STRAIGHT_POLYMONIO:
	move $t0, $a0
	
	li $t1, 0
	sw $t1, ($a1)
	
	li $t3, 0xAA	# piece color
	
	subi $t0, $t0, 4
	sw $t3, ($t0)
	subi $t0, $t0, 16
	sw $t3, ($t0)
	subi $t0, $t0, 16
	sw $t3, ($t0)
	subi $t0, $t0, 16
	sw $t3, ($t0)

	jr $ra
#########################################
##    End create Straight Polyomino    ##
#########################################

#####################################
##    Create Square  Polyomino     ##
#####################################
# $a0 = Start matrix memory position
# $a1 = Type adress
CREATE_SQUARE_POLYMONIO:
	move $t0, $a0
	
	li $t1, 1
	sw $t1, ($a1)
	
	li $t3, 0x70	# piece color
	
	subi $t0, $t0, 36
	sw $t3, ($t0)
	subi $t0, $t0, 4
	sw $t3, ($t0)
	subi $t0, $t0, 12
	sw $t3, ($t0)
	subi $t0, $t0, 4
	sw $t3, ($t0)

	jr $ra
#########################################
##    End create Square Polyomino      ##
#########################################


#####################################
##    Create T Polyomino           ##
#####################################
# $a0 = Start matrix memory position
# $a1 = Type adress
CREATE_T_POLYMONIO:
	move $t0, $a0
	
	li $t1, 2
	sw $t1, ($a1)
	
	li $t3, 0x96	# piece color
	
	subi $t0, $t0, 36
	sw $t3, ($t0)
	subi $t0, $t0, 12
	sw $t3, ($t0)
	subi $t0, $t0, 4
	sw $t3, ($t0)
	subi $t0, $t0, 4
	sw $t3, ($t0)

	jr $ra
#########################################
##    End T Square Polyomino           ##
#########################################

#####################################
##    Create J Polyomino           ##
#####################################
# $a0 = Start matrix memory position
# $a1 = Type adress
CREATE_J_POLYMONIO:
	move $t0, $a0
	
	li $t1, 3
	sw $t1, ($a1)
	
	li $t3, 0xA6	# piece color
	
	subi $t0, $t0, 36
	sw $t3, ($t0)
	subi $t0, $t0, 16
	sw $t3, ($t0)
	subi $t0, $t0, 4
	sw $t3, ($t0)
	subi $t0, $t0, 4
	sw $t3, ($t0)

	jr $ra
#########################################
##    End J Square Polyomino           ##
#########################################

#####################################
##    Create L Polyomino           ##
#####################################
# $a0 = Start matrix memory position
# $a1 = Type adress
CREATE_L_POLYMONIO:
	move $t0, $a0
	
	li $t1, 4
	sw $t1, ($a1)
	
	li $t3, 0xB6	# piece color
	
	subi $t0, $t0, 40
	sw $t3, ($t0)
	subi $t0, $t0, 8
	sw $t3, ($t0)
	subi $t0, $t0, 4
	sw $t3, ($t0)
	subi $t0, $t0, 4
	sw $t3, ($t0)

	jr $ra
#########################################
##    End L Square Polyomino           ##
#########################################

#####################################
##    Create S Polyomino           ##
#####################################
# $a0 = Start matrix memory position
# $a1 = Type adress
CREATE_S_POLYMONIO:
	move $t0, $a0
	
	li $t1, 5
	sw $t1, ($a1)
	
	li $t3, 0xB0	# piece color
	
	subi $t0, $t0, 36
	sw $t3, ($t0)
	subi $t0, $t0, 4
	sw $t3, ($t0)
	subi $t0, $t0, 8
	sw $t3, ($t0)
	subi $t0, $t0, 4
	sw $t3, ($t0)

	jr $ra
#########################################
##    End S Square Polyomino           ##
#########################################

#####################################
##    Create Z Polyomino           ##
#####################################
# $a0 = Start matrix memory position
# $a1 = Type adress
CREATE_Z_POLYMONIO:
	move $t0, $a0
	
	li $t1, 6
	sw $t1, ($a1)
	
	li $t3, 0xCA	# piece color
	
	subi $t0, $t0, 32
	sw $t3, ($t0)
	subi $t0, $t0, 4
	sw $t3, ($t0)
	subi $t0, $t0, 16
	sw $t3, ($t0)
	subi $t0, $t0, 4
	sw $t3, ($t0)

	jr $ra
#########################################
##    End Z Square Polyomino           ##
#########################################

################################
##    Print Current Piece     ##
################################
# $a0 = Player {0, 1, 2, 3}
# $a1 = if ($a1 == 1) print black
PRINT_CURRENT_PIECE:
	addi $sp, $sp, -4 
	sw   $ra, 0($sp)
	addi $sp, $sp, -4 
	sw   $s0, 0($sp)
	addi $sp, $sp, -4 
	sw   $s1, 0($sp)
	addi $sp, $sp, -4 
	sw   $s2, 0($sp)	# $s2 = X
	addi $sp, $sp, -4 
	sw   $s3, 0($sp)	# $s3 = Y
	addi $sp, $sp, -4 
	sw   $s4, 0($sp)	# $s4 = player
	addi $sp, $sp, -4 
	sw   $s5, 0($sp)	# $s5 = end X
	addi $sp, $sp, -4 
	sw   $s6, 0($sp)

	move $s4, $a0
	move $s6, $a1

	subi $t0, $s7, OFFSET_INFO_PIECE
	mul $t1, $a0, 80	# bytes in info matrix
	sub $s0, $t0, $t1	# $s0 = fist position in info
	
	#({X, Y, Typer, Rotation, [4X4]})
	lw $s2, ($s0)		# load X
	subi $s0, $s0, 4
	lw $s3, ($s0)		# load Y
	
	addi $s5, $s2, 4	# calculate end X
	
	subi $s0, $s0, 12	# now $s0 is in te first position of the matrix
	subi $s1, $s0, 64	# $s1 saves the position to end the loop
	
	PRINT_CURRENT_PIECE_LOOP:
	lw $t0, ($s0)
	
	beq $t0, 0x00, DO_NOT_PRINT_CURRENT_PIECE
	# Print square

	bne $s6, 1, PRINT_DEFAULT_COLOR
	# print black
	li $t0, 0x00
	PRINT_DEFAULT_COLOR:
	
	blt $s3, 0, DO_NOT_PRINT_CURRENT_PIECE		# Y < 0

	move $a0, $s2
	move $a1, $s3
	move $a2, $t0
	move $a3, $s4
	jal PRINT_SQUARE
	
	DO_NOT_PRINT_CURRENT_PIECE:
	
	addi $s2, $s2, 1
	bne $s2, $s5, DO_NOT_INCREASE_Y
	subi $s2, $s2, 4
	addi $s3, $s3, 1
	DO_NOT_INCREASE_Y:
	
	subi $s0, $s0, 4
	bne $s0, $s1, PRINT_CURRENT_PIECE_LOOP
	
	lw   $s6, 0($sp)
	addi $sp, $sp, 4
	lw   $s5, 0($sp)
	addi $sp, $sp, 4
	lw   $s4, 0($sp)
	addi $sp, $sp, 4
	lw   $s3, 0($sp)
	addi $sp, $sp, 4
	lw   $s2, 0($sp)
	addi $sp, $sp, 4
	lw   $s1, 0($sp)
	addi $sp, $sp, 4
	lw   $s0, 0($sp)
	addi $sp, $sp, 4
	lw   $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
################################
##   End Print Current Piece  ##
################################

############################
##   Increase Difficulty  ##
############################
INCREASE_DIFFICULTY:
	subi $t0, $s7, OFFSET_SPEED_DOWN
	lw $t1, ($t0)
	subi $t1, $t1, 10000
	sw $t1, ($t0)
	jr $ra
###############################
##  End increase Difficulty  ##
###############################

############################
##   Init users clocks    ##
############################
INIT_USERS_CLOCKS: 
	subi $t0, $s7, OFFSET_USER_CLOCK
	
	li $t1, 0
	sw $t1, ($t0)
	
	subi $t0, $t0, 4
	sw $t1, ($t0)
	
	subi $t0, $t0, 4
	sw $t1, ($t0)
	
	subi $t0, $t0, 4
	sw $t1, ($t0)
	
	jr $ra
##############################
##   End init users clocks  ##
##############################

########################################		 +
###Random-Number Generator (RNGesus)####		
########################################		
	
#utilizando LCG (a = 5, c = 1, m = 16, x0 = SEED)		
RANDOM: 

	la $t0, SEED
	lw $t1, 0($t0) 		#carrega em t1 o valor do seed		
	subi $t1, $s7, OFFSET_USER_CLOCK
	lw $t1, ($t1)

	li $t2, 5		
	mult $t1, $t2		#a*Xn		
	mflo $t1		
	addi $t1, $t1, 1	# a*Xn + c		
	li $t2, 16		
	div $t1, $t2		#mod m		
	mfhi $t1		#t1 = (a*Xn+c)%m = Xn+1		
	sw $t1, 0($t0)		#devolve para poder calcular mais adiante o prox		
			
	li $t2, 7		
	div $t1, $t2		#coloca o resultado do LCG para mod 7		
	mfhi $t1		
	move $v0, $t1		#coloca o valor em v0 para retorno		
	jr $ra		
#############		
## End RNG ##		
#############

