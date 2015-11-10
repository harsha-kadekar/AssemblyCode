;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Name:	SplashScreen
;Author:	Harsha Kadekar
;Description:	This dll will create and displays the splash screen
;Date:	16-12-2011
;Last Modified:	16-12-2011
;Source:	Iczelion
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.386
.model flat,stdcall
option casemap:none

include windows.inc
include user32.inc
include kernel32.inc
include gdi32.inc

includelib user32.lib
includelib kernel32.lib
includelib gdi32.lib

.data
sBitmapName db "MySplash",0
sClassName db "SplashClass",0
hBitMap dd 0
TimerID dd 0

.data?
hInstance HINSTANCE ?

.code
DllEntry proc hInst:HINSTANCE, reason:DWORD, reserved1:DWORD
	mov eax, reason
	cmp eax, DLL_PROCESS_ATTACH
	jne AFTERIF
		push hInst
		pop hInstance
		Call ShowBitMap
	AFTERIF:
	mov eax, TRUE
	Ret
DllEntry EndP

ShowBitMap proc
	LOCAL wc:WNDCLASSEX
	LOCAL msg:MSG
	LOCAL hwnd:HWND
	
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
	push hInstance
	push NULL
	push NULL
	push 250
	push 250
	push CW_USEDEFAULT
	push CW_USEDEFAULT
	push WS_POPUP
	push NULL
	push OFFSET sClassName
	push NULL
	Call CreateWindowEx
	mov hwnd, eax
	
	push SW_SHOWNORMAL
	push hwnd
	Call ShowWindow
	
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
ShowBitMap EndP

WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	LOCAL ps:PAINTSTRUCT
	LOCAL hdc:HDC
	LOCAL hMemDC:HDC
	LOCAL hOldBmp:DWORD
	LOCAL bitmap:BITMAP
	LOCAL DlgHeight:DWORD
	LOCAL DlgWidth:DWORD
	LOCAL DlgRect:RECT
	LOCAL DesktopRect:RECT
	
	mov eax,uMsg
	cmp eax, WM_DESTROY
	je DESTROY
	cmp eax, WM_CREATE
	je CREATE
	cmp eax, WM_TIMER
	je TIMER
	cmp eax, WM_PAINT
	je PAINT
	cmp eax, WM_LBUTTONDOWN
	je LBUTTONDOWN
	
	jmp DEFAULT
	
	DESTROY:
		cmp hBitMap,0
		je AFTERIF_DESTROY
			push hBitMap
			Call DeleteObject
		AFTERIF_DESTROY:
		
		push NULL
		Call PostQuitMessage
		
		jmp EndProc
	
	CREATE:
		lea eax, DlgRect
		push eax
		push hWnd
		Call GetWindowRect
		
		Call GetDesktopWindow
		mov ecx, eax
		
		lea eax, DesktopRect
		push eax
		push ecx
		Call GetWindowRect
		
		push 0
		mov eax, DlgRect.bottom
		sub eax, DlgRect.top
		mov DlgHeight, eax
		push eax
		
		mov eax, DlgRect.right
		sub eax, DlgRect.left
		mov DlgWidth, eax
		push eax
		
		mov eax, DesktopRect.bottom
		sub eax, DlgHeight
		shr eax,1
		push eax
		
		mov eax, DesktopRect.right
		sub eax, DlgWidth
		shr eax, 1
		push eax
		
		push hWnd
		Call MoveWindow
		
		push OFFSET sBitmapName
		push hInstance
		Call LoadBitmap
		mov hBitMap, eax
		
		push NULL
		push 5000
		push 1
		push hWnd
		Call SetTimer
		mov TimerID, eax
		
		jmp EndProc
		
	TIMER:
		push NULL
		push NULL
		push WM_LBUTTONDOWN
		push hWnd
		Call SendMessage
		
		push TimerID
		push hWnd
		Call KillTimer
		
		jmp EndProc
	
	PAINT:
		lea eax, ps
		push eax
		push hWnd
		Call BeginPaint
		mov hdc, eax
		
		push hdc
		Call CreateCompatibleDC
		mov hMemDC, eax
		
		push hBitMap
		push eax
		Call SelectObject
		mov hOldBmp,eax
		
		lea eax, bitmap
		push eax
		push SIZEOF BITMAP
		push hBitMap
		Call GetObject
		
		push SRCCOPY
		push bitmap.bmHeight
		push bitmap.bmWidth
		push 0
		push 0
		push hMemDC
		push 250
		push 250
		push 0
		push 0
		push hdc
		Call StretchBlt
		
		push hOldBmp
		push hMemDC
		Call SelectObject
		
		push hMemDC
		Call DeleteDC
		
		lea eax, ps
		push eax
		push hWnd
		Call EndPaint
		
		jmp EndProc
		
	LBUTTONDOWN:
		push hWnd
		Call DestroyWindow
		
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

End DllEntry


