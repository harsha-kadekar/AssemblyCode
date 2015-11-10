.386
.model flat, stdcall
option casemap:none

include windows.inc
include kernel32.inc
include msvcrt.inc
include user32.inc

includelib  msvcrt.lib
includelib kernel32.lib
includelib user32.lib
;includelib ..\SortingAlgorithms.lib

.data
LibName db "SortingAlgorithms.dll",0
FunctionName db "InsertionSort",0
;DummyName db "TestFunc"
DllNotFound db "I m not able to find the dll you bugger!!!",0
FunctionNotFound db "Hello I am not able to find the function!! Correct ur code!!",0
aiTest  DWORD   9, 8, 7, 6, 5, 4, 3, 19, 1, 31, 0
szFmt   DB      '%d ', 0h
AppName DB "SortUse",0

.data?
hLib dd ?
InsertionSortAddr dd ?


   ; printf format spec

.code
;InsertionSort PROTO pArray:DWORD, nSize:DWORD

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
			mov InsertionSortAddr, eax    
			push    11    
			push    offset aiTest    
			call    [InsertionSortAddr]
			        
	
			; print the array now    
			mov ecx, 11    
			mov esi, offset aiTest        
	
			print_loop: 
				cmp ecx, 0                
				je  loop_exit                                
				; printf("%d ", aiTest[ecx*4]);                
				mov eax, ecx                
				imul eax, 4                
				add eax, esi                                
				push eax                
				push offset szFmt                
				call crt_printf                                
				dec ecx                                
				jmp print_loop                        
			loop_exit:
			
		SECONDAFTERIF:
			push hLib
			Call FreeLibrary
	AFTERIF:  
	
	push NULL                
	call ExitProcess                                     
end start