; x86 Architecture OS
; _________________________________________
; Start of OS code:

org 0x7C00 

bits 16

%define ENDL 0x0D, 0x0A

; ______________________________________________________________________________
; FAT12 Header:
jmp short start
nop

bdb_oem:                    db 'MSWIN4.1'           ; 8 bytes
bdb_bytes_per_sector:       dw 512
bdb_sectors_per_cluster:    db 1
bdb_reserve_sectors:        dw 1
bdb_fat_count:              db 2
bdb_dir_entries_count:      dw 0E0h
bdb_total_sectors:          dw 2880                 ; 2880 * 512 = 1.44MB
bdb_media_descriptor_type:  db 0F0h                 ; F0 = 3.5" floppy disk
bdb_sectors_per_fat:        dw 9                    ; 9 sectors/fat
bdb_sectors_per_track:      dw 18
bdb_heads:                  dw 2
bdb_hidden_sectors:         dd 0
bdb_large_sector_count:     dd 0   

; extended boot record
ebr_drive_number:           db 0                    ; 0x00 floppy, 0x80 hdd
                            db 0                    ; reserved
ebr_signature:              db 29h
ebr_volume_id:              db 12h, 34h, 56h, 78h   ; serial number
ebr_volume_label:           db 'NANOBYTE OS'        ; 11 bytes, padded with space
ebr_system_id:              db 'FAT12  '            ; 8 bytes


; ______________________________________________________________________________
; MAIN FUNCTION:
start:
    jmp main

puts:
    push si               ; si will be used to walk through the string, changing its value.
    push ax               ; ax (specifically al for the character and ah for the BIOS call) will be modified during the loop.

.loop:
    lodsb                 ; Loads a byte from the address [DS:SI] into AL, then automatically increments SI to point to the next byte. This effectively moves through the string character by character.
    or al, al             ; checks if AL is zero (null terminator) by performing an OR operation with itself, which sets the Zero flag if AL is zero.
    jz .done              ; jz = (Jump if Zero) - If AL is zero (jz .done), the loop ends; otherwise, it jumps back to .loop to continue reading characters.
    mov ah, 0x0e          ; Set up for BIOS interrupt to write character to screen in teletype mode
    mov bh, 0             ; Sets the page number for text mode to 0 (default).
    int 0x10              ; This invokes the BIOS interrupt service routine to display the character represented in AL on the screen.
    jmp .loop             ; Continue loop to print next character

.done:
    pop ax                ; Restore the saved registers
    pop si                ; Restore the saved registers
    ret                   ; Return control to the caller          

main:
    ; Initialize data and extra segment registers to 0 for simplicity
    mov ax, 0           
    mov ds, ax
    mov es, ax

    ; Set up stack segment and stack pointer. Here, we're using the same memory where the code is loaded, but at the highest address, growing downward.
    mov ss, ax
    mov sp, 0x7C00    

    ; Read something from the floppy disc. BIOS should set DL to drive number
    mov [ebr_drive_number], dl
    
    mov ax, 1             ; LBA=1, second sector from disk
    mov cl, 1             ; 1 sector to read
    mov bx, 0x7E00        ; data should be after the bootloader
    call disk_read

    ; Print the greeting message
    mov si, msg_hello     ; Load the "msg_hello" string into SI
    call puts             ; Call the print function

    ; Halt the CPU to stop execution
    cli                   ; disable interups, this way CPU cant get out of "halt" state
    hlt

floppy_error:
    mov si, msg_read_failed
    call puts
    jmp wait_key_and_reboot

wait_key_and_reboot:
    mov ah, 0
    int 16h               ; wait for keypress
    jmp 0FFFFh:0          ; jump to beginning of BIOS, should reboot

.halt:
    cli                   ; disable interups, this way CPU cant get out of "halt" state
    hlt


; ______________________________________________________________________________
; Disk Routines:

; Converts an LBA address to a CHS Address
; Parameters:
;   - ax: LBA Address
; Returns:
;   - cx [bits 0-5] sector number
;   - cx [bits 6-15] cylinder
;   - dh: head

lba_to_chs:

    push ax
    push dx

    xor dx, dx                              ; dx = 0
    div word [bdb_sectors_per_track]        ; ax = LBA / SectorsPerTrack
                                            ; dx = LBA % SectorsPerTracl

    inc dx                                  ; dx = (LBA % SectorsPerTrack + 1) = sector
    mov cx, dx                              ; cx = sector

    xor dx, dx                              ; dx = 0
    div word [bdb_heads]                    ; ax = (LBA / SectorsPerTrack) / Heads = cylinder
                                            ; dx = (LBA / SectorsPerTrack) % Heads = head
  
    mov dh, dl                              ; dh = head
    mov ch, al                              ; ch = cylinder (lower 8 bits)
    shl ah, 6
    or cl, ah                               ; put upper 2 bits of cylinder in CL

    pop ax
    mov dl, al                              ; restore DL
    pop ax
    ret


; ______________________________________________________________________________
; Reads sectors of a disk:
; Parameters:
;   - ax: LBA Address
;   - cl: number of sectors to read (up to 128 bits)
;   - dl: drive number
;   - es:bx: memory address where to store read data

disk_read:
    push ax                                 ; save registers we will modify
    push bx
    push cx
    push dx
    push di 

    push cx                                 ; temporarily save CL to prevent it from being written over (number of sectors to read)
    call lba_to_chs                         ; compute CHS
    pop ax                                  ; AL = number of sectors to read

    mov ah, 02h
    mov di, 3                               ; retry count

    ; Because floppy discs are unreliable, it is recommended to try read at least three times
    ; We can do this by calling a loop:

.retry:
    pusha                                   ; save all registers, we dont know what the bios modifies
    stc                                     ; set carry flag, some BIOS's dont set it
    int 13h                                 ; carry flag cleared => success
    jnc .done                               ; jump if carry not set

    ; read failed
    popa
    call disk_reset

    dec di
    test di, di
    jnz .retry

.fail:
    ; all attempts failed
    jmp floppy_error

.done:
    popa

    pop di 
    pop dx
    pop cx
    pop bx
    pop ax                                 ; restore registers modified
    ret 


; ______________________________________________________________________________
; Resets disk controller
; Parameters:
;   - dl: drive number

disk_reset:
    pusha
    mov ah, 0
    stc
    int 13h
    jc floppy_error
    popa
    ret


; ______________________________________________________________________________
; Messages to print:

msg_hello:                  db "Hello X, this is DollaHane's OS", ENDL, 0
msg_read_failed:            db "Read from disk failed!", ENDL, 0

times 510-($-$$) db 0
dw 0xAA55