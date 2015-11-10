;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;NAME:			ProcessExample
;AUTHOR:		HARSHA KADEKAR
;DESCRIPTION:	Just to experiment with the win32 apis regarding process
;DATE:			13-11-2011
;LAST MODIFIED:	15-11-2011
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


.386
.model FLAT, stdcall
option casemap:none

include windows.inc
include kernel32.inc
include user32.inc

includelib user32.lib
includelib kernel32.lib

WinMain proto :DWORD, :DWORD, :DWORD, :DWORD
WndProc proto :DWORD, :DWORD, :DWORD, :DWORD

.const
IDM_CREATE_PROCESS equ 1001
IDM_TERMINATE	  equ 1002
IDM_EXIT		  equ 1003

.data
sClassName db "ProcessClass",0
sAppName db "ProcessExample",0
sMenuName db "FirstMenu",0
;sProgramename db "SimplePaint.exe",0
sProgramename db "C:\\WINDOWS\\system32\\mspaint.exe",0


.data?
hInstance HINSTANCE ?
sCommandLine LPSTR ?
hMenu HANDLE ?
dExitCode DWORD ?
processInfo PROCESS_INFORMATION <>


.code
start:
	push NULL
	Call GetModuleHandle
	mov hInstance, eax
	
	Call GetCommandLine
	mov sCommandLine, eax
	
	push SW_SHOWDEFAULT
	push sCommandLine
	push NULL
	push hInstance
	Call WinMain
	
	push eax
	Call ExitProcess
	
	WinMain proc hInst:HINSTANCE, hPrevInst:HINSTANCE, CmdLine:LPSTR, CmdShow:DWORD
		
		LOCAL wc:WNDCLASSEX
		LOCAL msg:MSG
		LOCAL hwnd:HWND
		
		mov wc.cbClsExtra, NULL
		mov wc.cbSize, SIZEOF WNDCLASSEX
		mov wc.cbWndExtra, NULL
		mov wc.hbrBackground, COLOR_WINDOW + 1
		push IDC_ARROW
		push NULL
		Call LoadCursor
		mov wc.hCursor, eax
		push IDI_APPLICATION
		push NULL 
		Call LoadIcon
		mov wc.hIcon,eax 
		mov wc.hIconSm, NULL
		mov eax, hInst
		mov wc.hInstance,eax
		mov wc.lpfnWndProc, OFFSET WndProc
		mov wc.lpszClassName, OFFSET sClassName
		mov wc.lpszMenuName, OFFSET sMenuName
		mov wc.style, CS_HREDRAW or CS_VREDRAW
		
		lea eax, wc
		push eax
		Call RegisterClassEx
		
		push NULL
		push hInst
		push NULL
		push NULL
		;push 200
		;push 300
		push CW_USEDEFAULT
		push CW_USEDEFAULT
		push CW_USEDEFAULT
		push CW_USEDEFAULT
		push WS_OVERLAPPEDWINDOW
		push OFFSET sAppName
		push OFFSET sClassName
		;push WS_EX_CLIENTEDGE
		push NULL
		Call CreateWindowEx
		mov hwnd, eax
		
		push SW_SHOWNORMAL
		push hwnd
		Call ShowWindow
		
		push hwnd
		Call UpdateWindow
		
		push hwnd
		Call GetMenu
		mov hMenu, eax
		
		MAINWHILE:
			push 0
			push 0
			push NULL
			;push OFFSET msg
			lea eax, msg
			push eax
			Call GetMessage
			
			cmp eax, 0
			je END_MAINWHILE
			;push OFFSET msg
				lea eax, msg
				push eax
				Call TranslateMessage
				
				lea eax, msg
				push eax
				Call DispatchMessage
				
			jmp MAINWHILE
		END_MAINWHILE:
		
		mov eax, msg.wParam
		Ret
	WinMain EndP
	
	WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	
;		LOCAL startInfo:STARTUPINFO
;		.IF uMsg==WM_DESTROY
;			invoke PostQuitMessage,NULL
;		.ELSEIF uMsg==WM_INITMENUPOPUP
;			invoke GetExitCodeProcess,processInfo.hProcess,ADDR dExitCode
;			.if eax==TRUE
;				.if dExitCode==STILL_ACTIVE
;					invoke EnableMenuItem,hMenu,IDM_CREATE_PROCESS,MF_GRAYED
;					invoke EnableMenuItem,hMenu,IDM_TERMINATE,MF_ENABLED
;				.else
;					invoke EnableMenuItem,hMenu,IDM_CREATE_PROCESS,MF_ENABLED
;					invoke EnableMenuItem,hMenu,IDM_TERMINATE,MF_GRAYED
;				.endif
;			.else
;				invoke EnableMenuItem,hMenu,IDM_CREATE_PROCESS,MF_ENABLED
;				invoke EnableMenuItem,hMenu,IDM_TERMINATE,MF_GRAYED
;			.endif
;		.ELSEIF uMsg==WM_COMMAND
;			mov eax,wParam
;			.if lParam==0
;				.if ax==IDM_CREATE_PROCESS
;					.if processInfo.hProcess!=0
;						invoke CloseHandle,processInfo.hProcess
;						mov processInfo.hProcess,0
;					.endif
;					invoke GetStartupInfo,ADDR startInfo
;					invoke CreateProcess,ADDR sProgramename,NULL,NULL,NULL,FALSE,\
;	                                        NORMAL_PRIORITY_CLASS,\
;	                                        NULL,NULL,ADDR startInfo,ADDR processInfo
;					invoke CloseHandle,processInfo.hThread
;				.elseif ax==IDM_TERMINATE
;					invoke GetExitCodeProcess,processInfo.hProcess,ADDR dExitCode
;					.if dExitCode==STILL_ACTIVE
;						invoke TerminateProcess,processInfo.hProcess,0
;					.endif
;					invoke CloseHandle,processInfo.hProcess
;					mov processInfo.hProcess,0
;				.else
;					invoke DestroyWindow,hWnd
;				.endif
;			.endif
;		.ELSE
;			invoke DefWindowProc,hWnd,uMsg,wParam,lParam
;			ret
;		.ENDIF
;		xor    eax,eax
;		ret

	
		LOCAL startInfo:STARTUPINFO
		
		mov eax, uMsg
		cmp eax, WM_DESTROY
		je DESTROY
		cmp eax, WM_INITMENUPOPUP
		je MENUPOP
		cmp eax, WM_COMMAND
		je COMMAND
		
		jmp DEFAULT
		
		DESTROY:
			push NULL
			Call PostQuitMessage
			jmp ENDPROC
		
		MENUPOP:
			lea eax, dExitCode
			push eax
			push processInfo.hProcess
			Call GetExitCodeProcess
			
			cmp eax, TRUE
			jne MENUPOP_ELSE1
				cmp dExitCode, STILL_ACTIVE
				jne MENUPOP_ELSE2
					push MF_GRAYED
					push IDM_CREATE_PROCESS
					push hMenu
					Call EnableMenuItem
					
					push MF_ENABLED
					push IDM_TERMINATE
					push hMenu
					Call EnableMenuItem
					
					jmp MENUPOP_ENDIF1
				MENUPOP_ELSE2:
					push MF_ENABLED
					push IDM_CREATE_PROCESS
					push hMenu
					Call EnableMenuItem
					
					push MF_GRAYED
					push IDM_TERMINATE
					push hMenu
					Call EnableMenuItem
					
					jmp MENUPOP_ENDIF1
			MENUPOP_ELSE1:
				push MF_ENABLED
				push IDM_CREATE_PROCESS
				push hMenu
				Call EnableMenuItem
				
				push MF_GRAYED
				push IDM_TERMINATE
				push hMenu
				Call EnableMenuItem
				
			MENUPOP_ENDIF1:
				jmp ENDPROC
		
		COMMAND:
			mov eax, wParam
			cmp lParam, 0
			jne ENDPROC
				cmp ax, IDM_CREATE_PROCESS
				je M_CREATE
				cmp ax, IDM_TERMINATE
				je M_TERMINATE
				cmp ax, IDM_EXIT
				je M_EXIT
				
				jmp ENDPROC
				
				M_CREATE:
					cmp processInfo.hProcess, 0
					je CREATEENDIF1
						push processInfo.hProcess
						Call CloseHandle
					CREATEENDIF1:
					
					lea eax, startInfo
					push eax
					Call GetStartupInfo
					
					lea eax, processInfo
					push eax
					lea eax, startInfo
					push eax
					push NULL
					push NULL
					push NORMAL_PRIORITY_CLASS
					push FALSE
					push NULL
					push NULL
					push NULL
					push OFFSET sProgramename
					Call CreateProcess
					
					push processInfo.hThread
					Call CloseHandle
					
					jmp ENDPROC
				
				M_TERMINATE:
					lea eax, dExitCode
					push eax
					push processInfo.hProcess
					Call GetExitCodeProcess
					
					cmp dExitCode, STILL_ACTIVE
					jne TERMINATE_ENDIF
						push 0
						push processInfo.hProcess
						Call TerminateProcess
					TERMINATE_ENDIF:
					
					push processInfo.hProcess
					Call CloseHandle
					
					mov processInfo.hProcess, 0
					
					jmp ENDPROC
				
				M_EXIT:
					push hWnd
					Call DestroyWindow
					
					jmp ENDPROC
									
		DEFAULT:
			push lParam
			push wParam
			push uMsg
			push hWnd
			Call DefWindowProc
			ret
			
		ENDPROC:
			xor eax, eax			
		
		Ret
	WndProc EndP
end start
	
	