section .data
	from_message db "Mistä haluat konvertoida?",10,0
	from_message_length equ $ - from_message
	to_message db "Mihin haluat konvertoida?",10,0
	to_message_length equ $ - to_message
	options_message db "1. Desimaali",10,"2. Binääri",10,"3. Hexadesimaali",10,0
	options_message_length equ $ - options_message
	conversion_failed_message db "Konvertointi epäonnistui",10,0
	conversion_failed_message_length equ $ - conversion_failed_message
	max_write_length equ 11
	
	from_option times max_write_length db 0
	option_invalid_message db "Ei oo fresh case!",10,0
	option_invalid_message_length equ $ - option_invalid_message
	to_option times max_write_length db 0

	enter_decimal_value_message db "Syötä desimaaliarvo",0,10
	enter_decimal_value_message_length equ $ - enter_decimal_value_message
	enter_binary_value_message db "Syötä binääriarvo",0,10
	enter_binary_value_message_length equ $ - enter_binary_value_message
	enter_hexadecimal_value_message db "Syötä hexadesimaaliarvo",0,10
	enter_hexadecimal_value_message_length equ $ - enter_hexadecimal_value_message
	
	value_entered times max_write_length db 0 
	value_entered_length dd 0
	conversion_result times max_write_length db 0
	conversion_result_length dd 0

	hexadecimal_letters db 'A','B','C','D','E','F','a','b','c','d','e','f'
	hexadecimal_letters_length equ $ - hexadecimal_letters
	hexadecimal_numbers db '0','1','2','3','4','5','6','7','8','9'
	hexadecimal_numbers_length equ $ - hexadecimal_numbers
	
	buffer_for_hexadecimal_values times max_write_length dd 0 
	pointer_to_binary_string dd 0
	binary_string_length dd 0
	temporary_binary_buffer times 4 db '0'

section .text

is_binary_input_valid:
	push ebp
	mov ebp, esp
	mov ecx, [ebp + 8]
	sub ecx, 2
	mov edi, 0
	mov ebx, 0
binary_input_valid_loop:
	mov dl, [value_entered + edi]
	cmp dl, '0',
	je binary_input_valid
	cmp dl, '1'
	je binary_input_valid
	jmp binary_input_not_valid

binary_input_valid:
	cmp edi, ecx 
	jge binary_sequence_valid
	inc edi
	jmp binary_input_valid_loop
binary_input_not_valid:
	mov eax, 0
	pop ebp
	ret
binary_sequence_valid:
	mov eax, 1
	pop ebp
	ret

is_decimal_input_valid:
	push ebp
	mov ebp, esp
	mov ecx, [ebp + 8]
	sub ecx, 2
	mov edi, 0
	mov ebx, 0
decimal_input_valid_loop:
	mov dl, [value_entered + edi]
	cmp dl, [hexadecimal_numbers + ebx]
	je reset_iterator
	cmp ebx, 9
	je decimal_input_is_not_valid
	inc ebx
	jmp decimal_input_valid_loop
reset_iterator:
	mov ebx, 0
	cmp edi, ecx
	jge decimal_input_is_valid
	inc edi
	jmp decimal_input_valid_loop
decimal_input_is_not_valid:
	mov eax, 0
	pop ebp
	ret
decimal_input_is_valid:
	mov eax, 1
	pop ebp
	ret

power_of_base_16:
	push ebp
	mov ebp, esp
	mov eax, 16 
	mov edx, 0
	mov ecx, 16
	mov edi, 0
	cmp [ebp + 8], 0
	je return_one
	cmp [ebp + 8], 1
	je return_sixteen
	sub [ebp + 8], 1
	jmp power_loop
return_one:
	mov eax, 1
	pop ebp
	ret
return_sixteen:
	mov eax, 16
	pop ebp
	ret
power_loop:
	mul ecx
	inc edi
	cmp edi, [ebp + 8] 
	jge power_loop_exit
	jmp power_loop
	
power_loop_exit:
	pop ebp
	ret

reverse_string:
	push ebp
	mov ebp, esp
	mov esi, [ebp + 8]
	mov ebx, [ebp + 12]
	sub ebx, 1
	mov eax, 0
reverse_loop:
	mov dl, [esi + eax]
	mov cl, [esi + ebx]
	mov [esi + ebx], dl
	mov [esi + eax], cl
	inc eax
	sub ebx, 1
	cmp eax, ebx
	jge reversed
	jmp reverse_loop
reversed:
	pop ebp
	ret

convert_hexadecimal_to_decimal:
	push ebp	
	mov ebp, esp
	mov esi, [ebp + 8]
	mov edi, [ebp + 12]
parse_hexadecimal_value:
	mov eax, 0
	mov ebx, 0
	mov edx, 0
	cmp edi, 0
	jl parse_hexadecimal_values_done
	
check_for_hexadecimal_number:
	mov cl, [hexadecimal_numbers + eax]
	cmp [esi + edi], cl
	je is_hexadecimal_number
	inc eax
	cmp eax, hexadecimal_numbers_length
	jge check_for_hexadecimal_letter
	jmp check_for_hexadecimal_number
check_for_hexadecimal_letter:
	mov cl, [hexadecimal_letters + ebx],
	cmp [esi + edi], cl
	je is_hexadecimal_letter
	inc ebx
	cmp ebx, hexadecimal_letters_length
	jge is_invalid_character
	jmp check_for_hexadecimal_letter
	jmp is_invalid_character
is_hexadecimal_number:
	mov al, [esi + edi]
	sub eax, 48
	mov [buffer_for_hexadecimal_values + edi * 4], eax
	sub edi, 1
	jmp parse_hexadecimal_value

is_hexadecimal_letter:
	mov ecx, 10
	mov bl, 'A'
	mov dl, 'a'
	mov al, [esi + edi]
get_letter_value:
	cmp al, bl
	je letter_match
	cmp al, dl
	je letter_match
	inc ebx
	inc ecx
	inc edx
	jmp get_letter_value
letter_match:
	mov [buffer_for_hexadecimal_values + edi * 4], ecx
	sub edi, 1
	jmp parse_hexadecimal_value
parse_hexadecimal_values_done:
	mov eax, 1
	pop ebp
	ret

is_invalid_character:
	mov eax, 3
	pop ebp
	ret

convert_binary_to_hexadecimal:
	push ebp
	mov ebp, esp
	mov edi, [ebp + 8] ; Binary length
	mov esi, 0 ; conversion_result iterator
start_binary_to_hexadecimal:
	cmp edi, 0
	jle binary_to_hexadecimal_done
	mov edx, 0
	mov eax, 1
	mov ecx, 1
	cmp byte [value_entered + edi], '1'
	je initial_power_of_one
	jmp binary_to_hexadecimal_loop
initial_power_of_one:
	add edx, 1
binary_to_hexadecimal_loop:	
	sub edi, 1
	mov eax, 1
	shl eax, cl
	inc ecx
	cmp byte [value_entered + edi], '1'
	je is_one
	jmp is_zero
is_one:
	add edx, eax
is_zero:
	cmp eax, 8
	jae convert_to_hexadecimal
	cmp edi, 0
	jbe convert_to_hexadecimal
	jmp binary_to_hexadecimal_loop
convert_to_hexadecimal:
	cmp edx, 9
	ja value_above_nine
	cmp edx, 9	
	jbe value_between_zero_and_nine
	cmp edx, 0
	jae value_between_zero_and_nine
	jmp insert_hexadecimal
value_between_zero_and_nine:
	add edx, 48
	jmp insert_hexadecimal
value_above_nine:
	add edx, 55
insert_hexadecimal:
	mov [conversion_result + esi], dl
	inc esi
	sub edi, 1
	
	jmp start_binary_to_hexadecimal
binary_to_hexadecimal_done:	
	mov [conversion_result + esi], 10
	pop ebp
	ret

convert_decimal_to_hexadecimal:
	push ebp
	mov ebp, esp
	mov eax, [ebp + 8]
	mov ebx, 0
	mov ecx, 16
	mov edx, 0
	mov edi, 0
decimal_to_hexadecimal_loop:
	cmp eax, 0
	je decimal_to_hexadecimal_done
	div ecx
	cmp edx, 9
	ja above_nine
	cmp edx, 9
	jbe between_nine_and_zero 
	cmp edx, 0
	jae between_nine_and_zero
	jmp after_hexadecimal_conversion
between_nine_and_zero:
	add edx, 48
	mov [conversion_result + edi], dl
	jmp after_hexadecimal_conversion
above_nine:
	add edx, 55 
	mov [conversion_result + edi], dl
after_hexadecimal_conversion:
	inc edi
	mov edx, 0
	jmp decimal_to_hexadecimal_loop
decimal_to_hexadecimal_done:
	mov [conversion_result + edi], 10
	pop ebp
	ret

convert_binary_to_decimal:
	push ebp
	mov ebp, esp
	mov edi, [ebp + 8] ; length of the binary
	mov edx, 0 ; init sum
	sub edi, 1 ; length-1
	mov ecx, 1 ; exponent
	cmp byte [value_entered + edi], '1'
	je add_one
	jmp binary_to_decimal_loop
add_one:
	add edx, 1
binary_to_decimal_loop:
	cmp edi, 0
	jle binary_to_decimal_done
	mov eax, 1 ; base
	shl eax, cl
	inc ecx
	sub edi, 1
	cmp byte [value_entered + edi], '1'
	je add_to_sum
	jmp binary_to_decimal_loop
add_to_sum:
	add edx, eax
	jmp binary_to_decimal_loop
binary_to_decimal_done:
	pop ebp
	ret

get_decimals_binary_length:
	push ebp
	mov ebp, esp
	mov ebx, [ebp + 8]
	mov ecx, 1
calculate_binary_length:
	mov eax, 1 
	shl eax, cl 
	inc ecx 
	cmp eax, ebx
	jg length_calculated_but_sub_one
	je length_calculated
	jmp calculate_binary_length
length_calculated_but_sub_one:
	sub ecx, 1
length_calculated:
	pop ebp
	ret

convert_decimal_to_binary:
	push ebp
	mov ebp, esp
	mov eax, [ebp + 8]
	mov edi, [ebp + 12]

	mov [conversion_result + edi + 1], 10
	mov [conversion_result + edi + 2], 0
divide_by_two:
	mov ebx, 0
	mov ecx, 2
	mov edx, 0
	div ecx
	
	cmp edx, 1
	je insert_one
	jmp insert_zero
insert_one:
	mov [conversion_result + edi], '1'
	jmp after_insert
insert_zero:
	mov [conversion_result + edi], '0'
	
after_insert:
	cmp eax, 0
	je decimal_to_binary_conversion_done
	sub edi, 1
	jmp divide_by_two

decimal_to_binary_conversion_done:
	pop ebp
	ret

multiply_coefficient_by_ten:
	push ebp
	mov ebp, esp
	mov eax, [ebp + 8]	
	mov ebx, 10
	mul ebx
	mov ebx, eax
	pop ebp
	ret

convert_decimal_to_string:
	push ebp
	mov ebp, esp
	mov eax, [ebp + 8]
	mov edi, 0
	
decimal_to_string_loop:
	mov ebx, 0
	mov ecx, 10
	mov edx, 0
	div ecx
	add dl, 48
	mov byte [conversion_result + edi], dl
	inc edi
	cmp eax, 0
	je decimal_to_string_converted
	jmp decimal_to_string_loop
decimal_to_string_converted:
	mov [conversion_result + edi], 10 
	mov [conversion_result + edi + 1], 0
	pop ebp
	ret

convert_string_to_decimal:
	push ebp
	mov ebp, esp
	mov esi, [ebp + 8] ; string itself
	mov edi, [ebp + 12] ; string length
	sub edi, 2
	mov ebx, 1 
	mov ecx, 0 

conversion_loop:
	mov eax, 0
	mov al, [esi + edi]
	sub al, 48
	mul ebx 
	add ecx, eax
	
	push ebx,
	call multiply_coefficient_by_ten
	add esp, 4
	
	cmp edi, 0
	je converted_to_decimal
	sub edi, 1
	jmp conversion_loop
converted_to_decimal:
	pop ebp
	ret

get_message_length:
	push ebp
	mov ebp, esp
	mov esi, [ebp + 8]
	mov eax, 0
count_length:
	mov cl, [esi + eax]	
	cmp cl, 0
	je end_of_message
	inc eax
	jmp count_length

end_of_message:
	pop ebp
	ret

display_message:
	push ebp
	mov ebp, esp
	mov eax, 4
	mov ebx, 0
	mov ecx, [ebp + 8]
	mov edx, [ebp + 12]
	int 0x80
	pop ebp
	ret

write_input:
	push ebp
	mov ebp, esp
	mov eax, 3
	mov ebx, 0
	mov ecx, [ebp + 8]
	mov edx, max_write_length 
	int 0x80
	pop ebp
	ret

validate_option:
	push ebp
	mov ebp, esp
	mov esi, [ebp + 8]
	mov al, [esi]
	cmp al, '1'
	jb validation_failed
	cmp al, '3'
	ja validation_failed
	jmp validation_success
validation_failed:
	mov ebx, 0
	pop ebp
	ret	
validation_success:
	mov ebx, 1
	pop ebp
	ret

global _start
_start:
	push from_message_length
	push from_message
	call display_message
	add esp, 8
	push options_message_length
	push options_message
	call display_message
	add esp, 8
write_from_option:
	push from_option
	call write_input
	add esp, 4
	push from_option
	call validate_option
	add esp, 4

	cmp ebx, 1
	je from_option_valid 
	push option_invalid_message_length	
	push option_invalid_message
	call display_message
	add esp, 8
	jmp write_from_option

from_option_valid:
	cmp al, '1'
	je first_from_option
	cmp al, '2'
	je second_from_option
	cmp al, '3'
	je third_from_option

first_from_option:
	push enter_decimal_value_message_length
	push enter_decimal_value_message
	call display_message
	add esp, 8
	jmp enter_value
second_from_option:
	push enter_binary_value_message_length
	push enter_binary_value_message
	call display_message
	add esp, 8
	jmp enter_value
third_from_option:
	push enter_hexadecimal_value_message_length
	push enter_hexadecimal_value_message
	call display_message
	add esp, 8
enter_value:
	push value_entered
	call write_input
	add esp, 4
	push to_message_length	
	push to_message
	call display_message
	add esp, 8
	push options_message_length
	push options_message
	call display_message
	add esp, 8
write_to_option:
	push to_option
	call write_input
	add esp, 4
	push to_option
	call validate_option
	add esp, 4
	cmp ebx, 1
	je to_option_valid
	push option_invalid_message_length
	push option_invalid_message
	call display_message
	add esp, 8
	jmp write_to_option

to_option_valid:
	mov esi, from_option
	mov bl, byte [esi]
	cmp bl, '1'
	je from_decimal_to
	cmp bl, '2'
	je from_binary_to
	cmp bl, '3'
	je from_hexadecimal_to
	jmp end

from_decimal_to:
	cmp al, '1'
	je from_decimal_to_decimal
	cmp al, '2'
	je from_decimal_to_binary
	cmp al, '3'
	je from_decimal_to_hexadecimal
	jmp end

from_binary_to:
	cmp al, '1'
	je from_binary_to_decimal
	cmp al, '2'
	je from_binary_to_binary
	cmp al, '3'
	je from_binary_to_hexadecimal
	jmp end

from_hexadecimal_to:
	cmp al, '1'
	je from_hexadecimal_to_decimal
	cmp al, '2'
	je from_hexadecimal_to_binary
	cmp al, '3'
	je from_hexadecimal_to_hexadecimal
	jmp end
	
	
from_decimal_to_decimal:
	; Validate input
	push value_entered
	call get_message_length
	add esp, 4
	push eax
	call is_decimal_input_valid
	add esp, 4
	cmp eax, 0
	je conversion_failed
	push value_entered
	call get_message_length
	add esp, 4
	push eax
	push value_entered
	call convert_string_to_decimal
	add esp, 8
	cmp ecx, 255
	jg conversion_failed
	cmp ecx, 0
	jl conversion_failed
	push value_entered
	call get_message_length
	add esp, 4
	push eax
	push value_entered
	call display_message	
	add esp, 8
	jmp end

from_decimal_to_binary:
	; Validate input
	push value_entered
	call get_message_length
	add esp, 4
	push eax
	call is_decimal_input_valid
	add esp, 4
	cmp eax, 0
	je conversion_failed
	push value_entered
	call get_message_length
	add esp, 4
	push eax
	push value_entered
	call convert_string_to_decimal
	add esp, 8
	cmp ecx, 255
	jg conversion_failed
	cmp ecx, 0
	jl conversion_failed
	push value_entered
	call get_message_length
	add esp, 4
	push eax
	push value_entered
	call convert_string_to_decimal
	add esp, 8
	push ecx 
	call get_decimals_binary_length
	add esp, 4
	add ecx, 1
	mov [conversion_result_length], ecx
	push [conversion_result_length]
	push ebx 
	call convert_decimal_to_binary
	add esp, 8
	push max_write_length
	push conversion_result
	call display_message
	jmp end

from_decimal_to_hexadecimal:
	; Validate input
	push value_entered
	call get_message_length
	add esp, 4
	push eax
	call is_decimal_input_valid
	add esp, 4
	cmp eax, 0
	je conversion_failed
	push value_entered
	call get_message_length
	add esp, 4
	push eax
	push value_entered
	call convert_string_to_decimal
	add esp, 8
	cmp ecx, 255
	jg conversion_failed
	cmp ecx, 0
	jl conversion_failed
	push value_entered
	call get_message_length
	add esp, 4
	push eax
	push value_entered
	call convert_string_to_decimal
	add esp, 8
	push ecx
	call convert_decimal_to_hexadecimal	
	add esp, 4
	push edi
	push conversion_result
	call reverse_string
	add esp, 8
	inc edi
	push edi
	push conversion_result
	call display_message
	add esp, 8
	jmp end

from_binary_to_decimal:
	; validate binary input
	push value_entered
	call get_message_length
	add esp, 4
	push eax
	call is_binary_input_valid
	add esp, 4
	cmp eax, 0
	je conversion_failed
	push value_entered
	call get_message_length
	add esp, 4
	sub eax, 1 
	push eax
	call convert_binary_to_decimal
	add esp, 4
	push edx
	call convert_decimal_to_string
	add esp, 4
	push edi
	push conversion_result	
	call reverse_string
	add esp, 8
	inc edi
	push edi
	push conversion_result
	call display_message
	add esp, 8
	jmp end

from_binary_to_binary:
	; validate binary input
	push value_entered
	call get_message_length
	add esp, 4
	push eax
	call is_binary_input_valid
	add esp, 4
	cmp eax, 0
	je conversion_failed
	push value_entered
	call get_message_length
	add esp, 4
	push eax
	push value_entered
	call display_message	
	add esp, 8
	jmp end

from_binary_to_hexadecimal:
	; validate binary input
	push value_entered
	call get_message_length
	add esp, 4
	push eax
	call is_binary_input_valid
	add esp, 4
	cmp eax, 0
	je conversion_failed
	push value_entered
	call get_message_length
	add esp, 4
	sub eax, 2 
	push eax
	call convert_binary_to_hexadecimal
	add esp, 4
	mov edi, esi
	push esi
	push conversion_result
	call reverse_string
	add esp, 8
	inc edi
	push edi
	push conversion_result
	call display_message
	add esp, 8
	jmp end

from_hexadecimal_to_decimal:
	push value_entered
	call get_message_length
	add esp, 4
	sub eax, 2
	push eax
	push value_entered
	call convert_hexadecimal_to_decimal
	add esp, 8
	cmp eax, 3
	je conversion_failed

	push value_entered
	call get_message_length
	add esp, 4

	sub eax, 2
	mov ebx, eax
	mov eax, 0
	mov esi, 0
	
calculate_parsed_values:
	push esi; exponent
	call power_of_base_16
	add esp, 4
	inc esi
	mov ecx, [buffer_for_hexadecimal_values + ebx * 4]
	mul ecx
	mov [buffer_for_hexadecimal_values + ebx * 4], eax
	cmp ebx, 0
	jle calculate_sum
	sub ebx, 1
	jmp calculate_parsed_values

calculate_sum:
	push value_entered
	call get_message_length
	add esp, 4
	sub eax, 2
	mov esi, eax
	mov edi, 0
sum_loop:
	add ebx, [buffer_for_hexadecimal_values + edi * 4]
	cmp edi, esi
	je hexadecimal_to_decimal_done
	inc edi
	jmp sum_loop
hexadecimal_to_decimal_done:
	push ebx
	call convert_decimal_to_string
	add esp, 4
	push conversion_result
	call get_message_length
	add esp, 4
	sub eax, 1
	push eax
	push conversion_result
	call reverse_string
	add esp, 8
	push conversion_result
	call get_message_length
	add esp, 4
	push max_write_length
	push conversion_result
	call display_message
	add esp, 8
	jmp end

from_hexadecimal_to_binary:
	push value_entered
	call get_message_length
	add esp, 4
	sub eax, 2
	push eax
	push value_entered
	call convert_hexadecimal_to_decimal
	add esp, 8
	push value_entered
	call get_message_length
	add esp, 4
	sub eax, 1
	mov ecx, 4
	sub eax, 1
	mov [value_entered_length], eax 
	mul ecx
	mov [binary_string_length], eax
	xor ebx, ebx
	mov edx, 3
	mov esi, 0x22
	mov edi, -1
	xor ebp, ebp
	mov eax, 192
	int 0x80
	mov [pointer_to_binary_string], eax
	mov edi, 0 
	mov esi, 0
hexadecimal_to_binary_conversion_loop:
	mov eax, [buffer_for_hexadecimal_values + edi * 4]
	mov ebx, 0 
reset_temporary_binary:
	mov [temporary_binary_buffer + ebx], '0'
	cmp ebx, 3
	je divide_decimals
	inc ebx
	jmp reset_temporary_binary
move_to_next_decimal:
	mov bl, [temporary_binary_buffer + eax]
	mov [pointer_to_binary_string + esi], bl
	inc eax
	inc esi
	cmp eax, 4
	jl move_to_next_decimal
	mov eax, 0
	cmp edi, [value_entered_length]
	je hexadecimal_to_binary_done
	inc edi
	jmp hexadecimal_to_binary_conversion_loop
divide_decimals:	
	mov ecx, 2
	mov edx, 0
	div ecx
	cmp edx, 1
	je value_is_one
	jmp still_divide
value_is_one:
	mov [temporary_binary_buffer + ebx], '1'
still_divide:
	cmp eax, 0
	jle move_to_next_decimal
	sub ebx, 1
	jmp divide_decimals
hexadecimal_to_binary_done:
	mov [pointer_to_binary_string + esi], 10
	inc esi
	mov [pointer_to_binary_string + esi], 0
	push esi
	push pointer_to_binary_string
	call display_message
	add esp, 8
	jmp end

from_hexadecimal_to_hexadecimal:
	push value_entered
	call get_message_length
	add esp, 4
	push eax
	push value_entered
	call display_message	
	add esp, 8
	jmp end

conversion_failed:
	push conversion_failed_message_length
	push conversion_failed_message
	call display_message
	add esp, 8
end:
	mov eax, 1
	mov ebx, 0
	int 0x80
