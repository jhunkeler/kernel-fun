; Interrupt Controller
PIC1         equ 0x20        ; IO base address for master PIC
PIC2         equ 0xA0        ; IO base address for slave PIC
PIC1_COMMAND equ PIC1
PIC1_DATA    equ (PIC1+1)
PIC2_COMMAND equ PIC2
PIC2_DATA    equ (PIC2+1)

ICW1_ICW4       equ 0x01     ; ICW4 (not) needed
ICW1_SINGLE     equ 0x02     ; Single (cascade) mode
ICW1_INTERVAL4  equ 0x04     ; Call address interval 4 (8)
ICW1_LEVEL      equ 0x08     ; Level triggered (edge) mode
ICW1_INIT       equ 0x10     ; Initialization - required!

ICW4_8086       equ 0x01     ; 8086/88 (MCS-80/85) mode
ICW4_AUTO       equ 0x02     ; Auto (normal) EOI
ICW4_BUF_SLAVE  equ 0x08     ; Buffered mode/slave
ICW4_BUF_MASTER equ 0x0C     ; Buffered mode/master
ICW4_SFNM       equ 0x10     ; Special fully nested (not)

; Video
CONSOLE_W equ 80
CONSOLE_H equ 25
CONSOLE_SIZE equ CONSOLE_W * CONSOLE_H * 2
VIDEO_RAM equ 0xb8000
