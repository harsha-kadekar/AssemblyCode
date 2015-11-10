;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Name:	WndSubClassingExample
;Author:	Harsha Kadekar
;Description:	This feature helps in edit box and other controls user given value validation
;Date:	21-11-2011
;Last Modified:	21-11-2011
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.386
.model flat, stdcall

option casemap:none

include user32.inc
include kernel32.inc
include windows.inc

includelib user32.lib
includelib kernel32.lib

WinMain proto :DWORD, :DWORD, :DWORD, :DWORD
EditWndProc proto :DWORD, :DWORD, :DWORD, :DWORD
WndProc proto :DWORD, :DWORD, :DWORD, :DWORD

.data
sClassName db "WndSubClassing",0
sAppName db "WmdSubClassingApp",0
sEditClass db "EDIT",0
sMessage db "You pressed enter in the text box!!!!", 0

.data?
hInstance HINSTANCE ?
hwndEdit HWND ?
OldWndProc dd ?

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
	
	WinMain proc hInst:HINSTANCE, hPrevInst:HINSTANCE, sCmdLine:LPSTR, CmdShow:DWORD
	
		LOCAL hwnd:HWND
		LOCAL msg:MSG
		LOCAL wc:WNDCLASSEX
		
		mov wc.cbSize,SIZEOF WNDCLASSEX
		mov wc.style, CS_HREDRAW or CS_VREDRAW
		mov wc.lpfnWndProc,OFFSET WndProc
		mov wc.cbClsExtra, NULL
		mov wc.cbWndExtra, NULL
		mov eax, hInst
		mov wc.hInstance, eax
		mov wc.hbrBackground, COLOR_APPWORKSPACE
		mov wc.lpszMenuName, NULL
		mov wc.lpszClassName, OFFSET sClassName
		push IDI_APPLICATION
		push NULL
		Call LoadIcon
		mov wc.hIcon, eax
		mov wc.hIconSm, NULL
		push IDC_ARROW
		push NULL
		Call LoadCursor
		mov wc.hCursor, eax
		
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
		push WS_OVERLAPPED+WS_VISIBLE+WS_CAPTION+WS_SYSMENU+WS_MINIMIZEBOX+WS_MAXIMIZEBOX
		push OFFSET sAppName
		push OFFSET sClassName
		push WS_EX_CLIENTEDGE
		Call CreateWindowEx
		mov hwnd, eax
		
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
		cmp eax, WM_DESTROY
		je DESTROY
		
		jmp DEFAULT
		
		CREATE:
			push NULL
			push hInstance
			push NULL
			push hWnd
			push 25
			push 300
			push 20
			push 20
			push WS_CHILD+WS_BORDER+WS_VISIBLE
			push NULL
			push OFFSET sEditClass
			push WS_EX_CLIENTEDGE
			Call CreateWindowEx
			mov hwndEdit,eax
			
			push eax
			Call SetFocus
			
			push OFFSET EditWndProc
			push GWL_WNDPROC
			push hwndEdit
			Call SetWindowLong
			
			mov OldWndProc, eax
			
			jmp EndProc
			
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
	
	EditWndProc proc hEdit:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	
		mov eax, uMsg
	
		cmp eax, WM_CHAR
		je CHAR_MSG
		cmp eax, WM_KEYDOWN
		je KEYDOWN
	
		jmp DEFAULT_CUST
	
		CHAR_MSG:
			mov eax, wParam
			.if(al >= "0" && al <= "9")||(al >= "A" && al <= "F") || (al >= "a" && al <= "f") || al == VK_BACK
				.if(al >="a" && al <= "f")
					sub al,20h
				.endif
				push lParam
				;push wParam
				push eax
				push uMsg
				push hEdit
				push OldWndProc
				Call CallWindowProc
				ret
			.endif
			jmp Edit_EndProc
		
		KEYDOWN:
			mov eax, wParam
			cmp al, VK_RETURN
			jne ELSE_KEYDOWN
				push MB_OK+MB_ICONINFORMATION
				push OFFSET sAppName
				push OFFSET sMessage
				push hEdit
				Call MessageBox
				
				push hEdit
				Call SetFocus
				jmp Edit_EndProc
			ELSE_KEYDOWN:
				push lParam
				push wParam
				push uMsg
				push hEdit
				push OldWndProc
				Call CallWindowProc
				ret
		
		DEFAULT_CUST:
			push lParam
			push wParam
			push uMsg
			push hEdit
			push OldWndProc
			Call CallWindowProc
			
			ret
		
		Edit_EndProc:
			xor eax, eax
		Ret
	EditWndProc EndP
	
end start