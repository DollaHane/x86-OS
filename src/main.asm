; x86 Architecture OS
; _________________________________________
; Start of OS code:

; BIOS puts OS at address 7C00. The ORG directive tells the assembler to calculate all memory offsets starting at 7C00
org 0x7C00 

; Tell assembler to emit 16-bit code, which is necessary for real mode used by early boot processes
bits 16

; Define end-of-line characters for DOS newline (carriage return followed by line feed)
%define ENDL 0x0D, 0x0A

; Start of the program
start:
    ; Jump to main to bypass any data that might be placed before the code
    ; Used at the beginning of an assembly program to ensure the execution starts at the main function, 
    ; which contains the primary logic of the program.
    jmp main

; Function to print a string to the screen
; Parameters:
;   - DS:SI points to the string to be printed
puts:
    ; These push instructions save the current values of si and ax onto the stack. This is done to preserve these registers' values since they will be modified in the function.
    push si
    push ax

.loop:
    lodsb                 ; loads a byte from the address pointed to by SI into AL. The SI register is then automatically incremented.
    or al, al             ; checks if AL is zero (null terminator) by performing an OR operation with itself, which sets the Zero flag if AL is zero.
    jz .done              ; If AL is zero (jz .done), the loop ends; otherwise, it jumps back to .loop to continue reading characters.
    mov ah, 0x0e          ; Set up for BIOS interrupt to write character to screen in teletype mode
    mov bh, 0             ; Page number (for text mode)
    int 0x10              ; Call BIOS interrupt to print character    
    jmp .loop             ; Continue loop to print next character

.done:
    pop ax                ; Restore the saved registers
    pop si                ; Restore the saved registers
    ret                   ; Return control to the caller          

; Main program execution starts here
main:
    ; Initialize data and extra segment registers to 0 for simplicity
    mov ax, 0           
    mov ds, ax
    mov es, ax

    ; Set up stack segment and stack pointer. Here, we're using the same memory where the code is loaded, but at the highest address, growing downward.
    mov ss, ax
    mov sp, 0x7C00      

    ; Print the greeting message
    mov si, msg_hello   ; Load the address of the message into SI
    call puts           ; Call the print function

    ; Halt the CPU to stop execution
    hlt

.hlt:
    ; Infinite loop to keep CPU halted, preventing boot from continuing to next sector
    jmp .hlt            

; Define the greeting message with DOS newline characters
msg_hello db "Hello X, this is DollaHane", ENDL, 0

; Pad the boot sector to 510 bytes and add boot signature
; This calculates the number of bytes from the start of this section to the current position
; Then, it pads the rest of the first sector (510 bytes - current size) with zeros
; Finally, it ensures the boot sector ends with the boot signature 0xAA55
times 510-($-$$) db 0
dw 0xAA55



; NOTES

; _________________________________________
; The following OS is built following the tutorials presented by Nanobyte
; https://www.youtube.com/watch?app=desktop&v=9t-SPC7Tczc&list=LL&index=5

; _________________________________________
; How the BIOS finds an OS (Legacy Booting):
; - BIOS loads the first sector (512 bytes) of each bootable device into memory at location 0x7C00
; - BIOS checks for the 0xAA55 signature at the end of this sector
; - If the signature is found, the code at 0x7C00 executes, and the OS booting process begins

; _________________________________________
; What is the Stack:
; - Memory accessed in a FIFO manner using "push" and "pop"
; - Used to save and return address when calling functions
; - Moves downwards
; - Needs to be placed at the beginning of the OS so that operations do not overwrite the OS

; _________________________________________
; Interupts:
; A signal which makes the processor stop what it's doing in order to handle that signal
; Can be triggered by the following:
; 1. An exception / Error (eg. dividing by zero, segmentation fault, page fault)
; 2. Hardware (eg. keyboard key pressed, timer tick, disk controller finished an operation)
; 3. Software (Through the INT instruction)

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
; LODSB, LODSW, LODSD:
; - These instructions load a byte/word/double-word from DS:SI into AL/AX/EAX, then increments SI by the number of bytes loaded

; _________________________________________
; OR (Destination, Source):
; Performs bitwise OR between source and destination, stores result in destination

; _________________________________________
; $:
; - Represents the current address in the assembly code where this symbol is used

; _________________________________________
; $$:
; - Represents the beginning address of the current section, useful for calculating sizes or offsets within a section

