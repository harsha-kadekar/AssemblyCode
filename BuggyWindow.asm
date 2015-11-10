.386
.MODEL FLAT, STDCALL
OPTION CASEMAP:NONE

INCLUDE windows.inc
INCLUDE kernel32.inc
INCLUDE masm32.inc
INCLUDE user32.inc
INCLUDE gdi32.inc

INCLUDELIB kernel32.lib
INCLUDELIB masm32.lib
INCLUDELIB user32.lib


.DATA

	ClassName			DB		"WinClass", 0
	AppName				DB		"Special Window", 0
	WindowName			DB		"Title Of My Window !", 0
	
	RegClsExMBText		DB		"Failed to register window class", 0
	RegClsExMBCaption	DB		"Error", 0
	
	CrtWndMBText		DB		"Failed to create window", 0
	CrtWndMBCaption		DB		"Error", 0
.DATA?

	hInstance HINSTANCE ?

.CONST


.CODE
START:
	PUSH NULL
	CALL GetModuleHandle
	MOV hInstance, EAX
	
	PUSH hInstance
	PUSH NULL
	PUSH NULL
	PUSH 0
	CALL WinMain
	
	PUSH EAX
	;PUSH ExitProcess
	Call ExitProcess

WinMain PROC hInst: HINSTANCE, hPrevInst: HINSTANCE, lpCmdLine: LPSTR, nCmdShow: DWORD

	LOCAL wc: WNDCLASSEX
	LOCAL Msg: MSG
	LOCAL hWnd: HWND

	MOV wc.cbSize, SIZEOF WNDCLASSEX
	MOV wc.style, 0
	
	;PUSH offset WndProc
	;POP wc.lpfnWndProc
	MOV wc.lpfnWndProc, offset WndProc
	
	MOV wc.cbClsExtra, 0
	MOV wc.cbWndExtra, 0

	PUSH hInstance
	POP wc.hInstance

	;CALL LoadIcon
	PUSH IDI_APPLICATION
	PUSH NULL
	CALL LoadIcon
	MOV wc.hIcon, EAX
	
	;CALL LoadCursor
	PUSH IDC_ARROW
	PUSH NULL
	CALL LoadCursor
	MOV wc.hCursor, EAX
	
	MOV wc.hbrBackground, COLOR_WINDOW + 1
	MOV wc.lpszMenuName, NULL
	
	PUSH offset ClassName
	POP wc.lpszClassName
	
	;CALL LoadIcon
	PUSH IDI_APPLICATION
	PUSH NULL
	CALL LoadIcon
	MOV wc.hIconSm, EAX

	;CALL RegisterClassEx
	LEA EAX, wc
	PUSH EAX
	CALL RegisterClassEx

 	CMP EAX, 0
 	JZ l_RegClassFail

	;CALL CreateWindowEx
	PUSH NULL
	PUSH hInstance
	PUSH NULL
	PUSH NULL
	PUSH CW_USEDEFAULT
	PUSH CW_USEDEFAULT
	PUSH CW_USEDEFAULT
	PUSH CW_USEDEFAULT
	PUSH WS_OVERLAPPEDWINDOW + WS_VISIBLE
	PUSH offset WindowName
	PUSH offset ClassName
	PUSH WS_EX_CLIENTEDGE

	CALL CreateWindowEx

	CMP EAX, NULL
	JE l_CreateWindowFail
	
	mov hWnd, eax

	;CALL ShowWindow
	PUSH nCmdShow
	PUSH hWnd
	CALL ShowWindow

	;CALL UpdateWindow
	PUSH hWnd
	CALL UpdateWindow


l_WhileLoop:

	;CALL GetMessage
	PUSH 0
	PUSH 0
	PUSH NULL
	LEA EAX, Msg
	PUSH EAX
	CALL GetMessage

	CMP EAX, 0
	JE l_OutOfWhileLoop

	LEA EAX, Msg
	PUSH EAX
	CALL TranslateMessage
	
	LEA EAX, Msg
	PUSH EAX
	CALL DispatchMessage

	JMP l_WhileLoop

l_OutOfWhileLoop:

	MOV EAX, Msg.wParam
	JMP l_ToTheEnd
	
l_RegClassFail:

	PUSH MB_ICONEXCLAMATION
	PUSH offset RegClsExMBCaption
	PUSH offset RegClsExMBText
	PUSH NULL
	CALL MessageBox

	XOR EAX, EAX
	JMP l_ToTheEnd

l_CreateWindowFail:

	PUSH MB_ICONEXCLAMATION
	PUSH offset CrtWndMBCaption
	PUSH offset CrtWndMBText
	PUSH NULL
	CALL MessageBox
	
	XOR EAX, EAX
	JMP l_ToTheEnd

l_ToTheEnd:
	
	
	RET
WinMain EndP


WndProc PROC hWnd: HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM

	LOCAL hMenu: HMENU

;	CMP Msg, WM_COMMAND
;	JE l_Cmd
	
	CMP Msg, WM_CLOSE
	JE l_Close

	CMP Msg, WM_DESTROY
	JE l_Destroy

	;JNE RecursiveCall

	PUSH lParam
	PUSH wParam	
	PUSH Msg
	PUSH hWnd

	CALL DefWindowProc
	RET

l_Close:
	PUSH hWnd
	CALL DestroyWindow
	JMP l_EndOfProc

l_Destroy:

	PUSH NULL
	CALL PostQuitMessage
	JMP l_EndOfProc
	
l_EndOfProc:
	;XOR EAX, TRUE
	xor eax, eax
	RET
WndProc EndP

END START