;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Name:	ChildExample
;Author:	Harsha Kadekar B M
;Description:	Example of how to use child controls
;Date:	18-10-2011
;Last Modified:	18-10-2011
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


.386
.Model Flat, STDCALL
option CASEMAP:	NONE

;Files containg the PROTOS and structures and different windows API proto
include windows.inc
include kernel32.inc
include user32.inc
include gdi32.inc

;Import the libraries which has many apis used in this program
includelib kernel32.lib
includelib user32.lib
includelib gdi32.lib 

WinMain PROTO :DWORD, :DWORD, :DWORD, :DWORD
WndProc	PROTO :DWORD, :DWORD, :DWORD, :DWORD

.Data

sClassName db "ChildExample",0
sAppName db "ChildControlls", 0
sMenuName db "FirstMenu",0
sButtonClassName db "button",0
sButtonText db "Just Example",0
sEditClassName db "edit",0
sTestString db "This is just an example",0

.data?
hInstance HINSTANCE ?
CommandLine LPSTR ?
hwndButton HWND ?
hwndEdit HWND ?
sBuffer db 512 dup(?)

.const
ButtonID equ 1
EditID equ 2
IDM_HELLO equ 1
IDM_CLEAR equ 2
IDM_GETTEXT equ 3
IDM_EXIT equ 4

.Code

start:
	push NULL
	call GetModuleHandle
	mov hInstance, eax

	call GetCommandLine
	mov CommandLine, eax

	push SW_SHOWDEFAULT
	push CommandLine
	push NULL
	push hInstance
	Call WinMain

	push eax
	Call ExitProcess
	
	WinMain proc hInst:HINSTANCE, hprevInstance:HINSTANCE, sCommandLine:LPSTR, CmdShow:DWORD
		
		LOCAL wndClass: WNDCLASSEX
		LOCAL hWnd:	HWND
		LOCAL msg:	MSG
		
		mov wndClass.cbClsExtra, NULL
		mov wndClass.cbSize, SIZEOF WNDCLASSEX
		mov wndClass.cbWndExtra, NULL
		mov wndClass.hbrBackground, COLOR_BTNFACE+1
		push IDC_ARROW
		push NULL
		call LoadCursor
		mov wndClass.hCursor,eax
		push IDI_APPLICATION
		push NULL
		Call LoadIcon 
		mov wndClass.hIcon, eax
		mov wndClass.hIconSm, NULL
		mov eax, hInst
		mov wndClass.hInstance, eax
		mov wndClass.lpfnWndProc, OFFSET WndProc
		mov wndClass.lpszClassName, OFFSET sClassName
		;mov wndClass.lpszMenuName, NULL
		mov wndClass.lpszMenuName, OFFSET sMenuName
		mov wndClass.style, CS_HREDRAW or CS_VREDRAW
		
		lea eax, wndClass
		push eax
		Call RegisterClassEx
		
		push NULL
		push hInst
		push NULL
		push NULL
		;push CW_USEDEFAULT
		push 200
		;push CW_USEDEFAULT
		push 300
		push CW_USEDEFAULT
		push CW_USEDEFAULT
		push WS_OVERLAPPEDWINDOW
		push OFFSET sAppName
		push OFFSET sClassName
		push WS_EX_CLIENTEDGE
		Call CreateWindowEx
		mov hWnd, eax
		
		push SW_SHOWNORMAL
		push hWnd
		Call ShowWindow
		
		push hWnd
		Call UpdateWindow
		
		STARTWHILE:
			push 0
			push 0
			push NULL
			lea eax, msg
			push eax
			Call GetMessage
			cmp eax, 0
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
		cmp eax, WM_COMMAND
		je COMMAND
		cmp eax, WM_DESTROY
		je DESTROY
		jmp EndWndProc
		
		CREATE:
			push NULL
			push hInstance
			push EditID
			push hWnd
			push 25
			push 200
			push 35
			push 50
			push WS_CHILD or WS_VISIBLE or WS_BORDER or ES_LEFT or ES_AUTOHSCROLL
			push NULL
			push OFFSET sEditClassName
			push WS_EX_CLIENTEDGE
			Call CreateWindowEx
			mov hwndEdit, eax
			
			push hwndEdit
			Call SetFocus
			
			push NULL
			push hInstance
			push ButtonID
			push hWnd
			push 25
			push 140
			push 70
			push 75
			push WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON
			push OFFSET sButtonText
			push OFFSET sButtonClassName
			push NULL
			Call CreateWindowEx
			mov hwndButton, eax
			
			xor eax, eax
			ret
		
		COMMAND:
			mov eax, wParam
			
			push edx
			mov edx, lParam
			cmp edx, 0
			jne ELSECOMMAND
				cmp ax, IDM_HELLO
				je M_HELLO
				cmp ax, IDM_CLEAR
				je M_CLEARBOX
				cmp ax,IDM_GETTEXT
				je M_GETTEXT
				cmp ax,IDM_EXIT
				je M_EXIT
				
				xor eax, eax
				ret
				
				M_HELLO:
					push offset sTestString
					push hwndEdit
					Call SetWindowText
					
					xor eax, eax
					ret
				M_CLEARBOX:
					push NULL
					push hwndEdit
					Call SetWindowText
					
					xor eax, eax
					ret
				M_GETTEXT:
					push 512
					lea eax, sBuffer
					push eax
					push hwndEdit
					Call GetWindowText
					push MB_OK
					push OFFSET sAppName
					push OFFSET sBuffer
					push NULL
					Call MessageBox
					
					xor eax, eax
					ret
				M_EXIT:
					push hWnd
					Call DestroyWindow
					
					xor eax, eax
					ret
			ELSECOMMAND:
				cmp ax, ButtonID
				jne AFTERIF
					shr eax, 16
					cmp ax, BN_CLICKED
					jne AFTERIF
						push 0
						push IDM_GETTEXT
						push WM_COMMAND
						push hWnd
						Call SendMessage
						
						xor eax, eax
						ret
			AFTERIF:
			xor eax, eax
			ret
			
		DESTROY:
			PUSH NULL
			Call PostQuitMessage
			
			xor eax,eax
			ret
		
		EndWndProc:
			push lParam
			push wParam
			push uMsg
			push hWnd
			Call DefWindowProc	
	
		Ret
	WndProc EndP
	
end start