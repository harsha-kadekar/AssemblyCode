;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Name:	ThreadExamp
;Author:	Harsha
;Description:	Understanding threads in assembly
;Date:	16-11-2011
;Last Modified:	16-11-2011
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.386
.model FLAT, STDCALL

option casemap: none

include windows.inc
include user32.inc
include kernel32.inc

includelib user32.lib
includelib kernel32.lib

WinMain proto :DWORD, :DWORD, :DWORD, :DWORD
WndProc proto :DWORD, :DWORD, :DWORD, :DWORD
;ThreadProc proto :DWORD

.const

IDM_CREATE_THREAD equ 1001
IDM_EXIT equ 1002
WM_FINISH equ WM_USER+100h

.data

sClassName db "ThreadExampleClass",0
sAppName db "Threads", 0
sMenuName db "FirstMenu", 0
sSuccessString db "The calculation is completed",0

.data?
hInstance HINSTANCE ?
sCommandLine LPSTR ?
hWnd HWND ?
ThreadID DWORD ?
hMenu HANDLE ?

.code
start:
	
	push NULL
	Call GetModuleHandle
	mov hInstance, eax
	
	Call GetCommandLine
	mov sCommandLine, eax
	
	push SW_SHOWDEFAULT
	push sCommandLine
	push NULL
	push hInstance
	Call WinMain
	
	push eax
	Call ExitProcess
	
	
	WinMain proc hInst:HINSTANCE, hPrevInst:HINSTANCE, sCmdLine:LPSTR, CmdShow:DWORD
	

	
		LOCAL wc:WNDCLASSEX
		LOCAL msg:MSG
		
		mov wc.cbClsExtra, NULL
		mov wc.cbSize, SIZEOF WNDCLASSEX
		mov wc.cbWndExtra, NULL
		mov wc.hbrBackground, COLOR_WINDOW + 1
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
		;push 200
		;push 300
		push CW_USEDEFAULT
		push CW_USEDEFAULT
		push CW_USEDEFAULT
		push CW_USEDEFAULT
		push WS_OVERLAPPEDWINDOW
		push OFFSET sAppName
		push OFFSET sClassName
		push WS_EX_CLIENTEDGE
		;push NULL
		Call CreateWindowEx
		mov hWnd, eax
		push SW_SHOWNORMAL
		push hWnd
		Call ShowWindow
		
		push hWnd
		Call UpdateWindow
		
		push hWnd
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
	
	
	WndProc proc hwnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
		

		mov eax, uMsg
		
		cmp eax, WM_DESTROY
		je DESTROY
		cmp eax, WM_COMMAND
		je COMMAND
		cmp eax, WM_FINISH
		je FINISH
		
		jmp DEFAULT
		
		DESTROY:
			push NULL
			Call PostQuitMessage
			jmp EndProc
		
		COMMAND:
			mov eax, wParam
			cmp lParam, 0
			jne EndProc
				cmp ax, IDM_CREATE_THREAD
				je M_CREATE_THREAD
				cmp ax, IDM_EXIT
				je M_EXIT
				
				jmp EndProc
				
				M_CREATE_THREAD:
					mov eax, OFFSET ThreadProc
					
					push OFFSET ThreadID
					push NORMAL_PRIORITY_CLASS
					push NULL
					push eax
					push NULL
					push NULL
					Call CreateThread
					
					push eax
					Call CloseHandle
					
					jmp EndProc
				M_EXIT:
					push hwnd
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
			push hwnd
			Call DefWindowProc
			
			ret
		EndProc:
			xor eax, eax
	
		Ret
	WndProc EndP 
	
	ThreadProc proc USES ecx Param:DWORD
	

		mov ecx, 600000000
		LOOP1:
			add eax, eax
			dec ecx
			jz GET_OUT
			jmp LOOP1
		GET_OUT:
			push NULL
			push NULL
			push WM_FINISH
			push hWnd
			Call PostMessage
			
		Ret
	ThreadProc EndP
	
end start
	