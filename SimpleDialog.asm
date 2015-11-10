;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Name:	SimpleDialog
;Author:	Harsha Kadekar
;Description:	Just an example to see the working of dialog box
;Date:	20-10-2011
;Last Modified:	24-10-2011
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.386
.Model flat, STDCALL
option casemap: none

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
WndProc PROTO :DWORD, :DWORD, :DWORD, :DWORD

.data

sClassName db "DialogClass", 0
sMenuName db "FirstMenu", 0
sDialogName db "FirstDialog", 0
sAppName db "Dialogue", 0
TestString db "Here is the dialogue box",0

.data?

hInstance HINSTANCE ?
CommandLine LPSTR ?
sBuffer db 512 dup(?)

.const

IDC_EDIT equ 1002
IDC_BUTTON equ 1003
IDM_SET equ 1001
IDM_CLEAR equ 1002
IDM_GET equ 1003
IDM_EXIT equ 1004

.code

start:
	push NULL
	Call GetModuleHandle
	mov hInstance, eax
	
	Call GetCommandLine
	mov CommandLine, eax
	
	push SW_SHOWDEFAULT
	push CommandLine
	push NULL
	push hInstance
	Call WinMain
	
	push eax
	Call ExitProcess
	
	WinMain proc hInst:HINSTANCE, hPrevInst:HINSTANCE, CmdLine:LPSTR, CmdShow:DWORD
	
		LOCAL wc:WNDCLASSEX
		LOCAL msg:MSG
		LOCAL hDlg:HWND
		
		mov wc.cbClsExtra, NULL
		mov wc.cbSize, SIZEOF WNDCLASSEX
		mov wc.cbWndExtra, DLGWINDOWEXTRA
		mov wc.hbrBackground, COLOR_BTNFACE +1
		push IDC_ARROW
		push NULL
		Call LoadCursor
		mov wc.hCursor,eax
		push IDI_APPLICATION
		push NULL 
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
		push NULL
		push NULL
		push OFFSET sDialogName
		push hInst
		Call CreateDialogParam
		mov hDlg, eax
		
		push SW_SHOWNORMAL
		push hDlg
		Call ShowWindow
		
		push hDlg
		Call UpdateWindow
		
		push IDC_EDIT
		push hDlg
		Call GetDlgItem
		push eax
		Call SetFocus
		
		WHILESTART:
			push 0
			push 0
			push NULL
			lea eax, msg
			push eax
			Call GetMessage
			
			cmp eax, 0
			je AFTERWHILE
			
				lea eax, msg
				push eax
				push hDlg
				Call IsDialogMessage
				cmp eax, FALSE
				jne WHILESTART
					lea eax, msg
					push eax
					Call TranslateMessage
					
					lea eax, msg
					push eax
					Call DispatchMessage
			jmp WHILESTART
		AFTERWHILE:
		
		mov eax, msg.wParam
		Ret
	WinMain EndP
	
	WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	
		mov eax, uMsg
		
		cmp eax, WM_COMMAND
		je COMMAND
		cmp eax, WM_DESTROY
		je DESTROY
		jmp EndWndProc
		
		COMMAND:
			mov eax, wParam
			cmp lParam, 0
			jne ELSEPART
				cmp ax, IDM_GET
				je M_GET
				cmp ax, IDM_CLEAR
				je M_CLEAR
				cmp ax, IDM_SET
				je M_SET
				cmp ax, IDM_EXIT
				je M_EXIT
				
				xor eax, eax
				ret
				
				M_GET:
					push 512
					push OFFSET sBuffer
					push IDC_EDIT
					push hWnd
					Call GetDlgItemText
					
					push MB_OK
					push OFFSET sAppName
					push OFFSET sBuffer
					push NULL
					Call MessageBox
					
					xor eax, eax
					ret
				M_CLEAR:
					push NULL
					push IDC_EDIT
					push hWnd
					Call SetDlgItemText
					
					xor eax, eax
					ret
				M_SET:
					push OFFSET TestString
					push IDC_EDIT
					push hWnd
					Call SetDlgItemText
					
					xor eax, eax
					ret
				M_EXIT:
					push hWnd
					Call DestroyWindow
					
					xor eax, eax
					ret
			ELSEPART:
				shr eax, 16
				cmp ax, BN_CLICKED
				jne AFTERIF
					;push OFFSET TestString
					;push IDC_EDIT
					;push hWnd
					;Call SetDlgItemText
					push 512
					push OFFSET sBuffer
					push IDC_EDIT
					push hWnd
					Call GetDlgItemText
					
					push MB_OK
					push OFFSET sAppName
					push OFFSET sBuffer
					push hWnd
					Call MessageBox
			AFTERIF:
			xor eax, eax
			ret
			
		DESTROY:
			push NULL
			Call PostQuitMessage
			xor eax, eax
			ret
		EndWndProc:
			push lParam
			push wParam
			push uMsg
			push hWnd
			Call DefWindowProc
		
		ret
			
	WndProc EndP
	
end start