;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Name:	SortingAlgorithms
;Author:	Harsha Kadekar
;Descripton:	This Dll has many algorithms which can be used in our other programs
;Date:	20-1-2012
;Last Modified:	23-2-2012
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.386
.model flat,stdcall

option casemap:none

include windows.inc
include kernel32.inc
include user32.inc

includelib kernel32.lib
includelib user32.lib

.data
sDllName db "SortingAlgorithms",0
szFmt db "%d ",0

.data
temp3 db 512 dup(?)


.code

DllEntry proc hInstDll:HINSTANCE, reason:DWORD, reserved1:DWORD
	.if reason == DLL_PROCESS_ATTACH
		;Nothing
	.elseif reason== DLL_THREAD_ATTACH
		;Nothing
	.elseif reason== DLL_PROCESS_DETACH
		;Nothing
	.else
		;Nothing
	.endif
	
	mov eax, TRUE
	Ret
DllEntry EndP

 

InsertionSort proc pArray:DWORD, nSize:DWORD
	
	LOCAL temp:DWORD 
	
	mov ecx, 1
	mov esi, pArray
	assume esi:ptr DWORD
	
	START_WHILE:
		mov eax, nSize
		;dec eax
		cmp ecx, eax
		jge END_WHILE
		
		mov eax, ecx
		imul eax, 4
		mov ebx, [esi + eax]
		mov temp, ebx
		mov edx, ecx
		dec edx
		mov eax, temp
		mov ebx, edx
		imul ebx, 4
		;.while edx >= 0 && [esi+ebx] > eax
		START_WHILE2:
			cmp edx, 0
			jl END_WHILE2
			cmp [esi+ebx], eax
			jle END_WHILE2

			;mov eax, temp
			;mov temp2, edx
			;.if [esi+edx*4] >eax
				mov ebx, edx
				imul ebx,4
				mov eax, [esi+ebx]
				mov ebx, eax
				mov eax, edx
				inc eax
				imul eax,4
				mov [esi+eax], ebx
				dec edx
				mov ebx, edx
				imul ebx,4
				mov eax, temp
			;.endif
			jmp START_WHILE2
		END_WHILE2:
		
		mov eax, edx
		inc eax
		imul eax, 4
		mov ebx, temp
		mov [esi+eax], ebx
		inc ecx
		jmp START_WHILE
	END_WHILE:
	
	Ret
InsertionSort EndP

MergeSort proc pArray:DWORD, dStartIndex:DWORD, dEndIndex:DWORD

	LOCAL dMidIndex:DWORD
	LOCAL dTempLoc1:DWORD
	mov eax, dStartIndex
	mov edx, dEndIndex
	;dec edx
	.if eax < edx
	
		;invoke MessageBox,NULL, OFFSET sDllName, OFFSET sDllName,MB_OK
		
		
		mov eax, dStartIndex
		add eax, dEndIndex
		;mov edx, 2
		mov edx, 0
		mov ebx, 2
		div ebx
		mov dMidIndex, eax
		
		push dMidIndex
		push dStartIndex
		push pArray
		Call MergeSort
		
		;invoke MessageBox,NULL, OFFSET sDllName, OFFSET sDllName,MB_OK
		
		mov eax, dMidIndex
		inc eax
		push dEndIndex
		push eax
		push pArray
		Call MergeSort
		
		push dEndIndex
		push dMidIndex
		push dStartIndex
		push pArray
		Call Merge
	.endif
	
;	mov ecx, dEndIndex
;			;mov ecx, 14
;			;mov ecx, 2
;			;dec ecx    
;			mov esi, pArray
;			;mov esi, pArray
;			assume esi:ptr DWORD        
;	
;			print_loop: 
;				cmp ecx, dStartIndex               
;				jl  loop_exit                                
;				; printf("%d ", aiTest[ecx*4]);                
;				mov eax, ecx                
;				imul eax, 4                
;				;add eax, esi                                
;				;push eax
;				;push [eax+esi]
;				mov dTempLoc1, ecx
;				;add eax, esi
;				;push eax                
;				;push offset szFmt                
;				;call crt_printf
;				invoke wsprintf, OFFSET temp3, OFFSET szFmt, [eax+esi]
;				invoke MessageBox, NULL, OFFSET temp3, OFFSET sDllName, MB_OK
;				mov ecx, dTempLoc1                                
;				dec ecx                                
;				jmp print_loop                        
;			loop_exit:
;			
;			invoke MessageBox,NULL, OFFSET sDllName, OFFSET sDllName,MB_OK
		
	Ret
MergeSort EndP

Merge proc pArray:DWORD, dStartIndex:DWORD, dMidIndex:DWORD, dEndIndex:DWORD
	
	LOCAL pLeftArray:DWORD
	LOCAL pRightArray:DWORD
	LOCAL hLeftMemory:HANDLE
	LOCAL hRightMemory:HANDLE
	LOCAL dLeftSize:DWORD
	LOCAL dRightSize:DWORD
	LOCAL dTempLeft:DWORD
	LOCAL dTempRight:DWORD
	LOCAL dTempIndex:DWORD
	LOCAL dTempLoc1:DWORD
	LOCAL dTempLoc2:DWORD
	
	;invoke MessageBox,NULL, OFFSET sDllName, OFFSET sDllName,MB_OK
	mov ecx, dEndIndex
			;mov ecx, 14
			;mov ecx, 2
			;dec ecx    
			mov esi, pArray
			;mov esi, pArray
			assume esi:ptr DWORD        
	
;			print_loop: 
;				cmp ecx, dStartIndex               
;				jl  loop_exit                                
;				; printf("%d ", aiTest[ecx*4]);                
;				mov eax, ecx                
;				imul eax, 4                
;				;add eax, esi                                
;				;push eax
;				;push [eax+esi]
;				mov dTempLoc1, ecx
;				;add eax, esi
;				;push eax                
;				;push offset szFmt                
;				;call crt_printf
;				invoke wsprintf, OFFSET temp3, OFFSET szFmt, [eax+esi]
;				invoke MessageBox, NULL, OFFSET temp3, OFFSET sDllName, MB_OK
;				mov ecx, dTempLoc1                                
;				dec ecx                                
;				jmp print_loop                        
;			loop_exit:
	
;	invoke wsprintf, OFFSET temp3, OFFSET szFmt, dStartIndex
;	invoke MessageBox, NULL, OFFSET temp3, OFFSET sDllName, MB_OK
;	
;	invoke wsprintf, OFFSET temp3, OFFSET szFmt, dEndIndex
;	invoke MessageBox, NULL, OFFSET temp3, OFFSET sDllName, MB_OK
;	
;	invoke wsprintf, OFFSET temp3, OFFSET szFmt, dMidIndex
;	invoke MessageBox, NULL, OFFSET temp3, OFFSET sDllName, MB_OK
	
	mov eax, dEndIndex
	mov edx, dMidIndex
	;inc edx
	sub eax, edx
	mov dRightSize, eax
	
	mov eax, dMidIndex
	mov edx, dStartIndex
	sub eax, edx
	inc eax
	mov dLeftSize, eax
	
	mov eax, dRightSize
	;mov edx, 4
	imul eax,4
	
	;mov eax, dMidIndex
	;.if eax==0
	;	ret
	;.endif
	
	;invoke MessageBox,NULL, OFFSET sDllName, OFFSET sDllName,MB_OK
	
	invoke GlobalAlloc,GMEM_MOVEABLE or GMEM_ZEROINIT, eax
	mov hRightMemory, eax
	
	invoke GlobalLock,hRightMemory
	mov pRightArray, eax
	
	mov eax, dLeftSize
	;mov edx, 4
	imul eax, 4
	invoke GlobalAlloc,GMEM_MOVEABLE or GMEM_ZEROINIT, eax
	mov hLeftMemory, eax
	
	invoke GlobalLock,hLeftMemory
	mov pLeftArray, eax
	
	;invoke MessageBox,NULL, OFFSET sDllName, OFFSET sDllName,MB_OK
	
	mov ecx, dLeftSize
	dec ecx
	mov edx,0
	mov esi, pArray
	assume esi:ptr DWORD
	
	mov edi, pLeftArray
	assume edi:ptr DWORD
	;.while ecx >= 0
	START_WHILELEFT:
		cmp ecx, 0
		jl END_WHILELEFT
		mov eax, dStartIndex
		add eax, edx
		mov ebx, edx
		imul eax,4
		mov edx, ebx
		;mov ebx, 4
		;mul ebx
		mov ebx, [esi+eax]
		mov [edi + edx*4], ebx
		inc edx
		dec ecx
	;.endw
		jmp START_WHILELEFT
	END_WHILELEFT:
	
	;invoke MessageBox,NULL, OFFSET sDllName, OFFSET sDllName,MB_OK
	
	mov edi,pRightArray
	assume edi:ptr DWORD
	mov ecx, dRightSize
	dec ecx
	mov edx, 0
	;.while ecx >= 0
	START_WHILERIGHT:
		cmp ecx, 0
		jl END_WHILERIGHT
		mov eax, dMidIndex
		inc eax
		add eax, edx
		mov ebx, edx
		imul eax, 4
		mov edx, ebx
		;mov ebx, 4
		;mul ebx
		mov ebx, [esi+eax]
		mov [edi +edx*4], ebx
		inc edx
		dec ecx
	;.endw
		jmp START_WHILERIGHT
	END_WHILERIGHT:
	
;	invoke MessageBox,NULL, OFFSET sDllName, OFFSET sDllName,MB_OK
	 
	mov dTempLeft, 0
	mov dTempRight, 0
	;mov dTempIndex, 0
	mov eax, dStartIndex
	mov dTempIndex, eax
	 
	mov eax, dTempIndex
	mov edx, dEndIndex
	
	mov esi, pLeftArray
	assume esi:ptr DWORD
	mov edi, pRightArray
	assume edi:ptr DWORD
 
	;.while eax < edx
	START_WHILEACT:
		cmp eax, edx
		jge END_WHILEACT
		
		mov eax, dTempLeft
		mov edx, dTempRight
		
		mov ebx, [esi+ eax*4]
		mov dTempLoc1, ebx
		mov ebx, [edi+ edx*4]
		mov dTempLoc2, ebx
		mov eax, dTempLoc1
		mov edx, dTempLoc2
		.if  eax > edx
			mov eax, dTempLeft
			mov edx, dTempRight
			
			mov esi, pArray
			assume esi:ptr DWORD
			
			mov eax, dTempIndex
			mov ebx, [edi+edx*4]
			mov [esi + eax*4], ebx
			inc dTempRight
		.else
			mov eax, dTempLeft
			mov edx, dTempRight
			
			mov edi, pArray
			assume edi:ptr DWORD
			
			mov edx, dTempIndex
			mov ebx, [esi+eax*4]
			mov [edi + edx*4], ebx
			inc dTempLeft
		.endif
		
		inc dTempIndex
		
		mov eax, dTempLeft
		mov edx, dLeftSize
		
		.if eax >= edx
			mov esi, pRightArray
			mov edi, pArray
			assume esi:ptr DWORD
			assume edi:ptr DWORD
			
			mov eax, dTempRight
			mov edx, dRightSize
			;.while eax<= edx
			START_INWHILE:
				cmp eax, edx
				jge END_INWHILE
				mov eax, dTempRight
				mov edx, dTempIndex
				mov ebx, [esi+eax*4]
				mov [edi + edx*4], ebx
				inc dTempIndex
				inc dTempRight
				mov eax, dTempRight
				mov edx, dRightSize
				jmp START_INWHILE
			;.endw
			END_INWHILE:
			
			;.break
			jmp END_WHILEACT
		.endif
		
		mov eax, dTempRight
		mov edx, dRightSize
		.if eax >= edx
			mov esi, pLeftArray
			mov edi, pArray
			assume esi:ptr DWORD
			assume edi:ptr DWORD
			
			mov eax, dTempLeft
			mov edx, dLeftSize
			;.while eax<= edx
			START_INWHILE2:
				cmp eax, edx
				jge END_INWHILE2
				mov eax, dTempLeft
				mov edx, dTempIndex
				mov ebx, [esi+eax*4]
				mov [edi +edx*4], ebx
				inc dTempIndex
				inc dTempLeft
				mov eax, dTempLeft
				mov edx, dLeftSize
				jmp START_INWHILE2
			;.endw
			END_INWHILE2:
			
			;.Break
			jmp END_WHILEACT
		.endif
		
		mov eax, dTempIndex
		mov edx, dEndIndex
	
		mov esi, pLeftArray
		assume esi:ptr DWORD
		mov edi, pRightArray
		assume edi:ptr DWORD
		jmp START_WHILEACT
	;.endw
	END_WHILEACT:
	
;;	invoke MessageBox,NULL, OFFSET sDllName, OFFSET sDllName,MB_OK
	
	push pLeftArray
	Call GlobalUnlock

	push pRightArray
	Call GlobalUnlock
		
	push hLeftMemory
	Call GlobalFree
	
	push hRightMemory
	Call GlobalFree
	
	Ret
Merge EndP

BubbleSort proc pArray:DWORD, nSize:DWORD
	
	LOCAL bSwapped:DWORD
	LOCAL dTemp:DWORD
	
	mov esi, pArray
	assume esi:ptr DWORD
	
	mov bSwapped, 1
	mov ecx, nSize
	
	STARTWHILE:
		cmp bSwapped, 1
		jne ENDWHILE
		
		mov bSwapped, 0
		mov edx, 0
		
		START_FOR:
			cmp edx, ecx
			jg END_FOR
			
			mov eax, [esi + edx*4]
			mov ebx, [esi + edx*4 +4]
			cmp eax, ebx
			;cmp [esi + edx*4], [esi + edx*4 +4]
			jle AFTER_IF
				;mov dTemp, [esi +edx*4]
				mov eax, [esi+edx*4]
				mov ebx, [esi + edx*4 +4]
				mov [esi+edx*4], ebx
				;mov [esi + edx*4], [ esi +edx*4 +4]
				mov [esi+ edx*4 +4], eax
				;mov [esi +edx*4 +4], dTemp
				
				mov bSwapped, 1
			AFTER_IF:
			
			inc edx
			jmp START_FOR
		END_FOR:
		
		dec ecx
		jmp STARTWHILE
	ENDWHILE:
	
	Ret
BubbleSort EndP

QuickSort proc pArray:DWORD, dwLeft:DWORD, dwRight:DWORD
	LOCAL dwQ:DWORD
	
	mov eax, dwLeft
	mov edx, dwRight
	cmp eax, edx
	jg END_IF
		push dwRight
		push dwLeft
		push pArray
		Call Partition
		mov dwQ, eax
		
		dec eax
		push eax
		push dwLeft
		push pArray
		Call QuickSort
		
		mov eax, dwQ
		inc eax
		push dwRight
		push eax
		push pArray
		Call QuickSort
		
	END_IF:
	
	;mov eax, 0
		
	Ret
QuickSort EndP

Partition proc pArray:DWORD, dwLeft:DWORD, dwRight:DWORD

	LOCAL key:DWORD
	LOCAL i:DWORD
	LOCAL j:DWORD
	
	mov esi, pArray
	assume esi: ptr DWORD
	
	mov eax, dwRight
	;mov key, [esi + eax*4]
	mov edx, [esi + eax*4]
	mov key, edx
	mov eax, dwLeft
	dec eax
	mov i, eax
	
	mov ecx, dwLeft
	START_FOR:
		mov edx, dwRight
		dec edx
		cmp ecx, edx
		jg END_FOR
		
		mov eax, [esi+ecx*4]
		cmp eax, key
		jg AFTER_IF
			inc i
			mov eax, i
			mov edx, [esi+ eax*4]
			mov ebx, [esi+ ecx*4]
			mov [esi+ eax*4], ebx
			mov [esi+ ecx*4], edx
		AFTER_IF:
		
		inc ecx
		jmp START_FOR
	END_FOR:
	
	mov eax, i
	inc eax
	mov edx, [esi+ eax*4]
	
	mov ecx, dwRight
	mov ebx, [esi+ ecx*4]
	
	mov [esi+ eax*4], ebx
	mov [esi+ ecx*4], edx
	
	mov eax, i
	inc eax
	
	Ret
Partition EndP

HeapSort proc pArray:DWORD, lowindex:DWORD, highindex:DWORD

	LOCAL child1:DWORD
	LOCAL child2:DWORD
	LOCAL tempsize:DWORD
	LOCAL actualsize:DWORD
	
	mov esi, pArray
	assume esi: ptr DWORD
	
	mov eax, highindex
	inc eax
	mov actualsize, eax
	mov tempsize, eax
	
	mov ecx, eax
	
	START_WHILE:
		cmp ecx, 0
		jle END_WHILE
		
		mov ecx, tempsize
		START_FOR:
			cmp ecx, 0
			jle END_FOR
			
			mov eax, ecx
			shl eax, 1
			mov child2, eax
			dec eax
			mov child1, eax
			
			inc eax
			cmp eax, tempsize
			jg NEAR_END_FOR
				dec eax
				mov edx, [esi+eax*4]
				mov eax, ecx
				dec eax
				mov ebx, [esi+eax*4]
				cmp edx, ebx
				jle AFTER_IF1
					mov eax, child1
					mov [esi+ eax*4], ebx
					mov eax, ecx
					dec eax
					mov [esi+eax*4], edx
			AFTER_IF1:
			
			mov eax, child2
			inc eax
			cmp eax, tempsize
			jg NEAR_END_FOR
				dec eax
				mov edx, [esi+eax*4]
				mov eax, ecx
				dec eax
				mov ebx, [esi+eax*4]
				cmp edx, ebx
				jle AFTER_IF2
					mov eax, child2
					mov [esi+eax*4], ebx
					mov eax, ecx
					dec eax
					mov [esi+eax*4], edx
			AFTER_IF2:
			
			NEAR_END_FOR:
			
			dec ecx
			jmp START_FOR
		END_FOR:
		
		mov eax, tempsize
		dec eax
		mov edx, [esi+eax*4]
		mov ebx, [esi+ 0*4]
		mov [esi+eax*4], ebx
		mov [esi+ 0*4], edx
		
		dec tempsize
		mov ecx, tempsize
		
		jmp START_WHILE
		
	END_WHILE:
				
	Ret
HeapSort EndP

TestFunc proc
	push MB_OK
	push OFFSET sDllName
	push OFFSET sDllName
	push NULL
	Call MessageBox
	
	Ret
TestFunc EndP



END DllEntry
