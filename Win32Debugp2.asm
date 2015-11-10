;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Name:	Win32Debugp2
;Author:	Harsha Kadekar
;Description:	This program will debug a progam. It will read a data from the internal register of a
;				process and writes to that process when the process is running
;Date:	18-12-2011
;Last Modified:	18-12-2011
;Source:	Iczelion
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
sAppName db "Win32Debugp2",0
sClassName db "SimplePaintClass",0
SearchFail db "Cannot find the target process",0
TargetPatched db "TargetPatched!",0
buffer dw 9090h

.data?
DBEvent DEBUG_EVENT <>
ProcessId dd ?
ThreadId dd ?
align dword
context CONTEXT <>

.code
start:
	push NULL
	push OFFSET sClassName
	Call FindWindow
	
	cmp eax, NULL
	je ELSEPART
		mov edx, eax
		lea eax, ProcessId
		push eax
		push edx
		Call GetWindowThreadProcessId
		mov ThreadId, eax
		
		push ProcessId
		Call DebugActiveProcess
		
		START_WHILE:
			push INFINITE
			lea eax, DBEvent
			push eax
			Call WaitForDebugEvent
			
			mov eax, DBEvent.dwDebugEventCode
			cmp eax, EXIT_PROCESS_DEBUG_EVENT
			je EXIT_PROCESS
			cmp eax, CREATE_PROCESS_DEBUG_EVENT
			je CREATE_PROCESS
			cmp eax, EXCEPTION_DEBUG_EVENT
			je EXCEPTION
			
			jmp AFTER_IFELSE
			
			EXIT_PROCESS:
				jmp END_WHILE
			
			CREATE_PROCESS:
				mov context.ContextFlags, CONTEXT_CONTROL
				
				lea eax, context
				push eax
				push DBEvent.u.CreateProcessInfo.hThread
				Call GetThreadContext
				
				push NULL
				push 2
				lea eax, buffer
				push eax
				push context.regEip
				push DBEvent.u.CreateProcessInfo.hProcess
				Call WriteProcessMemory
				
				push MB_OK+MB_ICONINFORMATION
				push OFFSET sAppName
				push OFFSET TargetPatched
				push 0
				Call MessageBox
				
				jmp AFTER_IFELSE
			
			EXCEPTION:
				cmp DBEvent.u.Exception.pExceptionRecord.ExceptionCode, EXCEPTION_BREAKPOINT
				jne AFTER_IFELSE
					push DBG_CONTINUE
					push DBEvent.dwThreadId
					push DBEvent.dwProcessId
					Call ContinueDebugEvent
					
					jmp START_WHILE
					
			AFTER_IFELSE:
				
				push DBG_EXCEPTION_NOT_HANDLED
				push DBEvent.dwThreadId
				push DBEvent.dwProcessId
				Call ContinueDebugEvent
				jmp START_WHILE
				
		END_WHILE:
		
		jmp AFTER_IF
	
	ELSEPART:
		push MB_OK+MB_ICONERROR
		push OFFSET sAppName
		push OFFSET SearchFail
		push 0
		Call MessageBox
		
	AFTER_IF:
	push 0
	Call ExitProcess
	
end start	
		