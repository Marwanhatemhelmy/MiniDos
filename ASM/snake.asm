[bits 16]
[org 0x0000]

start:
    cli

    ; setting ds
    mov ax, cs
    mov ds, ax

    ; setting stack
    mov ax, 0xFFFF
    mov ss, ax
    mov sp, 0xFFFF

    ; setting text mode
    mov ah, 0x00
    mov al, 0x03
    int 0x10

    sti

    call drawBoarders

    ; setting beggining cursor position
    mov ah, 0x02
    mov bh, 0x00
    mov dh, 0x01
    mov dl, 0x01
    int 0x10

    call writeScore

    ; initiate seed
    call seedFromClock

    jmp move

; only checks if key is pressed and loads the scan code into ah
readKey:
    mov ah, 0x01
    int 0x16
    ret

; waits for keystroke and if a key is available it clears it
removeKey:
    mov ah, 0x00
    int 0x16
    ret

readCursorPosition:
    mov ah, 0x03
    mov bh, 0x00
    int 0x10
    ret

; writes 's' at cursor coordinates
writeSnakeAtCursor:
    mov ah, 0x09
    mov al, 0x73 ; 's'
    mov bh, 0x00
    mov bl, 0x07
    mov cx, 0x01
    int 0x10
    ret

writeScore:
    ; save original cursor coordinates
    call readCursorPosition
    movzx bx, dh
    push bx
    movzx bx, dl
    push bx

    ; move cursor to score text position
    mov ah, 0x02
    mov bh, 0x00
    mov dx, 0x1000
    int 0x10

    mov cx, 0x0000
    mov ax, [score]
    .push_string_digits:
        mov dx, 0x0000
        mov bx, 0x000A
        div bx

        add dx, 0x30 ; '0'
        push dx

        inc cx

        cmp ax, 0x0000
        jne .push_string_digits
    

    mov si, 0x0008
    .write_string_digits:
        pop bx

        mov byte [scoreString+si], bl
        inc si
        dec cx

        cmp cx, 0x0000
        jne .write_string_digits


    mov si, scoreString
    call write_string_on_screen
    ; restore original cursor coordinates
    pop bx
    mov dl, bl
    pop bx
    mov dh, bl
    mov ah, 0x02
    mov bh, 0x00
    int 0x10

    ret

drawBoarders:
    mov dx, 0x0000
    drawRowsBoarders:
        ; set cursor posion
        mov ah, 0x02
        mov bh, 0x00
        int 0x10

        ; draw at ceiling
        mov ah, 0x09
        mov al, 0x23 ; '#'
        mov bh, 0x00
        mov bl, 0x07
        mov cx, 0x01
        int 0x10

        push dx ; save row
        mov dh, 0x0F ; floor boarders
        mov ah, 0x02
        mov bh, 0x00
        int 0x10
        ; draw at floor
        mov ah, 0x09
        mov al, 0x23 ; '#'
        mov bh, 0x00
        mov bl, 0x07
        mov cx, 0x01
        int 0x10
        pop dx

        inc dl
        cmp dl, 0x0F
        jne drawRowsBoarders

    mov dx, 0x0000
    drawColumnsBoarders:
        ; set cursor posion
        mov ah, 0x02
        mov bh, 0x00
        int 0x10

        ; draw at left boarder
        mov ah, 0x09
        mov al, 0x23 ; '#'
        mov bh, 0x00
        mov bl, 0x07
        mov cx, 0x01
        int 0x10

        push dx ; save column
        mov dl, 0x0F ; right boarder
        mov ah, 0x02
        mov bh, 0x00
        int 0x10
        ; draw at right boarder
        mov ah, 0x09
        mov al, 0x23 ; '#'
        mov bh, 0x00
        mov bl, 0x07
        mov cx, 0x01
        int 0x10
        pop dx

        inc dh
        cmp dh, 0x0F
        jne drawColumnsBoarders
    ret

; explanation : every cusor coordinate (snake head coordinate) is pushed to a buffer,
; where we get the oldest cursor coordinate (snake head coordinate) at every loop to set it as the new tail coordinate (last 's' in snake body)
; change the new address where the new tail coordinates are stored
setTailNewCoordinatesOffset:
    mov bx, [tailCoordinatesOffset]
    cmp bx, 0xFA00 ; setting a limit for the buffer
    jne decrementTailCoordinatesOffset
    mov word [tailCoordinatesOffset], 0xFFFF
    decrementTailCoordinatesOffset:
        sub bx, 0x0002
        mov [tailCoordinatesOffset], bx
    ret

; change the new address where the new head coordinates are stored
setHeadNewCoordinatesOffset:
    mov bx, [headCoordinatesOffset]
    cmp bx, 0xFA00 ; setting a limit for the buffer
    jne decrementHeadCoordinatesOffset
    mov word [headCoordinatesOffset], 0xFFFF
    decrementHeadCoordinatesOffset:
        sub bx, 0x0002
        mov [headCoordinatesOffset], bx
    ret

; push latest snake head coordinate onto the buffer
setHeadNewCoordinates:
    call setHeadNewCoordinatesOffset
    call readCursorPosition
    mov bx, [headCoordinatesOffset]
    mov [ds:bx], dx
    ret

getTailCoordinates:
    mov bx, [tailCoordinatesOffset]
    mov bx, [ds:bx] ; bh = row, bl = column
    ret

removeTail:
    ; save original cursor position
    call readCursorPosition
    movzx bx, dh
    push bx
    movzx bx, dl
    push bx

    ; move cursor to tail coordinates
    call getTailCoordinates
    mov dx, bx
    mov ah, 0x02
    mov bh, 0x00
    int 0x10

    ; write ' ' at cursor
    mov ah, 0x09
    mov al, 0x20 ; ' '
    mov bh, 0x00
    mov bl, 0x07
    mov cx, 0x01
    int 0x10

    ; reset cursor to original position
    pop bx
    mov dl, bl
    pop bx
    mov dh, bl
    mov ah, 0x02
    mov bh, 0x00
    int 0x10

    ; decrement tail index
    call setTailNewCoordinatesOffset

    ret

; check if snake hit itself or apple
checkSnakeHit:
    ; read character at cursor
    mov ah, 0x08
    mov bh, 0x00
    int 0x10
    cmp al, 0x73 ; 's'
    je gameOver
    cmp al, 0x61 ; 'a'
    jne return
    mov byte [growFlag], 0x01

; generate seed
seedFromClock:
    push ax
    push cx
    push dx

    mov ah, 0x00
    int 0x1A

    mov ax, dx
    xor ax, cx
    mov [seed], ax

    pop dx
    pop cx
    pop ax
    ret

; get random number between 0-65534
getRandom:
    push dx

    mov ax, [seed]
    mov dx, 0x6255
    mul dx
    add ax, 0x3619
    
    mov [seed], ax

    pop dx
    ret

; scale down the random number to be between 1-14
scaledRandom:
    call getRandom
    mov cx, 0x0D
    xor dx, dx
    div cx ; dx contains a random number beteen 0-13
    inc dx ; to make it from 1-14 instead of 0-13
    ret

placeApple:
    mov al, [appleFlag]
    cmp al, 0x01 ; check if already there is an apple existing
    je return

    mov byte [appleFlag], 0x01 ; set apple flag to 1, means apple exist
    
    ; save cursor position
    call readCursorPosition
    movzx bx, dh
    push bx
    movzx bx, dl
    push bx

    ; find a random coordinates for the apple, and also make sure it doesn't spawn on the snake
    findRandomNonSnakeOccupiedPosition:
        call scaledRandom ; dl contains random number between 1-15
        push dx
        call scaledRandom
        mov dh,dl
        pop bx
        mov dl, bl

        ; move cursor to the apple potential coordinates
        mov ah, 0x02
        mov bh, 0x00
        int 0x10

        ; read character at the position
        mov ah, 0x08
        mov bh, 0x00
        int 0x10

        cmp al, 0x73 ; 's'
        je findRandomNonSnakeOccupiedPosition

    ; write a (apple) at cursor position
    mov ah, 0x09
    mov al, 0x61 ; 'a'
    mov bh, 0x00
    mov cx, 0x01
    int 0x10

    ; restore original cursor position
    pop bx
    mov dl, bl
    pop bx
    mov dh, bl
    mov ah, 0x02
    mov bh, 0x00
    int 0x10

move:
    call writeScore
    call checkSnakeHit
    call readCursorPosition
    call placeApple
    ; check for screen boarders
    cmp dh, 0x0F
    je gameOver
    cmp dh, 0x00
    je gameOver
    cmp dl, 0x0F
    je gameOver
    cmp dl, 0x00
    je gameOver

    call writeSnakeAtCursor

    call readKey
    ; check if key available in buffer
    jz continue
    cmp ah, 0x48
    je up
    cmp ah, 0x50
    je down
    cmp ah, 0x4b
    je left
    cmp ah, 0x4d
    je right

    up:
        call removeKey
        mov al, [vertical]
        cmp al, 0x01 ; check if going against the snake direction
        je continue
        mov byte [vertical], -1
        mov byte [horizontal], 0x00
        jmp continue
    down:
        call removeKey
        mov al, [vertical]
        cmp al, -1 ; check if going against the snake direction
        je continue
        mov byte [vertical], 0x01
        mov byte [horizontal], 0x00
        jmp continue
    left:
        call removeKey
        mov al, [horizontal]
        cmp al, 0x01 ; check if going against the snake direction
        je continue
        mov byte [vertical], 0x00
        mov byte [horizontal], -1
        jmp continue
    right:
        call removeKey
        mov al, [horizontal]
        cmp al, -1 ; check if going against the snake direction
        je continue
        mov byte [vertical], 0x00
        mov byte [horizontal], 0x01
        jmp continue

    continue:
        call delay
        call setHeadNewCoordinates
        mov bl, [growFlag]
        cmp bl, 0x01
        je growing
        call removeTail
        not_growing:
            call readCursorPosition
            ; move cursor
            add dh, [vertical]
            add dl, [horizontal]
            mov ah, 0x02
            mov bh, 0x00
            int 0x10

            jmp move

        growing:
            inc byte [score]
            mov byte [appleFlag], 0x00
            mov byte [growFlag], 0x00
            call readCursorPosition
            ; move cursor
            add dh, [vertical]
            add dl, [horizontal]
            mov ah, 0x02
            mov bh, 0x00
            int 0x10
    jmp move

delay:
    mov ax, 0xFFFF
    decrement:
        mov bx, 0x0FFF
        decrement1:
            sub bx, 0x0001
            cmp bx, 0x0000
            jne decrement1
        sub ax, 0x0001
        cmp ax, 0x0000
        jne decrement
    ret

return:
    ret

gameOver:
    ; move cursor to the text position
    mov ah, 0x02
    mov bh, 0x00
    mov dh, 0x11
    mov dl, 0x00
    int 0x10

    ; reset the variables
    mov byte [vertical], 0x01
    mov byte [horizontal], 0x00
    mov word [score], 0x0000
    mov dword [scoreString+0x0008], '    '
    mov byte [appleFlag], 0x00
    mov word [tailCoordinatesOffset], 0xFFFE
    mov word [headCoordinatesOffset], 0xFFFE

    mov si, gameOverString
    call write_string_on_screen
    waitForRespond:
        call readKey
        jz waitForRespond
        call removeKey

        cmp al, 0x31 ; '1'
        je start

        cmp al, 0x30 ; '0'
        jne waitForRespond
        mov ah, 0x22
        int 0x21
    hlt

;args : [si = address to string (must end in 0 to stop writing)]
write_string_on_screen:
    push ax
    push bx
    push si

    loop_string_bytes:
        mov ah, 0x0E
        lodsb
        mov bh, 0x00
        mov bl, 0x07
        int 0x10

        cmp byte [si], 0x00
        jne loop_string_bytes

    pop si
    pop bx
    pop ax
    
    ret

vertical : db 0x01 ; 1 = down, -1 = up
horizontal : db 0x00 ; 1 = right, -1 = left
tailCoordinatesOffset : dw 0xFFFE
headCoordinatesOffset : dw 0xFFFE
growFlag : db 0x00 ; 1 = snake is growing, 0 = snake isn't growing
appleFlag : db 0x00 ; 1 = apple exists, 0 = apple doesn't exist
score : dw 0x0000
scoreString : db 'score :      ', 0x00
gameOverString : db 'GAME OVER!, if you want to play again press 1 & if you want to exit press 0', 0x00
seed : dw 0x0000
snake_file_string : db "SNAKE   BIN", 0x00