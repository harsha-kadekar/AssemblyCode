;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Name:	SuperClassWindow
;Author:	Harsha Kadekar
;Description:	This will give you example of how to superclass a window
;Date:	14-12-2011
;Last Modified:	114-12-2011
;Coutousey:	Iczelion
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.386
.model flat, stdcall
option casemap:none

include windows.inc
include user32.inc
include kernel32.inc

includelib user32.lib
includelib kernel32.lib

WM_SUPERCLASS equ WM_USER+5

WinMain PROTO :DWORD, :DWORD, :DWORD, :DWORD
WndProc PROTO :DWORD, :DWORD, :DWORD, :DWORD
EditWndProc PROTO :DWORD, :DWORD, :DWORD, :DWORD

.data
sClassName db "SuperClassWndClass",0
sAppName db "SuperClassingWindow",0
sEditClass db "EDIT",0
sNewClass db "SuperEditClass",0
sMessage db "you have pressed the enter key in the text box!",0

.data?
hInstance dd ?
hWndEdit dd 6 dup(?)
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
	
	WinMain proc hInst:HINSTANCE, hPrevInst:HINSTANCE, CmdLine:LPSTR, CmdShow:DWORD
	
		LOCAL wc:WNDCLASSEX
		LOCAL msg:MSG
		LOCAL hWnd:HWND
		
		mov wc.cbClsExtra, NULL
		mov wc.cbSize, SIZEOF WNDCLASSEX
		mov wc.cbWndExtra, NULL
		mov wc.hbrBackground, COLOR_APPWORKSPACE
		push NULL
		push IDC_ARROW
		Call LoadCursor
		mov wc.hCursor,eax
		push NULL
		push IDI_APPLICATION
		Call LoadIcon
		mov wc.hIcon, eax
		mov wc.hIconSm, eax
		mov eax, hInst
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
		push 220
		push 320
		push CW_USEDEFAULT
		push CW_USEDEFAULT
		push WS_OVERLAPPED+WS_CAPTION+WS_SYSMENU+WS_MINIMIZEBOX+WS_MAXIMIZEBOX+WS_VISIBLE
		push OFFSET sAppName
		push OFFSET sClassName
		push WS_EX_CLIENTEDGE+WS_EX_CONTROLPARENT
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
			je STOP_WHILE
				lea eax, msg
				push eax
				Call TranslateMessage
				
				lea eax, msg
				push eax
				Call DispatchMessage
				
			jmp START_WHILE
		STOP_WHILE:
		
		mov eax, msg.wParam
		
		Ret
	WinMain EndP
	
	WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	
		LOCAL wc:WNDCLASSEX
		
		mov eax, uMsg
		cmp eax, WM_CREATE
		je CREATE
		cmp eax, WM_DESTROY
		je DESTROY
		
		jmp DEFAULT
		
		CREATE:
			mov wc.cbSize, SIZEOF WNDCLASSEX
			
			lea eax, wc
			push eax
			push OFFSET sEditClass
			push NULL
			Call GetClassInfoEx
			
			push wc.lpfnWndProc
			pop OldWndProc
			
			mov wc.lpfnWndProc, OFFSET EditWndProc
			push hInstance
			pop wc.hInstance
			
			mov wc.lpszClassName, OFFSET sNewClass
			
			lea eax, wc
			push eax
			Call RegisterClassEx
			
			xor ebx, ebx
			mov edi, 20
			START_CREATE_WHILE:
				cmp ebx, 6
				jge END_CREATE_WHILE
					push NULL
					push hInstance
					push ebx
					push hWnd
					push 25
					push 300
					push edi
					push 20
					push WS_CHILD+WS_BORDER+WS_VISIBLE
					push NULL
					push OFFSET sNewClass
					push WS_EX_CLIENTEDGE
					Call CreateWindowEx
					
					mov dword ptr [hWndEdit+4*ebx], eax
					add edi, 25
					inc ebx
				jmp START_CREATE_WHILE
			END_CREATE_WHILE:
			
			push hWndEdit
			Call SetFocus
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
		
		jmp DEFAULT
		
		CHAR_MSG:
			mov eax, wParam
			;.if( al>="0" && al<="9")||( al>="A" && al<="F")||( al>="a"&& al<="f")|| (al==VK_BACK)
			 .if (al>="0" && al<="9") || (al>="A" && al<="F") || (al>="a" && al<="f") || al==VK_BACK
				.if( al>="a" && al<="f")
					sub al, 20h
				.endif
				
				push lParam
				push eax
				push uMsg
				push hEdit
				push OldWndProc
				Call CallWindowProc
				
				ret
			.endif
			jmp EndProc_EDIT
		
		KEYDOWN:
			mov eax, wParam
			cmp al, VK_TAB
			je TABVK
			cmp al, VK_RETURN
			je RETURNVK
			
			jmp DEFAULT_KEY
			
			RETURNVK:
				push MB_OK+MB_ICONINFORMATION
				push OFFSET sAppName
				push OFFSET sMessage
				push hEdit
				Call MessageBox
				
				push hEdit
				Call SetFocus
				jmp EndProc_EDIT
			
			TABVK:
				push VK_SHIFT
				Call GetKeyState
				
				test eax, 80000000
				.if ZERO?
					push GW_HWNDNEXT
					push hEdit
					Call GetWindow
					cmp eax, NULL
					jne AFTER_IF_TAB
						push GW_HWNDFIRST
						push hEdit
						Call GetWindow
						
					jmp AFTER_IF_TAB
				.else
					push GW_HWNDPREV
					push hEdit
					Call GetWindow
					cmp eax, NULL
					jne AFTER_IF_TAB
						push GW_HWNDLAST
						push hEdit
						Call GetWindow
				.endif
				AFTER_IF_TAB:
				push eax
				Call SetFocus
				
				xor eax, eax
				ret
		
			DEFAULT_KEY:
				push lParam
				push wParam
				push uMsg
				push hEdit
				push OldWndProc
				Call CallWindowProc
				
				ret
		
		DEFAULT:
			push lParam
			push wParam
			push uMsg
			push hEdit
			push OldWndProc
			Call CallWindowProc
			
			ret
		
		EndProc_EDIT:
		
			xor eax, eax
		
		Ret
	EditWndProc EndP
	
end start	
	
	
	
	
	