;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Name:	ComControlExample
;Author:	Harsha Kadekar
;Description:	Testing the Com Controlls, understanding its working
;Date:	19-11-2011
;Last Modified:	19-11-2011
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.386
.model flat, stdcall

option casemap:none

include user32.inc
include kernel32.inc
include windows.inc
include comctl32.inc

includelib user32.lib
includelib kernel32.lib
includelib comctl32.lib

WinMain proto :DWORD, :DWORD, :DWORD, :DWORD
WndProc proto :DWORD, :DWORD, :DWORD, :DWORD

.const
IDC_PROGRESS equ 1
IDC_STATUS equ 2
IDC_TIMER equ 3

.data
sClassName db "CommonControllExample", 0
sAppName db "CommonControllExperiment",0
sProgressClass db "msctls_progress32", 0
sMessage db "Finished!",0
TimerID dd 0

.data?
hInstance HINSTANCE ?
hwndProgress dd ?
hwndStatus dd ?
CurrentStep dd ?

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
	
	Call InitCommonControls
	
	WinMain proc hInst:HINSTANCE, hPrevInst:HINSTANCE, CmdLine:LPSTR, CmdShow:DWORD
		LOCAL wc:WNDCLASSEX
		LOCAL msg:MSG
		LOCAL hwnd:HWND
		
		mov wc.cbSize, SIZEOF WNDCLASSEX
		mov wc.style,CS_HREDRAW OR CS_VREDRAW
		mov wc.lpfnWndProc,OFFSET WndProc
		mov wc.cbClsExtra,NULL
		mov wc.cbWndExtra,NULL
		mov eax, hInst
		mov wc.hInstance,eax
		mov wc.hbrBackground, COLOR_APPWORKSPACE
		mov wc.lpszMenuName,NULL
		mov wc.lpszClassName,OFFSET sClassName
		push IDI_APPLICATION
		push NULL
		Call LoadIcon
		mov wc.hIcon,eax
		push IDC_ARROW
		push NULL
		Call LoadCursor
		mov wc.hCursor,eax
		mov wc.hIconSm,NULL
		
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
		push WS_OVERLAPPED + WS_CAPTION +WS_SYSMENU + WS_MINIMIZEBOX + WS_MAXIMIZEBOX + WS_VISIBLE
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
			
			cmp eax, TRUE
			jne ENDWHILE
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
		cmp eax, WM_TIMER
		je TIMER
		
		jmp DEFAULT
		
		CREATE:
			push NULL
			push hInstance
			push IDC_PROGRESS
			push hWnd
			push 20
			push 300
			push 200
			push 100
			push WS_CHILD+WS_VISIBLE
			push NULL
			push OFFSET sProgressClass
			push NULL
			Call CreateWindowEx
			
			mov hwndProgress, eax
			mov eax, 1000
			mov CurrentStep, eax
			shl eax, 16
			
			push eax
			push 0
			push PBM_SETRANGE
			push hwndProgress
			Call SendMessage
			
			push 0
			push 10
			push PBM_SETSTEP
			push hwndProgress
			Call SendMessage
			
			push IDC_STATUS
			push hWnd
			push NULL
			push WS_CHILD+WS_VISIBLE
			Call CreateStatusWindow
			
			mov hwndStatus, eax
			push NULL
			push 100
			push IDC_TIMER
			push hWnd
			Call SetTimer
			
			mov TimerID, eax
			
			jmp EndProc
		
		DESTROY:
			push NULL
			Call PostQuitMessage
			
			cmp TimerID, 0
			je EndProc
				push TimerID
				push hWnd
				Call KillTimer
			
			jmp EndProc
			
		TIMER:
			push 0
			push 0
			push PBM_STEPIT
			push hwndProgress
			Call SendMessage
			
			sub CurrentStep, 10
			
			cmp CurrentStep, 0
			jne EndProc
				push TimerID
				push hWnd
				Call KillTimer
				
				mov TimerID, 0
				
				push OFFSET sMessage
				push 0
				push SB_SETTEXT
				push hwndStatus
				Call SendMessage
				
				push MB_OK+MB_ICONINFORMATION
				push OFFSET sAppName
				push OFFSET sMessage
				push hWnd
				Call MessageBox
				
				push 0
				push 0
				push SB_SETTEXT
				push hwndStatus
				Call SendMessage
				
				push 0
				push 0
				push PBM_SETPOS
				push hwndProgress
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