;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Name:	PipeExample
;Author:	Harsha Kadekar
;Description:	To understand the working of pipes. Here annonymous pipes are used
;Date:	21-11-2011
;Last Modified:	21-11-2011
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.386
.model flat, stdcall

option casemap:none

include user32.inc
include kernel32.inc
include windows.inc
include gdi32.inc

includelib user32.lib
includelib kernel32.lib
includelib gdi32.lib

WinMain proto :DWORD,:DWORD, :DWORD, :DWORD
WndProc proto :DWORD, :DWORD, :DWORD, :DWORD

.const
IDR_MAINMENU equ 1000
IDM_ASSEMBLE equ 1002

.data
sClassName db "PipeExampleClass",0
sAppName db "PipeExampleApp", 0
CreatePipeError db "Error during pipe creation",0
sCreateProcessError db "Error during the process creation",0
sCommandLine db "ml /c /coff /Cp test.asm",0
sEditClass db "EDIT", 0

.data?
hInstance HINSTANCE ?
hwndEdit HWND ?

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
		LOCAL wc:WNDCLASSEX
		LOCAL msg:MSG
		LOCAL hwnd:HWND
		
		mov wc.cbSize, SIZEOF WNDCLASSEX
		mov wc.style, CS_HREDRAW or CS_VREDRAW
		mov wc.lpfnWndProc, OFFSET WndProc
		mov wc.hbrBackground, COLOR_APPWORKSPACE
		mov wc.cbClsExtra, NULL
		mov wc.cbWndExtra, NULL
		mov eax, hInst
		mov wc.hInstance, eax
		mov wc.lpszMenuName, IDR_MAINMENU
		mov wc.lpszClassName, OFFSET sClassName
		push IDI_APPLICATION
		push NULL
		Call LoadIcon
		mov wc.hIcon, eax
		mov wc.hIconSm, eax
		push IDC_ARROW
		push NULL
		mov wc.hCursor, eax
		
		lea eax, wc
		push eax
		Call RegisterClassEx
		
		push NULL
		push hInst
		push NULL
		push NULL
		push 200
		push 400
		push CW_USEDEFAULT
		push CW_USEDEFAULT
		push WS_OVERLAPPEDWINDOW+WS_VISIBLE
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
		LOCAL stinfo:STARTUPINFO
		LOCAL pi:PROCESS_INFORMATION
		LOCAL hRead:HWND
		LOCAL hWrite:HWND
		LOCAL rect:RECT
		LOCAL buffer[1024]:byte
		LOCAL bytesRead:DWORD
		LOCAL hdc:DWORD
		LOCAL sat:SECURITY_ATTRIBUTES
		
		mov eax, uMsg
		
		cmp eax, WM_CREATE
		je CREATE
		cmp eax, WM_CTLCOLOREDIT
		je CTLCOLOREDIT
		cmp eax, WM_SIZE
		je WNDSIZE
		cmp eax, WM_COMMAND
		je COMMAND
		cmp eax, WM_DESTROY
		je DESTROY
		
		jmp DEFAULT
		
		CREATE:
			push NULL
			push hInstance
			push NULL
			push hWnd
			push 0
			push 0
			push 0
			push 0
			push WS_CHILD+WS_VISIBLE+ES_MULTILINE+ES_AUTOHSCROLL+ES_AUTOVSCROLL
			push NULL
			push OFFSET sEditClass
			push NULL
			Call CreateWindowEx
			mov hwndEdit, eax
			
			jmp EndProc
			
		CTLCOLOREDIT:
			push Yellow
			push wParam
			Call SetTextColor
			
			push Black
			push wParam
			Call SetBkColor
			
			push BLACK_BRUSH
			Call GetStockObject
			ret
		
		WNDSIZE:
			mov edx,lParam
			mov ecx, edx
			shr ecx, 16
			and edx, 0ffffh
			
			push TRUE
			push ecx
			push edx
			push 0
			push 0
			push hwndEdit
			Call MoveWindow
			
			jmp EndProc
		
		COMMAND:
			cmp lParam, 0
			jne EndProc
				mov eax, wParam
				cmp ax, IDM_ASSEMBLE
				jne EndProc
					mov sat.nLength, SIZEOF SECURITY_ATTRIBUTES
					mov sat.lpSecurityDescriptor, NULL
					mov sat.bInheritHandle, TRUE
					
					push NULL
					lea eax, stinfo
					push eax
					;push addr hWrite
					;push addr hRead
					lea eax, hWrite
					push eax
					lea eax, hRead
					push eax
					Call CreatePipe
					
					cmp eax, NULL
					jne COMMAND_ELSE
						push MB_ICONERROR+MB_OK
						push OFFSET sAppName
						push OFFSET CreatePipeError
						push hWnd
						Call MessageBox
						
						jmp EndProc
					COMMAND_ELSE:
						mov stinfo.cb, SIZEOF STARTUPINFO
						lea eax, stinfo
						push eax
						Call GetStartupInfo
						
						mov eax, hWrite
						mov stinfo.hStdOutput, eax
						mov stinfo.hStdError, eax
						mov stinfo.dwFlags, STARTF_USESHOWWINDOW+STARTF_USESTDHANDLES
						mov stinfo.wShowWindow, SW_HIDE
						
						lea eax, pi
						push eax
						lea eax, stinfo
						push eax
						push NULL
						push NULL
						push NULL
						push TRUE
						push NULL
						push NULL
						push OFFSET sCommandLine
						push NULL
						Call CreateProcess
						
						cmp eax, NULL
						jne COMMAND_ELSE2
							push MB_ICONERROR+MB_OK
							push OFFSET sAppName
							push OFFSET sCreateProcessError
							push hWnd
							Call MessageBox
							
							jmp COMMAND_AFTERELSE2
						COMMAND_ELSE2:
							push hWrite
							Call CloseHandle
							
							COM_WHILE:
								push 1024
								lea eax, buffer
								push eax
								Call RtlZeroMemory
								
								push NULL
								lea eax, bytesRead
								push eax
								push 1023
								lea eax, buffer
								push eax
								push hRead
								Call ReadFile
								
								cmp eax, NULL
								jne AFTERIF_COM
									jmp COMMAND_AFTERELSE2
								AFTERIF_COM:
								
								push 0
								push -1
								push EM_SETSEL
								push hwndEdit
								Call SendMessage
								
								lea eax, buffer
								push eax
								push FALSE
								push EM_REPLACESEL
								push hwndEdit
								Call SendMessage
								
								jmp COM_WHILE
							COMMAND_AFTERELSE2:
							
							push hRead
							Call CloseHandle
							
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
	
end start
