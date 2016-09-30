section .text

global pio_read
global pio_write

pio_read:
    push ebp
    mov ebp, esp

    mov edx, [esp + 8]
    in al, dx

    leave
    ret

pio_write:
    push ebp
    mov ebp, esp

    mov edx, [esp + 8]
    mov al, [esp + 12]
    out dx, al

    leave
    ret
