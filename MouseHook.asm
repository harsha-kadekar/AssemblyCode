;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Name:	MouseHook
;Author:	Harsha Kadekar
;Description: This is hook dll which will track the mouse events.
;Date:	16-12-2011
;Last Modified:	16-12-2011
;Source:	Iczelion
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.386
.model flat, stdcall

option casemap:none

include windows.inc
include user32.inc
include kernel32.inc

includelib user32.lib
includelib kernel32.lib

.const
WM_MOUSEHOOK equ WM_USER+6

.data
hInstance dd 0

.data?
hHook dd ?
hWnd dd ?

.code
	DllEntry proc hInst:HINSTANCE, reason:DWORD, reserved1:DWORD
		cmp reason, DLL_PROCESS_ATTACH
		jne AFTERIF
			push hInst
			pop hInstance
		AFTERIF:
		mov eax, TRUE
		Ret
	DllEntry EndP
	
	MouseProc proc nCode:DWORD, wParam:WPARAM, lParam:LPARAM
		push lParam
		push wParam
		push nCode
		push hHook
		Call CallNextHookEx
		
		mov edx, lParam
		assume edx:PTR MOUSEHOOKSTRUCT
		
		push [edx].pt.y
		push [edx].pt.x
		Call WindowFromPoint
		
		push 0
		push eax
		push WM_MOUSEHOOK
		push hWnd
		Call PostMessage
		
		assume edx:nothing
		xor eax, eax
		
		Ret
	MouseProc EndP
	
	InstallHook proc hwnd:DWORD
		push hwnd
		pop hWnd
		
		push NULL
		push hInstance
		push OFFSET MouseProc
		push WH_MOUSE
		Call SetWindowsHookEx
		
		mov hHook, eax
		
		Ret
	InstallHook EndP
	
	UninstallHook proc 
		push hHook
		Call UnhookWindowsHookEx	
		Ret
	UninstallHook EndP
	
End DllEntry
