.386
.model flat, stdcall

option casemap :none

include windows.inc
include kernel32.inc
include user32.inc


includelib kernel32.lib
includelib user32.lib

.data
	heading db "This is an arithmatic operation function", 0
	GoodText db "ok i have counted 6 correctly", 0
	BadText db "Done mistake in counting", 0
	Total sdword 0
	
.code
	start:
		mov ecx, 6
		xor eax, eax
		
		_startloop:	add eax, ecx
					dec ecx
					jnz _startloop
		
		mov edx, 7
		mul edx
		
		push eax
		pop Total
		
		cmp Total, 147
		jz _GoodCounting
		
		_BadCounting:push MB_OK
					 push offset heading
					 push offset BadText
					 push NULL
					 call MessageBox
					 jmp _ending
		
		_GoodCounting:push MB_OK
					  push offset heading
					  push offset GoodText
					  push NULL
					  call MessageBox
		
		_ending:	push 0
					call ExitProcess
	
	end start	
	