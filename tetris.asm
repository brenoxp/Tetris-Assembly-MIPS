.eqv VGA 0xFF000000
.eqv TAMX 320
.eqv TAMY 240
.eqv A_MENU_1 100
.eqv A_MENU_2 130
.eqv A_MENU_3 160
.eqv A_MENU_4 190


.data

	SUP_A:  .float  160.0
	SUP_B:  .float 80.0
	SUP_C:	.float 16.0
	SUP_D: .float 53.333333
	SUP_E: .float 40.0
	CONST1: .float 0.0912372213
	UM:      .float  1.0
	UMCINCO: .float  1.5
	VINTE: .float 20.0
	
	
	TETRIS_STRING:   .asciiz "TETRIS\n"
	PLAYERS_1:   .asciiz "1 Jogador\n"
	PLAYERS_2:   .asciiz "2 Jogadores\n"
	PLAYERS_3:   .asciiz "3 Jogadores\n"
	PLAYERS_4:   .asciiz "4 Jogadores\n"
	SELECT_OPTION:   .asciiz "->\n"
	
.text
# ------  INÍCIO DA MAIN ------
MAIN:
	
	# Inicializa a tela
	la $t0, VGA
	li $t1, TAMX
	li $t5, 0x00  # cor 0x00000000
	
	jal MENU

	li $v0 10
	syscall


MENU:
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
	li $a2, A_MENU_1	
	li $a3, 0x00FF	
	syscall
	
	li $v0, 104	
	la $a0, PLAYERS_2
	li $a1, 120	
	li $a2, A_MENU_2	
	li $a3, 0x00FF	
	syscall
	
	li $v0, 104	
	la $a0, PLAYERS_3
	li $a1, 120
	li $a2, A_MENU_3	
	li $a3, 0x00FF	
	syscall
	
	li $v0, 104	
	la $a0, PLAYERS_4
	li $a1, 120
	li $a2, A_MENU_4	
	li $a3, 0x00FF	
	syscall
	
	
	li $t2, 90
	jal PRINT_MENU_OPTION
	
	lw   $ra, 0($sp)
	addi $sp, $sp, 4 
	
	jr $ra


PRINT_MENU_OPTION:  #t2 : posicao y do seletor

	li $v0, 104	
	la $a0, SELECT_OPTION
	move $a1, $t2
	li $a2, A_MENU_1	
	li $a3, 0x00FF
	syscall


READ_MENU_OPTION_INPUT:
	li   $v0, 12       
  	syscall            # Read Character
  	addiu $a0, $v0, 0  # $a0 gets the next char
  	
  	li $t1, 83
  	beq $t1, $a0 PRESS_MENU_S
  	
  	
  	j PRESS_MENU_NOTHING
  	
PRESS_MENU_S:
	li $t2 120
	jal PRINT_MENU_OPTION
	
PRESS_MENU_NOTHING:

  	
  	
  	
  	li   $v0, 11       
  	syscall            # Write Character
  	b READ_MENU_OPTION_INPUT
  	nop
