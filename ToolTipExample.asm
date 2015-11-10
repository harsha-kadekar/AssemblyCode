;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Name:	ToolTipExample
;Author:	Harsha Kadekar
;Description:	This window shows a tooltip in a client area
;Date:	17-12-2011
;Last Modified:	17-12-2011
;Source:	Iczelion
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.386
.model flat, stdcall

option casemap:none

include windows.inc
include user32.inc
include kernel32.inc
include comctl32.inc

includelib user32.lib
includelib kernel32.lib
includelib comctl32.lib

DlgProc proto :DWORD, :DWORD, :DWORD, :DWORD
EnumChild proto :DWORD, :DWORD
SetDlgToolArea proto :DWORD, :DWORD, :DWORD, :DWORD, :DWORD

.const
IDD_MAINDLG equ 1001

.data
sToolTipClassName db "Tooltips_class32",0
sUpLeftDialogText db "This is the upper left area of the dialog",0
sUpRightDialogText db "This is the upper right area of the dialog",0
sDownLeftDialogText db "This is the lower left area of the dialog",0
sDownRightDialogText db "This is the lower right area of the dialog",0

.data?
hwndTool dd ?
hInstance dd ?

.code
start:
	push NULL
	Call GetModuleHandle
	mov hInstance, eax
	
	push NULL
	push OFFSET DlgProc
	push NULL
	push IDD_MAINDLG
	push hInstance
	Call DialogBoxParam
	
	push eax
	Call ExitProcess
	
	DlgProc proc hDlg:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
		LOCAL ti:TOOLINFO
		LOCAL id:DWORD
		LOCAL rect:RECT
		
		mov eax, uMsg
		cmp eax, WM_INITDIALOG
		je INITDIALOG
		cmp eax, WM_CLOSE
		je CLOSE
		
		jmp DEFAULT
		
		INITDIALOG:
			Call InitCommonControls
			
			push NULL
			push hInstance
			push NULL
			push NULL
			push CW_USEDEFAULT
			push CW_USEDEFAULT
			push CW_USEDEFAULT
			push CW_USEDEFAULT
			push TTS_ALWAYSTIP
			push NULL
			push OFFSET sToolTipClassName
			push NULL
			Call CreateWindowEx
			mov hwndTool, eax
			
			mov id, 0
			mov ti.cbSize, SIZEOF TOOLINFO
			mov ti.uFlags, TTF_SUBCLASS
			mov eax, hDlg
			mov ti.hWnd, eax
			
			lea eax, rect
			push eax
			push hDlg
			Call GetWindowRect
			
			lea eax, rect
			push eax
			push id
			push OFFSET sUpLeftDialogText
			lea eax, ti
			push eax
			push hDlg
			Call SetDlgToolArea
			inc id
			
			lea eax, rect
			push eax
			push id
			push OFFSET sUpRightDialogText
			lea eax, ti
			push eax
			push hDlg
			Call SetDlgToolArea
			inc id
			
			lea eax, rect
			push eax
			push id
			push OFFSET sDownLeftDialogText
			lea eax, ti
			push eax
			push hDlg
			Call SetDlgToolArea
			inc id
			
			lea eax, rect
			push eax
			push id
			push OFFSET sDownRightDialogText
			lea eax, ti
			push eax
			push hDlg
			Call SetDlgToolArea
			
			lea eax, ti
			push eax
			lea eax, EnumChild
			push eax
			push hDlg
			Call EnumChildWindows
			
			jmp EndProc
		
		CLOSE:
			push NULL
			push hDlg
			Call EndDialog
			
			jmp EndProc

		DEFAULT:
			mov eax, FALSE
			ret
		
		EndProc:
			mov eax, TRUE
		Ret
	DlgProc EndP
	
	EnumChild proc uses edi hwndChild:DWORD, lParam:LPARAM
		LOCAL buffer[256]:byte
		
		mov edi, lParam
		assume edi:ptr TOOLINFO
		
		push hwndChild
		pop [edi].uId
		or [edi].uFlags, TTF_IDISHWND
		
		push 255
		lea eax, buffer
		push eax
		push hwndChild
		Call GetWindowText
		
		lea eax, buffer
		mov [edi].lpszText, eax
		
		push edi
		push NULL
		push TTM_ADDTOOL
		push hwndTool
		Call SendMessage
		
		assume edi:nothing
		
		
		Ret
	EnumChild EndP
	
	SetDlgToolArea proc uses edi esi hDlg:DWORD, lpti:DWORD, lpText:DWORD, id:DWORD, lprect:DWORD
		mov edi, lpti
		mov esi, lprect
		
		assume esi:ptr RECT
		assume edi:ptr TOOLINFO
		
		mov eax, id
		cmp eax, 0
		je ZERO
		cmp eax, 1
		je ONE
		cmp eax, 2
		je TWO
		cmp eax, 3
		je THREE
		
		jmp EndProc
		
		ZERO:
			mov [edi].rect.left, 0
			mov [edi].rect.top, 0
			mov eax, [esi].right
			sub eax, [esi].left
			shr eax, 1
			mov [edi].rect.right, eax
			mov eax, [esi].bottom
			sub eax, [esi].top
			shr eax, 1
			mov [edi].rect.bottom, eax
			
			jmp EndProc
		
		ONE:
			MOV eax, [esi].right
			sub eax, [esi].left
			shr eax, 1
			;inc eax
			mov [edi].rect.left, eax
			mov [edi].rect.top, 0
			mov eax, [esi].right
			sub eax, [esi].left
			mov [edi].rect.right, eax
			mov eax, [esi].bottom
			sub eax, [esi].top
			mov [edi].rect.bottom, eax
			
			jmp EndProc
			
		TWO:
			mov [edi].rect.left, 0
			mov eax, [esi].bottom
			sub eax, [esi].top
			shr eax, 1
			;inc eax
			mov [edi].rect.top, eax
			mov eax, [esi].right
			sub eax, [esi].left
			shr eax, 1
			mov [edi].rect.right, eax
			mov eax, [esi].bottom
			sub eax, [esi].top
			mov [edi].rect.bottom, eax
			
			jmp EndProc
			
		THREE:
			mov eax, [esi].right
			sub eax, [esi].left
			shr eax, 1
			;inc eax
			mov [edi].rect.left, eax
			mov eax, [esi].bottom
			sub eax, [esi].top
			shr eax, 1
			;inc eax
			mov [edi].rect.top, eax
			mov eax, [esi].right
			sub eax, [esi].left
			mov [edi].rect.right, eax
			mov eax, [esi].bottom
			sub eax, [esi].top
			mov [edi].rect.bottom, eax
			
		EndProc:
		
		push lpText
		pop [edi].lpszText
		
		push lpti
		push NULL
		push TTM_ADDTOOL
		push hwndTool
		Call SendMessage
		
		assume esi:nothing
		assume edi:nothing
		
		Ret
	SetDlgToolArea EndP 
	
end start