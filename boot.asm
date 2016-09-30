bits 32

section .text
    align 4
    dd 0x1BADB002
    dd 0x00
    dd - (0x1BADB002 + 0x00)

global start
extern kmain

start:
    cli
    mov esp, stack_top
    call marker_begin
    call kmain
    call marker_done
.hltloop:
    hlt
jmp .hltloop

marker_begin:
    mov word [VIDEO_RAM + CONSOLE_SIZE - 2], \
                0x4F << 8 | 'B' ; END OF MAIN MARKER
    ret

marker_done:
    mov word [VIDEO_RAM + CONSOLE_SIZE - 2], \
                0x4F << 8 | 'H' ; END OF MAIN MARKER
    ret

section .data

%include 'constants.asm'

section .bss
align 4
stack_bottom:
    resb 8192
stack_top:
EOK:
