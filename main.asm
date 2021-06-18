#Author: Marcus Vinícius Medeiros Pará
#NUSP: 11031663
#
#This is a program to parse a string as an integer.
#Despite it was only tested in bases 2, 10 and 16, it must work for any base
#in the interval [2,16].
#The input must be as follows:
#
#input_string
#input_base
#output_base
#
#
	.data
	
	.align 0
input: .space 34
output: .space 34
auxiliar: .space 34

invalid_input_msg: .asciiz "Input string and base don't match"
invalid_base_msg:  .asciiz "Invalid base: base must be in interval [2,16]"

	.align 2
input_size: .word 0
int_to_hex: .byte 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 97, 98, 99, 100, 101, 102
		
	.align 2
	.text
	.globl main
	
main:
	#read input
	la $a0, input
	jal read_str
	
	#read input base
	addiu $v0, $zero, 5
	syscall
	addu $s1, $v0, $zero
	
	addu $a0, $zero, $s1
	jal check_base
	
	#read output base
	addiu $v0, $zero, 5
	syscall
	addu $s0, $v0, $zero
	
	addu $a0, $zero, $s0
	jal check_base
	
	la $a0, input
	jal get_str_size
	addu $a1, $v0, $zero
	addu $a2, $s1, $zero
	jal check_input
	
	#convert input to integer
	jal str_to_int
	
	#convert integer to a string in a given base
	addu $a0, $v0, $zero
	la $a1, output
	addu $a2, $zero, $s0
	jal int_to_str
	
	addu $a0, $a1, $zero
	jal print_str
	
	j end
	
read_str:
	addi $a1, $zero, 34
	addi $v0, $zero, 8
	syscall
	
	jr $ra
	
get_str_size:
	addi $v0, $zero, 0
	add $t0, $zero, $a0
get_str_size_loop:
	lb $t2, 0($t0)
	beq $t2, 10, get_str_size_end
	beq $t2, 0, get_str_size_end
	addi $v0, $v0, 1
	addi $t0, $t0, 1
	j get_str_size_loop
get_str_size_end:
	jr $ra
	
print_str:
	addi $v0, $zero, 4
	syscall
	jr $ra

print_int:
	addi $v0, $zero, 36
	syscall
	jr $ra

print_newline:
	addi $a0, $zero, 10
	addi $v0, $zero, 11
	syscall
	jr $ra

power:
	add $t0, $a1, $zero
	addi $v0, $zero, 1
power_loop:
	beq $t0, $zero, power_end
	mul $v0, $v0, $a0
	addi $t0, $t0, -1
	j power_loop
power_end:
	jr $ra
	
check_input:
#a0: input string
#a1: size of input
#a2: base
#
#if input is not valid, exit program
	addu $t0, $a0, $zero
	addi $t1, $a1, -1
	addu $t2, $a2, $zero
	
check_input_loop:
	blt $t1, $zero, check_input_end
	lb $t3, 0($t0)
	
	#check if character is less than '0' in ASCII
	addi $t4, $zero, 48
	blt $t3, $t4, invalid_input_end
	
	#check if base is greater than 9
	addi $t4, $zero, 9
	slt $t5, $t4, $t2 
	
	#check if character is greater than '9' in ASCII
	addi $t4, $zero, 57
	slt $t6, $t4, $t3 
	
	#if base is greater than 9 and character greater than '9', a different verification is done
	and $t5, $t5, $t6
	bne $t5, $zero, check_hex 
	
	#check if character is greater than the base
	subiu $t3, $t3, 48
	ble $t2, $t3, invalid_input_end 
	
	j check_input_loop_end
	
check_hex:
	#check if character is greater than the base
	la $t7, int_to_hex
	addu $t7, $t7, $t2
	addi $t7, $t7, -1
	lb $t7, 0($t7)
	blt $t7, $t3, invalid_input_end
	
	#check if character is less than 'a' in ASCII
	addiu $t7, $zero, 97
	blt $t3, $t7, invalid_input_end

check_input_loop_end:
	addi $t1, $t1, -1
	addi $t0, $t0, 1
	
	j check_input_loop
	
check_input_end:
	jr $ra

check_base:
#Check if $a0 is a valid base value
#
#a0: input integer
	addiu $t0, $zero, 2
	addiu $t1, $zero, 16
	blt $a0, $t0, invalid_base_end
	blt $t1, $a0, invalid_base_end
	jr $ra

str_to_int:
# Parses ASCII string at address in a0 as an integer returned at v0.
# This is done by multiplying each character by power(base, postion_of_digit) and adding the results, returned at v0
# To do this operation, we first convert the ASCII character to an integer in interval [0,base[ 
#
#$a0: input string
#a1: size of input string
#a2: base
#
#returns: integer at $v0
	addu $t0, $a0, $zero
	addi $t1, $a1, -1
	addi $t3, $zero, 0
	addi $sp, $sp, -4
	sw $ra, 0($sp) #storing $ra because it will be lost when other function is called
str_to_int_loop:
	blt $t1, $zero, str_to_int_end 
	
	#converts character to integer
	lb $t2, 0($t0)
	addi $t2, $t2, -48
	blt $t2, 10, str_to_int_case_not_hex #if character is greater than '9' in ASCII
	addi $t2, $t2, -39

str_to_int_case_not_hex: #actually this is always executed, but when the character is greater than '9', we skip the previous instruction
	#storing registers before calling power function
	addi $sp, $sp, -20
	sw $a0, 16($sp)
	sw $t0, 12($sp)
	sw $t1, 8($sp)
	sw $t2, 4($sp)
	sw $t3, 0($sp)
	
	#setting arguments of power (base and exponent)
	addu $a0, $a2, $zero
	addu $a1, $t1, $zero
	jal power
	
	#retrieving registers
	lw $t3, 0($sp)
	lw $t2, 4($sp)
	lw $t1, 8($sp)
	lw $t0, 12($sp)
	lw $a0, 16($sp)
	addi $sp, $sp, 20
	
	#adding partial result to $t3 (later returned at $v0)	
	mulu $t2, $t2, $v0
	addu $t3, $t3, $t2
	addi $t1, $t1, -1
	addi $t0, $t0, 1
	j str_to_int_loop
str_to_int_end:
	#retrieving $ra
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	#setting return value
	addu $v0, $t3, $zero
	jr $ra
	
int_to_str:
#Converts an at $a0 to a string at address contained in $a1, using base at $a2.
#This is done through an iterative method.
#We divide the input by the base and write down the remainder until the quotient is zero.
#At first, the string is reversed, so in the the end we reverse it.
#
#a0: input integer
#a1: output string
#a2: base
	addu $t0, $a0, $zero
	la $t1, auxiliar
	addu $t2, $zero, $a2
int_to_str_loop:
	#divide input by base
	divu $t0, $t2
	mfhi $t4 #remainder
	mflo $t5 #quotient
	
	#check table for ascii value
	la $t6, int_to_hex
	addu $t6, $t6, $t4
	lb $t4, 0($t6)
	
	#store ascii value at auxiliar
	sb $t4, 0($t1)
	addiu $t1, $t1, 1
	
	#check exit condition
	beq $t5, $zero, int_to_str_end
	
	#update divider value
	addu $t0, $t5, $zero
	
	j int_to_str_loop
int_to_str_end:
	#set end character
	addiu $t4, $zero, 10
	sb $t4, 0($t1)
	
	#storing registers before calling invert_str
	addi $sp, $sp, -12
	sw $ra, 8($sp)
	sw $a0, 4($sp)
	sw $a1, 0($sp)
	
	#invert string
	la $a0, auxiliar
	jal invert_str
	
	#retrieving registers
	lw $a1, 0($sp)
	lw $a0, 4($sp)
	lw $ra, 8($sp)
	addi $sp, $sp, 12
	
	jr $ra
	
invert_str:
#Inverts the input string at $a0 and outputs at the address at $a1.
#
#a0: input string
#a1: output string
	
	#storing registers before calling get_str_size
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	jal get_str_size
	
	#retrieving registers
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	#copying registers
	addu $t0, $a0, $zero
	addu $t1, $a1, $zero
	addu $t2, $v0, $zero
	
	#setting initial address at end of input string and initializing loop
	addu $t0, $t0, $t2
	addi $t0, $t0, -1
invert_str_loop:
	beq $t2, $zero, invert_str_end
	lb $t3, 0($t0)
	sb $t3, 0($t1)
	addi $t2, $t2, -1
	addi $t0, $t0, -1
	addi $t1, $t1, 1
	j invert_str_loop
invert_str_end:
	#setting end character
	sb $zero, 0($t1)
	jr $ra

invalid_base_end:
#Outpust error message when base is invalid
	la $a0, invalid_base_msg
	addiu $v0, $zero, 4
	syscall
	j end

invalid_input_end:
#Outpust error message when input is invalid
	la $a0, invalid_input_msg
	addiu $v0, $zero, 4
	syscall
end:
	addi $v0, $zero, 10
	syscall

