.386
.model flat, stdcall
option casemap :none

include windows.inc
include kernel32.inc
include masm32.inc

includelib kernel32.lib
includelib masm32.lib
 
.data
	introduction db "Hi, Welcome to assembly programing", 0dh,0ah, 0
	ReadArraySentence db "Please enter the integer values to be stored in the array", 0dh, 0ah, 0
	PrintArraySentence db "Interger array stored is ", 0dh, 0ah, 0
	SortingArraySentence db "Sorting Array......", 0dh, 0ah, 0
	clr db 0dh,0ah, 0
	;WordMask dw 0ffH
	
	
.data?
	
	
	nArray dw 5 dup(?)
	nvalue dw 1 dup(?)
	
.code

	start:
		
		push offset introduction
		call StdOut
		
		push offset nArray
		call ReadArray
		
		push offset nArray
		call PrintArray
		
		push offset clr
		call StdOut
		
		push offset nArray
		call SortArray
		
		push offset nArray
		call PrintArray
		
		;Following code is just for making the screen to stay after sorting completes
		push 2
		push offset nvalue
		call StdIn
		
		push 2
		push offset nvalue
		call StdIn

		push 0
		call ExitProcess
	
		ReadArray proc
			
			push offset ReadArraySentence
			call StdOut
			xor ebx, ebx
			
			mov bx, 5
			mov esi, offset nArray
			readloop: push 1
					  push esi
					  Call StdIn			;Reading single byte
					  xor eax, eax
					  mov ax, [esi]
					  sub ax, 30h			;As it is read as ascii character I am converting it to integers
					  mov [esi], ax
					  
			          inc esi
			          inc esi				;As i am doing the word memory addressing i have to move address by 2, even though
				      						;i am reading just bytes
				      dec bx
				      	 
					  jnz readloop
			Ret
		ReadArray EndP
		
		PrintArray proc
		
			push offset PrintArraySentence
			call StdOut
			
			xor ebx, ebx
			mov bx, 5
			mov esi, offset nArray
			printloop: xor eax, eax
					   mov ax, [esi]
					   ;and ax, WordMask
					   add ax, 30h				;converting integer back to ascii and then printing it
					   mov nvalue, ax
					   push offset nvalue
					   call StdOut
					   inc esi
					   inc esi
					   dec bx
					   jnz printloop
			Ret
		PrintArray EndP
		
		
		SortArray proc
		
			push offset SortingArraySentence
			call StdOut
			
			xor ecx, ecx
			mov cx, 5
			firstforloop: xor ebx,ebx
						  mov bx,cx
						  dec bx
						  jz endfun
						  mov esi, offset nArray
			secondforloop:xor eax, eax
						  mov ax, [esi]
						  ;and ax, WordMask
						  xor edx, edx
						  mov dx, [esi + 2]
						  ;and dx, WordMask
						  cmp ax,dx
						  jle continue
						  
						  xchg ax, dx
						  mov [esi], ax
						  mov [esi+2], dx
				continue: inc esi
						  inc esi
						  dec bx
						  jnz secondforloop
				endfun:   dec cx
						  jnz firstforloop
						  
			
			Ret
		SortArray EndP
	
	
	
	end start
	


