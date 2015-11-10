;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Name: HookMain
;Author:	Harsha Kadekar
;Description:	This is program takes part the GUI part. This is part of the program used to see the
;				working of the hook dll
;Date:	16-12-2011
;Last Modified:	16-12-2011
;Source:	Iczelion
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.386
.model flat, stdcall

option casemap:none

include windows.inc
include user32.inc
include kernel32.inc
include MouseHook.inc

includelib user32.lib
includelib kernel32.lib
includelib MouseHook.lib

;wsprintfA PROTO C :DWORD, :DWORD, :VARARG
;wsprintf TEXTEQU <wsprintfA>

DlgFunc PROTO :DWORD, :DWORD, :DWORD, :DWORD


.const
IDD_MAINDLG equ 101
IDC_CLASSNAME equ 1000
IDC_HANDLE equ 1001
IDC_WNDPROC equ 1002
IDC_HOOK equ 1004
IDC_EXIT equ 1005
WM_MOUSEHOOK equ WM_USER+6

.data
bHookFlag dd FALSE
sHookText db "&Hook",0
sUnhookText db "&UnHook", 0
template db "%lx",0

.data?
hInstance dd ?
hHook dd ?

.code
start:

	push NULL
	Call GetModuleHandle
	mov hInstance, eax
	
	push NULL
	push OFFSET DlgFunc
	push NULL
	push IDD_MAINDLG
	push hInstance
	Call DialogBoxParam
	
	push NULL
	Call ExitProcess
	
	DlgFunc proc hDlg:DWORD, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	
	LOCAL hLib:DWORD
	LOCAL buffer[128]:BYTE
	LOCAL buffer1[128]:BYTE
	LOCAL rect:RECT
	
	mov eax, uMsg
	cmp eax, WM_CLOSE
	je CLOSE
	cmp eax, WM_INITDIALOG
	je INITDIALOG
	cmp eax, WM_MOUSEHOOK
	je MOUSEHOOK
	cmp eax, WM_COMMAND
	je COMMAND
	
	jmp DEFAULT
	
	CLOSE:
		cmp bHookFlag, TRUE
		jne AFTERIF_CLOSE
			Call UninstallHook
		AFTERIF_CLOSE:
		push NULL
		push hDlg
		Call EndDialog
		jmp EndProc
		
	INITDIALOG:
		lea eax,rect
		push eax
		push hDlg
		Call GetWindowRect
		
		push SWP_SHOWWINDOW
		push rect.bottom
		push rect.right
		push rect.top
		push rect.left
		push HWND_TOPMOST
		push hDlg
		Call SetWindowPos
		
		jmp EndProc
		
	MOUSEHOOK:
		push 128
		lea eax, buffer1
		push eax
		push IDC_HANDLE
		push hDlg
		Call GetDlgItem
		
		push wParam
		push OFFSET template
		lea eax, buffer
		push eax
		Call wsprintf
		
		lea eax, buffer1
		push eax
		lea eax, buffer
		push eax
		Call lstrcmpi
		
		cmp eax, 0
		je AFTERIF_MOUSEHOOK1
			lea eax, buffer
			push eax
			push IDC_HANDLE
			push hDlg
			Call SetDlgItemText
		AFTERIF_MOUSEHOOK1:
		
		push 128
		lea eax,buffer1
		push eax
		push IDC_CLASSNAME
		push hDlg
		Call GetDlgItemText
		
		push 128
		lea eax,buffer
		push eax
		push wParam
		Call GetClassName
		
		lea eax,buffer1
		push eax
		lea eax, buffer
		push eax
		Call lstrcmpi
		
		cmp eax, 0
		je AFTERIF_MOUSEHOOK2
			lea eax, buffer
			push eax
			push IDC_CLASSNAME
			push hDlg
			Call SetDlgItemText
		AFTERIF_MOUSEHOOK2:
		
		push 128
		lea eax, buffer1
		push eax
		push IDC_WNDPROC
		push hDlg
		Call GetDlgItemText
		
		push GCL_WNDPROC
		push wParam
		Call GetClassName
		
		push eax
		push OFFSET template
		lea eax, buffer
		push eax
		Call wsprintf
		
		lea eax, buffer1
		push eax
		lea eax, buffer
		push eax
		Call lstrcmpi
		
		cmp eax, 0
		je AFTERIF_MOUSEHOOK3
			lea eax, buffer
			push eax
			push IDC_WNDPROC
			push hDlg
			Call SetDlgItemText
		AFTERIF_MOUSEHOOK3:
		
		jmp EndProc
		
	COMMAND:
		cmp lParam, 0
		je EndProc
			mov eax, wParam
			mov edx, eax
			shr edx, 16
			cmp dx, BN_CLICKED
			jne EndProc
				cmp ax, IDC_EXIT
				jne ELSE_COMMAND1
					push 0
					push 0
					push WM_CLOSE
					push hDlg
					Call SendMessage
					jmp EndProc
				ELSE_COMMAND1:
					cmp bHookFlag, FALSE
					jne ELSE_COMMAND2
						push hDlg
						Call InstallHook
						cmp eax, NULL
						je EndProc
							mov bHookFlag, TRUE
							push OFFSET sUnhookText
							push IDC_HOOK
							push hDlg
							Call SetDlgItemText
							jmp EndProc
					ELSE_COMMAND2:
						Call UninstallHook
						push OFFSET sUnhookText
						push IDC_HOOK
						push hDlg
						Call SetDlgItemText
						
						mov bHookFlag, FALSE
						push NULL
						push IDC_CLASSNAME
						push  hDlg
						Call SetDlgItemText
						
						push NULL
						push IDC_HANDLE
						push hDlg
						Call SetDlgItemText
						
						push NULL
						push IDC_WNDPROC
						push hDlg
						Call SetDlgItemText
						
						jmp EndProc
		
		DEFAULT:
			mov eax, FALSE
			ret
		
		EndProc:
			
		mov eax, TRUE
		ret
		
	DlgFunc endp

end start
		
		
		
		
		


