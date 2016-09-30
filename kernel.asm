section .text
align 4
global kmain
global interrupt_handler
extern idt_init
extern pio_read
extern pio_write

interrupt_handler:
    mov ebx, [esp + 34]
    shr ebx, 16
    cmp ebx, 0x21
    je .int21

    jmp .end

.int21:

    cmp ah, 0x1
    je .int21.kprint
    jmp .end

.int21.kprint:
    ;sub esp, 4
    ;mov [esp - 4], bx

    ;shr bx, 8
    ;push word bx

    ;mov bx, [esp - 4]
    ;and bx, 0xff
    ;push bx

    ;call screen_gotoxy
    ;add esp, 8

    push edx
    call kprint
    add esp, 4

.end:
    ret

cursor_move:
    push ebp
    mov ebp, esp

    sub ebp, 4
    call screen_getxy
    mov [ebp - 4], eax

    push 0x3D4
    push 14
    call pio_write

    mov ebx, [ebp + 4]
    shr ebx, 8
    push 0x3D5
    push word [ebx]
    call pio_write

    push 0x3D4
    push 15
    call pio_write

    mov ebx, [ebp + 4]
    push 0x3D5
    push word [ebx]
    call pio_write

    add ebp, 4
    leave
    ret

screen_fill:
    ; = purpose
    ; Fills the screen with a character and color
    ;
    ; = stack arguments (order of use)
    ; push ' '      ; character
    ; push 0x07     ; color attribute

    push ebp
    mov ebp, esp

    xor eax, eax                ; clear eax
    mov eax, [ebp + 8]          ; get character
    shl eax, 8                  ; shift character into MSB
    or eax, [ebp + 12]          ; set color attribute

    mov ecx, CONSOLE_SIZE       ; use entire screen
    mov edi, screen_buffer      ; destination = screen_buffer
    cld                         ; will increment esi and edi
    rep stosw                   ; char+color -> screen_buffer

    mov esp, ebp
    pop ebp

    ret

screen_refresh:
    push ebp
    mov ebp, esp
    pusha

    mov ecx, CONSOLE_SIZE       ; use entire screen
    mov esi, screen_buffer      ; source = screen_buffer
    mov edi, VIDEO_RAM          ; destination = video RAM
    cld                         ; will increment esi and edi
    rep movsw                   ; char+color -> screen_buffer

    popa
    mov esp, ebp
    pop ebp
    ret

screen_gotoxy:
    push ebp
    mov ebp, esp
    pusha

    ; y * width + x
    mov ebx, CONSOLE_W * 2
    mov eax, [ebp + 12]
    mul ebx
    add eax, [ebp + 8]
    mov [screen_pos], eax

    popa
    leave
    ret

screen_getxy:
    push ebp
    mov ebp, esp

    mov eax, [screen_pos]

    leave
    ret

screen_updatexy:
    push ebp
    mov ebp, esp

    add word [screen_pos], 2

    cmp word [screen_pos], CONSOLE_SIZE
    call screen_scroll_up

    leave
    ret

screen_scroll_up:
    push ebp
    mov ebp, esp

    nop

    leave
    ret

screen_scroll_down:
    push ebp
    mov ebp, esp

    nop

    leave
    ret


kprint:
    ; = purpose
    ; Writes a buffer to the screen
    ;
    ; = globals
    ; kprint_delay:   if != 0; echo slowly
    ;
    ; = stack arguments (order of use)
    ; push buffer

    push ebp
    mov ebp, esp

    xor ebx, ebx
    xor esi, esi
    xor edi, edi

    mov esi, [ebp + 8]          ; source buffer
    mov edi, screen_buffer      ; output to screen buffer
    mov ebx, [screen_pos]       ; get current screen position
    add edi, ebx                ; move to current screen position
    mov ecx, 0xff               ; delay counter

.write:

    cmp byte [kprint_delay], 0  ; determine if we want a delay
    je .nodelay                 ;   if kprint_nodelay == 0:
                                ;       nodelay()
                                ;   else:
                                ;       delay()

.delay:
    dec ecx                     ; while ecx != 0: ecx--
    call screen_refresh
    jne .delay

.nodelay:
    mov ebx, [esi]              ; get value from source buffer
    mov [edi], bl               ; write value to screen buffer
    inc esi                     ; next char in source buffer
    add edi, 2                  ; skip over screen attribute byte
    call screen_updatexy        ; update screen_pos

    cmp bl, 0                   ; if ch != 0: write
    jne .write

    call screen_refresh         ; dump screen buffer to video ram

    leave
    ret

kputc:
    push ebp
    mov ebp, esp

    mov esi, [screen_pos]
    mov edi, screen_buffer
    add edi, esi

    mov [edi], dl
    call screen_updatexy
    call screen_refresh

    leave
    ret

kprintnl:
    push ebp
    mov ebp, esp

    nop

    leave
    ret

kmain:
    push ebp
    mov ebp, esp

    mov byte [screen_pos], 2    ; Initialize screen position
    ;call cursor_move

    call idt_init

                                ; Fill screen with
    push ' '               ; spaces &&
    push 0x07                   ; white forground on blue background
    call screen_fill            ; fill the screen buffer
    call screen_refresh         ; dump screen buffer to video ram

    ;push 12
    ;push 30
    ;call screen_gotoxy

    ;mov byte [kprint_delay], 1  ; tell kprint to delay writes
    push message                ; push message address as argument
    call kprint                 ; print message

    call kprintnl

    mov dl, 'A'
    call kputc

    mov word [VIDEO_RAM + CONSOLE_SIZE - 6], \
                0x4F << 8 | 'I' ; END OF MAIN MARKER
    ;mov ah, 1
    ;mov bh, 2
    ;mov bl, 2
    ;mov edx, message2
    ;int 21h ; here goes nothing

    mov word [VIDEO_RAM + CONSOLE_SIZE - 6], \
                0x2F << 8 | 'I' ; END OF MAIN MARKER

    mov word [VIDEO_RAM + CONSOLE_SIZE - 4], \
                0x2F << 8 | 'K' ; END OF MAIN MARKER

    mov esp, ebp
    pop ebp
    ret

section .data
%include 'constants.asm'

message: db 'Kernel programming is fun!', 0
message2: db 'This is a test.', 0

section .bss
kprint_delay: resb 1
screen_pos: resd 1
screen_buffer: resb CONSOLE_SIZE
screen_buffer_end:

