nasm=nasm -f elf -g
TARGET=kernel

all: $(TARGET)

boot.o: boot.asm
	$(nasm) -o boot.o boot.asm

io.o: io.asm
	$(nasm) -o io.o  io.asm

irq.o: irq.asm
	$(nasm) -o irq.o irq.asm

kernel.o: kernel.asm
	$(nasm) -o kernel.o kernel.asm

ctest.o: ctest.c
	gcc -c -o ctest.o -m32 -O3 -nostdlib -nostdinc \
		-fno-builtin -fno-stack-protector \
		-nostartfiles -nodefaultlibs \
		-Wall -Wextra \
		ctest.c
$(TARGET): ctest.o irq.o io.o kernel.o boot.o
	ld -g -m elf_i386 -T link.ld -o $(TARGET) boot.o io.o irq.o ctest.o kernel.o

run: $(TARGET)
	qemu-system-i386 -m 8M -kernel $(TARGET)

debug: $(TARGET)
	qemu-system-i386 -d int,guest_errors -no-reboot -s -S -m 8M -kernel $(TARGET) &
	gdb -ex 'kdev' \
		-ex 'continue' \
		$(TARGET)

clean:
	rm -f kernel
	rm *.o

