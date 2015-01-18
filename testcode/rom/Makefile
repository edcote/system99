PROG=rom
OBJS=rom.o

CC=sde-gcc
AS=sde-as
LD=sde-ld
OBJDUMP=sde-objdump
OBJCOPY=sde-objcopy

CCFLAGS=-mips32 -EB -mbranch-likely=no -msoft-float -mno-dsp -O0
ASFLAGS=-mips32 -EB -O0

LDFLAGS= -T rom.ld -Map system.map

all: $(PROG)

%.o: %.s
	$(AS) $(ASFLAGS) $< -o $@

%.o: %.c
	$(CC) $(CCFLAGS) -c $<

$(PROG): $(OBJS)
	$(LD) $(LDFLAGS) $(OBJS) -o $@
	$(OBJCOPY) -O binary --change-section-address .text=0x00000000 -R .comment -R .pdr -R .reginfo $@ $@.bin
	$(OBJCOPY) -O ihex   --change-section-address .text=0x00000000 -R .comment -R .pdr -R .reginfo $@ $@.hex
	$(OBJDUMP) -d $@ > objdump.disasm
	$(OBJDUMP) -s $@ > objdump.full

clean :
	rm -f *~ \#* *.bak *.o *.hex *.bin *.srec *.mif $(PROG) objdump* *.map $@
