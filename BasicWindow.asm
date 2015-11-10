.386
.model flat, stdcall

option casemap :none


include windows.inc
include kernel32.inc
include user32.inc
include gdi32.inc

includelib kernel32.lib
includelib user32.lib
includelib gdi32.lib

WinMain proto :DWORD, :DWORD, :DWORD, :DWORD

.data
	ClassName db "WinClass", 0
	AppName db "SimpleWindow", 0
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
	;dwCharSet DWORD 1
	
.data?
	hInstance HINSTANCE ?
	hHeap DWORD ?
	dwCharSet DWORD ?
	
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
		
		
		
		WinMain proc hInst:HINSTANCE, hPrevInst:HINSTANCE, CmdLine:LPSTR, CmdShow:DWORD
			
			local wc:WNDCLASSEX
			local msg:MSG
			local hwnd:HWND
			
			mov wc.cbSize, SIZEOF WNDCLASSEX
			mov wc.lpszClassName, offset ClassName
			push hInstance
			pop wc.hInstance
			;mov wc.hInstance, hInstance    -- this is wrong because its two memory locations i am using for move instruction
			mov wc.cbClsExtra, NULL
			mov wc.cbWndExtra, NULL
			mov wc.hbrBackground, COLOR_WINDOW+1
			push IDC_ARROW
			push NULL
			Call LoadCursor
			mov wc.hCursor, eax
			push IDI_APPLICATION
			push NULL
			Call LoadIcon
			mov wc.hIcon, eax
			mov wc.hIconSm, NULL
			mov wc.lpfnWndProc, offset WndProc
			mov wc.lpszMenuName, NULL
			mov wc.style, CS_HREDRAW or CS_VREDRAW
			
			;push offset wc -- this is wrong, what i understood is that in this case we are ordering the assembler to do 2 
			;                  different operations for single instruction, like moving the pointer also and doing some addition operation on the pointer
			;                  also in run time assembler is not able to know the address of it as it is a variable
			;                  i know i am not understood it correct... his english was very bad!!!!! Will try to understand more today.
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
			push WS_OVERLAPPEDWINDOW or WS_VISIBLE
			push offset AppName
			push offset ClassName
			push 0
			Call CreateWindowEx
			
			mov hwnd, eax
			
			;jmp $		;Its a bug just introduced for testing Basic Debugger
			
			push SW_SHOWNORMAL
			push hwnd
			Call ShowWindow
			
			push hwnd
			Call UpdateWindow
			
			whileloop: push 0
					   push 0
					   push NULL
					   ;push offset msg
					   lea eax, msg
					   push eax
					   Call GetMessage
					   cmp eax, 0
					   jz endwhile
					   ;push offset msg
					   lea eax, msg
					   push eax
					   Call TranslateMessage
					   ;push offset msg
					   lea eax, msg
					   push eax
					   Call DispatchMessage
					   jmp whileloop
			endwhile: mov eax, msg.wParam				  					   
	
			Ret
		WinMain EndP
		
		WndProc proc hWnd:HWND, message:UINT, wParam:WPARAM, lParam:LPARAM
		
			;cmp uMsg, WM_DESTROY
			;jnz elsepart
			;	push 0
			;	Call PostQuitMessage
			;	jmp afterif
			;elsepart:
			;		push lParam
			;		push wParam
			;		push uMsg
			;		push hWnd
			;		Call DefWindowProc
			;		Ret
			;afterif:
			;	   xor eax, eax
		;Ret
		;WndProc EndP 
		
		
		local hdc:HDC
		local x:DWORD
		local y:DWORD
		local i:DWORD
		local ps:PAINTSTRUCT
		local tm:TEXTMETRIC
		
		mov eax, message
		cmp eax, WM_INPUTLANGCHANGE
		je CHARSET
		cmp eax, WM_CREATE
		je CREATE
		cmp eax, WM_SIZE
		je WINDOWSIZE
		cmp eax, WM_SETFOCUS
		je SETFOCUS
		cmp eax, WM_KILLFOCUS
		je KILLFOCUS
		;cmp eax, WM_KEYDOWN
		;je KEYDOWN
		cmp eax, WM_CHAR
		je CHARACTER
		cmp eax, WM_PAINT
		je PAINT
		cmp eax, WM_DESTROY
		je DESTROY
		jmp ENDPROC
		
		CHARSET:	mov eax, wParam
					mov dwCharSet, eax
		
		CREATE:		push hWnd
					Call GetDC
					mov hdc, eax
					
					push NULL
					push 1
					push 0
					push 0
					push 0
					push 1				;enquire about the default value for charset
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
					mov ebx,cxChar
					xor edx, edx
					;div eax, edx
					div ebx
					mov edx, 1
					cmp edx, eax
					jl AFTERMAX1_SIZE
					mov cxBuffer, edx
					jmp NEXTMAX
			AFTERMAX1_SIZE:mov cxBuffer, eax	
			NEXTMAX:	mov eax, cyClient
					;div eax, cyChar
					mov ebx, cyChar
					xor edx, edx
					div ebx
					mov edx, 1
					cmp edx, eax
					jl AFTERMAX2_SIZE
					mov cyBuffer, edx
					jmp MAXOVER
			AFTERMAX2_SIZE:mov cyBuffer, eax
			
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
					
		SETFOCUS:	push cyChar
					push cxChar
					push NULL
					push hWnd
					Call CreateCaret
					
					mov eax, cyChar
					mov ebx, yCaret
					xor edx, edx
					mul ebx
					push eax
					mov eax, cxChar
					mov ebx, xCaret
					xor edx, edx
					mul ebx
					push eax
					Call SetCaretPos
					
					push hWnd
					Call ShowCaret
					
					ret 
					
		KILLFOCUS:	push hWnd
					Call HideCaret
					
					Call DestroyCaret
					ret
					
		KEYDOWN:	cmp wParam, VK_HOME
					je HOME
					cmp wParam, VK_END
					je VKEND
					cmp wParam, VK_PRIOR
					je PRIOR
					cmp wParam, VK_NEXT
					je NEXT
					cmp wParam, VK_LEFT
					je LEFT
					cmp wParam, VK_RIGHT
					je RIGHT
					cmp wParam, VK_UP
					je UP
					cmp wParam, VK_DOWN
					je DOWN
					cmp wParam, VK_DELETE
					je VKDELETE
					jmp ENDKEYDOWN
					
					HOME:	mov xCaret, 0
							jmp ENDKEYDOWN
					
					VKEND:	mov eax, cxBuffer
							dec eax
							mov xCaret, eax
							jmp ENDKEYDOWN
							
					PRIOR:	mov yCaret, 0
							jmp ENDKEYDOWN
							
					NEXT:	mov eax, cyBuffer
							dec eax
							mov yCaret, eax
							jmp ENDKEYDOWN
							
					LEFT:	mov edx, 0
							mov eax, xCaret
							dec eax
							cmp eax, edx
							jg IFLEFT1
							mov xCaret, edx
							jmp AFTERIFLEFT1
							IFLEFT1:	mov xCaret, eax
							AFTERIFLEFT1:	jmp ENDKEYDOWN
					
					RIGHT:	mov eax, xCaret
							mov edx, cxBuffer
							inc eax
							dec edx
							cmp eax, edx
							jl IFRIGHT1
							mov xCaret, edx
							jmp AFTERIFRIGHT1
							IFRIGHT1:	mov xCaret, eax
							AFTERIFRIGHT1:	jmp ENDKEYDOWN
							
					UP:		mov eax, yCaret
							dec eax
							mov edx, 0
							cmp eax, edx
							jg IFUP1
							mov yCaret, edx
							jmp AFTERUP1
							IFUP1:	mov yCaret, eax
							AFTERUP1:	jmp ENDKEYDOWN
							
					DOWN:	mov eax, yCaret
							mov edx, cyBuffer
							inc eax
							dec edx
							cmp eax, edx
							jl IFDOWN1
							mov yCaret, edx
							jmp AFTERDOWN1
							IFDOWN1:	mov yCaret, eax
							AFTERDOWN1:	jmp ENDKEYDOWN
							
					VKDELETE:	mov ecx, xCaret
							mov ebx, cxBuffer
							dec ebx
							DELETEFOR1:	cmp ecx, ebx
							jge ENDDELETEFOR1
							mov eax, pBuffer
							add eax, ecx
							inc eax
							mov i, eax
							mov eax, yCaret
							xor edx, edx
							mul cxBuffer
							add eax, i
							mov esi, eax
							mov edx, [esi]
							dec eax
							mov esi, eax
							mov [esi], edx
							inc ecx
							jmp DELETEFOR1
							
							ENDDELETEFOR1:	mov eax, pBuffer
											add eax, cxBuffer
											dec eax
											mov i, eax
											xor edx, edx
											mov eax, yCaret
											mul cxBuffer
											add eax, i
											mov esi, eax
											mov BYTE PTR [esi], 020h
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
							push 1				;enquire about the default value for charset
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
							
							mov eax, cxBuffer
							sub eax, xCaret
							push eax
							mov eax, pBuffer
							add eax, xCaret
							mov i, eax
							mov eax, yCaret
							xor edx, edx
							mul cxBuffer
							add eax, i
							push eax
							mov eax, cyChar
							xor edx, edx
							mul yCaret
							push eax
							mov eax, cxChar
							xor edx, edx
							mul xCaret
							push eax
							push hdc
							Call TextOut
							
							push SYSTEM_FONT
							call GetStockObject
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
							
							jmp ENDKEYDOWN
							
				ENDKEYDOWN:	mov eax, yCaret
							xor edx, edx
							mul cyChar
							push eax
							
							mov eax, xCaret
							xor edx, edx
							mul cxChar
							push eax
							
							Call SetCaretPos
							ret
								 
		
		CHARACTER:	mov i, 0
					mov ecx, lParam
					and ecx, 0FFh
					CHARFOR1:	cmp i, ecx
								jl CHARAFTERIF1
								
								mov eax, wParam
								cmp eax, '\b'
								je CHARBACK
								cmp eax, '\t'
								je CHARTAB
								cmp eax, '\n'
								je CHARLINE
								cmp eax, '\r'
								je CHARRETURN
								cmp eax, '\x1B'
								je CHARESCAPE
								jmp CHARDEFAULT
								
					CHARBACK:	cmp xCaret, 0
								jle CHARBACKAFTER
									dec xCaret
									push 1
									push VK_DELETE
									push WM_KEYDOWN
									push hWnd
									Call SendMessage
								CHARBACKAFTER:	jmp SWITCHOUT
					
					CHARTAB:	 push 1
								 push 020h
								 push WM_CHAR
								 push hWnd
								 call SendMessage
										   
								 xor eax, eax
								 xor edx, edx
								 mov eax, xCaret
								 mov ebx, 8
								 div ebx
								 cmp edx, 0
								 jne CHARTAB
								jmp SWITCHOUT
								
					CHARLINE:	inc yCaret
								mov eax, yCaret
								cmp eax, cyBuffer
								jne SWITCHOUT
									mov yCaret, 0
									jmp SWITCHOUT
					
					CHARRETURN:	mov xCaret, 0
								inc yCaret
								mov eax, yCaret
								cmp eax, cyBuffer
								jne SWITCHOUT
									mov yCaret, 0
									jmp SWITCHOUT
					CHARESCAPE:	mov x, 0
								mov y, 0
								ESCAPEFOR1:	mov ebx, cyBuffer
											cmp y, ebx
											jge ENDESCAPEFOR1
								ESCAPEFOR2:	mov ebx, cxBuffer
											cmp x, ebx
											jge INCREMENTOR
											
											mov eax, pBuffer
											add eax, x
											mov ebx, eax
											xor edx, edx
											mov eax, y
											mul cxBuffer
											add eax, ebx
											mov esi, eax
											mov BYTE PTR [esi], 020h
											inc x
											jmp ESCAPEFOR2
								INCREMENTOR:inc y
											jmp ESCAPEFOR1
								ENDESCAPEFOR1: mov xCaret, 0
											   mov yCaret, 0
											   
								push FALSE
								push NULL
								push hWnd
								Call InvalidateRect
								jmp SWITCHOUT
								
		
					CHARDEFAULT:mov eax, pBuffer
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
					jne SWITCHOUT
						mov xCaret, 0
						inc yCaret
						mov eax, yCaret
						cmp eax, cyBuffer
						jne SWITCHOUT
							mov yCaret, 0
				SWITCHOUT: inc i
						   jmp CHARFOR1
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
	
	end start