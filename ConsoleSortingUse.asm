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
;includelib SortingAlgorithms.lib
;includelib ..\SortingAlgorithms.lib

.data
LibName db "SortingAlgorithms.dll",0
FunctionName db "InsertionSort",0
FunctionName2 db "MergeSort",0
FunctionName3 db "BubbleSort",0
FunctionName4 db "QuickSort",0
FunctionName5 db "HeapSort", 0
DllNotFound db "I m not able to find the dll you bugger!!!",0
FunctionNotFound db "Hello I am not able to find the function!! Correct ur code!!",0
;aiTest  DWORD   9, 8, 7, 6, 5, 4, 3, 19, 1, 31, 0
aiTest DWORD 100, 4, 6, 5, 89, 20, 1, 67, 93, 7, 88, 45, 32, 60
;aiTest DWORD 5,6
szFmt   DB      '%d ',0dh,0ah, 0
szFmt2 DB '%s',0dh,0ah,0
AppName DB "SortUse",0
temp DWORD 0

.data?
hLib dd ?
InsertionSortAddr dd ?
MergeSortAddr dd ?
BubbleSortAddr dd ?
QuickSortAddr dd ?
HeapSortAddr dd ?


   ; printf format spec

.code
;InsertionSort PROTO pArray:DWORD, nSize:DWORD

start:

	push OFFSET LibName
	Call LoadLibrary
	
	cmp eax, NULL
	jne MAINELSE
		push OFFSET DllNotFound
		push OFFSET szFmt2
		Call crt_printf
		jmp AFTERIF
	MAINELSE:
	
		mov hLib, eax
		;push OFFSET FunctionName
		;push OFFSET FunctionName2
		;push OFFSET FunctionName3
		;push OFFSET FunctionName4
		push OFFSET FunctionName5
		push hLib
		Call GetProcAddress
		
		cmp eax, NULL
		jne SECONDELSE
			push OFFSET FunctionNotFound
			push OFFSET szFmt2
			Call crt_printf
			jmp SECONDAFTERIF
		SECONDELSE:
			;mov InsertionSortAddr, eax    
			;mov MergeSortAddr, eax
			;mov BubbleSortAddr, eax
			;mov QuickSortAddr, eax
			mov HeapSortAddr, eax
			;push    11
			;push 10
			;push 14
			push 13
			;push 2
			;push 1   
			push 0 
			push    offset aiTest
			Call [HeapSortAddr]
			;Call [QuickSortAddr]
			;Call [BubbleSortAddr]
			;Call [MergeSortAddr]    
			;call    [InsertionSortAddr]
			;Call InsertionSort        
			
			; print the array now    
			;mov ecx, 11
			;mov ecx, 11
			mov ecx, 14
			;mov ecx, 2
			dec ecx    
			mov esi, offset aiTest
			;mov esi, pArray
			assume esi:ptr DWORD        
	
			print_loop: 
				cmp ecx, 0                
				jl  loop_exit                                
				; printf("%d ", aiTest[ecx*4]);                
				mov eax, ecx                
				imul eax, 4                
				;add eax, esi                                
				;push eax
				push [eax+esi]
				mov temp, ecx
				;add eax, esi
				;push eax                
				push offset szFmt                
				call crt_printf
				mov ecx, temp                                
				dec ecx                                
				jmp print_loop                        
			loop_exit:
			
		SECONDAFTERIF:
			push hLib
			Call FreeLibrary
	AFTERIF: 
	
	push MB_OK
	push OFFSET LibName
	push OFFSET LibName
	push NULL
	Call MessageBox 
	
	push NULL                
	call ExitProcess                                     
end start