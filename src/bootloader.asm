section mbr
	cli
	xor ax, ax
	mov ds, ax
	mov es, ax
	mov ss, ax
	; NOTE: 0x500 to 0x7BFF (29.75 KiB) should be usable as stack
	mov sp, 0x7C00
	sti

	; load the rest of the program into memory
	mov si, _main_da_packet
	mov ah, 0x42
	int 0x13
	jc _failed_disk_read
	cmp word [_signature], SIGNATURE
	jne _failed_disk_read

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

_failed_disk_read:
	movzx ax, ah
	mov di, _failed_disk_read_msg + _failed_disk_read_msg_len
	call _format_ax

	mov si, _failed_disk_read_msg
	mov ah, 0x0E
	mov cx, _failed_disk_read_msg_len
	.loop:
    lodsb
    int 0x10
	loop .loop

	.hang:
	hlt
	jmp .hang
_failed_disk_read_msg: db "failed at reading disk: ah=   "
_failed_disk_read_msg_len: equ $-_failed_disk_read_msg

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
	; some BIOSes don't support reading more than 18 sectors at a time
	static_assert {code_size / 512 <= 18}
	static_assert {code_size % 512 == 0}
	at .num_sectors, dw code_size / 512
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

times 510-($-$$) db 0
; boot signature
dw 0xAA55
_end_of_mbr:
