OUTPUT_ARCH(aarch64)
ENTRY(_text)
SECTIONS
{
 . = 0x80000;
 .text : { *(.text) *(.text.boot)}
}
