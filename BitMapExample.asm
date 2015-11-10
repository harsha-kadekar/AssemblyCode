;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Name:	BitMapExample
;Author:	Harsha Kadekar
;Description:	This draws a bitmap image on a window.
;Date:	16-12-2011
;Last Modified:	16-12-2011
;Source:	Iczelion
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.386
.model flat,stdcall
option casemap:none

include windows.inc
include gdi32.inc
include user32.inc
include kernel32.inc

includelib gdi32.lib
includelib user32.lib
includelib kernel32.lib

WinMain proto :DWORD, :DWORD, :DWORD, :DWORD
WndProc proto :DWORD, :DWORD, :DWORD, :DWORD

.const
IDB_MAIN equ 1

.data
sClassName db "BitmapClass",0
sAppName db "BitmapDisplayApp",0

.data?
hInstance HINSTANCE ?
sCommandLine LPSTR ?
hBitmap dd ?

.code
start:
	push NULL
	Call GetModuleHandle
	mov hInstance,eax
	
	Call GetCommandLine
	mov sCommandLine, eax
	
	push SW_SHOWDEFAULT
	push sCommandLine
	push NULL
	push hInstance
	Call WinMain
	
	push eax
	Call ExitProcess
	
	WinMain proc hInst:HINSTANCE, hPrevInst:HINSTANCE, sCmdLine:LPSTR, ShowCommand:DWORD
		LOCAL wc:WNDCLASSEX
		LOCAL msg:MSG
		LOCAL hWnd:HWND
		
		mov wc.cbClsExtra, NULL
		mov wc.cbSize, SIZEOF WNDCLASSEX
		mov wc.cbWndExtra, NULL
		mov wc.hbrBackground, COLOR_APPWORKSPACE
		push IDC_ARROW
		push NULL
		Call LoadCursor
		mov wc.hCursor,eax
		push IDI_APPLICATION
		push NULL 
		Call LoadIcon
		mov wc.hIcon,eax 
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
		mov hWnd, eax
		
		push SW_SHOWNORMAL
		push hWnd
		Call ShowWindow
		
		push hWnd
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
		LOCAL ps:PAINTSTRUCT
		LOCAL hDC:HDC
		LOCAL hMemDC:HDC
		LOCAL rect:RECT
		
		mov eax, uMsg
		cmp eax, WM_CREATE
		je CREATE
		cmp eax, WM_PAINT
		je PAINT
		cmp eax, WM_DESTROY
		je DESTROY
		
		jmp DEFAULT
		
		CREATE:
			push IDB_MAIN
			push hInstance
			Call LoadBitmap
			mov hBitmap, eax
			jmp EndProc
			
		PAINT:
			lea eax, ps
			push eax
			push hWnd
			Call BeginPaint
			mov hDC, eax
			
			push hDC
			Call CreateCompatibleDC
			mov hMemDC, eax
			
			push hBitmap
			push hMemDC
			Call SelectObject
			
			lea eax, rect
			push eax
			push hWnd
			Call GetClientRect
			
			push SRCCOPY
			push 0
			push 0
			push hMemDC
			push rect.bottom
			push rect.right
			;push rect.top
			;push rect.left
			push 0
			push 0
			push hDC
			Call BitBlt
			
			push hMemDC
			Call DeleteDC
			
			lea eax, ps
			push eax
			push hWnd
			Call EndPaint
			
			jmp EndProc
			
		DESTROY:
			push hBitmap
			Call DeleteObject
			
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