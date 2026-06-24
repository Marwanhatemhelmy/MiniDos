[bits 16]
[org 0x0700]

cmp ah, 0xFF
jne interrupt

; loading the command prompt file and jumping to it
mov ah, iexit_to_cmd
int 0x21

interrupt:

    push ds ; saving ds
    push ax

    mov ax, 0x0000 ; setting ds to 0 to match the kernel, because the kernel file is loaded at ds = cs = 0x0000 and offset of 0x0700
    mov ds, ax

    pop ax
    inc word [interrupt_scope] ; increment interrupt scope, ex : interrupt_scope = 2, means two nested interrupts inside each other

    cmp word [interrupt_scope], 0x0001 ; if the first interrupt then load original ds offset to ss, otherwise leave ds offset as is
    jne handlers

    mov word [ds_offset_on_stack], sp

    jmp handlers

;----------static variables----------
bpb_offset : equ 0x0500

; reserved segment is for copying, renaming, deleting, and anything that requires,
; a temperory portion of data no exceeding the 64kb to be stored on ram
reserved_offset : equ 0x0000
reserved_segment : equ 0x6FFF

;interrupt functions numbers
icompare_strings : equ 0x00

; low level fat16 routines
inumber_of_bytes_per_sector : equ 0x01
inumber_of_sectors_per_cluster : equ 0x02
inumber_of_reserved_sectors : equ 0x03
inumber_of_fats : equ 0x04
inumber_of_sectors_per_fat : equ 0x05
inumber_of_root_dir_entries : equ 0x06

; higher level fat16 routines
istarting_root_dir_sector : equ 0x07
inumber_of_root_dir_sectors : equ 0x08
inumber_of_entries_per_root_dir_sector : equ 0x09
iending_root_dir_sector : equ 0x0A
iending_fat_sector : equ 0x0B
icluster_starting_sector : equ 0x0C
inumber_of_bytes_per_cluster : equ 0x0D

; advanced fat16 routines
ifat_entry_value : equ 0x10
ilast_fat_entry_in_cluster_chain : equ 0x11
iset_fat_entry_value : equ 0x12
ifile_root_directory_entry : equ 0x13
iset_root_dir_entry_file_name : equ 0x14
iset_root_dir_entry_starting_cluster_number : equ 0x15
iload_file_with_cluster_number : equ 0x16
iload_file : equ 0x17
idelete_root_dir_entry : equ 0x18
idelete_cluster_chain : equ 0x19
idelete_file : equ 0x1A
ifind_free_root_dir_entry : equ 0x1B
iexpand_cluster_chain : equ 0x1C
ishrink_cluster_chain : equ 0x1D
ireserve_free_cluster_chain : equ 0x1E
iwrite_cluster_data : equ 0x1F
isave_file_changes : equ 0x20
icopy_file : equ 0x21

; additional routines
iexit_to_cmd : equ 0x22
ichange_driver_number : equ 0x23
iget_current_driver_number : equ 0x24
isize_betwenn_segments : equ 0x25
icheck_driver_availability : equ 0x26
ifile_size_on_driver_in_sectors : equ 0x27
idevice_power_off : equ 0x28
iload_root_dir_at_reserved_segment : equ 0x29

handlers:

    cmp ah, icompare_strings
    je compare_strings

    ; low level fat16 routines
    cmp ah, inumber_of_bytes_per_sector
    je number_of_bytes_per_sector
    cmp ah, inumber_of_sectors_per_cluster
    je number_of_sectors_per_cluster
    cmp ah, inumber_of_reserved_sectors
    je number_of_reserved_sectors
    cmp ah, inumber_of_fats
    je number_of_fats
    cmp ah, inumber_of_sectors_per_fat
    je number_of_sectors_per_fat
    cmp ah, inumber_of_root_dir_entries
    je number_of_root_dir_entries

    ; higher level fat16 routines
    cmp ah, istarting_root_dir_sector
    je starting_root_dir_sector
    cmp ah, inumber_of_root_dir_sectors
    je number_of_root_dir_sectors
    cmp ah, inumber_of_entries_per_root_dir_sector
    je number_of_entries_per_root_dir_sector
    cmp ah, iending_root_dir_sector
    je ending_root_dir_sector
    cmp ah, iending_fat_sector
    je ending_fat_sector
    cmp ah, icluster_starting_sector
    je cluster_starting_sector
    cmp ah, inumber_of_bytes_per_cluster
    je number_of_bytes_per_cluster

    ; advanced fat16 routines
    cmp ah, ifat_entry_value
    je fat_entry_value
    cmp ah, ilast_fat_entry_in_cluster_chain
    je last_fat_entry_in_cluster_chain
    cmp ah, iset_fat_entry_value
    je set_fat_entry_value
    cmp ah, ifile_root_directory_entry
    je file_root_directory_entry
    cmp ah, iset_root_dir_entry_file_name
    je set_root_dir_entry_file_name
    cmp ah, iset_root_dir_entry_starting_cluster_number
    je set_root_dir_entry_starting_cluster_number
    cmp ah, iload_file_with_cluster_number
    je load_file_with_cluster_number
    cmp ah, iload_file
    je load_file
    cmp ah, idelete_root_dir_entry
    je delete_root_dir_entry
    cmp ah, idelete_cluster_chain
    je delete_cluster_chain
    cmp ah, idelete_file
    je delete_file
    cmp ah, ifind_free_root_dir_entry
    je find_free_root_dir_entry
    cmp ah, iexpand_cluster_chain
    je expand_cluster_chain
    cmp ah, ishrink_cluster_chain
    je shrink_cluster_chain
    cmp ah, ireserve_free_cluster_chain
    je reserve_free_cluster_chain
    cmp ah, iwrite_cluster_data
    je write_cluster_data
    cmp ah, isave_file_changes
    je save_file_changes
    cmp ah, icopy_file
    je copy_file

    ; additional routines
    cmp ah, iexit_to_cmd
    je exit_to_cmd
    cmp ah, ichange_driver_number
    je change_driver_number
    cmp ah, iget_current_driver_number
    je get_current_driver_number
    cmp ah, isize_betwenn_segments
    je size_betwenn_segments
    cmp ah, icheck_driver_availability
    je check_driver_availability
    cmp ah, ifile_size_on_driver_in_sectors
    je file_size_on_driver_in_sectors
    cmp ah, idevice_power_off
    je device_power_off
    cmp ah, iload_root_dir_at_reserved_segment
    je load_root_dir_at_reserved_segment

    jmp ireturn

;function no. = 0x00
;args : [cx = length of comparison
;       ,dx = address of first string relative to first segment
;       ,bx = address of second string relative to second segment
;       ,fs = fist segment
;       ,gs = second segment
compare_strings:
    push bx
    push cx
    push dx

    .loop_strings_bytes:
        cmp cx, 0x0000
        je .equal
        sub cx, 0x0001

        push bx
        mov bx, dx
        mov al, [fs:bx] ; fs:dx
        pop bx
        mov ah, [gs:bx] ; gs:bx

        cmp ah, al

        jne .not_equal

        add dx, 0x0001
        add bx, 0x0001

        jmp .loop_strings_bytes
    .equal:
        pop dx
        pop cx
        pop bx
        mov al, 0x01 ; indicating strings matched
        jmp ireturn
    .not_equal:
        pop dx
        pop cx
        pop bx
        mov al, 0x00 ; indicating strings didn't match
        jmp ireturn

; --------------------------------------------------------------------------------------
; low level fat16 routines
; *MUST READ BPB USING DAP METHOD AND STORE IT (BPB) AT 0x0000:0x0500 BEFORE USING THEM*
; --------------------------------------------------------------------------------------

;function no. = 0x01
number_of_bytes_per_sector:
    mov ax, [ds:bpb_offset+0x0B]
    jmp ireturn

;function no. = 0x02
number_of_sectors_per_cluster:
    movzx ax, byte [ds:bpb_offset+0x0D]
    jmp ireturn

;function no. = 0x03
number_of_reserved_sectors:
    mov ax, [ds:bpb_offset+0x0E]
    jmp ireturn

;function no. = 0x04
number_of_fats:
    movzx ax, byte [ds:bpb_offset+0x10]
    jmp ireturn

;function no. = 0x05
number_of_sectors_per_fat:
    mov ax, [ds:bpb_offset+0x16]
    jmp ireturn

;function no. = 0x06
number_of_root_dir_entries:
    mov ax, [ds:bpb_offset+0x11]
    jmp ireturn

; ---------------------------
; higher level fat16 routines
; ---------------------------

;function no. = 0x07
starting_root_dir_sector:
    push bx ;save bx

    mov ah, inumber_of_fats
    int 0x21
    
    push ax

    mov ah, inumber_of_sectors_per_fat
    int 0x21
    
    pop bx
    mul bx

    push ax

    mov ah, inumber_of_reserved_sectors
    int 0x21
    
    pop bx
    add ax, bx ; ax = starting root dir. sector

    pop bx

    jmp ireturn

;function no. = 0x08
number_of_root_dir_sectors:
    push bx ;save bx
    push cx ;save cx

    mov ah, inumber_of_bytes_per_sector
    int 0x21
    
    mov bx, ax
    mov ah, inumber_of_root_dir_entries
    int 0x21
    
    mov cx, 0x0020 ; (32) in decimal
    mul cx
    div bx
    ; ax = number or root dir. sectors
    
    pop cx
    pop bx

    jmp ireturn

;function no. = 0x09
number_of_entries_per_root_dir_sector:
    
    push bx
    push dx

    mov ah, inumber_of_root_dir_sectors
    int 0x21

    mov bx, ax

    mov ah, inumber_of_root_dir_entries
    int 0x21

    mov dx, 0x0000
    div bx

    pop dx
    pop bx

    jmp ireturn

;function no. = 0x0A
ending_root_dir_sector:
    push bx ;save bx

    mov ah, istarting_root_dir_sector
    int 0x21
    
    push ax

    mov ah, inumber_of_root_dir_sectors
    int 0x21
    
    pop bx
    add ax, bx
    sub ax, 0x0001 ; ax = ending root dir. sector

    pop bx

    jmp ireturn

;function no. = 0x0B
ending_fat_sector:
    push bx ;save bx
    
    mov ah, inumber_of_reserved_sectors
    int 0x21
    
    mov bx, ax

    mov ah, inumber_of_sectors_per_fat
    int 0x21
    
    add ax, bx ; ax = ending fat sector
    
    pop bx
    
    jmp ireturn

;function no. = 0x0C
;args : [bx = fat entry index]
cluster_starting_sector:

    sub bx, 0x0002
    push bx

    mov ah, inumber_of_sectors_per_cluster
    int 0x21
    
    mov bx, ax
    pop ax
    mul bx ; ax = (32 * (cluster no. - 2))
    push ax

    mov ah, iending_root_dir_sector
    int 0x21

    mov bx, ax
    pop ax
    add ax, bx
    add ax, 0x0001 ; ax = cluster starting sector number
    
    jmp ireturn

;function no. = 0x0D
number_of_bytes_per_cluster:

    push bx ;save bx

    mov ah, inumber_of_sectors_per_cluster
    int 0x21

    mov bx, ax

    mov ah, inumber_of_bytes_per_sector
    int 0x21

    mul bx ; ax = number of bytes per cluster

    pop bx

    jmp ireturn

; -----------------------
; advanced fat16 routines
; -----------------------

;function no. = 0x10
;args : [bx = fat enty index]
fat_entry_value:

    push dx
    push bx
    push di
    push fs
    
    push bx ;save the fat entry index

    mov dx, 0x0000 ;higher 16-bits of the dividend
    mov ax, bx ;lower 16-bits of the dividend (the fat entry index "bx")
    mov bx, 0x0100 ; (256) in decimal, the number of fat 16 entries (words or 2 bytes) in one sector, 1 sector = 512 byte = 256 words (in fat 16 a fat entry = 2 bytes)
    div bx ;now ax contains an offset to the starting fat sector
           ;**so if fat starts at sector 32 and ax = 5, then the entry is at sector 32+5 = 37**

    mov bx, ax

    mov ah, inumber_of_reserved_sectors
    int 0x21

    add ax, bx ;now we add the offset to starting fat sector, so ax now equal the sector that the entry is at

    mov di, reserved_segment
    mov fs, di
    mov di, reserved_offset
    mov word [dap_offset], di
    mov word [dap_segment], fs
    mov word [dap_starting_sector], ax
    mov word [dap_number_of_sectors], 0x0001

    call read
    
    pop bx
    mov dx, 0x0000 ;higher 16-bits of the dividend
    mov ax, bx ;lower 16-bits of the dividend (the fat entry index "bx")
    mov bx, 0x0100 ; (256) in decimal, the number entries per fat table (fat 16)
    div bx
    mov bx, dx ;now bx = it's indix in this sector, because it's not guaranteed that the sector will be the first sector in fat
    mov ax, 0x0002
    mul bx ;multipling fat entry index by 2, because one fat entry index = 2 bytes
    mov bx, ax
    mov ax, [fs:di+bx] ;ax contains the next fat entry index (next cluster number)

    pop fs
    pop di
    pop bx
    pop dx

    jmp ireturn

;function no. = 0x11
;args : [bx = any fat entry index in the cluster chain]
last_fat_entry_in_cluster_chain:
    ; in case the cluster chain contains only one fat entry
    mov cx, bx
    mov dx, cx
    .loop_fat_entries:
        mov ah, ifat_entry_value
        int 0x21
        mov bx, ax ; bx = next fat entry index or 0xFFFF
        cmp bx, 0xFFFF
        je ireturn
        mov dx, cx ; dx = previous fat entry index
        mov cx, ax ; cx = next fat entry index
        jmp .loop_fat_entries

;function no. = 0x12
;args : [bx = fat entry index, cx = new value]
set_fat_entry_value:

    push dx
    push bx
    push di
    push fs
    
    push bx ;save the fat entry index

    mov dx, 0x0000 ;higher 16-bits of the dividend
    mov ax, bx ;lower 16-bits of the dividend (the fat entry index "bx")
    mov bx, 0x0100 ; (256) in decimal, the number of fat 16 entries (words or 2 bytes) in one sector, 1 sector = 512 byte = 256 words (in fat 16 a fat entry = 2 bytes)
    div bx ;now ax contains an offset to the starting fat sector
           ;**so if fat starts at sector 32 and ax = 5, then the entry is at sector 32+5 = 37**

    mov bx, ax

    mov ah, inumber_of_reserved_sectors
    int 0x21

    add ax, bx ;now we add the offset to starting fat sector, so ax now equal the sector that the entry is at

    mov di, reserved_segment
    mov fs, di
    mov di, reserved_offset
    mov word [dap_offset], di
    mov word [dap_segment], fs
    mov word [dap_starting_sector], ax
    mov word [dap_number_of_sectors], 0x0001

    call read
    
    pop bx
    mov dx, 0x0000 ;higher 16-bits of the dividend
    mov ax, bx ;lower 16-bits of the dividend (the fat entry index "bx")
    mov bx, 0x0100 ; (256) in decimal, the number entries per fat table (fat 16)
    div bx
    mov bx, dx ;now bx = it's indix in this sector, because it's not guaranteed that the sector will be the first sector in fat
    mov ax, 0x0002
    mul bx ;multipling fat entry index by 2, because one fat entry index = 2 bytes
    mov bx, ax
    mov [fs:di+bx], cx ;write new value on hard

    call write


    pop fs
    pop di
    pop bx
    pop dx

    jmp ireturn

;function no. = 0x13
;args : [bx = address of file name]
file_root_directory_entry:
    ; the fs & di registers are choosen for segment and offset as these registers are relatively neglectable
    push di
    push fs

    mov di, reserved_offset
    mov ax, reserved_segment
    mov fs, ax
    mov word [dap_offset], di
    mov word [dap_segment], fs

    push bx

    mov ah, istarting_root_dir_sector
    int 0x21
    
    mov cx, ax
    mov ah, iending_root_dir_sector
    int 0x21
    
    pop bx

    push ax ; save ending root directory sector
    push cx ; save starting root directory sector

    .loop_root_dir_sectors:
        pop cx
        mov word [dap_starting_sector], cx
        call read

        push cx ; save sector number

        push di ; pointer to the beginning of current root dir. sector

        push 0x0000 ; current entry index at sector

        .loop_root_dir_sector_entries:
            mov cx, 0x000B ; (11) in decimal, file name in the entry will always be 11 bytes, because I'm not using the long file name
            mov dx, di

            push bx

            mov bx, word [ds_offset_on_stack] ; bx = offset to original ds on stack
            mov ax, word [ss:bx] ; ax = value of orginal ds

            pop bx

            push gs

            mov gs, ax
            mov ah, icompare_strings ; compare file name in the entry with the file name in the variable (command_file_string)
            int 0x21

            pop gs
            
            cmp al, 0x01 ; al=1, if file name matched the string
            je .found_root_dir_entry
            pop dx ; now dx = current entry index at sector
            pop ax
            push ax
            add dx, 0x0001 ; incrementing entry index
            push dx ; save dx after being incremented (current entry index at sector)
            
            mov ah, inumber_of_entries_per_root_dir_sector
            int 0x21

            cmp ax, dx ; check if we reached the last entry in this sector
            je .next_root_dir_sector

            add di, 0x0020 ; (32) indecimal increament pointer by 32 bytes to move to next entry as each entry = 32 bytes

            jmp .loop_root_dir_sector_entries

        .next_root_dir_sector:
            add sp, 0x0002 ; removing entry index from stack
            pop di ; pointer to the beginning of current root dir. sector
            pop cx ; sector number
            pop ax ; ending root dir. sector
            cmp cx, ax ; check if current sector number is the last sector in root dir. table
            je .not_found_root_dir_entry
            add cx, 0x0001
            push ax
            push cx

        jmp .loop_root_dir_sectors

    .found_root_dir_entry:
        mov ax, 0x0001 ; indicates that root dir. entry was found successfully
        mov bx, [fs:di+0x1A] ; (21) in decimal, first cluster number
        pop dx ; entry index at sector
        pop di ; pointer to the beginning of current root dir. sector
        pop cx ; sector number
        add sp, 0x0002 ; remove ending sector number (which was stored in ax) from the stack

        pop fs
        pop di

        jmp ireturn

    .not_found_root_dir_entry:
        mov ax, 0x0000 ; indicates that root dir. entry wasn't found

        pop fs
        pop di

        jmp ireturn  

;function no. = 0x14
;args : [bx = file name address, cx = sector number, dx = entry index in sector]
set_root_dir_entry_file_name:

    push fs
    push di
    push bx
    push cx
    push dx

    mov ah, iending_root_dir_sector
    int 0x21

    add sp, 0x000A ; (10) in decimal, restore pushed registers
    cmp cx, ax ; check if the root dir. entry sector number is in the root dir.
    mov ax, 0x0000 ; indicating file name modification failed
    jg ireturn
    sub sp, 0x000A ; (10) in decimal

    mov ah, inumber_of_entries_per_root_dir_sector
    int 0x21

    add sp, 0x000A ; (10) in decimal, restore pushed registers
    cmp dx, ax ; check if the root dir. entry index is in any root dir. sector
    mov ax, 0x0000 ; indicating file name modification failed
    jg ireturn
    sub sp, 0x000A ; (10) in decimal

    mov word [dap_offset], reserved_offset
    mov word [dap_segment], reserved_segment
    mov word [dap_starting_sector], cx
    mov word [dap_number_of_sectors], 0x0001

    call read

    mov ax, reserved_segment
    mov fs, ax

    pop dx
    push dx

    mov ax, 0x0020 ; (32) in decimal, cause every entry is 32 bytes in fat 16
    mul dx ; dx now is a pointer to the string at the root dir. entry
    mov dx, ax ; dx = the offset to fs to the beginning of the current entry
    mov ax, 0x0000 ; string byte index

    .loop_string_bytes:
        mov di, bx ; di now points to the string to be written, (not the string at the root dir. entry)
        add di, ax

        push bx
        push ax

        mov bx, word [ds_offset_on_stack] ; ax = offset to original ds on stack
        mov ax, word [ss:bx] ; ax = original ds that was pushed by the interrupt handler
        mov gs, ax

        pop ax
        pop bx

        movzx cx, byte [gs:di]
        mov di, dx ; di now points to the string at the root dir. entry
        add di, ax
        mov byte [fs:di], cl
        add ax, 0x0001
        cmp ax, 0x000B ; (11) in decimal
        jne .loop_string_bytes

    pop bx
    pop cx
    pop dx
    pop di
    pop fs

    mov word [dap_offset], reserved_offset
    mov word [dap_segment], reserved_segment
    mov word [dap_starting_sector], cx
    mov word [dap_number_of_sectors], 0x0001

    call write

    mov ax, 0x0001 ; indicating file name modified successfuly

    jmp ireturn

;function no. = 0x15
;args : [bx = file name address, cx = new cluster number]
set_root_dir_entry_starting_cluster_number:
    push bp ; using (bp) to avoid doing too much pushes and pops
    mov bp, sp

    push cx ; save new cluster number
    mov ah, ifile_root_directory_entry
    int 0x21

    add sp, 0x0004
    cmp ax, 0x0000 ; check if root dir. entry wasn't found
    je ireturn ; return, & ax = 0
    sub sp, 0x0004

    push fs
    push dx
    push bx

    mov ax, reserved_segment
    mov fs, ax
    mov ax, 0x0020 ; (32) in decimal, every root dir. entry = 32 bytes
    mul dx ; multiply entry index by 32, ax = pointer to first byte of root dir. entry
    mov bx, ax
    push cx ; save starting root dir. sector
    mov cx, word [ss:bp-0x0002] ; cx not contains new cluster number
    mov word [fs:bx+0x001A], cx ; (26) in decimal, write new cluster number on ram in reserved segment
    pop cx

    pop bx ; root dir. entry starting fat entry index
    pop dx ; root dir. entry index in sector
    pop fs

    mov word [dap_offset], reserved_offset
    mov word [dap_segment], reserved_segment
    mov word [dap_starting_sector], cx
    mov word [dap_number_of_sectors], 0x0001
    
    pop cx ; new cluster number
    pop bp
    
    call write

    jmp ireturn

;-----------------------file loading segment-----------------------

;function no. = 0x16
;args : [bx = cluster number, cx = loading offset, dx = loading segment]
load_file_with_cluster_number:

    .loop_clusters:
        push bx
        push dx
        push cx

        mov ah, inumber_of_sectors_per_cluster
        int 0x21
        ; ax = number of sectors to read = number of sectors per cluster
        push ax
        
        mov ah, icluster_starting_sector
        int 0x21
        ; ax = cluster starting sector
        mov word [dap_starting_sector], ax

        pop ax ;number of sectors per cluster
        mov word [dap_number_of_sectors], ax

        pop cx
        mov word [dap_offset], cx

        pop dx
        mov word [dap_segment], dx
        
        call read
        
        mov ah, inumber_of_bytes_per_cluster
        int 0x21

        add cx, ax ;now cx = the incremented offset

        mov ah, ifat_entry_value
        pop bx
        int 0x21

        mov bx, ax ; bx = the next fat entry index (cluster number)

        cmp cx, 0xFFFF ; (65535) in decimal, check if we reached the end of segment, (then we will need to extend the segment
        jl .next_cluster ; if we didn't reach the end of the segment then there is no need to extend the segment, so we can just go to next fat entry

        add dx, 0x1000 ; adding 0x1000 to segment register will make it go 64kb forward
        mov cx, 0x0000 ; zeroing the offset is necessary as we will start from a different segment base

        .next_cluster:
            cmp bx, 0xFFFF
            jne .loop_clusters

    jmp ireturn

;function no. = 0x17
;args : [bx = file name address, cx = loading offset, dx = loading segment]
load_file:
    push cx
    push dx

    mov ah, ifile_root_directory_entry
    int 0x21
    
    add sp, 0x0004 ; remove cx and dx from the stack
    cmp ax, 0x0000 ; check if root dir. entry wasn't found
    je ireturn ; return, & ax would = 0
    sub sp, 0x0004 ; restore cx and dx back on the stack

    pop dx
    pop cx
    
    mov ah, iload_file_with_cluster_number
    int 0x21

    jmp ireturn

;-----------------------file deletion segment-----------------------

;function no. = 0x18
;args : [bx = file name address]
delete_root_dir_entry:
    mov ah, ifile_root_directory_entry
    int 0x21

    cmp ax, 0x0000 ; check if root dir. entry wasn't found
    je ireturn ; return, & ax would = 0

    push fs
    push dx ; root dir. entry index at sector
    push bx ; first fat entry index (cluster number)

    mov ax, reserved_segment
    mov fs, ax
    mov ax, 0x0020 ; (32) in decimal, every root dir. entry is 32 bytes
    mul dx
    mov bx, ax ; bx = pointer to first byte of the root dir. entry
    mov byte [fs:bx], 0xE5 ; mark first byte as deleted with 0xE5

    pop bx ; deleted root dir. entry starting fat entry index
    pop dx ; deleted root dir. entry index in sector
    pop fs

    ; dx = deleted root dir. entry index in sector
    ; di = pointer to first byte of the root dir. entry

    mov word [dap_offset], reserved_offset
    mov word [dap_segment], reserved_segment
    mov word [dap_starting_sector], cx
    mov word [dap_number_of_sectors], 0x0001

    call write

    mov ax, 0x0001 ; root dir. entry deleted successfully

    jmp ireturn

;function no. = 0x19
;args : [bx = first fat entry index]
delete_cluster_chain:

    push bx
    mov ah, ifat_entry_value
    int 0x21
    pop bx

    push ax ; next fat entry index

    mov cx, 0x0000
    mov ah, iset_fat_entry_value
    int 0x21

    pop ax
    mov bx, ax
    cmp ax, 0xFFFF
    jne delete_cluster_chain

    jmp ireturn

;function no. = 0x1A
;args : [bx = file name address]
delete_file:
    mov ah, idelete_root_dir_entry
    int 0x21

    ; if ax = 0, then no root dir. entry with that file name was found
    cmp ax, 0x0000
    je ireturn

    mov ah, idelete_cluster_chain
    int 0x21

    jmp ireturn

;-----------------------file saving segment-----------------------

;function no. = 0x1B
find_free_root_dir_entry:

    push fs

    mov ah, istarting_root_dir_sector
    int 0x21

    push 0x0000; entry index in sector
    push ax; current sector

    mov ah, iending_root_dir_sector
    int 0x21
    mov cx, ax ; cx contains ending root dir. sector

    .loop_root_dir_sectors:
        mov word [dap_offset], reserved_offset
        mov word [dap_segment], reserved_segment

        pop ax
        push ax
        
        mov word [dap_starting_sector], ax
        mov word [dap_number_of_sectors], 0x0001

        call read

        .loop_root_dir_sector_entries:
            mov ax, reserved_segment
            mov fs, ax
            pop ax
            pop bx ; bx now contains the current entry index
            push bx
            push ax
            mov ax, 0x0020 ; (32) in decimal
            mul bx ; multiply bx by 32 to get the exact offset, because each entry is 32 bytes
            push di ; save di
            mov di, ax ; let di be a temporary offset
            movzx bx, byte [fs:di] ; load the first byte of the entry in bx
            pop di

            cmp bx, 0x0000
            je .found_root_dir_entry
            cmp bx, 0x00E5
            je .found_root_dir_entry

            pop ax ; next sector
            pop bx ; current entry index
            add bx, 0x0001 ; increment entry index
            push bx
            push ax

            cmp bx, 0x0010 ; check we reached the last entry in sector
            jne .loop_root_dir_sector_entries

            pop ax
            pop bx
            add ax, 0x0001 ; increment ax to point to next sector
            mov bx, 0x0000 ; set entry index to 0
            push bx
            push ax

            cmp ax, cx
            jg .not_found_root_dir_entry

            jmp .loop_root_dir_sectors

    .found_root_dir_entry:
        pop cx ; sector number
        pop dx ; entry index in sector
        pop fs
        mov ax, 0x0001 ; indicating a free root dir. entry was found
        jmp ireturn
    
    .not_found_root_dir_entry:
        pop ax ; ending root dir. sector
        pop bx ; entry index (0) because it's the ending sector
        pop fs
        mov ax, 0x0000 ; indicating no free root dir. entry was found
        jmp ireturn

;function no. = 0x1C
;args : [bx = any cluster number in the cluster chain to be expanded, cx = number of clusters to add]
expand_cluster_chain:
    cmp cx, 0x0000 ; check if no clusters to be added
    je ireturn

    mov ah, ifat_entry_value
    int 0x21

    cmp ax, 0x0000 ; check if free fat entry
    je ireturn

    push dx
    push cx
    push bx

    mov ah, inumber_of_sectors_per_cluster
    int 0x21

    mov dx, 0x0000
    mul cx
    mov bx, ax ; bx = size of new clusters to be added in sectors

    mov ah, ireserve_free_cluster_chain
    int 0x21

    add sp, 0x0006 ; remove number of clusters to be added and the original cluster number
    cmp ax, 0x0000
    je ireturn
    sub sp, 0x0006 ; restoring number of clusters to be added and the original cluster number

    mov cx, bx ; cx = first fat entry index (cluster number) in reserved cluster chain

    mov ah, ilast_fat_entry_in_cluster_chain
    pop bx ; fat entry index in original cluster chain
    push bx
    push cx
    int 0x21

    mov ah, iset_fat_entry_value
    mov bx, cx
    pop cx ; first fat entry index (cluster number) in reserved cluster chain
    int 0x21

    pop bx
    pop cx
    pop dx

    jmp ireturn

;function no. = 0x1D
;args : [bx = first cluster number, cx = number of fat entries to remove]
shrink_cluster_chain:
    cmp cx, 0x0000 ; check if no fat entry to be removed
    je ireturn

    mov ah, ifat_entry_value
    int 0x21

    cmp ax, 0xFFFF ; check if only one fat entry in cluster chain, (this routine isn't for deleting, but rather shrinking the cluster chain)
    je ireturn

    push dx
    push cx
    push bx

    mov ax, cx
    push ax ; removed fat entry index

    .remove_fat_entry:
        pop ax
        pop bx
        pop cx
        push cx
        push bx
        push ax

        ; getting the last cluster number and it's previous cluster number in cluster chain
        mov ah, ilast_fat_entry_in_cluster_chain
        int 0x21

        ; setting last cluster number in cluster chain to 0x0000 (free entry)
        mov ah, iset_fat_entry_value
        mov bx, cx
        mov cx, 0x0000
        int 0x21

        ; setting last cluster number's previous cluster number in cluster chain to 0xFFFF (last entry)
        mov ah, iset_fat_entry_value
        mov bx, dx
        mov cx, 0xFFFF
        int 0x21
        
        pop ax
        dec ax
        push ax

        cmp ax, 0x0000 ; checking if removed all fat entries intended to be remove
        jne .remove_fat_entry

    pop ax
    pop dx
    pop cx
    pop bx

    jmp ireturn

;function no. = 0x1E
;args : [bx = file size on ram (in sectors)]
reserve_free_cluster_chain:
    push bp
    mov bp, sp

    push bx ; save file size on ram (in sectors) (bp-2)
    mov bx, 0x0001 ; start after fat entry 1 as fat entries [0,1] are reserved

    .first_free_entry:
        inc bx ; increment fat entry index

        mov ah, ifat_entry_value
        int 0x21

        cmp ax, 0x0000 ; check if fat entry is free or not
        jne .first_free_entry

    push 0x0001 ; number of reserved fat entries (bp-4)
    push bx ; save bx to return it as the first entry index in the reserved chain (bp-6)
    push bx ; previous free fat entry index (bp-8)

    cmp word [ss:bp-0x0002], 0x0021 ; (33) in decimal, checking if file size is less than 1 fat entry (1 fat entry usually represents 32 sectors)
    jl .last_reserved_entry

    .loop_fat_entries:
        inc bx
        cmp bx, 0xFFFF ; check if reached last entry in fat table
        je .not_enough_space

        mov ah, ifat_entry_value
        int 0x21

        cmp ax, 0x0000
        jne .loop_fat_entries

        mov cx, bx ; new value = current fat entry index
        mov ax, bx
        pop bx ; bx = previous free fat entry index
        push ax ; current fat entry index
        mov ah, iset_fat_entry_value ; set previous fat entry value to point to current fat entry index
        int 0x21

        mov ah, inumber_of_sectors_per_cluster
        int 0x21
        mov bx, ax
        mov dx, 0x0000
        mov ax, word [ss:bp-0x0002] ; file size (in sectors)
        div bx ; divide file size (in sectors)/number of sectors per cluster, 
               ; ax will contain the number of reserved fat entris needed for the file

        cmp dx, 0x0000 ; check if no remainder, so continue without incrementing ax, otherwise increment it
        je .skip_file_size_normalization

        inc ax ; increment ax since there is a remainder

        .skip_file_size_normalization:
        pop bx ; current fat entry index
        push bx

        mov cx, word [ss:bp-0x0004] ; number of reserved fat entries
        inc cx ; increment number of reserved fat entries
        mov word [ss:bp-0x0004], cx ; change it on the stack

        cmp ax, cx ; compare the number of reserved fat entris needed for the file, with number of currently reserved fat entries
        je .last_reserved_entry

        jmp .loop_fat_entries
    
    .last_reserved_entry:
        pop bx ; last free entry index
        pop ax ; first free fat entry index
        pop cx ; number of reserved fat entries
        pop dx ; file size (in sectors)
        pop bp ; base pointer
        push ax
        push cx
        mov cx, 0xFFFF
        mov ah, iset_fat_entry_value
        int 0x21
        pop cx
        pop ax
        push ax
        mov ax, bx ; ax = last free entry index
        pop bx ; first free fat entry index
        jmp ireturn

    .not_enough_space:
        pop bx ; last free entry index
        pop ax ; first free fat entry index
        pop cx ; number of reserved fat entries
        pop dx ; file size (in sectors)
        pop bp ; base pointer
        push ax
        push cx
        mov cx, 0xFFFF
        mov ah, iset_fat_entry_value
        int 0x21
        pop cx
        pop bx
        push bx
        ; reverse the process and free all the entries that we marked as reserved
        mov ah, idelete_cluster_chain
        int 0x21
        pop ax
        mov ax, 0x0000 ; indicating not enough space
        jmp ireturn

;**routine wasn't tested properly**
;function no. = 0x1F
;args : [bx = first cluster number, si = file starting offset, fs = file starting segment]
write_cluster_data:
    push bx

    mov word [dap_segment], fs
    mov word [dap_offset], si

    mov ah, inumber_of_sectors_per_cluster
    int 0x21
    mov word [dap_number_of_sectors], ax

    mov ah, icluster_starting_sector
    int 0x21
    mov word [dap_starting_sector], ax

    call write

    mov ax, 0xFFFF
    sub ax, si
    mov bx, ax ; bx = the distance from (si) to the end of it's segment perhaps (fs)
    
    mov ah, inumber_of_bytes_per_cluster
    int 0x21
    
    cmp bx, ax ; check if still there is space in the segment to increment si by the number of bytes per cluster
    jg .not_enough_segment_space
    
    add si, ax ; increment pointer
    mov ah, ifat_entry_value
    pop bx
    int 0x21

    mov bx, ax ; bx contains the next cluster number

    cmp bx, 0xFFFF
    jne write_cluster_data
    jmp ireturn

    .not_enough_segment_space:
        mov bx, fs
        add bx, 0x1000
        mov fs, ax ; increment segment to go 64kb forward
        mov bx, 0xFFFF
        sub bx, si ; bx = distance between offset (si) and end of old segment (fs)
        sub ax, bx
        mov si, ax

        mov ah, ifat_entry_value
        pop bx
        int 0x21

        mov bx, ax ; bx contains the next cluster number

        cmp bx, 0xFFFF
        jne write_cluster_data
        jmp ireturn

;**routine wasn't tested properly**
; it's purpose is to save changes that took place in a file, & it's the responsibility of the developers to decide the ending of their program
; as there is no interrupt routine to calculate the ending segment & offset of the program. "I'm talking as if it's a real OS, who else is
; going to see this comment other than me"

;function no. = 0x20
;args : [bx = file name address, si = file starting offset, fs = file starting segment, di = file ending offset, gs = file ending segment]
save_file_changes:
    mov ah, ifile_root_directory_entry
    int 0x21
    push bx

    add sp, 0x0002
    cmp ax, 0x0000
    je ireturn
    sub sp, 0x0002

    mov ah, ifile_size_on_driver_in_sectors ; result = ax
    int 0x21

    push ax ; file size on driver in sectors
    
    mov ah, isize_betwenn_segments ; bx = size between segments and offsets in sectors
    int 0x21

    pop ax ; file size on driver in sectors
    cmp bx, ax
    jl .shrink
    jg .expand
    je .save_cluster_data

    .expand:
        mov ah, iexpand_cluster_chain
        sub bx, ax
        mov cx, bx
        pop bx
        push bx
        int 0x21

        jmp .save_cluster_data

    .shrink:
        mov ah, ishrink_cluster_chain
        sub ax, bx
        mov cx, ax
        pop bx
        push bx

        int 0x21

        jmp .save_cluster_data

    .save_cluster_data:
        mov ah, iwrite_cluster_data
        pop bx
        cmp di, 0x3FFC
        je read_error
        int 0x21

    jmp ireturn

;function no. = 0x21
;args : [bx = fisrt file name offset to ds (to be copied), cx = second file name offset to ds (to be pasted), dl = driver number (to paste to)]
copy_file:
    push bp
    push dx

    ; getting current driver number
    mov ah, iget_current_driver_number
    int 0x21
    mov ah, 0x00

    push ax ; current driver number
    mov bp, sp

    push bx ; first file's name offset to ds
    push cx ; second file's name offset to ds

    ; checking driver availability
    mov ah, icheck_driver_availability
    mov al, dl
    int 0x21

    add sp, 0x000A ; (10) in decimal
    cmp al, 0x00
    je ireturn
    sub sp, 0x000A ; (10) in decimal

    ; getting the first file root dir. entry data and checking if it's actualy a file or not
    mov ah, ifile_root_directory_entry
    int 0x21

    push bx ; first file starting cluster number

    add sp, 0x000C ; (12) in decimal
    cmp ax, 0x0000
    je ireturn
    sub sp, 0x000C ; (12) in decimal

    ; getting the size of the first file in sectors
    mov ah, ifile_size_on_driver_in_sectors
    mov bx, word [ss:bp-0x0006] ; first file starting cluster number
    int 0x21

    push bx ; file size on first driver

    ; setting driver number to the driver number where the file will be pasted
    mov ax, word [ss:bp+0x0002] ; second driver number
    mov ah, ichange_driver_number
    int 0x21

    ;  getting second file root directory and checking if originaly there is a file with that name
    mov ah, ifile_root_directory_entry
    mov bx, word [ss:bp-0x0004] ; second file name offset to ds
    int 0x21

    add sp, 0x000E ; (14) in decimal
    cmp ax, 0x0001
    je ireturn
    sub sp, 0x000E ; (14) in decimal

    ; finding a free root dir entry and getting the sector that it lies at
    mov ah, ifind_free_root_dir_entry
    int 0x21

    push cx ; free root dir. entry sector
    push dx ; free root dir. entry index in sector

    add sp, 0x0012 ; (18) in decimal
    cmp ax, 0x0000 ; check if no free root dir. entry at second driver
    je ireturn
    sub sp, 0x0012 ; (18) in decimal

    ; reserve a cluster chain at second driver
    mov ah, ireserve_free_cluster_chain
    mov bx, word [ss:bp-0x0008] ; file size on first driver in sectors
    int 0x21

    add sp, 0x0012 ; (18) in decimal
    cmp ax, 0x0000 ; check if no space for the second file at the second driver
    je ireturn
    sub sp, 0x0012 ; (18) in decimal


    push bx ; first free fat entry index

    mov bx, word [ss:bp-0x0004] ; second file name offset to ds
    mov cx, word [ss:bp-0x000A] ; free root dir. entry sector
    mov dx, word [ss:bp-0x000C] ; free root dir. entry index in sector

    ; naming the free root dir. entry that we found
    mov ah, iset_root_dir_entry_file_name
    int 0x21

    mov bx, word [ss:bp-0x0004] ; second file name offset to ds
    mov cx, word [ss:bp-0x000E] ; second file's first cluster number

    ; setting a cluster number for the free root dir. entry that we found
    mov ah, iset_root_dir_entry_starting_cluster_number
    int 0x21

    ; saving first and second file's first cluster numbers
    mov ax, word [ss:bp-0x0006] ; first file's first cluster number
    push ax
    mov ax, word [ss:bp-0x000E] ; second file's first cluster number
    push ax
    .copy_clusters_data:
        ; setting driver number to it's original value
        mov dx, word [ss:bp] ; original driver number
        mov ah, ichange_driver_number
        mov al, dl
        int 0x21

        ; read first file cluster at reserved area
        mov word [dap_segment], reserved_segment
        mov word [dap_offset], reserved_offset
        mov ah, icluster_starting_sector
        pop cx
        pop bx ; bx = first file's first cluster number
        push bx
        push cx
        int 0x21
        mov word [dap_starting_sector], ax
        mov ah, inumber_of_sectors_per_cluster
        int 0x21
        mov word [dap_number_of_sectors], ax

        call read

        ; setting driver number to the value of the driver to paste into
        mov ax, word [ss:bp+0x0002]
        mov ah, ichange_driver_number
        int 0x21

        ; write one cluster from reserved area to second file cluster (n)
        mov word [dap_segment], reserved_segment
        mov word [dap_offset], reserved_offset
        mov ah, icluster_starting_sector
        pop bx ; bx = second file's first cluster number
        push bx
        int 0x21
        mov word [dap_starting_sector], ax
        mov ah, inumber_of_sectors_per_cluster
        int 0x21
        mov word [dap_number_of_sectors], ax

        call write

        ; go to next cluster number(first file)
        mov ah, ifat_entry_value
        pop cx
        pop bx
        int 0x21

        push ax ; first file's first cluster number
        push cx ; second file's first cluster number

        ; go to next cluster number(second file)
        mov ah, ifat_entry_value
        pop bx
        int 0x21

        push ax ; second file's first cluster number

        cmp bx, 0xFFFF
        jne .copy_clusters_data

    ; setting driver number to it's original value
    mov dx, word [ss:bp] ; original driver number
    mov ah, ichange_driver_number
    mov al, dl
    int 0x21

    mov sp, bp
    add sp, 0x0004
    pop bp
    mov ax, 0x0001

    jmp ireturn

; -------------------
; additional routines
; -------------------

; this function is for programs to exit and come back to the command prompt, & all it does is loads the command prompt and jumps to it
;function no. = 0x22
exit_to_cmd:
    mov bx, word [ds_offset_on_stack]
    mov word [ss:bx], 0x0000 ; since it's a special case routine we will need to set the original ds pushed on the stack to 0x0000
    mov ah, iload_file
    mov bx, command_file_string
    mov cx, 0x4700
    mov dx, 0x0000
    int 0x21
    dec word [interrupt_scope]
    add sp, 0x0008 ; remove the interrupt pushes + ds
    jmp 0X0000:0x4700

;function no. = 0x23
;args : [al = driver number (0x80, 0x81, 0x82,....)]
change_driver_number:
    mov ah, icheck_driver_availability
    int 0x21
    cmp al, 0x00
    je ireturn

    mov [driver_number], al

    ; loading BPB at 0x0000:0x0500
    mov word [dap_starting_sector], 0x0000
    mov word [dap_number_of_sectors], 0x0001
    mov word [dap_offset], bpb_offset
    mov word [dap_segment], 0x0000

    call read

    jmp ireturn

;function no. = 0x24
get_current_driver_number:
    mov al, [driver_number]

    jmp ireturn

;function no. = 0x25
;args : [si = file starting offset, fs = file starting segment, di = file ending offset, gs = file ending segment]
size_betwenn_segments:
    push cx
    push dx
    push si
    push fs
    push di
    push gs

    mov ax, gs
    mov cx, fs
    sub ax, cx
    mov cx, 0x0010 ; (16 in decimal)
    mul cx ; dx:ax
    ; (gs-fs)*16

    mov cx, di
    sub cx, si
    ; (di-si)

    push bx
    mov bx, 0x0000

    add ax, cx
    adc dx, bx
    ; dx:ax = (gs-fs)*16 + (di-si) = size between segments in bytes

    pop bx
    push ax
    mov ah, inumber_of_bytes_per_sector
    int 0x21
    mov cx, ax ; cx = number of bytes per sector
    pop ax
    div cx ; dx:ax (size between segments in bytes) / cx (number of bytes per sector)
           ; ax+1 = size between segments in sectors, if dx > 0
           ; ax = size between segments in sectors, if dx == 0

    mov bx, ax ; bx = quotient

    cmp dx, 0x0000 ; check if there is a remainder

    pop gs
    pop di
    pop fs
    pop si
    pop dx
    pop cx

    je ireturn
    add bx, 0x0001
    jmp ireturn

;function no. = 0x26
;args : [al = driver number]
check_driver_availability:
    cmp al, 0x97 ; check if driver letter is one single letter, ex : A,B,...Z, not AA,BF,...ZZ
    mov ah, al ; saving driver number in ah
    mov al, 0x00 ; indicating driver doesn't exist
    jg ireturn
    mov al, ah ; restoring driver number back in al

    push bx
    push dx
    push ax

    mov ah, 0x41
    mov bx, 0x55AA
    mov dl, al ; drive to test
    int 0x13

    pop ax
    pop dx
    pop bx

    jnc ireturn ; carry flag = 0 ; driver does exist
    mov al, 0x00 ; indicating driver doesn't exist
    jmp ireturn ; carry flag = 1 ; driver doesn't exist

;function no. = 0x27
;args : [bx = first cluster number]
file_size_on_driver_in_sectors:
    push cx
    push dx
    push bx

    mov cx, 0x0000

    .loop_fat_entries:
        mov ah, ifat_entry_value
        int 0x21
        add cx, 0x0001
        mov bx, ax
        cmp bx, 0xFFFF
        jne .loop_fat_entries

    ; cx = number of clusters
    mov dx, 0x0000
    mov ah, inumber_of_sectors_per_cluster
    int 0x21
    mul cx ; ax = size on driver in sectors

    pop bx
    pop dx
    pop cx
    jmp ireturn

;function no. = 0x28
device_power_off:
    mov ax, 0x5301
    xor bx, bx
    int 0x15

    mov ax, 0x530E
    mov bx, 0x0000
    mov cx, 0x0102
    int 0x15

    mov ax, 0x5307
    mov bx, 0x0001
    mov cx, 0x0003
    int 0x15

;function no. = 0x29
load_root_dir_at_reserved_segment:
    mov ah, istarting_root_dir_sector
    int 0x21
    mov word [dap_starting_sector], ax
    mov ah, inumber_of_root_dir_sectors
    int 0x21
    mov word [dap_number_of_sectors], ax
    mov word [dap_segment], reserved_segment
    mov word [dap_offset], reserved_offset

    call read

    jmp ireturn 

read:
    push dx
    push si
    push ax

    mov dl, [driver_number] ; drive number to read from
    mov si, dap ; pointer to dap
    mov ah, 0x42
    int 0x13

    pop ax
    pop si
    pop dx
    jc read_error
    ret

write:
    push dx
    push si
    push ax

    mov dl, [driver_number] ; drive number to write to
    mov si, dap ; pointer to dap
    mov ah, 0x43
    mov al, 0x00
    int 0x13

    pop ax
    pop si
    pop dx
    jc write_error
    ret

read_error:
    mov ah, 0x0E
    mov al, 0x45 ; 'E'
    mov bh, 0x00
    mov bl, 0x07
    int 0x10
    jmp read_error

write_error:
    mov ah, 0x0E
    mov al, 0x57 ; 'W'
    mov bh, 0x00
    mov bl, 0x07
    int 0x10
    jmp write_error

dap:
    db 0x10 ; size of DAP = 16 bytes
    db 0x00 ; always 0
    dap_number_of_sectors : dw 0x0000 ; reading/loading number of sectors
    dap_offset : dw 0x0000 ; reading/loading offset
    dap_segment : dw 0x0000 ; reading/loading segment
    dap_starting_sector : dq 0x0000 ; reading/loading starting sector

ireturn:
    dec word [interrupt_scope]
    pop ds ; restore ds
    iret

ds_offset_on_stack : dw 0x0000
interrupt_scope : dw 0x0000 ; call an interrupt and it will increment, return from an interrupt and it will decrement
command_file_string : db "COMMAND BIN"
snake_file_string : db "SNAKE   BIN"
driver_number : db 0x80 ; C = 0x80, D = 0x81, E = 0x82,....