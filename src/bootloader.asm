section mbr
	cli
	xor ax, ax
	mov ds, ax
	mov es, ax
	mov ss, ax
	; NOTE: 0x500 to 0x7BFF (29.75 KiB) should be usable as stack
	mov sp, 0x7C00
	sti

	mov [_boot_drive], dl

	; load the rest of the program into memory
	mov si, _main_da_packet
	mov ah, 0x42
	int 0x13
	jnc .read_success
	call _failed_disk_read

	mov si, _failed_lba_msg
	call _print_str

	; fallback to CHS addressing if LBA didn't work
	mov ah, 0x02
	mov al, _code_num_sectors
	xor ch, ch
	mov cl, 2 ; start sector (1-based)
	xor dh, dh
	mov dl, [_boot_drive]
	mov bx, _end_of_mbr ; destination
	int 0x13
	jnc .read_success
	call _failed_disk_read
	jmp _halt

	.read_success:
	cmp word [_signature], SIGNATURE
	je .verification_success
	mov si, _failed_signature_verification_msg
	call _print_str
	jmp _halt

	.verification_success:
	; set video mode to 0x13 (320x200 pixels with a 256 color palette)
	mov ah, 0
	mov al, 0x13
	int 0x10

	; enter protected mode
	cli
	lgdt [_gdtr]
	mov eax, cr0
	or al, 1
	mov cr0, eax
	; NOTE: '_entry32' is located in `kernel.asm`
	jmp dword 0x08:_entry32

_halt:
	hlt
	jmp _halt

_boot_drive: db 0
_failed_lba_msg: db "Failed to use LBA, trying with CHS addressing...", 0x0D, 0x0A, 0
_failed_signature_verification_msg: db "Failed to verify signature", 0x0D, 0x0A, 0

_failed_disk_read:
	movzx ax, ah
	mov di, _failed_disk_read_msg + _failed_disk_read_msg_ah
	call _format_ax

	mov si, _failed_disk_read_msg
	call _print_str

	ret
_failed_disk_read_msg: db "Failed to read disk: ah=   "
_failed_disk_read_msg_ah: equ $-_failed_disk_read_msg
db 0x0D, 0x0A, 0

; outputs 'ax' converted to a string to [di - 1], [di - 2], ...
_format_ax:
	mov bx, 10
	.loop:
		xor dx, dx
		div bx
		add dl, '0'
		dec di
		mov [di], dl
		test ax, ax
	jnz .loop
	ret

; prints the null-terminated string at [si]
_print_str:
	mov ah, 0x0E
	.loop:
    lodsb
		cmp al, 0
		je .ret
    int 0x10
	jmp .loop
	.ret:
	ret

static_assert {code_size % 512 == 0}
_code_num_sectors: equ code_size / 512
; some BIOSes don't support reading more than 18 sectors at a time
static_assert {_code_num_sectors <= 18}

struc disk_address_packet_t
	.size: resb 1
	.unused: resb 1
	.num_sectors: resb 2
	.buffer: resb 4
	.lba: resb 8
endstruc
align 4
_main_da_packet:
istruc disk_address_packet_t
	at .size, db 16
	at .unused, db 0
	at .num_sectors, dw _code_num_sectors
	at .buffer
		dw _end_of_mbr
		dw 0
	at .lba
		dd 1
		dd 0
iend

struc gdt_entry_t
	.limit_low: resb 2
	.base_low: resb 2
	.base_middle: resb 1
	.access: resb 1
	.granularity: resb 1
	.base_high: resb 1
endstruc
_gdtr:
	.limit dw _gdt_end - _gdt - 1
	.base dd _gdt
; NOTE: The code and data segments span only the first MiB of memory. If more
;       memory needs to be accessed, the A20 line must be enabled.
_gdt:
; null descriptor
dq 0
; code segment
istruc gdt_entry_t
	at .limit_low, dw 0xFF
	at .base_low, dw 0
	at .base_middle, db 0
	at .access, db 0b1001_1001
	at .granularity, db 0b1100_0000
	at .base_high, db 0
iend
; data segment
istruc gdt_entry_t
	at .limit_low, dw 0xFF
	at .base_low, dw 0
	at .base_middle, db 0
	at .access, db 0b1001_0011
	at .granularity, db 0b1100_0000
	at .base_high, db 0
iend
_gdt_end:

; fake bootable partition entry (some BIOSes refuse to boot without one)
times 446-($-$$) db 0
db 0x80
db 0, 1, 0
db 0x83
db 0, 1, 0
dd 0
dd 1

times 510-($-$$) db 0
; boot signature
dw 0xAA55
_end_of_mbr:
