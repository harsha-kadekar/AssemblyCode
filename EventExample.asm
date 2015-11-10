;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Name:	EventsExample
;Author:	Harsha Kadekar
;Description:	To study the working of event objects and thread communication using it.
;Date:	16-11-2011
;Last Modified:	16-11-2011
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.386
.model flat, stdcall

option casemap: none

include windows.inc
include user32.inc
include kernel32.inc

includelib user32.lib
includelib kernel32.lib

WinMain proto :DWORD, :DWORD, :DWORD, :DWORD
WndProc proto :DWORD, :DWORD, :DWORD, :DWORD

.const
IDM_START_THREAD equ 1001
IDM_STOP_THREAD equ 1002
IDM_EXIT equ 1003
WM_FINISH equ WM_USER+100h

.data
sClassName db "EventClass",0
sAppName db "EventObjectExample",0
sMenuName db "FirstMenu",0
sSuccessString db "The calculation is complete",0
sStopString db "The thread has stopped",0
EventStop BOOL FALSE

.data?
hInstance HINSTANCE ?
sCommandLine LPSTR ?
hwnd HWND ?
hMenu HWND ?
ThreadID DWORD ?
dExitCode DWORD ?
hEventStart HANDLE ?
hThread HANDLE ?

.code
start:
	push NULL
	Call GetModuleHandle
	mov hInstance, eax
	
	Call GetCommandLine
	mov eax, sCommandLine
	
	push SW_SHOWDEFAULT
	push sCommandLine
	push NULL
	push hInstance
	Call WinMain
	
	push eax
	Call ExitProcess
	
	WinMain proc hInst:HINSTANCE, hPrevInstance:HINSTANCE, CmdLine:LPSTR, CmdShow:DWORD
		
		LOCAL wc:WNDCLASSEX
		LOCAL msg:MSG
		
		mov wc.cbClsExtra, NULL
		mov wc.cbSize, SIZEOF WNDCLASSEX
		mov wc.cbWndExtra, NULL
		mov wc.hbrBackground, COLOR_WINDOW+1
		push IDC_ARROW
		push NULL
		Call LoadCursor
		mov wc.hCursor, eax
		push IDI_APPLICATION
		push NULL
		Call LoadIcon
		mov wc.hIcon, eax
		mov wc.hIconSm, NULL
		mov eax, hInst
		mov wc.hInstance, eax
		mov wc.lpfnWndProc, OFFSET WndProc
		mov wc.lpszClassName, OFFSET sClassName
		mov wc.lpszMenuName, OFFSET sMenuName
		mov wc.style, CS_HREDRAW or CS_VREDRAW
		
		lea eax, wc
		push eax
		Call RegisterClassEx
		
		push NULL
		push hInst
		push NULL
		push NULL
		push 200
		push 300
		push CW_USEDEFAULT
		push CW_USEDEFAULT
		push WS_OVERLAPPEDWINDOW
		push OFFSET sAppName
		push OFFSET sClassName
		push WS_EX_CLIENTEDGE
		Call CreateWindowEx
		mov hwnd, eax
		
		push SW_SHOWNORMAL
		push hwnd
		Call ShowWindow
		
		push hwnd
		Call UpdateWindow
		
		push hwnd
		Call GetMenu
		mov hMenu, eax
		
		STARTWHILE:
			push 0
			push 0
			push NULL
			lea eax, msg
			push eax
			Call GetMessage
			
			cmp eax, FALSE
			je ENDWHILE
				lea eax, msg
				push eax
				Call TranslateMessage
				
				lea eax, msg
				push eax
				Call DispatchMessage
			jmp STARTWHILE
		ENDWHILE:
		
		mov eax, msg.wParam
		
		Ret
	WinMain EndP
	
	WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
		
		mov eax, uMsg
		
		cmp eax, WM_CREATE
		je CREATE
		cmp eax, WM_DESTROY
		je DESTROY
		cmp eax, WM_COMMAND
		je COMMAND
		cmp eax, WM_FINISH
		je FINISH
		
		jmp DEFAULT
		
		CREATE:
			push NULL
			push FALSE
			push FALSE
			push NULL
			Call CreateEvent
			mov hEventStart, eax
			
			mov eax, OFFSET ThreadProc
			
			push OFFSET ThreadID
			push 0
			push NULL
			push eax
			push NULL
			push NULL
			Call CreateThread
			
			mov hThread, eax
			
			push eax
			Call CloseHandle
			
			jmp EndProc
		
		DESTROY:
			push NULL
			Call PostQuitMessage
			jmp EndProc
			
		COMMAND:
			mov eax, wParam
			cmp lParam, 0
			jne EndProc
				cmp ax, IDM_START_THREAD
				je M_START_THREAD
				cmp ax, IDM_STOP_THREAD
				je M_STOP_THREAD
				cmp ax, IDM_EXIT
				je M_EXIT
				
				jmp EndProc
				
				M_START_THREAD:
					push hEventStart
					Call SetEvent
					
					push MF_GRAYED
					push IDM_START_THREAD
					push hMenu
					Call EnableMenuItem
					
					push MF_ENABLED
					push IDM_STOP_THREAD
					push hMenu
					Call EnableMenuItem
					
					jmp EndProc
					
				M_STOP_THREAD:
					mov EventStop, TRUE
					
					push MF_ENABLED
					push IDM_START_THREAD
					push hMenu
					Call EnableMenuItem
					
					push MF_GRAYED
					push IDM_STOP_THREAD
					push hMenu
					Call EnableMenuItem
					
					jmp EndProc
				
				M_EXIT:
					push hWnd
					Call DestroyWindow
					
					jmp EndProc
		
		FINISH:
			push MB_OK
			push OFFSET sAppName
			push OFFSET sSuccessString
			push NULL
			Call MessageBox
			
			jmp EndProc
			
		DEFAULT:
			push lParam
			push wParam
			push uMsg
			push hWnd
			Call DefWindowProc
			
			ret
		
		EndProc:
		
			mov eax, eax
			
		Ret
	WndProc EndP
	
	ThreadProc proc USES ecx Param:DWORD
	

	push INFINITE
	push hEventStart
	Call WaitForSingleObject
    
    mov  ecx,600000000

		WHILEBEGIN:
			cmp ecx, 0
			je WHILEEND
				cmp EventStop, FALSE
				
				jne ELSEPART
					add eax, eax
					dec ecx
					
					jmp ENDIFPART
				ELSEPART:
					push MB_OK
					push OFFSET sAppName
					push OFFSET sStopString
					push hwnd
					Call MessageBox
					
					mov EventStop, FALSE
					jmp ThreadProc
				ENDIFPART:
			jmp WHILEBEGIN
		WHILEEND:
 	
	
        
		
		push NULL
		push NULL
		push WM_FINISH
		push hwnd
		Call PostMessage
		
		push MF_ENABLED
		push IDM_START_THREAD
		push hMenu
		Call EnableMenuItem
		
		push MF_GRAYED
		push IDM_STOP_THREAD
		push hMenu
		Call EnableMenuItem
		

		jmp ThreadProc
		Ret
	ThreadProc EndP
	
end start
	
	