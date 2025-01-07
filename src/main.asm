; x86 Architecture OS
; _________________________________________
; Start of OS code:

; BIOS puts OS at address 7C00. The ORG directive tells the assembler to calculate all memory offsets starting at 7C00
org 0x7C00 

; Tell assembler to emit 16-bit code, which is necessary for real mode used by early boot processes
bits 16

main: 
    ; Halt the CPU, stopping further execution
    hlt

.hlt:
    ; Label for an infinite loop to keep the CPU halted
    jmp .hlt ; this puts the CPU in an infinite loop

; This calculates the number of bytes from the start of this section to the current position
; Then, it pads the rest of the first sector (510 bytes - current size) with zeros
; Finally, it ensures the boot sector ends with the boot signature 0xAA55
times 510-($-$$) db 0
dw 0AA55h



; NOTES
; _________________________________________
; How the BIOS finds an OS (Legacy Booting):
; - BIOS loads the first sector (512 bytes) of each bootable device into memory at location 0x7C00
; - BIOS checks for the 0xAA55 signature at the end of this sector
; - If the signature is found, the code at 0x7C00 executes, and the OS booting process begins

; _________________________________________
; Directive VS Instruction:
; ## Directives ##
; - Directives are commands to the assembler about how to assemble the code, not part of the runtime execution
; - They can control memory layout, data definitions, and program structure
; - Examples include ORG, DB, DW, TIMES which vary across different assemblers like NASM, MASM, etc.
; ## Instructions ##
; - These are the actual operations the CPU will perform at runtime
; - Instructions like MOV, ADD, JMP directly correspond to machine code that the CPU understands

; _________________________________________
; ORG (Directive):
; - Sets the origin address for the code. Here, it tells the assembler to start at 0x7C00, where the BIOS expects to find boot code
; - All labels and addresses are calculated relative to this starting point

; _________________________________________
; DB (Directive) -> byte1, byte2, byte3...
; - Used to define one or more bytes in memory. Useful for defining data or padding

; _________________________________________
; DW (Directive) -> word1, word2, word3...
; - Defines one or more 16-bit words. Words are stored in little-endian format in x86 architecture

; _________________________________________
; TIMES (Directive) -> number instruction/data:
; - This directive repeats the following instruction or data a specified number of times, useful for padding or initializing arrays

; _________________________________________
; $:
; - Represents the current address in the assembly code where this symbol is used

; _________________________________________
; $$:
; - Represents the beginning address of the current section, useful for calculating sizes or offsets within a section

