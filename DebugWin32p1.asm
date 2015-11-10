;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Name:	DebugWin32p1
;Author:	Harsha Kadekar
;Description:	This program debugs a Win32 program and shows the program information.
;Date:	17-12-2011
;Last Modified:	17-12-2011
;Source:	Iczelion
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.386
.model flat, stdcall

option casemap:none

include windows.inc
include kernel32.inc
include user32.inc
include comdlg32.inc

includelib user32.lib
includelib kernel32.lib
includelib comdlg32.lib

.data
sAppName db "Win32ProgramDebugger",0
ofn OPENFILENAME <>
FilterString db "Executable Files",0,"*.exe",0
			 db "All Files", 0, "*.*",0,0
ExitProc db "The debugging program[debuggee] exits",0
NewThread db "A new Thread is created",0
EndThread db "A thread is destroyed",0
ProcessInfo db "FileHandle:%1x",0dh,0ah
			db "ProcessHandle:%1x",0dh,0ah
			db "ThreadHandle:%1x",0dh,0ah
			db "Image Base:%1x",0dh,0ah
			db "Start Address:%1x",0dh,0ah
			
.data?
buffer db 512 dup(?)
startinfo STARTUPINFO <>
pi PROCESS_INFORMATION <>
DBEvent DEBUG_EVENT <>

.code
start:
	mov ofn.lStructSize, SIZEOF ofn
	mov ofn.lpstrFilter, OFFSET FilterString
	mov ofn.lpstrFile, OFFSET buffer
	mov ofn.nMaxFile, 512
	mov ofn.Flags, OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST or OFN_LONGNAMES or OFN_EXPLORER or OFN_HIDEREADONLY
	lea eax, ofn
	push eax
	Call GetOpenFileName
	
	cmp eax, TRUE
	jne AFTERIF
		lea eax, startinfo
		push eax
		Call GetStartupInfo
		
		lea eax, pi
		push eax
		lea eax, startinfo
		push eax
		push NULL
		push NULL
		push DEBUG_PROCESS+DEBUG_ONLY_THIS_PROCESS
		push FALSE
		push NULL
		push NULL
		push NULL
		lea eax, buffer
		push eax
		Call CreateProcess
		
		START_WHILE:
			push INFINITE
			lea eax,DBEvent
			push eax
			Call WaitForDebugEvent
			
			mov eax, DBEvent.dwDebugEventCode
			cmp eax, EXIT_PROCESS_DEBUG_EVENT
			je EXIT_PROCESS
			cmp eax, CREATE_PROCESS_DEBUG_EVENT
			je CREATE_PROCESS
			cmp eax, EXCEPTION_DEBUG_EVENT
			je EXCEPTION_DEBUG
			cmp eax, CREATE_THREAD_DEBUG_EVENT
			je CREATE_THREAD
			cmp eax, EXIT_THREAD_DEBUG_EVENT
			je EVENT_THREAD_EXIT
			
			jmp AFTER_IFELSE
			
			EXIT_PROCESS:
				push MB_OK+MB_ICONINFORMATION
				push OFFSET sAppName
				push OFFSET ExitProc
				push 0
				Call MessageBox
				
				jmp END_WHILE
			
			CREATE_PROCESS:
				push DBEvent.u.CreateProcessInfo.lpStartAddress
				push DBEvent.u.CreateProcessInfo.lpBaseOfImage
				push DBEvent.u.CreateProcessInfo.hThread
				push DBEvent.u.CreateProcessInfo.hProcess
				push DBEvent.u.CreateProcessInfo.hFile
				lea eax, ProcessInfo
				push eax
				lea eax, buffer
				push eax
				Call wsprintf
				
				push MB_OK+MB_ICONINFORMATION
				push OFFSET sAppName
				lea eax, buffer
				push eax
				push 0
				Call MessageBox
				
				jmp AFTER_IFELSE
				
			EXCEPTION_DEBUG:
				cmp DBEvent.u.Exception.pExceptionRecord.ExceptionCode, EXCEPTION_BREAKPOINT
				jne AFTER_IFELSE
					push DBG_CONTINUE
					push DBEvent.dwThreadId
					push DBEvent.dwProcessId
					Call ContinueDebugEvent
					
					jmp START_WHILE
			
			CREATE_THREAD:
				push MB_OK+MB_ICONINFORMATION
				push OFFSET sAppName
				push OFFSET NewThread
				push 0
				Call MessageBox
				
				jmp AFTER_IFELSE
			
			EVENT_THREAD_EXIT:
				push MB_OK+MB_ICONINFORMATION
				push OFFSET sAppName
				push OFFSET EndThread
				push 0
				Call MessageBox
				
			AFTER_IFELSE:
				push DBG_EXCEPTION_NOT_HANDLED
				push DBEvent.dwThreadId
				push DBEvent.dwProcessId
				Call ContinueDebugEvent
				
			jmp START_WHILE
		
		END_WHILE:
		
		push pi.hProcess
		Call CloseHandle
		push pi.hThread
		Call CloseHandle
		
	AFTERIF:
	
	push 0
	Call ExitProcess
	
end start
		
			
		