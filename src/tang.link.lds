OUTPUT_ARCH(aarch64)
ENTRY(_text)
SECTIONS
{
.text : { *(.text) *(.text.boot)}
}
