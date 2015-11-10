;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Name:	TrayIcon
;Author:	Harsha Kadekar
;Description:	This will add a icon to the system tray in the task bar. Also creates a popup menu for that tray icon
;Date:	14-12-2011
;Last Modified:	14-12-2011
;Source:	Iczelion
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.386
.model flat, stdcall

option casemap:none

include windows.inc
include user32.inc
include kernel32.inc
include shell32.inc

includelib user32.lib
includelib kernel32.lib
includelib shell32.lib

WinMain proto :DWORD, :DWORD, :DWORD, :DWORD
WndProc proto :DWORD, :DWORD, :DWORD, :DWORD

.const
WM_SHELLNOTIFY equ WM_USER+5
IDI_TRAY equ 0
IDM_RESTORE equ 1000
IDM_EXIT equ 1010

.data
sClassName db "TrayIconClass",0
sAppName db "TrayIconApp",0
sRestoreString db "&Restore",0
sExitString db "E&xit Program",0

.data?
hInstance dd ?
note NOTIFYICONDATA <>
hPopupMenu dd ?

.code
start:
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
	
	WinMain proc hInst:HINSTANCE, hPrevInst:HINSTANCE, sCmdLine:LPSTR, ShowCmd:DWORD
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
		mov wc.hCursor, eax
		push IDI_APPLICATION
		push NULL
		Call LoadIcon
		mov wc.hIcon, eax
		mov wc.hIconSm, eax
		mov eax, hInst
		mov wc.hInstance, eax
		mov wc.lpfnWndProc, OFFSET WndProc
		mov wc.lpszClassName, OFFSET sClassName
		mov wc.lpszMenuName, NULL
		mov wc.style, CS_HREDRAW or CS_VREDRAW or CS_DBLCLKS
		
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
		push WS_OVERLAPPED + WS_CAPTION + WS_VISIBLE+ WS_MINIMIZEBOX + WS_MAXIMIZEBOX + WS_SYSMENU
		push OFFSET sAppName
		push OFFSET sClassName
		push OFFSET WS_EX_CLIENTEDGE
		Call CreateWindowEx
		mov hWnd, eax
		
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
		LOCAL pt:POINT
		
		mov eax, uMsg
		cmp eax, WM_CREATE
		je CREATE
		cmp eax, WM_DESTROY
		je DESTROY
		cmp eax, WM_SIZE
		je SIZE_MSG
		cmp eax, WM_COMMAND
		je COMMAND
		cmp eax, WM_SHELLNOTIFY
		je SHELLNOTIFY
		
		jmp DEFAULT
		
		CREATE:
			Call CreatePopupMenu
			mov hPopupMenu, eax
			
			push OFFSET sRestoreString
			push IDM_RESTORE
			push MF_STRING
			push hPopupMenu
			Call AppendMenu
			
			push OFFSET sExitString
			push IDM_EXIT
			push MF_STRING
			push hPopupMenu
			Call AppendMenu
			
			jmp EndProc
		
		DESTROY:
			push hPopupMenu
			Call DestroyMenu
			
			push NULL
			Call PostQuitMessage
			
			jmp EndProc
			
		SIZE_MSG:
			mov eax, wParam
			cmp eax, SIZE_MINIMIZED
			jne EndProc
				mov note.cbSize, SIZEOF NOTIFYICONDATA
				push hWnd
				pop note.hwnd
				mov note.uID, IDI_TRAY
				mov note.uFlags, NIF_ICON+NIF_MESSAGE+NIF_TIP
				mov note.uCallbackMessage, WM_SHELLNOTIFY
				push IDI_WINLOGO
				push NULL
				Call LoadIcon
				mov note.hIcon, eax
				push OFFSET sAppName
				lea eax, note.szTip
				push eax
				Call lstrcpy
				
				push SW_HIDE
				push hWnd
				Call ShowWindow
				
				lea eax, note
				push eax
				push NIM_ADD
				Call Shell_NotifyIcon
			jmp EndProc
			
		COMMAND:
			mov eax, lParam
			cmp eax, 0
			jne EndProc
				lea eax, note
				push eax
				push NIM_DELETE
				Call Shell_NotifyIcon
				
				mov eax, wParam
				cmp eax, IDM_RESTORE
				je RESTORE
				cmp eax, IDM_EXIT
				je EXIT_COMMAND
				
				jmp EndProc
				
				RESTORE:
					push SW_RESTORE
					push hWnd
					Call ShowWindow
					jmp EndProc
				
				EXIT_COMMAND:
					push hWnd
					Call DestroyWindow
					jmp EndProc
		
		SHELLNOTIFY:
			mov eax, wParam
			cmp eax, IDI_TRAY
			jne EndProc
				mov eax, lParam
				cmp eax, WM_RBUTTONDOWN
				je RBUTTONDOWN
				cmp eax, WM_LBUTTONDBLCLK
				je LBUTTONDBLCLK
				
				jmp EndProc
				
				RBUTTONDOWN:
					lea eax, pt
					push eax
					Call GetCursorPos
					
					push hWnd
					Call SetForegroundWindow
					
					push NULL
					push hWnd
					push NULL
					push pt.y
					push pt.x
					push TPM_RIGHTALIGN
					push hPopupMenu
					Call TrackPopupMenu
					
					push 0
					push 0
					push WM_NULL
					push hWnd
					Call PostMessage
					
					jmp EndProc
					
				LBUTTONDBLCLK:
					push 0
					push IDM_RESTORE
					push WM_COMMAND
					push hWnd
					Call SendMessage
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