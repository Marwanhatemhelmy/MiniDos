[bits 16]
[org 0x7C3E] ; it's set to 0x7C3E & not to 0x7C00, because from 0x7C00 to 0x7C3D is the parameters for the fat16 details

bpb_offset : equ 0x0500
reserved_offset : equ 0x0000
reserved_segment : equ 0x6FFF

jmp 0x0000:start

start:
    cli
    ; setting ds to equal cs
    mov ax, cs
    mov ds, ax

    ; setting the stack
    mov ax, 0xFFFF
    mov ss, ax
    mov sp, ax

    ; setting text mode
    mov ah, 0x00
    mov al, 0x03
    int 0x10
    sti

    ; loading BPB at 0x0000:0x0500
    mov word [dap_starting_sector], 0x0000
    mov word [dap_number_of_sectors], 0x0001
    mov word [dap_offset], bpb_offset
    mov word [dap_segment], 0x0000

    call read

    ; getting the kernel root dir. entry
    mov bx, kernel_file_name
    call file_root_directory_entry

    ; loading kernel at 0x0000:0x0700
    mov cx, 0x0700
    mov dx, 0x0000
    call load_file_with_cluster_number

    ; setting 0x21 interrupt
    mov word [0x84], 0x0700
    mov word [0x86], cs
    
    mov ah, 0xFF ; setting ah to 0xFF so that we can jump to the kernel without running any interrupts
    jmp 0x0700

    hlt

;args : [cx = length of comparison
;       ,bx = address of first string relative to first segment
;       ,dx = address of second string relative to second segment
;       ,fs = fist segment
;       ,gs = second segment
compare_strings:
    pushf
    push ax
    push bx
    push cx
    push dx

    loop_strings:
        cmp cx, 0x0000
        je equal
        sub cx, 0x0001

        push bx
        mov bx, dx
        mov al, [fs:bx]
        pop bx
        mov ah, [gs:bx]

        cmp ah, al

        jne not_equal

        add dx, 0x0001
        add bx, 0x0001

        jmp loop_strings
    equal:
        pop dx
        pop cx
        pop bx
        pop ax
        popf
        mov al, 0x01
        ret
    not_equal:
        pop dx
        pop cx
        pop bx
        pop ax
        popf
        mov al, 0x00
        ret

; -----------------------------------------------
; low level fat16 routines (each reads from BPB)
; -----------------------------------------------
number_of_bytes_per_sector:
    mov ax, [ds:bpb_offset+0x0B]
    ret

number_of_sectors_per_cluster:
    movzx ax, byte [ds:bpb_offset+0x0D]
    ret

number_of_reserved_sectors:
    mov ax, [ds:bpb_offset+0x0E]
    ret

number_of_fats:
    movzx ax, byte [ds:bpb_offset+0x10]
    ret

number_of_sectors_per_fat:
    mov ax, [ds:bpb_offset+0x16]
    ret

number_of_root_dir_entries:
    mov ax, [ds:bpb_offset+0x11]
    ret

; ---------------------------
; higher level fat16 routines
; ---------------------------
starting_root_dir_sector:

    call number_of_fats ; ax = number of fat tables (usually 2)
    push ax

    call number_of_sectors_per_fat ; ax = number of sectors per fat table
    pop bx
    mul bx ; ax = number of sectors in all fat tables

    push ax

    call number_of_reserved_sectors ; ax = number of reserved sectors at the beginning of the storage unit
    pop bx
    add ax, bx ; ax = starting root dir. sector

    ret

number_of_root_dir_sectors:
    call number_of_bytes_per_sector ; ax = number of bytes per sector
    mov bx, ax
    call number_of_root_dir_entries ; ax = number of root dir entries
    mov cx, 0x0020 ; size of root dir. entry
    mul cx ; ax = size of root dir. table in bytes
    div bx ; ax = dx:ax / bx = size of root dir. table in bytes / number of bytes per sector
    ret

ending_root_dir_sector:
    call starting_root_dir_sector
    push ax
    call number_of_root_dir_sectors
    pop bx
    add ax, bx
    sub ax, 0x0001
    ret

;args : [bx = fat entry index]
cluster_starting_sector:

    sub bx, 0x0002
    push bx

    call number_of_sectors_per_cluster
    
    mov bx, ax
    pop ax
    mul bx ; ax = (32 * (cluster no. - 2))
    push ax

    call ending_root_dir_sector

    mov bx, ax
    pop ax
    add ax, bx
    add ax, 0x0001 ; ax = cluster starting sector number
    
    ret

; -----------------------
; advanced fat16 routines
; -----------------------

; this function is a simplified version of itself, as it doesn't return the entry number
;args : [bx = address of file name]
file_root_directory_entry:
    ; the fs & di registers are choosen for segment and offset as these registers are relatively neglectable
    mov di, reserved_offset
    mov ax, reserved_segment
    mov fs, ax
    mov word [dap_offset], di
    mov word [dap_segment], fs

    push bx

    call starting_root_dir_sector
    
    mov cx, ax
    call ending_root_dir_sector
    
    pop bx

    push ax ; save ending root directory sector
    push cx ; save starting root directory sector

    loop_root_dir_sectors:
        pop cx
        mov word [dap_starting_sector], cx
        call read
        
        push cx ; save current sector number

        push di ; pointer to the beginning of current root dir. sector

        loop_root_dir_sector_entries:
            mov cx, 0x000B ; (11 in dec.)
            mov dx, di
            mov ax, ds
            mov gs, ax
            call compare_strings

            cmp al, 1 ; check if file name matched the string
            je found_root_dir_entry

            pop ax ; pointer to the beginning of current root dir. sector
            push ax
            push bx ; save bx
            mov bx, ax
            call number_of_bytes_per_sector
            add ax, bx ; now ax is a pointer to the end of current root dir. sector
            pop bx
            cmp ax, di ; check if we reached the ending of current root dir. sector
            je next_root_dir_sector
            add di, 0x20 ; (32 in dec.) increment root dir. entry pointer by 32, since every entry is 32 bytes
            jmp loop_root_dir_sector_entries

        next_root_dir_sector:
            pop di ; pointer to the beginning of current root dir. sector
            pop cx ; current sector number
            pop ax ; ending root dir. sector
            cmp cx, ax ; check if current sector number is the last sector in root dir. table
            je not_found_root_dir_entry
            add cx, 0x0001 ; increment sector number
            push ax
            push cx

        jmp loop_root_dir_sectors

    found_root_dir_entry:
        mov ax, 0x0001 ; indicating the entry was found
        mov bx, [fs:di+0x1A] ; number of first cluster
        pop di ; pointer to the beginning of current root dir. sector
        pop cx ; sector number
        add sp, 0x0002 ; remove ending sector number (which was stored in ax) from the stack
        ret

    not_found_root_dir_entry:
        mov ax, 0x0000 ; indicating entry wasn't found
        ret

; this function is very simplified as it requires the file to not exceed the size of one cluster, & it's not really a worry as it will not
; be used for loading any files except for the kernel
;args : [bx = cluster number, cx = loading offset, dx = loading segment]
load_file_with_cluster_number:
    mov word [dap_offset], cx
    mov word [dap_segment], dx

    call cluster_starting_sector
    mov word [dap_starting_sector], ax

    call number_of_sectors_per_cluster
    mov word [dap_number_of_sectors], ax

    call read

    ret

read:
    mov dl, 0x80 ; drive number
    mov si, dap ; pointer to dap
    mov ah, 0x42            ; extended read (LBA)
    int 0x13
    jc read_error
    ret

read_error:
    mov ah, 0x0E
    mov al, 'E'
    mov bh, 0x00
    mov bl, 0x07
    int 0x10
    jmp read_error

dap:
    db 0x10 ; size of DAP = 16 bytes
    db 0x00 ; always 0
    dap_number_of_sectors : dw 0x0000 ; reading/loading number of sectors
    dap_offset : dw 0x0000 ; reading/loading offset
    dap_segment : dw 0x0000 ; reading/loading segment
    dap_starting_sector : dq 0x0000 ; reading/loading starting sector

kernel_file_name : db "KERNEL  BIN"
times 510-($-$$) db 0
dw 0xAA55