;  A 16-bit DOS HelloWorld program originally by RedOx.  Produces a tiny model .com executable.

; To assemble and link from within WinAsm Studio, you must have a special 16-bit linker, 
; such as the one in the archive at this URL- http://win32assembly.online.fr/files/Lnk563.exe
; Run the archive to unpack Link.exe, rename the Link.exe file to Link16.exe and copy it
; into the \masm32\bin folder.
;
; To produce a .COM file, .model must be tiny, also you must add /tiny to the linker command line
.286
.model tiny

.code
org	07c00h
main:
	jmp short start
	nop
	
start:
	cli
	mov ax, cs
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov bp,7c00h
	mov sp,7c00h
	sti
	hlt
	
	ret
END main
	