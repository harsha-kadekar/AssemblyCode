.386
.model flat, stdcall
option casemap: none

include windows.inc
include masm32.inc
include kernel32.inc
include user32.inc

includelib kernel32.lib
includelib masm32.lib
includelib user32.lib

WinMain PROTO :DWORD, :DWORD, :DWORD, :DWORD

.DATA

	ClassName			DB		"WinClass", 0
	AppName				DB		"Regular Window", 0
	WindowName			DB		"Title Of My Window !", 0
	sMenuName           DB      "FirstMenu", 0					;Added by Harsha
	
	RegClsExMBText		DB		"Failed to register window class", 0
	RegClsExMBCaption	DB		"Error", 0
	
	CrtWndMBText		DB		"Failed to create window", 0
	CrtWndMBCaption		DB		"Error", 0

.DATA?

	hInstance	HINSTANCE ?
	
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
	CALL ExitProcess

	
WinMain PROC hInst: HINSTANCE, hPrevInst: HINSTANCE, lpCmdLine: LPSTR, nCmdShow: DWORD

	LOCAL wc: WNDCLASSEX
	LOCAL msg: MSG
	LOCAL hwnd: HWND
	
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
	;MOV wc.lpszMenuName, NULL
	MOV wc.lpszMenuName, OFFSET sMenuName					;Added by Harsha

	;MOV wc.lpszClassName, ClassName
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
 	JZ RegClassFail

	;CALL CreateWindowEx
	PUSH NULL
	PUSH hInstance
	PUSH NULL
	PUSH NULL
	PUSH CW_USEDEFAULT
	PUSH CW_USEDEFAULT
	PUSH CW_USEDEFAULT
	PUSH CW_USEDEFAULT
	PUSH WS_OVERLAPPEDWINDOW or WS_VISIBLE
	PUSH offset WindowName
	PUSH offset ClassName
	PUSH WS_EX_CLIENTEDGE

	CALL CreateWindowEx
	
	CMP EAX, NULL
	JE CreateWindowFail

	;CALL ShowWindow
	PUSH hwnd
	PUSH nCmdShow
	CALL ShowWindow

	;CALL UpdateWindow
	PUSH hwnd
	CALL UpdateWindow


WhileLoop:

	;CALL GetMessage
	PUSH 0
	PUSH 0
	PUSH NULL
	LEA EAX, msg
	PUSH EAX
	CALL GetMessage

	CMP EAX, 0
	JE OutOfWhileLoop

	LEA EAX, msg
	PUSH EAX
	CALL TranslateMessage
	
	LEA EAX, msg
	PUSH EAX
	CALL DispatchMessage

	JMP WhileLoop

OutOfWhileLoop:

	MOV EAX, msg.wParam
	JMP ToTheEnd
	
RegClassFail:

	PUSH MB_ICONEXCLAMATION
	PUSH offset RegClsExMBCaption
	PUSH offset RegClsExMBText
	PUSH NULL
	CALL MessageBox

	XOR EAX, EAX
	JMP ToTheEnd

CreateWindowFail:

	PUSH MB_ICONEXCLAMATION
	PUSH offset CrtWndMBCaption
	PUSH offset CrtWndMBText
	PUSH NULL
	CALL MessageBox
	
	XOR EAX, EAX
	JMP ToTheEnd

ToTheEnd:

	RET
WinMain EndP

WndProc PROC hwnd: HWND, msg: UINT, wParam: WPARAM, lParam: LPARAM

;	CMP msg, WM_CLOSE
;	JE l_Close

	CMP msg, WM_DESTROY
	JE l_Destroy

	;JNE RecursiveCall

	PUSH lParam
	PUSH wParam	
	PUSH msg
	PUSH hwnd

	CALL DefWindowProc
	RET
	
l_Close:
	PUSH hwnd
	CALL DestroyWindow
	JMP EndOfProc

l_Destroy:

	PUSH 0
	CALL PostQuitMessage
	JMP EndOfProc
	
EndOfProc:
	XOR EAX, EAX				; Return 0
	RET
WndProc EndP


END START