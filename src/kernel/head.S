.section ".text.boot"

.globl _text
_text:
    MRS X0, MPIDR_EL1
    AND X0, X0, #0xFF
    MOV X0, 0
    CBZ X0, relocate
halt:
    WFI
    B halt
relocate:
    MOV X0, 0