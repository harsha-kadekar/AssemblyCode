;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Name:	Win32Debugp3
;Author:	Harsha Kadekar
;Description:	This shows the Single Stepping or tracing of a process.
;Date:	18-12-2011
;Last Modified:	18-12-2011
;Source:	Iczelion
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.386
.model flat, stdcall

option casemap:none

include windows.inc
include user32.inc
include kernel32.inc
include comdlg32.inc

includelib user32.lib
includelib kernel32.lib
includelib comdlg32.lib

.data
sAppName db "Win32 Single Stepping App",0
ofn OPENFILENAME <>
FilterString db "Executable Files", 0, "*.exe", 0
			 db "All Files", 0, "*.*", 0, 0
ExitProc db "The debugee exits",0dh, 0ah
		 db "Total insstructions executed: %1u", 0
TotalInstruction dd 0

.data?
buffer db 512 dup(?)
startinfo STARTUPINFO <>
pi PROCESS_INFORMATION <>
DBEvent DEBUG_EVENT <>
align dword
context CONTEXT <>

.code
start:
	mov ofn.lStructSize, SIZEOF ofn
	mov ofn.lpstrFilter, OFFSET FilterString
	mov ofn.lpstrFile, OFFSET buffer
	mov ofn.nMaxFile, 512
	mov ofn.Flags, OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST or OFN_EXPLORER or OFN_HIDEREADONLY
	lea eax, ofn
	push eax
	Call GetOpenFileName
	
	cmp eax, TRUE
	jne AFTER_IF
		lea eax, startinfo
		push eax
		Call GetStartupInfo
		
		lea eax, pi
		push eax
		lea eax, startinfo
		push eax
		push NULL
		push NULL
		push DEBUG_PROCESS + DEBUG_ONLY_THIS_PROCESS
		push FALSE
		push NULL
		push NULL
		push NULL
		lea eax, buffer
		push eax
		Call CreateProcess
		
		START_WHILE:
			push INFINITE
			lea eax, DBEvent
			push eax
			Call WaitForDebugEvent
			
			mov eax, DBEvent.dwDebugEventCode
			cmp eax, EXIT_PROCESS_DEBUG_EVENT
			je EXIT_PROCESS
			cmp eax, EXCEPTION_DEBUG_EVENT
			je EXCEPTION
			
			jmp AFTER_ELSEIF
			
			EXIT_PROCESS:
				push TotalInstruction
				push OFFSET ExitProc
				lea eax, buffer
				push eax
				Call wsprintf
				
				push MB_OK+MB_ICONINFORMATION
				push OFFSET sAppName
				push OFFSET buffer
				push 0
				Call MessageBox
				
				jmp END_WHILE
				
			EXCEPTION:
				mov eax,DBEvent.u.Exception.pExceptionRecord.ExceptionCode
				cmp eax,EXCEPTION_BREAKPOINT
				je BREAKPOINT
				cmp eax, EXCEPTION_SINGLE_STEP
				je SINGLE_STEP
				
				jmp AFTER_ELSEIF
				
				BREAKPOINT:
					mov context.ContextFlags, CONTEXT_CONTROL
					
					lea eax, context
					push eax
					push pi.hThread
					Call GetThreadContext
					
					or context.regFlag, 100h
					
					lea eax, context
					push eax
					push pi.hThread
					Call SetThreadContext
					
					push DBG_CONTINUE
					push DBEvent.dwThreadId
					push DBEvent.dwProcessId
					Call ContinueDebugEvent
					
					jmp START_WHILE
				
				SINGLE_STEP:
					inc TotalInstruction
					;push 100h
					
					lea eax, context
					push eax
					push pi.hThread
					Call GetThreadContext
					
					or context.regFlag, 100h
					
					lea eax, context
					push eax
					push pi.hThread
					Call SetThreadContext
					
					push DBG_CONTINUE
					push DBEvent.dwThreadId
					push DBEvent.dwProcessId
					Call ContinueDebugEvent
					
					jmp START_WHILE
					
				jmp AFTER_ELSEIF
			
			AFTER_ELSEIF:
				push DBG_EXCEPTION_NOT_HANDLED
				push DBEvent.dwThreadId
				push DBEvent.dwProcessId
				Call ContinueDebugEvent
				
			jmp START_WHILE
			
		END_WHILE:
		
	AFTER_IF:
	
	push pi.hProcess
	Call CloseHandle
	
	push pi.hThread
	Call CloseHandle
	
	push 0
	Call ExitProcess
	
end start
				
					