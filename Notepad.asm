.486
.model flat, stdcall

option casemap:none


include kernel32.inc
include user32.inc
include windows.inc
include gdi32.inc


includelib kernel32.lib
includelib user32.lib
includelib masm32.lib
includelib gdi32.lib

WinMain proto :DWORD, :DWORD, :DWORD, :DWORD

.data
	sClassName db "asmNotePad", 0	
	sAppName db "asmPad", 0
	dwCharSet DWORD 1
	sRegisterError db "This programs require Windows NT", 0
	sTitleBarMsg db "This is a typing program", 0
	cxChar DWORD 0
	cyChar DWORD 0
	cxClient DWORD 0
	cyClient DWORD 0
	cxBuffer DWORD 0
	cyBuffer DWORD 0
	xCaret DWORD 0
	yCaret DWORD 0
	pBuffer DWORD 0
	dwFlags DWORD HEAP_ZERO_MEMORY

.data?
	hInstance HINSTANCE ?
	hHeap DWORD ?
	
.code
	start:
		push NULL
		Call GetModuleHandle
		mov hInstance, eax
		
		push 0
		push NULL
		push NULL
		push hInstance
		Call WinMain
		push eax
		Call ExitProcess
		
		
		
		
		WinMain Proc hInst:HINSTANCE, hPrevInstance:HINSTANCE, sCmdLine:LPSTR, iCmdShow:DWORD
		
			local hWnd:HWND
			local msg:MSG
			local wndClass:WNDCLASSEX
			
			
			mov wndClass.cbSize, SIZEOF WNDCLASSEX
			lea eax, sClassName
			mov wndClass.lpszClassName, eax
			mov eax, hInst
			mov wndClass.hInstance, eax
			mov wndClass.cbClsExtra, 0
			mov wndClass.cbWndExtra, 0
			mov wndClass.hbrBackground, COLOR_WINDOW+1
			push IDC_ARROW
			push NULL
			Call LoadCursor
			mov wndClass.hCursor,eax
			push IDI_APPLICATION
			push NULL;
			Call LoadIcon
			mov wndClass.hIcon, eax
			mov wndClass.hIconSm, NULL
			mov wndClass.lpfnWndProc, offset WndProc
			mov wndClass.lpszMenuName, NULL
			mov wndClass.style, CS_HREDRAW or CS_VREDRAW
			
			;push WHITE_BRUSH
			;Call GetStockObject
			;Call GetStockObject
			
			
			
			
			
			
			
			
			
			lea eax, wndClass
			push eax
			Call RegisterClassEx
			
			cmp eax, 0
			jne ENDIFMAIN
				push MB_ICONERROR
				lea eax, sAppName
				push eax
				lea eax, sRegisterError
				push eax
				push NULL
				Call MessageBox
				ret
ENDIFMAIN:	push NULL
			push hInst
			push NULL
			push NULL
			push CW_USEDEFAULT
			push CW_USEDEFAULT
			push CW_USEDEFAULT
			push CW_USEDEFAULT
			push WS_OVERLAPPEDWINDOW or WS_VISIBLE
			lea eax, sTitleBarMsg
			push eax
			lea eax, sAppName
			push eax
			;push offset sTitleBarMsg
			;push offset sAppName
			push 0
			Call CreateWindowEx
			mov hWnd, eax
			
			;push iCmdShow
			;push hWnd
			;Call ShowWindow
			
			;push hWnd
			;Call UpdateWindow   
			
WHILEMAIN:	push 0
			push 0
			push NULL
			lea eax, msg
			push eax
			Call GetMessage
			cmp eax, 0
			jz ENDWHILEMAIN
				lea eax,msg
				push eax
				Call TranslateMessage
				lea eax, msg
				push eax
				Call DispatchMessage
			jmp WHILEMAIN
ENDWHILEMAIN:mov eax, msg.wParam
			Ret
		WinMain EndP
		
	WndProc proc hWnd:HWND, message:UINT, wParam:WPARAM, lParam:LPARAM
		
		local hdc:HDC
		local x:DWORD
		local y:DWORD
		local i:DWORD
		local ps:PAINTSTRUCT
		local tm:TEXTMETRIC
		
		mov eax, message
		;cmp eax, WM_CREATE
		;je CREATE
		;cmp eax, WM_SIZE
		;je WINDOWSIZE
		;cmp eax, WM_CHAR
		;je CHARACTER
		;cmp eax, WM_PAINT
		;je PAINT
		cmp eax, WM_DESTROY
		je DESTROY
		jmp ENDPROC
		
		CREATE:		push hWnd
					Call GetDC
					mov hdc, eax
					
					push NULL
					push 1
					push 0
					push 0
					push 0
					push 0				;enquire about the default value for charset
					push 0
					push 0
					push 0
					push 0
					push 0
					push 0
					push 0
					push 0
					Call CreateFont
					push eax
					push hdc
					Call SelectObject
					
					lea eax, tm
					push eax
					push hdc
					Call GetTextMetrics
					mov eax, tm.tmAveCharWidth
					mov edx, tm.tmHeight
					mov cxChar, eax
					mov cyChar, edx
					
					push SYSTEM_FONT
					Call GetStockObject
					push eax
					push hdc
					Call SelectObject
					push eax
					Call DeleteObject
					
					push hdc
					push hWnd
					Call ReleaseDC
					
		WINDOWSIZE:	mov eax, message
					cmp eax, WM_SIZE
					jne AFTERIF_SIZE
						mov eax, lParam
						and eax, 0FFh
						mov cxClient, eax
						mov eax, lParam
						SHR eax, 010h
						mov cyClient, eax
			AFTERIF_SIZE: mov eax, cxClient
						  ;mov edx, cyClient
					;mov edx,cxChar
					;div eax, edx
					div cxChar
					mov edx, 1
					cmp edx, eax
					jl AFTERMAX1_SIZE
					mov cxBuffer, eax
					jmp NEXTMAX
			AFTERMAX1_SIZE:mov cxBuffer, edx	
			NEXTMAX:	mov eax, cyClient
					;div eax, cyChar
					div cyChar
					mov edx, 1
					cmp edx, eax
					jl AFTERMAX2_SIZE
					mov cyBuffer, eax
					jmp MAXOVER
			AFTERMAX2_SIZE:mov cyBuffer, edx
			
			MAXOVER:mov eax, NULL
					cmp pBuffer, eax
					je AFTERIF2_SIZE
						Call GetProcessHeap
						mov hHeap, eax
						push pBuffer
						push dwFlags
						push hHeap
						Call HeapFree
						jmp DEALLOC
			AFTERIF2_SIZE:Call GetProcessHeap
						  mov hHeap, eax
			DEALLOC: mov eax, cxBuffer
					;mov edx, cyBuffer
					mul cyBuffer
					mov edx, eax
					;push TCHAR
					;Call sizeof
					mov eax, TYPE TCHAR
					;mul eax, edx
					mul edx
					push eax
					push dwFlags
					push hHeap
					Call HeapAlloc
					mov pBuffer, eax
			FOR1_SIZE:	mov ecx, cyBuffer
						cmp y, ecx
						jge ENDFOR1_SIZE
			FOR2_SIZE:	mov ecx, cxBuffer
						cmp x, ecx
						jl NEXT1
						inc y
						jmp FOR1_SIZE
				NEXT1:	mov eax,pBuffer
						add eax, x
						;mov edx, cxBuffer
						;mul edx, y
						;add eax, edx
						mov edx, eax
						mov eax, cxBuffer
						mul y
						xchg eax, edx
						add eax, edx
						mov esi, eax
						mov BYTE PTR [esi], 020h
						inc x
						jmp FOR2_SIZE
			ENDFOR1_SIZE: mov x, 0
					mov y, 0
					mov xCaret, 0
					mov yCaret, 0
					
					Call GetFocus
					cmp hWnd, eax
					jne AFTERIF3_SIZE
						mov eax, cyChar
						;mul eax, yCaret
						mul yCaret
						push eax
						mov eax, cxChar
						;mul eax, xCaret
						mul xCaret
						push eax
						Call SetCaretPos
			AFTERIF3_SIZE:push TRUE
					push NULL
					push hWnd
					Call InvalidateRect
					ret		   
		
		CHARACTER:	mov eax, pBuffer
					add eax, xCaret
					mov edx, eax
					mov eax, cxBuffer
					mul yCaret
					add eax, edx
					mov esi, eax
					mov eax, wParam
					mov DWORD PTR [esi], eax
					
					push hWnd
					Call HideCaret
					
					push hWnd
					Call GetDC
					mov hdc, eax
					
					push NULL
					push 1
					push 0
					push 0
					push 0
					push 0
					push 0
					push 0
					push 0
					push 0
					push 0
					push 0
					push 0
					push 0
					Call CreateFont
					push eax
					push hdc
					Call SelectObject
					
					push 1
					mov eax, pBuffer
					add eax, xCaret
					mov edx, eax
					mov eax, cxBuffer
					mul yCaret
					add eax, edx
					push eax
					mov eax, yCaret
					mul cyChar
					push eax
					mov eax, xCaret
					mul cxChar
					push eax
					push hdc
					Call TextOut
					
					push SYSTEM_FONT
					Call GetStockObject
					push eax
					push hdc
					Call SelectObject
					push eax
					Call DeleteObject
					
					push hdc
					push hWnd
					Call ReleaseDC
					
					push hWnd
					Call ShowCaret
					
					inc xCaret
					mov eax, xCaret
					cmp eax, cxBuffer
					jne CHARAFTERIF1
						mov xCaret, 0
						inc yCaret
						mov eax, yCaret
						cmp eax, cyBuffer
						jne CHARAFTERIF1
							mov yCaret, 0
			CHARAFTERIF1:mov eax, yCaret
					mul cyChar
					push eax
					mov eax, xCaret
					mul cxChar
					push eax
					Call SetCaretPos
					ret
	
		PAINT: 	lea eax, ps
				push eax
				push hWnd
				Call BeginPaint
				
				push NULL
				push 1
				push 0
				push 0
				push 0
				push 0
				push 0
				push 0
				push 0
				push 0
				push 0
				push 0
				push 0
				push 0
				Call CreateFont
				push eax
				push hdc
				Call SelectObject
				
				mov y, 0
				mov ecx, cyBuffer
			PAINTFOR1:	cmp y, ecx
				jge ENDPAINTFOR1
					push cxBuffer
					mov eax, cxBuffer
					mul y
					add eax, pBuffer
					push eax
					mov eax, cyChar
					mul y
					push eax
					push 0
					push hdc
					Call TextOut
					inc y
				jmp PAINTFOR1
			ENDPAINTFOR1: push SYSTEM_FONT
				Call GetStockObject
				push eax
				push hdc
				Call SelectObject
				push eax
				Call DeleteObject
				
				lea eax, ps
				push eax
				push hWnd
				Call EndPaint
				ret
				
		DESTROY: push 0
				 Call PostQuitMessage
				 ret
		
		ENDPROC:push lParam
				push wParam
				push message
				push hWnd
				Call DefWindowProc
						
		Ret
	WndProc EndP
END start
