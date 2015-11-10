;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Name:	SplashScreenApp
;Author:	Harsha Kadekar
;Description:	This displays a splash screen when it launches
;Date:	17-12-2011
;Last Modified:	17-12-2011
;Source:	Iczelion
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.386
.model flat, stdcall

option casemap:none

include windows.inc
include user32.inc
include kernel32.inc

includelib user32.lib
includelib kernel32.lib

WinMain proto :DWORD, :DWORD, :DWORD, :DWORD

.data
sClassName db "SplashScreenAppClass", 0
sAppName db "SplashScreenApp",0
sLibName db "SplashScreen.dll",0

.data?
hInstance HINSTANCE ?

.code
start:
	push OFFSET sLibName
	Call LoadLibrary
	cmp eax, NULL
	je AFTERIF
		push eax
		Call FreeLibrary
	AFTERIF:
	
	push NULL
	Call GetModuleHandle
	mov hInstance, eax
	
	push SW_SHOWDEFAULT
	push NULL
	push NULL
	push hInstance
	Call WinMain
	
	push eax
	Call ExitProcess
	
	WinMain proc hInst:HINSTANCE, hPrevInst:HINSTANCE, sCmdLine:LPSTR, CmdShow:DWORD
		LOCAL wc:WNDCLASSEX
		LOCAL msg:MSG
		LOCAL hwnd:HWND
		
		mov wc.cbClsExtra, NULL
		mov wc.cbSize, SIZEOF WNDCLASSEX
		mov wc.cbWndExtra, NULL
		mov wc.hbrBackground, COLOR_APPWORKSPACE
		push IDC_ARROW
		push NULL
		Call LoadCursor
		mov wc.hCursor, eax
		push IDI_APPLICATION
		push NULL
		Call LoadIcon
		mov wc.hIcon, eax
		mov wc.hIconSm, eax
		mov eax, hInstance
		mov wc.hInstance, eax
		mov wc.lpfnWndProc, OFFSET WndProc
		mov wc.lpszClassName, OFFSET sClassName
		mov wc.lpszMenuName, NULL
		mov wc.style, CS_HREDRAW or CS_VREDRAW
		
		lea eax, wc
		push eax
		Call RegisterClassEx
		
		push NULL
		push hInst
		push NULL
		push NULL
		push CW_USEDEFAULT
		push CW_USEDEFAULT
		push CW_USEDEFAULT
		push CW_USEDEFAULT
		push WS_OVERLAPPEDWINDOW
		push OFFSET sAppName
		push OFFSET sClassName
		push NULL
		Call CreateWindowEx
		mov hwnd, eax
		
		push SW_SHOWNORMAL
		push hwnd
		Call ShowWindow
		
		push hwnd
		Call UpdateWindow
		
		START_WHILE:
			push 0
			push 0
			push NULL
			lea eax, msg
			push eax
			Call GetMessage
			
			cmp eax, FALSE
			je END_WHILE
				lea eax, msg
				push eax
				Call TranslateMessage
				
				lea eax, msg
				push eax
				Call DispatchMessage
			jmp START_WHILE
		END_WHILE:
		
		mov eax, msg.wParam
			
		Ret
	WinMain EndP
	
	WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
		mov eax, uMsg
		cmp eax, WM_DESTROY
		je DESTROY
		
		jmp DEFAULT
		
		DESTROY:
			push NULL
			Call PostQuitMessage
			jmp EndProc
		
		DEFAULT:
			push lParam
			push wParam
			push uMsg
			push hWnd
			Call DefWindowProc
			
			ret
		EndProc:
			xor eax, eax
		Ret
	WndProc EndP
	
end start
	