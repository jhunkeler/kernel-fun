section .text
align 4
global khalt
global kmain
global kend
global interrupt_handler

extern idt_init
extern pio_read
extern outb

extern ckmain
extern interrupt_handler

khalt:
    push ebp
    mov ebp, esp

    hlt

    leave
    ret

kmain:
    push ebp
    mov ebp, esp

    call idt_init
    call ckmain
    hlt

    mov esp, ebp
    pop ebp
    ret

section .data
%include 'constants.asm'

message: db 'Kernel programming is fun!', 0
message2: db 'This is a test.', 0

section .bss
kprint_delay: resb 1
kend: resb 1
