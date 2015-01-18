MEMORY
{
    rom   : ORIGIN = 0x08000000, LENGTH = 4k
}
 
SECTIONS
{
    .text :
    {
        . = ALIGN(4);
        *(.text)
        _text_end = . ;
    } > rom
}
