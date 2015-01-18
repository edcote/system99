MEMORY
{
    ram   : ORIGIN = 0x00000000, LENGTH = 64k
    rom   : ORIGIN = 0x08000000, LENGTH = 1k
    flash : ORIGIN = 0x09000000, LENGTH = 2048k
}
 
SECTIONS
{

    .text :
    {
        . = ALIGN(4);
        *(.text)
        _text_end = . ;
    } > flash

    .rodata :
    {
        . = ALIGN(4);
        *(.rodata)
    } > flash
 
    /* fix me */
    .data : 
        AT ( ADDR (.text) + SIZEOF (.text) + SIZEOF(.rodata) ) 
    {
        . = ALIGN(4);
        _data = . ;
        *(.data)
        _data_end = . ;
    } > ram
    
    .bss :
    {
        *(.bss)
    } > ram
    
}
