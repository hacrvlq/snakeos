%include "macros.mac"

section mbr vstart=0x7C00
; code and initialized data
section code vfollows=mbr
; uninitialized data
section bss vfollows=code nobits

bits 32
%include "kernel.asm"
%include "game.asm"

section code
; checked by the bootloader to ensure that the code section has been loaded
; correctly into memory
%define SIGNATURE 2025
_signature: dw SIGNATURE

align 512
code_size: equ $-$$

section bss
bss_size: equ $-$$

; ensure there are still 80.5 KiB available for the stack
static_assert {code_size + bss_size <= 400 * 1024}

bits 16
%include "bootloader.asm"
