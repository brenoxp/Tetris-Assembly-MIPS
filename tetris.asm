#    UnB - Universidade de Brasília
#    ------------------------------
#    Departamento de Ciência da Computação - 2016/2
#    Organização e Arquitetura de Computadores - Turma "A"
#    Prof.  Marcos Vinicius Lamar
#    Grupo 3: Breno Xavier Pinto - 13/0103845
#	      Jefferson Viana Fonseca Abreu - 13/0028959
#	      Miguel Angelo Montagner Filho -  13/0127302
#             Paulo Victor Gonçalves Farias - 13/0144754
# --------------------------------------------------------------------------------------------------------
#    Projeto Aplicativo: MIPS Tetris Multiplayer
#    -------------------------------------------
#    Objetivo: Implementação do clássico jogo Tetris para até 4 jogadores. Usando o kit de desenvolvimento
#	       DE2-70 e a interface infravermelho.
#
#    Conteúdo do arquivo: Grupo3_OAC20162_projeto.zip
#      > tetris.asm
#      > tetris_code.mif
#      > tetris_data.mif
#      > relatorioImplementacao.pdf
#      > MIPS-PUM-v4.5 (processador uniciclo)
#
# --------------------------------------------------------------------------------------------------------
#    tetris.asm
#    -------------------------------
#    Padrão: O programa, escrito em Assembly MIPS 32, está em conformidade com o uso de registradores du-
#	     rante a implementação.
#
#    Saída: Jogo Tetris implementado para um número de jogadores específico.
#
#    Limitações: As peças não rotacionam.
#
#    Como compilar e executar: ( na MAIN se $s0 = 0, TECLADO, simulação no MARS, $s0 = 1, simulação na placa)
#      No MARS:
#	      - Assemble file
#	      - Tools > Bitmap Display Tool
#	      - Run
#      Na DE2-70:
#	      - Com o Quartus aberto e a placa funcionando com o processador uniciclo.
#	      - Tools > In-System-Memory Content Editor
#	      - Atualize UseC e UseD para os arquivos tetris_code e tetris_data
#	      - Inicie a simulação na placa
#    Versão do Mars: 4.5
#
#    Foram feitos testes no sistema Linux Mint(64 bits), sendo que a versão entregue compilou na IDE e
#    também funcionou na placa.


#########################################################################################################
##                                        CONSTANTS                                                    ##
#########################################################################################################

.eqv VGA 0xFF000000		# VGA beginning address
.eqv TAMX 320 			# Display width in pixels
.eqv TAMY 240 			# Display height in pixels
.eqv PLAYERS_1_MENU_PY 100		# String position on menu for P1
.eqv PLAYERS_2_MENU_PY 130		# String position on menu for P2
.eqv PLAYERS_3_MENU_PY 160		# String position on menu for P3
.eqv PLAYERS_4_MENU_PY 190		# String position on menu for P4

#########################################################################################################
##                                       MEMORY OFFSETS                                                ##
#########################################################################################################

.eqv OFFSET_NUMBER_OF_PLAYERS 	0   		# 000 - 004
.eqv OFFSET_BOARD_POSITIONS   	68 		# 068 - 084
.eqv OFFSET_MATRICES	      	84		# 084 - 5084
.eqv OFFSET_SCORES	      	5084		# 5084 - 5100
.eqv OFFSET_SPEED_DOWN	      	5100		# 5100 - 5104
.eqv OFFSET_USER_CLOCK	      	5104		# 5104 - 5120
.eqv OFFSET_TYPE_CURRENT_PIECE 	5120		# 5120 - 5136
.eqv OFFSET_INFO_PIECE 		5236		# 5136 - 5456 ({X, Y, Type, Rotation, [4X4]}) * 4 PLAYERS
.eqv OFFSET_INFO_AUX_PIECE 	5556		# 5456 - 5536 ({X, Y, Type, Rotation, [4X4]})
.eqv OFFSET_REGISTERED_KEYS   	5636	        # 5536 - 5600
.eqv OFFSET_PLAYER_ALIVE         5700		# 5700 - 5716
.eqv OFFSET_OF_NEW_SP         	5716

#########################################################################################################
##                                       PIECE TYPE                                                    ##
#########################################################################################################
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


#########################################################################################################
##                                          IRDA                                                       ##
#########################################################################################################

.eqv IRDA_READ_ADDRESS 0xFFFF0504

#########################################################################################################
##                                          DATA                                                       ##
#########################################################################################################

.data
	NUM:   .float  160.0

	SEED: .word 0x00001015 	# Used in random function

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
	SCORE_P1:      .asciiz "SCORE P1:"
	SCORE_P2:      .asciiz "SCORE P2:"
	SCORE_P3:      .asciiz "SCORE P3:"
	SCORE_P4:      .asciiz "SCORE P4:"


#########################################################################################################
##                                          TETRIS                                                     ##
#########################################################################################################

.text
# <--------------------------------------  MAIN: BEGIN -------------------------------------------------->
MAIN:
	# Save initial $sp value into $s7, this value will remain unchanged through the game
	move $s7, $sp

	# Update $sp to its new offset
	subi $sp, $sp, OFFSET_OF_NEW_SP

	# Save number of users (Default 1)
	subi $t0, $s7, OFFSET_NUMBER_OF_PLAYERS
	li $t1, 1
	sw $t1, ($t0)
	
	# Configura os controles escolhidos se for IrDA
	li $s1, 0
	li $s2, 1 # indica que esta acontecendo antes da escolha dos jogadores
	#jal CONTROL_CONFIG
	
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
	
	# Configura os controles escolhidos se for IrDA
	li $s1, 0
	li $s2, 0 # indica que esta acontecendo depois da escolha dos jogadores
	#jal CONTROL_CONFIG

	jal INIT_MAIN_LOOP

	#jal PRINT_END_SCORE

	li $v0 10
	syscall
# <--------------------------------------  MAIN: END   -------------------------------------------------->

# xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

#########################################################################################################
##                                          MENU SCREEN                                                ##
#########################################################################################################

# <-------------------------------------- PRINT MENU BEGIN  --------------------------------------------->
PRINT_MENU:
	# Saves $ra value
	addi $sp, $sp, -4
	sw   $ra, 0($sp)

	# Clear screen
	li $v0, 48
	li $a0, 0x0000
	syscall

	# Printing strings of init screen
	li $v0, 104
	la $a0, TETRIS_STRING
	li $a1, 135
	li $a2, 30
	li $a3, 0x00FF
	syscall
	la $a0, PLAYERS_1
	li $a1, 120
	li $a2, PLAYERS_1_MENU_PY
	syscall
	la $a0, PLAYERS_2
	li $a1, 120
	li $a2, PLAYERS_2_MENU_PY
	syscall
	la $a0, PLAYERS_3
	li $a1, 120
	li $a2, PLAYERS_3_MENU_PY
	syscall
	la $a0, PLAYERS_4
	li $a1, 120
	li $a2, PLAYERS_4_MENU_PY
	syscall

	li $a3, 0x00FF
	# Prints '->' = option selected
	jal PRINT_MENU_OPTION

	# Loads $ra and returns
	lw   $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

# <-------------------------------------- PRINT MENU END   -------------------------------------------------->

# xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# <-------------------------------------- PRINT MENU OPTION BEGIN ------------------------------------------->
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

# <-------------------------------------- PRINT MENU OPTION END ------------------------------------------->

# xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# <-------------------------------------- PRINT MENU OPTION INPUT BEGIN------------------------------------>
### $s0 = 0 => KEYBOARD, $s1 = 1 => IRDA
READ_MENU_OPTION_INPUT:
	# Saves $ra
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	# checks to see if using keyboard
	beq $s1, $zero, USE_KEYBOARD

	# not using keyboard -> using irda
	# loads irda address
	la $s6, IRDA_READ_ADDRESS
	# Pointer to keys allocation in memory
	subi $s5, $s7, OFFSET_REGISTERED_KEYS

USE_IRDA:
	# Keeps IrDA on loop until it reads something from the receiver address
	# receives output at $v1
	jal IRDA_GET_KEY_IMM

	# Ve se eh um up down ou escolha
	DECODE_KEY:
	# se for um down
	lw $t7,($s5)
	bne $t7, $v1, NOT_DOWN_IR
	move $v1, $zero
	jal PRESS_MENU_DOWN

	NOT_DOWN_IR:
	# se for um up
	lw $t7,-4($s5)
	bne $t7, $v1, NOT_UP_IR
	move $v1, $zero
	jal PRESS_MENU_UP

	NOT_UP_IR:
	# se for um enter
	lw $t7,-8($s5)
	beq $t7, $v1, ENTER_IR
	move $v1, $zero
	#nao eh enter, volta
	j USE_IRDA

	ENTER_IR:
  	lw   $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

	# Keeps IrDA on loop until it reads something from the receiver addres
	# $s6 = Irda_read_address
	IRDA_GET_KEY_IMM:
	lw $v1, 0($s6) # $s6 = IRDA_READ_ADDRESS
	beq $v1, $zero, IRDA_GET_KEY_IMM
	jr $ra

# <-------------------------------------- PRINT MENU OPTION INPUT END ------------------------------------>

# xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# <--------------------------------------    USE KEYBOARD BEGIN ------------------------------------------->
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

# <--------------------------------------    USE KEYBOARD END ------------------------------------------->

# xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# <--------------------------------------    PRESS MENU DOWN BEGIN--------------------------------------->
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

# <--------------------------------------    PRESS MENU DOWN END --------------------------------------->

# xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# <--------------------------------------    PRESS MENU UP BEGIN --------------------------------------->
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
# <--------------------------------------    PRESS MENU UP END   --------------------------------------->

# xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# <--------------------------------------    PRESS MENU NOTHING  --------------------------------------->

PRESS_MENU_NOTHING:
  	li $v0, 11
  	syscall            # Write Character
  	j READ_MENU_OPTION_INPUT
  	nop

# <--------------------------------------    PRESS MENU NOTHING END ------------------------------------>
#########################################################################################################
##                                       END MENU SCREEN                                               ##
#########################################################################################################

#########################################################################################################
##                                       CONTROL CONFIG                                                ##
#########################################################################################################
# Configures the IrDA keys based on the number of players
CONTROL_CONFIG: 
	beq $s2, 1, OUT_CONTROL

	# savers $ra
	addi $sp, $sp, -4
	sw   $ra, 0($sp)

	# Load number of users
	subi $t0, $s7, OFFSET_NUMBER_OF_PLAYERS
	lw $t1, ($t0)
	move $s0, $t1

	# IrDA Read Address
	la $s6, IRDA_READ_ADDRESS

	# Pointer to keys allocation in memory
	subi $s5, $s7, OFFSET_REGISTERED_KEYS

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
	subi $s5, $s5, -4

	# GET KEY 1
	li $v0, 104
	la $a0, CONFIG_T1
	li $a1, 120
	li $a2, PLAYERS_2_MENU_PY
	li $a3, 0x00FF
	syscall
	jal GET_KEY
	subi $s5, $s5, -4

	# GET KEY 2
	li $v0, 104
	la $a0, CONFIG_T2
	li $a1, 120
	li $a2, PLAYERS_3_MENU_PY
	li $a3, 0x00FF
	syscall
	jal GET_KEY
	subi $s5, $s5, -4

	# GET KEY 3
	li $v0, 104
	la $a0, CONFIG_T3
	li $a1, 120
	li $a2, PLAYERS_4_MENU_PY
	li $a3, 0x00FF
	syscall
	jal GET_KEY
	subi $s5, $s5, -4
	
	beq $s0, $t3, END_CONFIG_KEYS
	addi $t3, $t3, 1
	j LOOP_CONTROL

	# Get key = 0 - Teclado
	# Get key = 1 - IrDA
	GET_KEY:
 
	move $t7, $zero
	beq $s1, $t7, TECLADO_GET_KEY
	addi $t7, $t7, 1
	beq $s1, $t7, IRDA_GET_KEY
	
	# Read character and saves ASCII code
	TECLADO_GET_KEY:
	li $v0, 12
	syscall

	# saves value
	sw $v0, ($s5) 
OUT_CONTROL: 
	jr $ra

# Keeps IrDA on loop until it reads something from the receiver addres
# $s6 = Irda_read_address
# $s5 = Address to save key
IRDA_GET_KEY:
	# Keeps searching until IrDA different than zero
	lw $v1, 0($s6) # $s6 = IRDA_READ_ADDRESS
	beq $v1, $zero, IRDA_GET_KEY

	# IrDA different than zero, save value and return
	sw $v1, 0($s5)
	move $v1, $zero
	jr $ra

END_CONFIG_KEYS:
	# Limpa a tela 
	li $v0, 48
	li $a0, 0x0000
	syscall
	lw   $ra, 0($sp) 

	addi $sp, $sp, 4
	jr $ra
#########################################################################################################
##                                     END CONTROL CONFIG                                              ##
#########################################################################################################


#########################################################################################################
##                                       PRINT PIXEL                                                   ##
#########################################################################################################
# $a0 = X
# $a1 = Y
# $a2 = Color
PLOT_PIXEL:
	li $v0, 45
	syscall
	jr $ra

#########################################################################################################
##                                       END PIXEL                                                     ##
#########################################################################################################


#########################################################################################################
##                                       PRINT STATIC BOARDS                                           ##
#########################################################################################################
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

#########################################################################################################
##                                      END STATIC BOARD                                               ##
#########################################################################################################

#########################################################################################################
##                                       PRINT ONE BOARD                                               ##
#########################################################################################################
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

#########################################################################################################
##                                  END  PRINT ONE BOARD                                               ##
#########################################################################################################

#########################################################################################################
##                                       PRINT SQUARE                                                  ##
#########################################################################################################
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
#########################################################################################################
##                                     PRINT SQUARE END                                                ##
#########################################################################################################


#########################################################################################################
##                                       INIT MATRICES                                                 ##
#########################################################################################################
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
#########################################################################################################
##                                       END INIT MATRICES                                             ##
#########################################################################################################


#########################################################################################################
##                                       PRINT BOARDS 		                                       ##
#########################################################################################################
PRINT_BOARDS:
	addi $sp, $sp, -4
	sw   $ra, 0($sp)
	addi $sp, $sp, -4
	sw   $s0, 0($sp)
	addi $sp, $sp, -4
	sw   $s1, 0($sp)

	subi $s0, $s7, OFFSET_NUMBER_OF_PLAYERS
	lw $s0, ($s0)
	li $s1, 0

	LOOP_PRINT_BOARDS:
	
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

#########################################################################################################
##                                    END PRINT BOARDS 		                                       ##
#########################################################################################################


#########################################################################################################
##                                       PRINT BOARD 		                                       ##
#########################################################################################################
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

#########################################################################################################
##                                      END PRINT BOARD 		                               ##
#########################################################################################################


#########################################################################################################
##                                       INIT SCORE		                                       ##
#########################################################################################################
INIT_SCORE:
	addi $sp, $sp, -4
	sw   $ra, 0($sp)

	li $t0, 0
	subi $t1, $s7, OFFSET_SCORES
	sw $t0, ($t1)
	subi $t1, $t1, -4
	sw $t0, ($t1)
	subi $t1, $t1, -4
	sw $t0, ($t1)
	subi $t1, $t1, -4
	sw $t0, ($t1)
	
	subi $t7, $s7, OFFSET_NUMBER_OF_PLAYERS
	lw $t7, ($t7)
	
	li $a0, 1
	li $a1, 0
	jal UPDATE_SCORE
	beq $t7, 1, END_INIT
	
	li $a0, 2
	li $a1, 0
	jal UPDATE_SCORE
	beq $t7, 2, END_INIT
	
	li $a0, 3
	li $a1, 0
	jal UPDATE_SCORE
	beq $t7, 3, END_INIT
	
	li $a0, 4
	li $a1, 0
	jal UPDATE_SCORE
	
END_INIT:

	lw   $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
#########################################################################################################
##                                      END INIT SCORE		                                       ##
#########################################################################################################


#########################################################################################################
##                                      UPDATE SCORE		                                       ##
#########################################################################################################
# $a0 = Player {0, 1, 2, 3}
# $a1 = Score to be added
UPDATE_SCORE:
	addi $sp, $sp, -4
	sw   $ra, 0($sp)
  
	move $t5, $a1
	move $t6, $a0
	subi $t0, $s7, OFFSET_BOARD_POSITIONS
	subi $t7, $s7, OFFSET_NUMBER_OF_PLAYERS
	lw $t7, ($t7)
	
	beq $t7, 1, UPDATE_1
	beq $t7, 2, UPDATE_2
	beq $t7, 3, UPDATE_3
	beq $t7, 4, UPDATE_4
# 1 PLAYER, atualiza player 1
UPDATE_1:

	lw $a1, ($t0)		# $a1 = X Position to print
	addi $a1, $a1, 8

	subi $t0, $s7, OFFSET_SCORES

	lw $a0, ($t0)
	add $a0, $a0, $t5
	sw $a0, ($t0)
	jal PRINT_UPDATE
	j END_UPDATE

# 2 players jogando, tem que saber qual deve atualizar
UPDATE_2:

	beq $t6, 1, UPDATE_1

	lw $a1, -4($t0)
	addi $a1, $a1, 8
	
	subi $t0, $s7, OFFSET_SCORES
	lw $a0, -4($t0)
	add $a0, $a0, $t5
	sw $a0, ($t0)
	jal PRINT_UPDATE
	j END_UPDATE
	
UPDATE_3:
	beq $t6, 1, UPDATE_1
	beq $t6, 2, UPDATE_2 
	
	lw $a1, -8($t0)
	addi $a1, $a1, 8
	
	subi $t0, $s7, OFFSET_SCORES
	lw $a0, -8($t0)
	add $a0, $a0, $t5
	sw $a0, ($t0) 
	jal PRINT_UPDATE
	j END_UPDATE
	
UPDATE_4:

	beq $t6, 1, UPDATE_1
	beq $t6, 2, UPDATE_2
	beq $t6, 3, UPDATE_3
	
	lw $a1,-12($t0)
	addi $a1, $a1, 8
	
	subi $t0, $s7, OFFSET_SCORES
	lw $a0, -12($t0)
	add $a0, $a0, $t5
	sw $a0, ($t0) 
	jal PRINT_UPDATE
	j END_UPDATE

PRINT_UPDATE:

	li $v0, 101
	li $a2, 200
	li $a3, 0xBB
	syscall
	jr $ra
	
END_UPDATE: 

	lw   $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
#########################################################################################################
##                                     END UPDATE SCORE                                                ##
#########################################################################################################

#########################################################################################################
##                                     INIT PLAYERS ALIVE                                              ##
#########################################################################################################
INIT_PLAYES_ALIVE:

	subi $t0, $s7, OFFSET_PLAYER_ALIVE

	li $t1, 1
	
	sw $t1, ($t0)
	subi $t0, $t0, 4
	sw $t1, ($t0)
	subi $t0, $t0, 4
	sw $t1, ($t0)
	subi $t0, $t0, 4
	sw $t1, ($t0)

	jr $ra
#########################################################################################################
##                                   END INIT PLAYERS ALIVE                                            ##
#########################################################################################################

#########################################################################################################
##                                       MAIN LOOP		                                       ##
#########################################################################################################
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

	jal INIT_PLAYES_ALIVE

	jal INIT_PLAYERS_PIECES

	subi $t0, $s7, OFFSET_SPEED_DOWN
	li $t1, 1000
	sw $t1, ($t0)		# save initial difficulty

	li $s1, 0		# Count amount of users = 0

	subi $s0, $s7, OFFSET_NUMBER_OF_PLAYERS
	lw $s0, ($s0)

	li $s2, 0

	li $a0, 0
	jal CREATE_PIECE

	#li $a0, 0
	#jal CAN_ROTATE_CURRENT_PIECE

	MAIN_LOOP:

	MAIN_LOOP_PLAYER:

	move $a0, $s1
	jal PLAYER_LOOP
	addi $s1, $s1, 1
	bne $s1, $s0,  MAIN_LOOP_PLAYER
	li $s1, 0

	addi $s2, $s2, 1
	bne $s2, 100000000, MAIN_LOOP


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
#########################################################################################################
##                                      END MAIN LOOP    	                                       ##
#########################################################################################################

#########################################################################################################
##                                     INIT PLAYERS PIECES    	                                       ##
#########################################################################################################
INIT_PLAYERS_PIECES:
	addi $sp, $sp, -4
	sw   $ra, 0($sp)
	addi $sp, $sp, -4
	sw   $s0, 0($sp)	
	addi $sp, $sp, -4
	sw   $s1, 0($sp)	

	subi $s0, $s7, OFFSET_NUMBER_OF_PLAYERS
	lw $s0, ($s0)

	li $s1, 0

	INIT_PLAYERS_PIECES_LOOP:
	move $a0, $s1
	jal CREATE_PIECE
	addi $s1, $s1, 1
	bne $s1, $s0, INIT_PLAYERS_PIECES_LOOP

	lw   $s1, 0($sp)
	addi $sp, $sp, 4
	lw   $s0, 0($sp)
	addi $sp, $sp, 4
	lw   $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
#########################################################################################################
##                                   END INIT PLAYERS PIECES                                          ##
#########################################################################################################

#########################################################################################################
##                                     PLAYER LOOP      	                                       ##
#########################################################################################################
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

	subi $t0, $s7, OFFSET_PLAYER_ALIVE
	mul $t1, $a0, 4
	sub $t0, $t0, $t1

	lw $t0, ($t0)
	beq $t0, 0, PLAYER_LOOP_EXIT


	subi $s0, $s7, OFFSET_USER_CLOCK	# $t0 = offset user clock
	mul $a0, $a0, 4
	sub $s0, $s0, $a0
	lw $s1, ($s0)						# $t1 = User clock

	subi $t2, $s7, OFFSET_SPEED_DOWN	# $t2 = offset speed down
	lw $t3, ($t2)						# $t3 = speed down


	# keyboard data address 0xff100004
	# right -> 110
	# left -> 97
	# up -> 119


	la $t7, 0xFF100004
	nop
	nop
	nop
	nop
	lw $t6, ($t7)

	bne $t6, 100, PLAYER_DID_NOT_PRESS_RIGHT
  	move $a0, $s2
	jal CAN_RIGHT_CURRENT_PIECE
	beq $v0, 0, PLAYER_DID_NOT_PRESS_RIGHT
	move $a0, $s2
	jal COPY_AUX_PIECE_AND_PRINT
  	PLAYER_DID_NOT_PRESS_RIGHT:

  	bne $t6, 97, PLAYER_DID_NOT_PRESS_LEFT
  	move $a0, $s2
	jal CAN_LEFT_CURRENT_PIECE
	beq $v0, 0, PLAYER_DID_NOT_PRESS_LEFT
	move $a0, $s2
	jal COPY_AUX_PIECE_AND_PRINT
  	PLAYER_DID_NOT_PRESS_LEFT:

  	bne $t6, 119, PLAYER_DID_NOT_PRESS_UP
  	move $a0, $s2
	jal CAN_ROTATE_CURRENT_PIECE
	beq $v0, 0, PLAYER_DID_NOT_PRESS_UP
	move $a0, $s2
	jal COPY_AUX_PIECE_AND_PRINT
  	PLAYER_DID_NOT_PRESS_UP:

  	li $t6, 0
  	sw $t6, ($t7)

	bgt $s1, $t3, PLAYER_DO_NOTHING
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

	REPEAT_COMPLETE_LINE:
	move $a0, $s2
	jal UPDATE_IF_COMPLETED_LINE
	bne $v0, -1, REPEAT_COMPLETE_LINE

	move $a0, $s2
	jal CREATE_PIECE
	DID_DOWN_CURRENT_PIECE:

	li $s1, 0
	sw $s1, ($s0)						# user clock = 0

	PLAYER_DO_NOTHING:

	addi $s1, $s1, 1					# User_clock++
	sw $s1, ($s0)

	PLAYER_LOOP_EXIT:

	lw   $s2, 0($sp)
	addi $sp, $sp, 4
	lw   $s1, 0($sp)
	addi $sp, $sp, 4
	lw   $s0, 0($sp)
	addi $sp, $sp, 4
	lw   $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
#########################################################################################################
##                                   END  PLAYER LOOP      	                                       ##
#########################################################################################################


#########################################################################################################
##                                     COMPLETED LINE      	                                       ##
#########################################################################################################
# $a0 = player
# $v0 = (line_completed) ? line : -1
UPDATE_IF_COMPLETED_LINE:
	addi $sp, $sp, -4 
	sw   $ra, 0($sp)
	addi $sp, $sp, -4 
	sw   $s0, 0($sp)

	mul $t0, $a0, 1000
	addi $t0, $t0, 160

	subi $t1, $s7, OFFSET_MATRICES
	sub $t1, $t1, $t0 

	li $t2, 0 			# current x
	li $t3, 0			# current y

	li $t4, 1 			# flag

	UPDATE_COMPLETED_LINE_LOOP:
	lw $t5, ($t1)
	subi $t1, $t1, 4

	bne $t5, 0x00, CONTINUE_FLAG
	li $t4, 0
	CONTINUE_FLAG:

	addi $t2, $t2, 1
	bne $t2, 10, UPDATE_COMPLETED_LINE_LOOP

	beq $t4, 1 FIND_LINE
	li $t4, 1
	li $t2, 0
	addi $t3, $t3, 1
	bne $t3, 20, UPDATE_COMPLETED_LINE_LOOP

	li $s0, -1
	j UPDATE_IF_COMPLETED_LINE_EXIT
	
	FIND_LINE:
	move $s0, $t3
	move $a1, $s0
	jal DOWN_LINES

	UPDATE_IF_COMPLETED_LINE_EXIT:
	move $v0, $s0

	lw   $s0, 0($sp)
	addi $sp, $sp, 4
	lw   $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
#########################################################################################################
##                                     END COMPLETED LINE      	                           		  ##
#########################################################################################################

#########################################################################################################
##                                     DOWN DOWN_LINES 	     	                           		  ##
#########################################################################################################
# $a0 = player
# $a1 = line
DOWN_LINES: 
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
	
	move $s0, $a0

	subi $s0, $s7, OFFSET_MATRICES
	mul $s1, $a0, 1000
	sub $s0, $s0, $s1 			# $s0 = init matrix

	subi $s0, $s0, 160
	
	li $s3, 9 					# $s3 = count x
	move $s4, $a1				# $t4 = count y

	mul $s2, $s4, 40
	addi $s2, $s2, 36
	sub $s0, $s0, $s2 			# $s0 = end of y line

	# $a0 = X position
	# $a1 = Y position
	# $a2 = color
	# $a3 = Player {0, 1, 2, 3}
	# PRINT_SQUARE

	DOWN_LINES_LOOP:
	addi $s2, $s0, 40
	lw $s2, ($s2)
	sw $s2, ($s0)	 			# puts color in $s0

	move $a0, $s3
	move $a1, $s4
	move $a2, $s2
	move $a3, $s0
	jal PRINT_SQUARE

	addi $s0, $s0, 4

	subi $s3, $s3, 1
	bge $s3, 0, DOWN_LINES_NOT_UPDATE_Y
	subi $s4, $s4, 1
	li $s3, 9

	DOWN_LINES_NOT_UPDATE_Y:
	bgt $s4, 0, DOWN_LINES_LOOP


	move $a0, $s0
	li $a1, 1
	jal UPDATE_SCORE

	
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
#########################################################################################################
##                                     END DOWN DOWN_LINES 	     	                           		  ##
#########################################################################################################


#########################################################################################################
##                                     SOLID PIECE       	                                       ##
#########################################################################################################
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

	bge $t3, 0, AUX_PIECE_NOT_KILL_PLAYER  # Y >= 0
	subi $t6, $s7, OFFSET_PLAYER_ALIVE
	mul $t7, $a0, 4
	sub $t6, $t6, $t7

	li $t7, 0
	sw $t7, ($t6)

	li $a0, 9
	li $v0, 1
	syscall


	j SOLID_PIECE_EXIT
	AUX_PIECE_NOT_KILL_PLAYER:


	NOT_SOLID_PIECE:

	addi $t2, $t2, 1
	bne $t2, $t4, SOLID_PIECE_LOOP_NOT_UPDATE_Y
	subi $t2, $t2, 4
	addi $t3, $t3, 1


	SOLID_PIECE_LOOP_NOT_UPDATE_Y:

	addi $t6, $t6, 1
	bne $t6, 16, SOLID_PIECE_LOOP

	SOLID_PIECE_EXIT:

	lw   $s2, 0($sp)
	addi $sp, $sp, 4
	lw   $s1, 0($sp)
	addi $sp, $sp, 4
	lw   $s0, 0($sp)
	addi $sp, $sp, 4
	jr $ra
#########################################################################################################
##                                    END SOLID PIECE       	                                       ##
#########################################################################################################

#################################
##  Can rotate current Piece   ##
#################################
# $a0 = player
# $v0 = (can_rotate) ? 1 : 0
CAN_ROTATE_CURRENT_PIECE:
	addi $sp, $sp, -4
	sw   $ra, 0($sp)
	addi $sp, $sp, -4
	sw   $s0, 0($sp)

	move $s0, $a0
	jal COPY_CURRENT_PIECE


	subi $t1, $s7, OFFSET_INFO_AUX_PIECE

	subi $a0, $t1, 16		# matrix0
	jal CLEAR_MATRIX_16

	#({X, Y, Type, Rotation, [4X4]})

	subi $t1, $s7, OFFSET_INFO_AUX_PIECE
	subi $a0, $t1, 8 	# $t1 = Type
	lw $a0, ($a0)

	bne $a0, 0, ROTATE_NOT_STRAIGHT
	jal ROTATE_STRAIGHT
	ROTATE_NOT_STRAIGHT:

	bne $a0, 1, ROTATE_NOT_SQUARE
	#jal ROTATE_SQUARE
	ROTATE_NOT_SQUARE:

	bne $a0, 2, ROTATE_NOT_T
	jal ROTATE_T
	ROTATE_NOT_T:

	bne $a0, 3, ROTATE_NOT_J
	jal ROTATE_J
	ROTATE_NOT_J:

	bne $a0, 4, ROTATE_NOT_L
	jal ROTATE_L
	ROTATE_NOT_L:

	bne $a0, 5, ROTATE_NOT_S
	#jal ROTATE_S
	ROTATE_NOT_S:

	bne $a0, 6, ROTATE_NOT_Z
	#jal ROTATE_Z
	ROTATE_NOT_Z:

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
## End can rotate current Piece ##
##################################


#########################################################################################################
##                                CLEAR MATRIX 16 	 		                                           ##
#########################################################################################################
# $a0 = init matrix
CLEAR_MATRIX_16:
	#clear matrix (16 positions)
	move $t1, $a0
	subi $t2, $t1, 64

	CLEAR_MATRIX_16_LOOP:
	li $t3, 0x00
	sw $t3, ($t1)
	subi $t1, $t1, 4
	bne $t1, $t2 CLEAR_MATRIX_16_LOOP

	jr $ra
#########################################################################################################
##                               END CLEAR MATRIX 16 	 		                                       ##
#########################################################################################################

#########################################################################################################
##                                 ROTATE STRAIGHT 		                                              ##
#########################################################################################################
ROTATE_STRAIGHT:
	addi $sp, $sp, -4
	sw   $ra, 0($sp)
	addi $sp, $sp, -4
	sw   $s0, 0($sp)

	subi $t1, $s7, OFFSET_INFO_AUX_PIECE
	subi $a0, $t1, 16		# matrix
 	subi $a1, $t1, 8	 	#type address

	subi $t0, $t1, 12
	lw $t2, ($t0)

	beq $t2, 0, ROTATE_STRAIGHT_R1
	li $t2, 0
	sw $t2, ($t0)
	jal CREATE_STRAIGHT_POLYMONIO_0
 	j ROTATE_STRAIGHT_EXIT
	ROTATE_STRAIGHT_R1:
	li $t2, 1
	sw $t2, ($t0)
	jal CREATE_STRAIGHT_POLYMONIO_1
 	j ROTATE_STRAIGHT_EXIT

	ROTATE_STRAIGHT_EXIT:


	lw   $s0, 0($sp)
	addi $sp, $sp, 4
	lw   $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
#########################################################################################################
##                                END ROTATE STRAIGHT 		                                           ##
#########################################################################################################



#########################################################################################################
##                                 ROTATE T 		                                              ##
#########################################################################################################
ROTATE_T:
# $a0 = Start matrix memory position
# $a1 = Type adress
# 0 -> 3

	addi $sp, $sp, -4
	sw   $ra, 0($sp)
	addi $sp, $sp, -4
	sw   $s0, 0($sp)

	subi $t1, $s7, OFFSET_INFO_AUX_PIECE
	subi $a0, $t1, 16		# matrix
 	subi $a1, $t1, 8	 	#type address

	subi $t0, $t1, 12
	lw $t2, ($t0)

	ROTATE_T_R4:
	bne $t2, 0, ROTATE_T_R1
	li $t2, 1
	sw $t2, ($t0)
	jal CREATE_T_POLYMONIO_0
 	j ROTATE_T_EXIT
 	
 	ROTATE_T_R1:
 	bne $t2, 1, ROTATE_T_R2
	li $t2, 2
	sw $t2, ($t0)
	jal CREATE_T_POLYMONIO_1
 	j ROTATE_T_EXIT


 	ROTATE_T_R2:
 	bne $t2, 2, ROTATE_T_R3
	li $t2, 3
	sw $t2, ($t0)
	jal CREATE_T_POLYMONIO_2
 	j ROTATE_T_EXIT

 	ROTATE_T_R3:
 	bne $t2, 3, ROTATE_T_R4
	li $t2, 0
	sw $t2, ($t0)
	jal CREATE_T_POLYMONIO_3
 	j ROTATE_T_EXIT

	ROTATE_T_EXIT:


	lw   $s0, 0($sp)
	addi $sp, $sp, 4
	lw   $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
#########################################################################################################
##                                END ROTATE T 		                                           ##
#########################################################################################################


#########################################################################################################
##                                 ROTATE L 		                                              ##
#########################################################################################################
ROTATE_L:
# $a0 = Start matrix memory position
# $a1 = Type adress
# 0 -> 3

	addi $sp, $sp, -4
	sw   $ra, 0($sp)
	addi $sp, $sp, -4
	sw   $s0, 0($sp)

	subi $t1, $s7, OFFSET_INFO_AUX_PIECE
	subi $a0, $t1, 16		# matrix
 	subi $a1, $t1, 8	 	#type address

	subi $t0, $t1, 12
	lw $t2, ($t0)

	ROTATE_L_R4:
	bne $t2, 0, ROTATE_L_R1
	li $t2, 1
	sw $t2, ($t0)
	jal CREATE_L_POLYMONIO_0
 	j ROTATE_T_EXIT
 	
 	ROTATE_L_R1:
 	bne $t2, 1, ROTATE_L_R2
	li $t2, 2
	sw $t2, ($t0)
	jal CREATE_L_POLYMONIO_1
 	j ROTATE_L_EXIT


 	ROTATE_L_R2:
 	bne $t2, 2, ROTATE_L_R3
	li $t2, 3
	sw $t2, ($t0)
	jal CREATE_L_POLYMONIO_2
 	j ROTATE_L_EXIT

 	ROTATE_L_R3:
 	bne $t2, 3, ROTATE_L_R4
	li $t2, 0
	sw $t2, ($t0)
	jal CREATE_L_POLYMONIO_3
 	j ROTATE_L_EXIT

	ROTATE_L_EXIT:


	lw   $s0, 0($sp)
	addi $sp, $sp, 4
	lw   $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
#########################################################################################################
##                                END ROTATE T 		                                           ##
#########################################################################################################



#########################################################################################################
##                                 ROTATE J		                                              ##
#########################################################################################################
ROTATE_J:
# $a0 = Start matrix memory position
# $a1 = Type adress
# 0 -> 3

	addi $sp, $sp, -4
	sw   $ra, 0($sp)
	addi $sp, $sp, -4
	sw   $s0, 0($sp)

	subi $t1, $s7, OFFSET_INFO_AUX_PIECE
	subi $a0, $t1, 16		# matrix
 	subi $a1, $t1, 8	 	#type address

	subi $t0, $t1, 12
	lw $t2, ($t0)

	ROTATE_J_R4:
	bne $t2, 0, ROTATE_J_R1
	li $t2, 1
	sw $t2, ($t0)
	jal CREATE_J_POLYMONIO_3
 	j ROTATE_T_EXIT
 	
 	ROTATE_J_R1:
 	bne $t2, 1, ROTATE_J_R2
	li $t2, 2
	sw $t2, ($t0)
	jal CREATE_J_POLYMONIO_2
 	j ROTATE_J_EXIT


 	ROTATE_J_R2:
 	bne $t2, 2, ROTATE_J_R3
	li $t2, 3
	sw $t2, ($t0)
	jal CREATE_J_POLYMONIO_1
 	j ROTATE_J_EXIT

 	ROTATE_J_R3:
 	bne $t2, 3, ROTATE_J_R4
	li $t2, 0
	sw $t2, ($t0)
	jal CREATE_J_POLYMONIO_0
 	j ROTATE_J_EXIT

	ROTATE_J_EXIT:


	lw   $s0, 0($sp)
	addi $sp, $sp, 4
	lw   $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
#########################################################################################################
##                                END ROTATE T 		                                           ##
#########################################################################################################


	jr $ra
##############
## Rotate J ##
##############

#########################################################################################################
##                                 CAN DOWN CURRENT PIECE                                              ##
#########################################################################################################
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
#########################################################################################################
##                                END CAN DOWN CURRENT PIECE                                           ##
#########################################################################################################

#########################################################################################################
##                                 CAN RIGHT CURRENT PIECE                                             ##
#########################################################################################################
# $a0 = player
# $v0 = (can_down) ? 1 : 0
CAN_RIGHT_CURRENT_PIECE:
	addi $sp, $sp, -4
	sw   $ra, 0($sp)
	addi $sp, $sp, -4
	sw   $s0, 0($sp)

	move $s0, $a0
	jal COPY_CURRENT_PIECE

	subi $t1, $s7, OFFSET_INFO_AUX_PIECE

	#({X, Y, Type, Rotation, [4X4]})

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
#########################################################################################################
##                                 END CAN RIGHT CURRENT PIECE                                         ##
#########################################################################################################

#########################################################################################################
##                                 CAN LEFT CURRENT PIECE                                              ##
#########################################################################################################
# $a0 = player
# $v0 = (can_down) ? 1 : 0
CAN_LEFT_CURRENT_PIECE:
	addi $sp, $sp, -4
	sw   $ra, 0($sp)
	addi $sp, $sp, -4
	sw   $s0, 0($sp)

	move $s0, $a0
	jal COPY_CURRENT_PIECE

	subi $t1, $s7, OFFSET_INFO_AUX_PIECE

	#({X, Y, Type, Rotation, [4X4]})

	lw $t0, ($t1)
	subi $t0, $t0, 1
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
#########################################################################################################
##                                  END CAN LEFT CURRENT PIECE                                         ##
#########################################################################################################

#########################################################################################################
##                                    COPY CURRENT PIECE 		                               ##
#########################################################################################################
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
#########################################################################################################
##                                  END COPY CURRENT PIECE 		                               ##
#########################################################################################################

#########################################################################################################
##                                    COPY AUX PIECE PRINT 		                               ##
#########################################################################################################
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
#########################################################################################################
##                                    END COPY AUX PIECE PRINT 		                               ##
#########################################################################################################


#########################################################################################################
##                                    AUX PIECE CAN MOVE  		                               ##
#########################################################################################################
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

	bgt $s0, 9, AUX_PIECE_CANT_MOVE	# X > 10 then cant move
	blt $s0, 0, AUX_PIECE_CANT_MOVE	# X <  0 then cant move

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
#########################################################################################################
##                                     END AUX PIECE CAN MOVE 	                                       ##
#########################################################################################################


#########################################################################################################
##                                         HAVE PIECE     	                                       ##
#########################################################################################################
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
#########################################################################################################
##                                    END HAVE PIECE        		                               ##
#########################################################################################################

#########################################################################################################
##                                     DOWN CURRENT PIECE		                               ##
#########################################################################################################
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
#########################################################################################################
##                                    END DOWN CURRENT PIECE		                               ##
#########################################################################################################

#########################################################################################################
##                                     CREATE PIECE      		                               ##
#########################################################################################################
# $a0 = Player to create piece {0, 1, 2, 3}
CREATE_PIECE:
	addi $sp, $sp, -4
	sw   $ra, 0($sp)
	addi $sp, $sp, -4
	sw   $s0, 0($sp)

	#{X, Y, Type, Rotation, [4X4]}

	move $s0, $a0	#$save $a0 in $s0

	subi $t0, $s7, OFFSET_INFO_PIECE
	subi $a1, $t0, 8

	mul $t1, $s0, 80	# bytes in info matrix
	sub $t0, $t0, $t1

	li $t1, 3
	sw $t1, ($t0)		#save initial x

	subi $t0, $t0, 4
	li $t1, -3
	#li $t1, 5
	sw $t1, ($t0)		#save initial y

	subi $t0, $t0, 4

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

	#jal RANDO
	li $v0, 0

	bne $v0, 0, NOT_CREATE_PIECE_0
	jal CREATE_STRAIGHT_POLYMONIO_0
	NOT_CREATE_PIECE_0:

	bne $v0, 1, NOT_CREATE_PIECE_1
	jal CREATE_SQUARE_POLYMONIO_0
	NOT_CREATE_PIECE_1:

	bne $v0, 2, NOT_CREATE_PIECE_2
	jal CREATE_T_POLYMONIO_0
	NOT_CREATE_PIECE_2:

	bne $v0, 3, NOT_CREATE_PIECE_3
	jal CREATE_J_POLYMONIO_0
	NOT_CREATE_PIECE_3:

	bne $v0, 4, NOT_CREATE_PIECE_4
	jal CREATE_L_POLYMONIO_0
	NOT_CREATE_PIECE_4:

	bne $v0, 5, NOT_CREATE_PIECE_5
	jal CREATE_S_POLYMONIO_0
	NOT_CREATE_PIECE_5:

	bne $v0, 6, NOT_CREATE_PIECE_6
	jal CREATE_Z_POLYMONIO_0
	NOT_CREATE_PIECE_6:

	move $a0, $s0
	jal PRINT_CURRENT_PIECE


	lw   $s0, 0($sp)
	addi $sp, $sp, 4
	lw   $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
#########################################################################################################
##                                    END CREATE PIECE      		                               ##
#########################################################################################################

#########################################################################################################
##                                     CREATE STRAIGHT POLYOMINO	                               ##
#########################################################################################################
# $a0 = Start matrix memory position
# $a1 = Type adress
CREATE_STRAIGHT_POLYMONIO_0:
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


#####################################
##    Create Straight Polyomino    ##
#####################################
# $a0 = Start matrix memory position
# $a1 = Type adress
CREATE_STRAIGHT_POLYMONIO_1:
	move $t0, $a0

	li $t1, 0
	sw $t1, ($a1)

	li $t3, 0xAA	# piece color

	subi $t0, $t0, 32
	sw $t3, ($t0)
	subi $t0, $t0, 4
	sw $t3, ($t0)
	subi $t0, $t0, 4
	sw $t3, ($t0)
	subi $t0, $t0, 4
	sw $t3, ($t0)

	jr $ra

#########################################################################################################
##                                    END CREATE STRAIGHT POLYOMINO	                                   ##
#########################################################################################################

#########################################################################################################
##                                     CREATE SQUARE POLYOMINO	                                       ##
#########################################################################################################
# $a0 = Start matrix memory position
# $a1 = Type adress
CREATE_SQUARE_POLYMONIO_0:
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
#########################################################################################################
##                                   END  CREATE SQUARE POLYOMINO	                               ##
#########################################################################################################

#####################################
##    Clear info matrix            ##
#####################################
# $a0 = begin matrix


	jr $ra
#####################################
##   End clear info matrix         ##
#####################################

#########################################################################################################
##                                     CREATE T POLYOMINO	                                       ##
#########################################################################################################
# $a0 = Start matrix memory position
# $a1 = Type adress
CREATE_T_POLYMONIO_0:
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
#########################################################################################################
##                                     END CREATE T POLYOMINO	                                         ##
#########################################################################################################

#########################################################################################################
##                                     CREATE T POLYOMINO	1                                            ##
#########################################################################################################
# $a0 = Start matrix memory position
# $a1 = Type adress
CREATE_T_POLYMONIO_1:
	move $t0, $a0

	li $t1, 2
	sw $t1, ($a1)

	li $t3, 0x96	# piece color

	subi $t0, $t0, 20
	sw $t3, ($t0)
	subi $t0, $t0, 16
	sw $t3, ($t0)
	subi $t0, $t0, 4
	sw $t3, ($t0)
	subi $t0, $t0, 12
	sw $t3, ($t0)

	jr $ra
#########################################################################################################
##                                     END CREATE T POLYOMINO	1                                       ##
#########################################################################################################

#########################################################################################################
##                                     CREATE T POLYOMINO	2                                            ##
#########################################################################################################
# $a0 = Start matrix memory position
# $a1 = Type adress
CREATE_T_POLYMONIO_2:
	move $t0, $a0

	li $t1, 2
	sw $t1, ($a1)

	li $t3, 0x96	# piece color

	subi $t0, $t0, 32
	sw $t3, ($t0)
	subi $t0, $t0, 4
	sw $t3, ($t0)
	subi $t0, $t0, 4
	sw $t3, ($t0)
	subi $t0, $t0, 12
	sw $t3, ($t0)

	jr $ra
#########################################################################################################
##                                     END CREATE T POLYOMINO	2                                       ##
#########################################################################################################

#########################################################################################################
##                                     CREATE T POLYOMINO	3                                            ##
#########################################################################################################
# $a0 = Start matrix memory position
# $a1 = Type adress
CREATE_T_POLYMONIO_3:
	move $t0, $a0

	li $t1, 2
	sw $t1, ($a1)

	li $t3, 0x96	# piece color

	subi $t0, $t0, 20
	sw $t3, ($t0)
	subi $t0, $t0, 12
	sw $t3, ($t0)
	subi $t0, $t0, 4
	sw $t3, ($t0)
	subi $t0, $t0, 16
	sw $t3, ($t0)

	jr $ra
#########################################################################################################
##                                     END CREATE T POLYOMINO	3                                       ##
#########################################################################################################


#########################################################################################################
##                                     CREATE J POLYOMINO	                                       ##
#########################################################################################################
# $a0 = Start matrix memory position
# $a1 = Type adress
CREATE_J_POLYMONIO_0:
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
#########################################################################################################
##                                     CREATE J POLYOMINO	                                       ##
#########################################################################################################

#########################################################################################################
##                                     CREATE J POLYOMINO	 1                                     ##
#########################################################################################################
# $a0 = Start matrix memory position
# $a1 = Type adress
CREATE_J_POLYMONIO_1:
	move $t0, $a0

	li $t1, 3
	sw $t1, ($a1)

	li $t3, 0xA6	# piece color

	subi $t0, $t0, 24
	sw $t3, ($t0)
	subi $t0, $t0, 16
	sw $t3, ($t0)
	subi $t0, $t0, 12
	sw $t3, ($t0)
	subi $t0, $t0, 4
	sw $t3, ($t0)

	jr $ra
#########################################################################################################
##                                     CREATE J POLYOMINO	 1                                      ##
#########################################################################################################

#########################################################################################################
##                                     CREATE J POLYOMINO	 2                                     ##
#########################################################################################################
# $a0 = Start matrix memory position
# $a1 = Type adress
CREATE_J_POLYMONIO_2:
	move $t0, $a0

	li $t1, 3
	sw $t1, ($a1)

	li $t3, 0xA6	# piece color

	subi $t0, $t0, 32
	sw $t3, ($t0)
	subi $t0, $t0, 4
	sw $t3, ($t0)
	subi $t0, $t0, 4
	sw $t3, ($t0)
	subi $t0, $t0, 16
	sw $t3, ($t0)

	jr $ra
#########################################################################################################
##                                     CREATE J POLYOMINO	 2                                      ##
#########################################################################################################
#########################################################################################################
##                                     CREATE J POLYOMINO	 3                                     ##
#########################################################################################################
# $a0 = Start matrix memory position
# $a1 = Type adress
CREATE_J_POLYMONIO_3:
	move $t0, $a0

	li $t1, 3
	sw $t1, ($a1)

	li $t3, 0xA6	# piece color

	subi $t0, $t0, 16
	sw $t3, ($t0)
	subi $t0, $t0, 4
	sw $t3, ($t0)
	subi $t0, $t0, 12
	sw $t3, ($t0)
	subi $t0, $t0, 16
	sw $t3, ($t0)

	jr $ra
#########################################################################################################
##                                     CREATE J POLYOMINO	 3                                      ##
#########################################################################################################


#########################################################################################################
##                                     CREATE L POLYOMINO	                                       ##
#########################################################################################################
# $a0 = Start matrix memory position
# $a1 = Type adress
CREATE_L_POLYMONIO_0:
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
#########################################################################################################
##                                     END CREATE L POLYOMINO	                                       ##
#########################################################################################################

#########################################################################################################
##                                     CREATE L POLYOMINO	  1                                     ##
#########################################################################################################
# $a0 = Start matrix memory position
# $a1 = Type adress
CREATE_L_POLYMONIO_1:
	move $t0, $a0

	li $t1, 4
	sw $t1, ($a1)

	li $t3, 0xB6	# piece color

	subi $t0, $t0, 20
	sw $t3, ($t0)
	subi $t0, $t0, 16
	sw $t3, ($t0)
	subi $t0, $t0, 16
	sw $t3, ($t0)
	subi $t0, $t0, 4
	sw $t3, ($t0)

	jr $ra
#########################################################################################################
##                                     END CREATE L POLYOMINO	    1                                   ##
#########################################################################################################

#########################################################################################################
##                                     CREATE L POLYOMINO	  2                                    ##
#########################################################################################################
# $a0 = Start matrix memory position
# $a1 = Type adress
CREATE_L_POLYMONIO_2:
	move $t0, $a0

	li $t1, 4
	sw $t1, ($a1)

	li $t3, 0xB6	# piece color

	subi $t0, $t0, 36
	sw $t3, ($t0)
	subi $t0, $t0, 4
	sw $t3, ($t0)
	subi $t0, $t0, 4
	sw $t3, ($t0)
	subi $t0, $t0, 8
	sw $t3, ($t0)

	jr $ra
#########################################################################################################
##                                     END CREATE L POLYOMINO	   2                                    ##
#########################################################################################################

#########################################################################################################
##                                     CREATE L POLYOMINO	  3                                    ##
#########################################################################################################
# $a0 = Start matrix memory position
# $a1 = Type adress
CREATE_L_POLYMONIO_3:
	move $t0, $a0

	li $t1, 4
	sw $t1, ($a1)

	li $t3, 0xB6	# piece color

	subi $t0, $t0, 24
	sw $t3, ($t0)
	subi $t0, $t0, 4
	sw $t3, ($t0)
	subi $t0, $t0, 16
	sw $t3, ($t0)
	subi $t0, $t0, 16
	sw $t3, ($t0)

	jr $ra
#########################################################################################################
##                                     END CREATE L POLYOMINO	   3                                    ##
#########################################################################################################

#########################################################################################################
##                                     CREATE S POLYOMINO	                                       ##
#########################################################################################################
# $a0 = Start matrix memory position
# $a1 = Type adress
CREATE_S_POLYMONIO_0:
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
#########################################################################################################
##                                   END CREATE S POLYOMINO	                                       ##
#########################################################################################################

#########################################################################################################
##                                     CREATE S POLYOMINO	           1                            ##
#########################################################################################################
# $a0 = Start matrix memory position
# $a1 = Type adress
CREATE_S_POLYMONIO_1:
	move $t0, $a0

	li $t1, 5
	sw $t1, ($a1)

	li $t3, 0xB0	# piece color

	subi $t0, $t0, 24
	sw $t3, ($t0)
	subi $t0, $t0, 12
	sw $t3, ($t0)
	subi $t0, $t0, 4
	sw $t3, ($t0)
	subi $t0, $t0, 12
	sw $t3, ($t0)

	jr $ra
#########################################################################################################
##                                   END CREATE S POLYOMINO	   1                                    ##
#########################################################################################################

########################################################################################################
##                                     CREATE S POLYOMINO	           2                            ##
#########################################################################################################
# $a0 = Start matrix memory position
# $a1 = Type adress
CREATE_S_POLYMONIO_2:
	move $t0, $a0

	li $t1, 5
	sw $t1, ($a1)

	li $t3, 0xB0	# piece color

	subi $t0, $t0, 32
	sw $t3, ($t0)
	subi $t0, $t0, 4
	sw $t3, ($t0)
	subi $t0, $t0, 16
	sw $t3, ($t0)
	subi $t0, $t0, 4
	sw $t3, ($t0)

	jr $ra
#########################################################################################################
##                                   END CREATE S POLYOMINO	   2                                    ##
#########################################################################################################

#########################################################################################################
##                                     CREATE Z POLYOMINO	                                       ##
#########################################################################################################
# $a0 = Start matrix memory position
# $a1 = Type adress
CREATE_Z_POLYMONIO_0:
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
#########################################################################################################
##                                     END CREATE Z POLYOMINO	                                       ##
#########################################################################################################

#########################################################################################################
##                                     CREATE Z POLYOMINO	   1                                    ##
#########################################################################################################
# $a0 = Start matrix memory position
# $a1 = Type adress
CREATE_Z_POLYMONIO_1:
	move $t0, $a0

	li $t1, 6
	sw $t1, ($a1)

	li $t3, 0xCA	# piece color

	subi $t0, $t0, 24
	sw $t3, ($t0)
	subi $t0, $t0, 12
	sw $t3, ($t0)
	subi $t0, $t0, 4
	sw $t3, ($t0)
	subi $t0, $t0, 12
	sw $t3, ($t0)

	jr $ra
#########################################################################################################
##                                     END CREATE Z POLYOMINO	     1                                  ##
#########################################################################################################

#########################################################################################################
##                                     CREATE Z POLYOMINO	      2                                 ##
#########################################################################################################
# $a0 = Start matrix memory position
# $a1 = Type adress
CREATE_Z_POLYMONIO_2:
	move $t0, $a0

	li $t1, 6
	sw $t1, ($a1)

	li $t3, 0xCA	# piece color

	subi $t0, $t0, 36
	sw $t3, ($t0)
	subi $t0, $t0, 4
	sw $t3, ($t0)
	subi $t0, $t0, 8
	sw $t3, ($t0)
	subi $t0, $t0, 4
	sw $t3, ($t0)

	jr $ra
#########################################################################################################
##                                     END CREATE Z POLYOMINO	     2                                  ##
#########################################################################################################

#########################################################################################################
##                                     PRINT CURRENT PIECE	                                       ##
#########################################################################################################
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
#########################################################################################################
##                                 END  PRINT CURRENT PIECE	                                       ##
#########################################################################################################

#########################################################################################################
##                                   INCREASE DIFFICULTY	                                       ##
#########################################################################################################
INCREASE_DIFFICULTY:
	subi $t0, $s7, OFFSET_SPEED_DOWN
	lw $t1, ($t0)
	subi $t1, $t1, 10000
	sw $t1, ($t0)
	jr $ra
#########################################################################################################
##                                  END INCREASE DIFFICULTY	                                       ##
#########################################################################################################

#########################################################################################################
##                                   INIT USER CLOCK     	                                       ##
#########################################################################################################
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
#########################################################################################################
##                                   END INIT USER CLOCK     	                                       ##
#########################################################################################################

#########################################################################################################
##                                  RANDOM NUMBER GENERATOR                                            ##
#########################################################################################################

#utilizando LCG (a = 5, c = 1, m = 16, x0 = SEED)
RANDOM:

	la $t0, SEED
	lw $t1, 0($t0) 		#carrega em t1 o valor do seed

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
#########################################################################################################
##                                END  RANDOM NUMBER GENERATOR                                         ##
#########################################################################################################

#########################################################################################################
##                                    PRINT END SCORE                                                  ##
#########################################################################################################
PRINT_END_SCORE:
	li $v0, 48
	li $a0, 0x00
	syscall

	subi $t1, $s7, OFFSET_NUMBER_OF_PLAYERS
	lw $t0, ($t1)
	move $s0, $t0
	subi $s1, $s7, OFFSET_SCORES

	addi $t0, $zero, 1

	# Printa P1
	li $v0, 104
	la $a0, SCORE_P1
	li $a1, 10
	li $a2, 60
	li $a3, 0x00FF
	syscall
	lw $t3, 0($s1)
	li $v0, 101
	move $a0, $t3
	li $a1, 90
	li $a2, 60
	li $a3, 0x00BB
	syscall
	beq $s0, $t0, END_SCORE
	addi $t0, $t0, 1

	# Printa P2
	li $v0, 104
	la $a0, SCORE_P2
	li $a1, 10
	li $a2, 90
	li $a3, 0x00FF
	syscall
	lw $t3, -4($s1)
	li $v0, 101
	move $a0, $t3
	li $a1, 90
	li $a2, 90
	li $a3, 0x00BB
	syscall
	beq $s0, $t0, END_SCORE
	addi $t0, $t0, 1

	# PRINTA P3
	li $v0, 104
	la $a0, SCORE_P3
	li $a1, 10
	li $a2, 120
	li $a3, 0x00FF
	syscall
	lw $t3, -8($s1)
	li $v0, 101
	move $a0, $t3
	li $a1, 90
	li $a2, 120
	li $a3, 0x00BB
	syscall
	beq $s0, $t0, END_SCORE

	# PRINTA P4
	li $v0, 104
	la $a0, SCORE_P4
	li $a1, 10
	li $a2, 150
	li $a3, 0x00FF
	syscall
	lw $t3, -12($s1)
	li $v0, 101
	move $a0, $t3
	li $a1, 90
	li $a2, 150
	li $a3, 0x00BB
	syscall

END_SCORE:
	jr $ra
#########################################################################################################
##                                    END PRINT END SCORE                                              ##
#########################################################################################################
