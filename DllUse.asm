;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Name:	DllUse
;Author:	Harsha Kadekar
;Description:	The program which uses the dll
;Date:	18-11-2011
;Last Modified:	18-11-2011
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.386
.model flat,stdcall
option casemap:none

include windows.inc
include user32.inc
include kernel32.inc

includelib user32.lib
includelib kernel32.lib

.data

LibName db "DllExample.dll",0
FunctionName db "TestFunc",0
Success db "I have come out of dll",0
DllNotFound db "I m not able to find the dll you bugger!!!",0
AppName db "LoadLibrary",0
FunctionNotFound db "Hello I am not able to find the function!! Correct ur code!!",0
Entry db "Entering the dll Function",0


.data?
hLib dd ?
TextHelloAddr dd ?

.code
start:

	push OFFSET LibName
	Call LoadLibrary
	
	cmp eax, NULL
	jne MAINELSE
		push MB_OK
		push OFFSET AppName
		push OFFSET DllNotFound
		push NULL
		Call MessageBox
		jmp AFTERIF
	MAINELSE:
		mov hLib, eax
		push OFFSET FunctionName
		push hLib
		Call GetProcAddress
		
		cmp eax, NULL
		jne SECONDELSE
			push MB_OK
			push OFFSET AppName
			push OFFSET FunctionNotFound
			push NULL
			Call MessageBox
			jmp SECONDAFTERIF
		SECONDELSE:
			mov TextHelloAddr, eax
			push MB_OK
			push OFFSET AppName
			push OFFSET Entry
			push NULL
			Call MessageBox
			
			;mov TextHelloAddr, eax
			Call [TextHelloAddr]
			;mov eax, [TextHelloAddr]
			;Call eax
			
			push MB_OK
			push OFFSET AppName
			push OFFSET Success
			push NULL
			Call MessageBox
			
		SECONDAFTERIF:
			push hLib
			Call FreeLibrary
			
	AFTERIF:
	push NULL
	Call ExitProcess
end start