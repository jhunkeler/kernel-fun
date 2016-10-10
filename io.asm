section .text

global inb
global outb

inb:
    mov edx, [esp + 4]
    in al, dx
    ret

outb:
    mov al, [esp + 8]
    mov edx, [esp + 4]
    out dx, al
    ret
