.286
.model TINY

.code
org	07c00h

main:
	jmp short start
	nop

start:
	cli
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov ss, ax
	mov bp, 7c00h
	mov sp, 7c00h
	sti
	
	hlt
	
	ret

END main