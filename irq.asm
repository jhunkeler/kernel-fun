section .text
global idt_entry
global PIC_sendEOI
global idt_init
extern interrupt_handler

extern inb
extern outb

struc idt_entry
    .base_low:  resw 1
    .selector:  resw 1
    .zero:      resb 1
    .flags:     resb 1
    .base_high: resw 1
endstruc

%macro no_error_code_interrupt_handler 1
global interrupt_handler_%1:
interrupt_handler_%1:
    push dword 0
    push dword %1
    jmp common_interrupt_handler
%endmacro

%macro error_code_interrupt_handler 1
global interrupt_handler_%1
interrupt_handler_%1:
    push dword %1
    jmp common_interrupt_handler
%endmacro

%macro idt_set_gate 2
    ; Assign values to IDT entry at interrupt (ecx)
    ; with the offset of the interrupt handler (edx)
    mov edx, %2
    mov [idt + %1 * 8 + idt_entry.base_low], dx
    mov word [idt + %1 * 8 + idt_entry.selector], 0x8
    mov byte [idt + %1 * 8 + idt_entry.zero], 0x0
    mov byte [idt + %1 * 8 + idt_entry.flags], 0x8e
    shr edx, 16
    mov word [idt + %1 * 8 + idt_entry.base_high], dx
%endmacro

common_interrupt_handler:
    pushad
    call interrupt_handler
    popad
    add esp, 8
    iret

no_error_code_interrupt_handler 0
no_error_code_interrupt_handler 1
no_error_code_interrupt_handler 2
no_error_code_interrupt_handler 3
no_error_code_interrupt_handler 4
no_error_code_interrupt_handler 5
no_error_code_interrupt_handler 6
no_error_code_interrupt_handler 7
error_code_interrupt_handler 8
no_error_code_interrupt_handler 9
error_code_interrupt_handler 10
error_code_interrupt_handler 11
error_code_interrupt_handler 12
error_code_interrupt_handler 13
error_code_interrupt_handler 14
no_error_code_interrupt_handler 15
no_error_code_interrupt_handler 16
no_error_code_interrupt_handler 17
no_error_code_interrupt_handler 18
no_error_code_interrupt_handler 19
no_error_code_interrupt_handler 20
no_error_code_interrupt_handler 21
no_error_code_interrupt_handler 22
no_error_code_interrupt_handler 23
no_error_code_interrupt_handler 24
no_error_code_interrupt_handler 25
no_error_code_interrupt_handler 26
no_error_code_interrupt_handler 27
no_error_code_interrupt_handler 28
no_error_code_interrupt_handler 29
no_error_code_interrupt_handler 30
no_error_code_interrupt_handler 31
; 32 unused
no_error_code_interrupt_handler 33


PIC_sendEOI:
    ret

PIC_remap:
    ;arguments:
    ;offset1 - vector offset for master PIC
    ;          vectors on the master become offset1..offset1+7
    ;offset2 - same for slave PIC: offset2..offset2+7

    push ebp
    mov ebp, esp

    sub ebp, 8

    push PIC1_DATA
    call inb
    mov [ebp - 4], al           ; save PIC1 mask

    push PIC2_DATA
    call inb
    mov [ebp - 8], al           ; save PIC2 mask

    push ICW1_INIT+ICW1_ICW4    ; initialization sequence (cascade)
    push PIC1_COMMAND
    call outb

    push ICW1_INIT+ICW1_ICW4    ; initialization sequence (cascade)
    push PIC2_COMMAND
    call outb

    push word [ebp + 8]         ; ICW2: Master PIC vector offset
    push PIC1_DATA
    call outb

    push word [ebp + 12]        ; ICW2: Save PIC vector offset
    push PIC2_DATA
    call outb

    push 0x4                    ; ICW3: tell Master PIC there is a slave PIC at IRQ2 (0000 0100)
    push PIC1_DATA
    call outb

    push 2                      ; ICW3: tell Slave PIC its cacade identity (0000 0010)
    push PIC2_DATA
    call outb

    push ICW4_8086
    push PIC1_DATA
    call outb

    push ICW4_8086
    push PIC2_DATA
    call outb

    push word [ebp - 4]
    push PIC1_DATA
    call outb

    push word [ebp - 8]
    push PIC2_DATA
    call outb

    add ebp, 8
    leave
    ret

idt_init:
    push ebp
    mov ebp, esp

    mov al, 0x0                             ; idt's initial value
    mov ecx, idt_entry_size * 256 - 1       ; Size of: idt
    mov edi, idt                            ; pointer to: idt
    cld                                     ; clear direction flag
    rep stosb                               ; fill array with zeros


    idt_set_gate 33, interrupt_handler_33   ; implement INT 21

    mov ebx, idt_entry_size * 256 - 1       ; size of: idt - 1
    mov eax, idt                            ; pointer to: idt

    mov [idt_ptr], ebx                      ; describe ITDR limit
    mov [idt_ptr + 2], eax                  ; describe ITDR offset

    push idt_ptr
    call idt_load                           ; load IDTR register

    leave
    ret



idt_load:
    push ebp
    mov ebp, esp

    mov edx, [esp + 8]
    lidt [edx]

    leave
    ret


section .data
%include 'constants.asm'

section .bss
align 4

idt_ptr:
    resw 1
    resd 1

idt:
    resb idt_entry_size * 256


