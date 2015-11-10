.386
.model flat, stdcall
option casemap:none

include windows.inc
include kernel32.inc

includelib kernel32.lib


.data
sum dw 0
x dw 1
y dw 2

.code
start:
	mov ax, x
	mov dx, y
	add ax, dx
	mov sum, ax
	
	xor eax, eax
	push eax
	Call ExitProcess
end start