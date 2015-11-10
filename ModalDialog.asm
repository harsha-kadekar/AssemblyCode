;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Name:	ModalDialog
;Author:	Harsha Kadekar
;Description:	Just an example to see the working of modal dialog box
;Date:	25-10-2011
;Last Modified:	30-10-2011
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

DlgProc PROTO :DWORD, :DWORD, :DWORD, :DWORD

.data

;sClassName db "DialogClass", 0
;sMenuName db "FirstMenu", 0
sDialogName db "IDD_DLG", 0
sAppName db "Dialogue", 0
TestString db "Here is the dialogue box",0

.data?

hInstance HINSTANCE ?
CommandLine LPSTR ?
sBuffer db 512 dup(?)
nError DWORD ?

.const

;IDC_EDIT equ 1002
;IDC_BUTTON equ 1003
;IDM_SET equ 1001
;IDM_CLEAR equ 1002
;IDM_GET equ 1003
;IDM_EXIT equ 1004

IDC_EDIT equ 1002
IDC_BUTTON equ 1003
;IDD_DLG equ 1001
;IDM_MNU equ 1000
;IDM_FILE equ 1011
IDM_SET equ 1001
IDM_CLEAR equ 1002
IDM_GET equ 1003
IDM_EXIT equ 1004

;FirstMenu equ 1000
;FirstDialog equ 1010

.code

start:
	push NULL
	Call GetModuleHandle
	mov hInstance, eax
	
	;Call GetCommandLine
	;mov CommandLine, eax
	
	push NULL
	push OFFSET DlgProc
	push NULL
	push OFFSET sDialogName
	push hInstance
	Call DialogBoxParam
	
	Call GetLastError
	mov nError, eax
	
	push eax
	Call ExitProcess
	
	DlgProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
			
		mov eax, uMsg
			
		cmp eax, WM_INITDIALOG
		je INITDIALOG
		cmp eax, WM_COMMAND
		je COMMAND
		cmp eax, WM_CLOSE
		je CLOSE
		
		mov eax, FALSE
		ret
		
		INITDIALOG:
			push IDC_EDIT
			push hWnd
			Call GetDlgItem
			
			push eax
			Call SetFocus
			
			mov eax, TRUE
			ret
		
		CLOSE:
			push 0
			push IDM_EXIT
			push WM_COMMAND
			push hWnd
			Call SendMessage
			
			mov eax, TRUE
			ret
		
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
				
				mov eax, FALSE
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
					
					mov eax, TRUE
					ret
				M_CLEAR:
					push NULL
					push IDC_EDIT
					push hWnd
					Call SetDlgItemText
					
					mov eax, TRUE
					ret
				M_SET:
					push OFFSET TestString
					push IDC_EDIT
					push hWnd
					Call SetDlgItemText
					
					mov eax, TRUE
					ret
				M_EXIT:
					push NULL
					push hWnd
					Call EndDialog
					
					mov eax, TRUE
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
			mov eax, TRUE
			ret
			
		
	
	
	Ret
DlgProc EndP
end start