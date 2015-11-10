.486
.model flat, stdcall
option casemap: none

include windows.inc
include masm32.inc
include kernel32.inc

includelib kernel32.lib
includelib masm32.lib


.data
	sIntroduction db "Please enter the file path to be opened and read", 0ah, 0dh, 0
	sFileIntroduction db "Contents of the file are", 0ah, 0dh, 0
	sErrorInstruction db "Error in opening the file, please verify the given path", 0ah, 0dh, 0
	sFilePath db "E:\Testing.txt",0

.data?
	;sFilePath db 256 dup(?)
	sBuffer db 512 dup(?)
	;sBuffer db 1 dup(?)
	hFileHandle HANDLE ?
	nWordsRead DWORD ?
	lpFileSize LPDWORD ?
	hConsoleOP HANDLE ?
	
.code
	start:
			push offset sIntroduction
			call StdOut
		
			;push 256
			;push offset sFilePath
			;call StdIn
			
			push offset sFilePath
			call StdOut
			
			;xor eax, eax
			;mov [sFilePath + 0ah], al
			
			push NULL
			push FILE_ATTRIBUTE_NORMAL
			push OPEN_EXISTING
			push NULL
			push FILE_SHARE_READ
			push GENERIC_READ
			push offset sFilePath
			call CreateFile
		
			;call OpenFile
			cmp ax, 2
			jne Found
			push offset sErrorInstruction
			call StdOut
			jmp EndProg
	Found:	mov hFileHandle, eax
			push lpFileSize
			push hFileHandle
			call GetFileSize
			
			xor ecx, ecx
			mov cx, ax
			
	FileRead:push NULL
			push offset nWordsRead
			push cx
			push offset sBuffer
			push hFileHandle
			call ReadFile
			
			xor eax, eax
			push STD_OUTPUT_HANDLE
			call GetStdHandle
			
			mov hConsoleOP, eax 
			
			call WriteConsole
			;cmp ax, 0
			;je EOF
			;cmp [sBuffer], 0
			;je EOF
			
			push offset sBuffer
			call StdOut
			;jmp FileRead
	EOF:	;push offset sBuffer
			;call StdOut
			push hFileHandle
			call CloseHandle
			
	
	EndProg:push 1
			call ExitProcess		
	
	end start



