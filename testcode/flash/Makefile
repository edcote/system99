PROG=flash
OBJS=main.o

CC=sde-gcc
AS=sde-as
LD=sde-ld
OBJDUMP=sde-objdump
OBJCOPY=sde-objcopy

CCFLAGS=-mips32 -EB -mbranch-likely=no -msoft-float -mno-dsp -O0
ASFLAGS=-mips32 -EB -O0

LDFLAGS= -T flash.ld -Map system.map -q

all: $(PROG)

%.o: %.s
	$(AS) $(ASFLAGS) $< -o $@

%.o: %.c
	$(CC) $(CCFLAGS) -c $<

$(PROG): $(OBJS)
	$(LD) $(LDFLAGS) $(OBJS) -o $@
	$(OBJCOPY) -O binary -R .comment -R .pdr -R .reginfo -S -g $@ $@.bin
	$(OBJDUMP) -D $@ > objdump.disasm
	$(OBJDUMP) -s $@ > objdump.full

clean :
	rm -f *~ \#* *.bak *.o *.hex *.bin *.srec $(PROG) objdump* *.map $@
