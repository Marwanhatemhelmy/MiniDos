[bits 16]
[org 0x4700]

start:
    cli
    mov ax, cs
    mov ds, ax

    mov ah, 0x00
    mov al, 0x03
    int 0x10

    sti

    ; getting current driver number
    mov ah, 0x21
    int 0x21

    sub al, 0x3D ; al = current driver letter
    mov [dir_name], al ; changing driver letter

    mov si, wellcom
    call write_string_on_screen
    call start_new_line
    mov si, wellcom2
    call write_string_on_screen
    call start_new_line
    mov si, wellcom3
    call write_string_on_screen
    call start_new_line
    mov si, dir_name
    call write_string_on_screen

    jmp command_loop

command_loop:

    mov ah, 0x01
    int 0x16

    ; check if no key is in buffer
    jz .no_keystroke_effect

    call read_keystroke

    ; check enter press
    cmp ah, 0x1C
    je .enter_press
    
    ; check back-space press
    cmp ah, 0x0E
    je .back_space_press

    ; check left_arrow press
    cmp ah, 0x4b
    je .left_arrow_press

    ; check right_arrow press
    cmp ah, 0x4d
    je .right_arrow_press

    ; check if not a literal key
    cmp al, 0x20
    jl .no_keystroke_effect
    cmp al, 0x7E
    jg .no_keystroke_effect

    call read_cursor_position
    cmp dl, max_command_buffer_length
    je .no_keystroke_effect

    ; writing in teletype mode
    mov ah, 0x0E
    mov bh, 0x00
    mov bl, 0x07
    int 0x10

    ; write to the command buffer
    call write_char_to_command_buffer

    jmp .no_keystroke_effect

    .enter_press:
        call start_new_line
        call excute_command
        call clear_command_buffer
        mov byte [commandidx], 0x00
        call start_new_line

        mov si, dir_name
        call write_string_on_screen

    jmp .no_keystroke_effect

    ; removing one character at cursor if posible
    .back_space_press:
        call read_cursor_position

        cmp dl, 0x04 ; check if the cursor is at the begginging of the row (can't go back)
        je .no_keystroke_effect

        call remove_char_from_command_buffer

        call erase_char ; erase the character from screen
    
    jmp .no_keystroke_effect

    .left_arrow_press:
        call read_cursor_position

        cmp dl, 0x04
        je .no_keystroke_effect

        sub byte [commandidx], 0x01

        call go_left

    jmp .no_keystroke_effect

    .right_arrow_press:
        call read_cursor_position
        cmp dl, max_command_buffer_length
        je .no_keystroke_effect
        inc byte [commandidx]
        call go_right

    .no_keystroke_effect:
        jmp command_loop

; cursor control functions
erase_char:
    push ax
    push bx
    push cx
    push dx

    ; moving cursor one character to the left
    call go_left

    ; writing space at cursor
    mov ah, 0x09
    mov al, 0x20 ; (space ' ')
    mov bh, 0x00
    mov bl, 0x07
    mov cx, 0x0001
    int 0x10

    pop dx
    pop cx
    pop bx
    pop ax

    ret

go_left:
    push ax
    push bx
    push cx
    push dx

    call read_cursor_position

    ; moving cursor one character to the left
    mov ah, 0x02
    mov bh, 0x00
    sub dl, 0x01
    int 0x10

    pop dx
    pop cx
    pop bx
    pop ax

    ret

go_right:
    push ax
    push bx
    push cx
    push dx

    call read_cursor_position

    ; moving cursor one character to the right
    mov ah, 0x02
    mov bh, 0x00
    inc dl
    int 0x10

    pop dx
    pop cx
    pop bx
    pop ax

    ret

start_new_line:
    push ax
    push bx
    push cx
    push dx

    ; read cursor position
    call read_cursor_position

    ; set cursor to begining of next line
    mov ah, 0x02
    mov bh, 0x00
    inc dh
    mov dl, 0x00
    int 0x10

    pop dx
    pop cx
    pop bx
    pop ax

    ret

;args : [bx = pointer to any byte before the token itself or to the first byte of the token]
get_token_length:
    push bx

    mov cx, 0x0000 ; token length

    call actual_token_starting_offset
    add sp, 0x0002 ; remove bx from the stack
    cmp dx, 0x0000 ; check if no tokens were prompted
    je return
    sub sp, 0x0002 ; restore bx onto the stack

    .loop_token_bytes:

        inc bx ; increment token offset
        inc cx ; increment token length

        cmp byte [ds:bx], 0x20 ; check if end of command line
        jg .loop_token_bytes

    pop bx

    ret

;args : [bx = pointer to any byte before the token itself or to the first byte of the token]
actual_token_starting_offset:
    mov dx, max_command_buffer_length
    add dx, command_buffer ; dx not contains the offset to the end of the command buffer

    cmp dx, bx ; check if command buffer pointer reached the limit of the command buffer
    mov dx, 0x0000 ; then return dx=0 if reached the limit
    je return

    mov dx, 0x0001 ; otherwise return dx=1
    cmp byte [ds:bx], 0x21 ; check if character isn't a literal, otherwise it should return as it has reached the Beginning of the token
    jge return

    inc bx ; increment token pointer
    
    jmp actual_token_starting_offset

;args : [al = argument index]
get_token:
    inc al
    mov bx, command_buffer
    call actual_token_starting_offset

    cmp dx, 0x0000 ; check if no command were in the command buffer
    mov cx, 0x0000 ; then return cx = 0
    je return

    .loop_tokens:
        call get_token_length ; cx now contains the token's length
        call actual_token_starting_offset
        add bx, cx ; bx is now a pointer to the byte after the last character of current arg. (usually a space ' ' or a null 0x00)

        dec al ; decrement token index

        cmp al, 0x00 ; check if reached the desired token to get
        jne .loop_tokens

    sub bx, cx ; now bx is adjusted to point to the first byte (char.) of the token at index (al)
               ; cx = token length (not zero indexed)

    ret

;args : [al = byte (character)]
write_char_to_command_buffer:
    cmp byte [commandidx], max_command_buffer_length ; check if reached the limit of the command buffer
    je return

    movzx bx, byte [commandidx]
    mov byte [ds:command_buffer+bx], al ; write the character at index

    inc byte [commandidx] ; need to increment buffer index at the end

    ret

remove_char_from_command_buffer:
    cmp byte [commandidx], 0x00 ; check if at the beginning of the command buffer
    je return

    sub byte [commandidx], 0x01 ; need to decrement buffer index first

    movzx bx, byte [commandidx]
    mov byte [ds:command_buffer+bx], 0x00  ; write 0 at index

    ret

clear_command_buffer: ; clear prompted command from command buffer
    push bx ; save bx
    push cx ; save cx

    mov bx, command_buffer
    mov cx, max_command_buffer_length
    add cx, bx ; cx now is a pointer to last byte in the command buffer

    .zero_command_byte:
        mov byte [ds:bx], 0x00 ; zero current byte in command buffer
        inc bx ; increment command buffer pointer

        cmp bx, cx ; check if reached the limit of the command buffer
        jne .zero_command_byte

    pop cx
    pop bx

    ret

excute_command:

    mov al, 0x00 ; get command, first token is the command, all tokens after it are arguments
    call get_token

    cmp cx, 0x0000 ; check if no command where entered
    je return

    mov ax, ds
    mov fs, ax
    mov gs, ax

    ; check if clear command
    mov dx, clear_string
    mov cx, 0x0005 ; 'clear' length
    mov ah, 0x00
    int 0x21

    cmp al, 0x01
    je clear_screen

    ; check if open command
    mov dx, open_string
    mov cx, 0x0004 ; 'open' length
    mov ah, 0x00
    int 0x21

    cmp al, 0x01
    je open_file

    ; check if delete command
    mov dx, delete_string
    mov cx, 0x0006 ; 'delete' length
    mov ah, 0x00
    int 0x21

    cmp al, 0x01
    je delete_file

    ; check if rename command
    mov dx, rename_string
    mov cx, 0x0006 ; 'rename' length
    mov ah, 0x00
    int 0x21

    cmp al, 0x01
    je rename_file

    ; check if copy command
    mov dx, copy_string
    mov cx, 0x0004 ; 'copy' length
    mov ah, 0x00
    int 0x21

    cmp al, 0x01
    je copy_file

    ; check if change directory command
    mov dx, change_dir_string
    mov cx, 0x0002 ; 'cd' length
    mov ah, 0x00
    int 0x21

    cmp al, 0x01
    je change_directory

    ; check if get directories command
    mov dx, get_directories_string
    mov cx, 0x0003 ; 'dir' length
    mov ah, 0x00
    int 0x21

    cmp al, 0x01
    je get_directories

    ; check if power off command
    mov dx, shut_down_string
    mov cx, 0x0004 ; 'shtd' length
    mov ah, 0x00
    int 0x21

    cmp al, 0x01
    je shut_down

    mov si, command_not_found_string
    jmp write_command_result_message ; if no command were found

; command functions
clear_screen:
    mov ax, 0x0003
    int 0x10
    ret

open_file:
    ; get first argument
    mov al, 0x01
    call get_token

    ; check if file name wasn't parsed
    mov si, no_arg_was_parsed_string
    cmp cx, 0x0000
    je write_command_result_message

    ; replacing the dot with spaces
    mov si, bx
    mov dx, file_name_buffer
    call replace_argument_filename_dot_with_spaces

    ; loading file at program_segment:program_offset
    mov bx, file_name_buffer
    mov ah, 0x14
    mov dx, program_segment
    mov cx, program_offset
    int 0x21

    ; checking if file wasn't found
    mov si, file_not_found_string
    cmp ax, 0x0000
    je write_command_result_message

    call clear_command_buffer ; it's a special case function as it will never reach the clear command buffer stage so we will need to do it
                              ; by ourselves
    
    ; jumping to program segment to run the program
    jmp program_segment:program_offset

delete_file:
    ; getting first argument
    mov al, 0x01
    call get_token

    ; checking if file name wasn't parsed
    mov si, no_arg_was_parsed_string
    cmp cx, 0x0000
    je write_command_result_message

    ; replacing the dot with spaces
    mov si, bx
    mov dx, file_name_buffer
    call replace_argument_filename_dot_with_spaces

    ; deleting the file
    mov bx, file_name_buffer
    mov ah, 0x17
    int 0x21

    ; checking if file wasn't found
    mov si, file_not_found_string
    cmp ax, 0x0000
    je write_command_result_message

    ; writing the result message if file was deleted
    mov si, file_deleted_successfuly_string
    jmp write_command_result_message

rename_file:
    ; --------------first file name--------------

    ; getting first argument
    mov al, 0x01
    call get_token

    ; checking if original file name wasn't parsed
    mov si, no_arg_was_parsed_string
    cmp cx, 0x0000
    je write_command_result_message

    ; replacing the dot with spaces
    mov si, bx
    mov dx, file_name_buffer
    call replace_argument_filename_dot_with_spaces

    ; getting first file root dir. entry
    mov bx, file_name_buffer
    mov ah, 0x12
    int 0x21
    push cx ; save sector number
    push dx ; entry index

    ; checking if file wasn't found
    mov si, file_not_found_string
    add sp, 0x0004 ; remove sector number and root dir. entry index from the stack
    cmp ax, 0x0000
    je write_command_result_message
    sub sp, 0x0004 ; restoring sector number back onto the stack

    ; --------------second file name--------------
    
    ; getting second argument
    mov al, 0x02
    call get_token

    ; checking if file name wasn't parsed
    mov si, insuffecient_number_of_args_string
    add sp, 0x0004
    cmp cx, 0x0000
    je write_command_result_message
    sub sp, 0x0004

    push bx ; saving second file name

    ; putting spaces in the file name buffer
    mov dx, file_name_buffer
    call space_filename_buffer

    pop bx ; restoring second file name

    ; replacing the dot with spaces
    mov si, bx
    call replace_argument_filename_dot_with_spaces

    ; getting second file root dir. entry
    mov bx, file_name_buffer
    mov ah, 0x12
    int 0x21

    ; checking if second file already exists
    mov si, file_already_exists_string
    add sp, 0x0004 ; remove sector number from the stack
    cmp ax, 0x0001
    je write_command_result_message
    sub sp, 0x0004 ; restoring sector number back onto the stack

    ; renaming file
    mov ah, 0x19
    mov bx, file_name_buffer
    pop dx
    pop cx
    int 0x21

    ; writing the result message if file was renamed
    mov si, file_renamed_successfuly_string
    jmp write_command_result_message

; example : copy SNAKE.BIN FILE.BIN D => copies SNAKE.BIN and paste it in D directory with the name of FILE.BIN
copy_file:
    ; --------------directory letter--------------

    ; getting third argument
    mov al, 0x03
    call get_token

    ; checking if directory letter wasn't parsed
    mov si, insuffecient_number_of_args_string
    cmp cx, 0x0000
    je write_command_result_message

    ; checking if directory wasn't parsed as a single letter
    mov si, incorrect_argument_string
    cmp cx, 0x0001
    jg write_command_result_message

    ; check driver availability
    mov ah, 0x23
    mov al, byte [bx]
    add al, 0x3D
    mov bl, al ; save driver number in bl
    int 0x21

    mov bh, 0x0000
    push bx ; saving directory number

    ; checking if driver isn't available
    mov si, incorrect_argument_string
    add sp, 0x0002 ; remove driver number
    cmp al, 0x00
    je write_command_result_message
    sub sp, 0x0002 ; restoring driver number

    ; --------------first file name--------------

    ; getting first argument
    mov al, 0x01
    call get_token

    ; checking if first file name wasn't parsed
    mov si, no_arg_was_parsed_string
    add sp, 0x0002 ; remove driver number
    cmp cx, 0x0000
    je write_command_result_message
    sub sp, 0x0002 ; restoring driver number

    ; replacing the dot with spaces
    mov si, bx
    mov dx, file_name_buffer
    call replace_argument_filename_dot_with_spaces

    mov bx, file_name_buffer
    push bx ; first file name
    mov ah, 0x12
    int 0x21

    mov si, file_not_found_string
    add sp, 0x0004 ; remove first file's name + driver number
    cmp ax, 0x0000
    je write_command_result_message
    sub sp, 0x0004 ; restoring first file's name + driver number

    ; --------------second file name--------------
    
    ; getting second argument
    mov al, 0x02
    call get_token

    ; checking if second file name wasn't parsed
    mov si, insuffecient_number_of_args_string
    add sp, 0x0004 ; remove first file's name
    cmp cx, 0x0000
    je write_command_result_message
    sub sp, 0x0004 ; restoring first file's name

    mov si, bx
    mov dx, file_name_buffer2
    call replace_argument_filename_dot_with_spaces
    mov bx, file_name_buffer2

    push bx ; second file name

    pop bx
    pop cx ; first file name
    pop ax ; driver number
    push ax
    push cx
    push bx

    mov cx, ax ; cx = driver number

    ; getting original driver number
    mov ah, 0x21
    int 0x21

    push ax ; original driver number

    ; changing driver
    mov ah, 0x20
    mov al, cl
    int 0x21

    ; searching for the root dir. entry
    mov ah, 0x12
    int 0x21

    ; checking if second file already exist in the directory that it will be pasted in
    mov si, file_already_exists_string
    add sp, 0x0008 ; remove first and second file's names
    cmp ax, 0x0001
    je write_command_result_message
    sub sp, 0x0008 ; restoring first and second file's names

    pop ax ; original driver number

    ; changing driver to the original one
    mov ah, 0x20
    int 0x21

    ; --------------copying--------------

    mov ah, 0x1E
    pop cx ; second file name
    pop bx ; first file name
    pop dx ; driectory number
    int 0x21

    ret

change_directory:

    ; getting first argument
    mov al, 0x01
    call get_token

    ; check if no argument was parsed
    mov si, no_arg_was_parsed_string
    cmp cx, 0x0000
    je write_command_result_message

    ; check if directory letter wasn't parsed as one single letter
    mov si, incorrect_argument_string
    cmp cx, 0x0001
    jg write_command_result_message

    movzx bx, byte [bx]

    push bx ; driver number as a letter, 'C', 'D', 'E',.....

    add bx, 0x003D ; (61) in decimal, now bx = driver number, 0x80, 0x81, 0x82,....

    ; check driver availability
    mov ah, 0x23
    mov al, bl
    int 0x21

    mov cl, bl

    pop bx ; driver number as a letter

    mov si, incorrect_argument_string
    cmp al, 0x00 ; check if driver doesn't exist
    je write_command_result_message

    ; change directory
    mov ah, 0x20
    mov al, cl
    int 0x21

    mov si, problem_occured_string
    cmp ah, 0x00 ; check if failed to change driver number
    je write_command_result_message

    ; changing driver letter at the command line
    mov byte [dir_name], bl

    ret

get_directories:
    mov ah, 0x26
    int 0x21

    push ds
    push bx
    push dx

    ; number of root dir. sectors
    mov ah, 0x08
    int 0x21

    mov dx, 0x0000
    mov bx, ax

    ; number of bytes per sector
    mov ah, 0x01
    int 0x21

    mul bx
    mov dx, ax

    mov bx, -32
    mov ax, 0x6FFF
    mov ds, ax

    add dx, bx ; dx = last offset of root dir

    .loop_root_dir_entries:
        add bx, 0x0020 ; (32) in decimal, each root dir. entry is 32 bytes
        cmp dx, bx
        jl .done
        mov si, bx
        cmp byte [bx], 0x00
        je .loop_root_dir_entries
        cmp byte [bx], 0xE5
        je .loop_root_dir_entries
        sub bx, 0x0020 ; (32) in decimal

        mov cx, 0x000B
        call write_string_on_screen_with_length
        call start_new_line
        add bx, 0x0020 ; (32) in decimal
        jmp .loop_root_dir_entries
        
    .done:
        pop dx
        pop bx
        pop ds

        ret

shut_down:
    mov ah, 0x25
    int 0x21

    mov si, problem_occured_string
    je write_command_result_message

; commands result messages
;args : [si = address to first byte of command result message]
write_command_result_message:
    call write_string_on_screen
    mov dx, file_name_buffer
    call space_filename_buffer
    mov dx, file_name_buffer2
    call space_filename_buffer
    ret

;args : [dx = file name buffer]
space_filename_buffer:
    mov bx, dx
    cmp byte [bx], 0x00 ; check if it's the last byte of the buffer
    je return

    mov bx, 0x0000 ; index
    .loop_filename_buffer_bytes:
        push bx
        add bx, dx
        mov byte [bx], 0x20 ; spacing each byte, placing (' ')
        pop bx
        inc bx

        cmp bx, 0x000B
        je return

        jmp .loop_filename_buffer_bytes

    ret

; ex : FILE.BIN => FILE    BIN
;args : [si = address to first byte of argument string in command buffer, cx = length of argument (non zero indexed), dx = file name buffer]
replace_argument_filename_dot_with_spaces:
    push cx
    push bx
    push si

    mov bx, 0x0000 ; index
    .loop_filename_bytes:
        lodsb ; al contains the char.
        push bx
        add bx, dx
        mov byte [bx], al ; placing character (al) at buffer (dx)
        pop bx
        inc bx

        add sp, 0x0006
        cmp bx, cx-0x0001 ; check if it's the last byte of the string and hasn't found the dot yet, then return
        je return
        sub sp, 0x0006

        cmp byte [si], '.'
        jne .loop_filename_bytes

    mov bx, 0x000A ; pointer to last byte of the file name buffer (zero indexed) (10 in decimal)
    pop si ; si = pointer to the first byte of the argument in the command buffer
    push si
    add si, cx ; cx = the length of the argument prompted at the cmd, not = 11, si now = offset to the end of the argument + 1,
               ; bec. cx is length of argument (non zero indexed)
    sub si, 0x0001
    .loop_arg_ext_bytes:
        mov al, [si] ; al contains the char.
        push bx
        add bx, dx
        mov byte [bx], al
        pop bx
        sub bx, 0x0001 ; decrement the index
        sub si, 0x0001

        cmp byte [si], '.' ; check if coming char, is a dot so dont continue
        jne .loop_arg_ext_bytes

    pop si
    pop bx
    pop cx

    ret
; some utils, low level callable lables
read_keystroke:
    mov ah, 0x00
    int 0x16
    ret

read_cursor_position:
    mov ah, 0x03
    mov bh, 0x00
    int 0x10
    ret

;args : [si = address to string (must end in 0 to stop writing), cx = string length]
write_string_on_screen_with_length:
    push ax
    push bx
    push si
    push cx

    .loop_string_bytes:
        mov ah, 0x0E
        lodsb
        mov bh, 0x00
        mov bl, 0x07
        int 0x10
        sub cx, 0x0001

        cmp cx, 0x0000
        jne .loop_string_bytes

    pop cx
    pop si
    pop bx
    pop ax
    
    ret

;args : [si = address to string (must end in 0 to stop writing)]
write_string_on_screen:
    push ax
    push bx
    push si

    .loop_string_bytes:
        mov ah, 0x0E
        lodsb
        mov bh, 0x00
        mov bl, 0x07
        int 0x10

        cmp byte [si], 0x00
        jne .loop_string_bytes

    pop si
    pop bx
    pop ax
    
    ret

read_error:
    mov ah, 0x0E
    mov al, 'E'
    mov bh, 0x00
    mov bl, 0x07
    int 0x10
    jmp read_error

; general return lable to jump to from any callable lable to return
return:
    ret

; static variables
max_command_buffer_length : equ 0x4F ; 79 in decimal
program_segment : equ 0x0871 ; segment where any program would be loaded
program_offset : equ 0x0000 ; offset to the segment where any program would be loaded

; command buffer & it's relatings
command_buffer : times 80 db 0x00
commandidx : db 0x00

; commands
clear_string : db "clear", 0x00
open_string : db "open", 0x00
delete_string : db "delete", 0x00
rename_string : db "rename", 0x00
copy_string : db "copy", 0x00
change_dir_string : db "cd", 0x00
get_directories_string : db "dir", 0x00
shut_down_string : db "shtd", 0x00

; other variables
dir_name : db "C:\>", 0x00
file_name_buffer : times 11 db 0x20 ; buffer for an eleven bytes file name string to be stored
db 0x00 ; ending of buffer
file_name_buffer2 : times 11 db 0x20 ; spare buffer for an eleven bytes file name string to be stored
db 0x00 ; ending of buffer
command_not_found_string : db "command not found", 0x00
file_not_found_string : db "file not found", 0x00
incorrect_argument_string : db "incorrect argument", 0x00
file_already_exists_string : db "file already exists", 0x00
file_deleted_successfuly_string : db "file deleted successfuly", 0x00
file_renamed_successfuly_string : db "file renamed successfuly", 0x00
no_arg_was_parsed_string : db "no argument was parsed", 0x00
insuffecient_number_of_args_string : db "insuffecient number of arguments", 0x00
problem_occured_string : db "oops!, it seems like something didn't go well", 0x00
wellcom : db "  -  ", 0x00
wellcom2 : db " --- ", 0x00
wellcom3 : db "----- mini os, developed by Marwan Hatem, all rights are not reserved", 0x00