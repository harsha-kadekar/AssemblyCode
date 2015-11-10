.386
.model flat, stdcall

option casemap :none


include windows.inc
include kernel32.inc
include user32.inc

includelib kernel32.lib
includelib user32.lib

WinMain proto :DWORD, :DWORD, :DWORD, :DWORD

.data
	ClassName db "WinClass", 0
	AppName db "SimpleWindow", 0
	dwCharSet DWORD DEFAULT_CHARSET
	cxChar DWORD 0
	cyChar DWORD 0
	cxClient DWORD 0
	cyClient DWORD 0
	cxBuffer DWORD 0
	cyBuffer DWORD 0
	xCaret DWORD 0
	yCaret DWORD 0
	pBuffer DB 0
	i dw 0
	j dw 0
	x dw 0
	y dw 0
	
	
	
.data?
	hInstance HINSTANCE ?
	
	
	
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
		
		WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
		
		
			local hdc:HDC
			;local x:DWORD
			;local y:DWORD
			;local i:DWORD
			local ps:PAINTSTRUCT
			local tm:TEXTMETRIC
			local hfont:HFONT
			local hrtHandle:HANDLE
			
			
			cmp uMsg, WM_INPUTLANGCHANGE
			jz INPUTLANGCHANGE
			cmp uMsg, WM_CREATE
			jz CREATE
			cmp uMsg, WM_SIZE
			jz SIZEMSG
			cmp uMsg, WM_SETFOCUS
			jz SETFOCUS
			cmp uMsg, WM_KILLFOCUS
			jz KILLFOCUS
			cmp uMsg, WM_KEYDOWN
			jz KEYDOWN
			cmp uMsg, WM_CHAR
			jz CHARMSG
			cmp uMsg, WM_PAINT
			jz PAINT
			cmp uMsg, WM_DESTROY
			jz DESTROY
			
			jmp ENDPROC
			
			INPUTLANGCHANGE:mov ax, wParam
							mov dwCharSet, ax
		
			
			CREATE:		 	push hWnd
					 		Call GetDC
					 		mov hdc, ax
					 
					 		push NULL
					 		push FIXED_PITCH 
					 		push 0
					 		push 0
					 		push 0
					 		push dwCharSet
					 		push 0
					 		push 0
					 		push 0
					 		push 0
					 		push 0
					 		push 0
					 		push 0
					 		push 0
					 		Call CreateFont
					 		mov hfont, eax
					 
					 		push hfont
					 		push hdc
					 		Call SelectObject
					 
					 		lea eax, tm
					 		push eax
					 		push hdc
					 		Call GetTextMetrics
					 
					 		mov eax,tm.tmAveCharWidth
					 		mov cxChar, eax
					 		mov eax, tm.tmHeight
					 		mov cyChar, eax
					 
					 		push SYSTEM_FONT
					 		Call GetStockObject
					 		mov hrtHandle, eax
					 
					 		push hrtHandle
					 		push hdc
					 		Call SelectObject
					 		mov hrtHandle, eax
					 
					 		push hrtHandle
					 		Call DeleteObject
					 
					 		push hdc
					 		push hWnd
					 		Call ReleaseDC
			SIZEMSG:		cmp uMsg, WM_SIZE
							jnz notsize
							xor eax, eax
							mov eax, lParam
							mov cxClient, ax
							SHR eax, 0x10
							mov cyClient, ax
				notsize:	mov eax, cxClient
							mov edx, cxChar
							div eax, edx
							mov edx, 1
							cmp edx, ax
							jl lesser
							mov cxBuffer, ax
							jmp after
					lesser: mov cxBuffer, 1
					after:	push TCHAR
							Call sizeof
							mul ax, cyBuffer
							mul ax, cxBuffer
							xor edx, edx
							mov edx, eax
							call GetProcessHeap
							push edx
							push HEAP_NO_SERIALIZE+HEAP_ZERO_MEMORY
							pusha
							call HeapAlloc
							mov pBuffer, ax
							
							mov cx, cyBuffer
					for1:	dec cx
							jz endfor
							inc i
							mov dx, cxBuffer
					for2:	dec dx
							jz for1
							inc j
							mov ax, pBuffer
							add ax, j
							mov bx, ax
							mov ax, cxBuffer
							mul ax, y
							add ax, bx
							mov [ax], 0x20
							jmp for2
					endfor: mov xCaret, 0
							mov yCaret, 0
							call GetFocus
							cmp eax, hWnd
							jne afterif
							mov ax, xCaret
							mul ax, cxChar
							mov bx, ax
							mov ax, yCaret
							mul ax, cyChar
							pusha
							mov dx, bx
							pushd
							call SetCaretPos
							push TRUE
							push NULL
							push hWnd
							Call InvalidateRect
							
							ret
			SETFOCUS:		push cyChar
							push cxChar
							push NULL
							push hWnd
							call CreateCaret
							mov ax, cxChar
							mul ax, xCaret
							mov cx, ax
							mov ax, cyChar
							mul ax, yCaret
							pusha
							mov dx, cx
							pushd
							call SetCaretPos
							push hWnd
							call ShowCaret
							ret
							
			KILLFOCUS:		push hWnd
							call HideCaret
							
							call DestroyCaret
							
							ret
						
			KEYDOWN:		mov eax, wParam
							cmp eax, VK_HOME
							je HOME
							cmp eax, VK_END
							je HOME_END
							cmp eax, VK_PRIOR
							je BEGINING
							cmp eax, VK_NEXT
							je NEXT
							cmp eax, VK_LEFT
							je LEFT
							cmp eax, VK_RIGHT
							je RIGHT
							cmp eax, VK_UP
							je UP
							cmp eax, VK_DOWN
							je DOWN
							cmp eax, VK_DELETE
							je DELETE
							jmp END2SWITCH
					
					HOME:	mov eax, 0
							mov xCaret, eax
							jmp END2SWITCH
					
					HOME_END:mov eax, cxBuffer
							mov xCaret, eax
							dec xCaret
							jmp END2SWITCH
					BIGINING:xor eax, eax
							 mov yCaret, eax
							 mp END2SWITCH
					NEXT:	mov eax, cyBuffer
							dec eax
							mov yCaret, eax
							jmp END2SWITCH
					LEFT:	mov eax, xCaret
							dec eax
							cmp eax, 0
							jl else_0
							mov xCaret, eax
							jmp afterif_0
						else_0:	mov xCaret, 0
						afterif_0: jmp END2SWITCH
						
					RIGHT:	mov eax, xCaret
							inc eax
							mov edx, cxBuffer
							dec edx
							cmp eax, edx
							jl else_1
							mov xCaret, edx
							jmp afterif_1
						else_1:	mov xCaret, eax
						afterif_1: jmp END2SWITCH
					
					UP:		mov eax, yCaret
							dec eax
							cmp eax, 0
							jl else_2
							mov yCaret, eax
							jmp afterif_2
						else_2:mov yCaret, 0
						afterif_2:jmp END2SWITCH
						
					DOWN:	mov eax, yCaret
							inc eax
							mov edx, cyBuffer
							dec edx
							cmp eax, edx
							jl else_3
							mov yCaret, edx
							jmp afterif_3
						else_3:mov yCaret, eax
						afterif_3:jmp END2SWITCH
						
					DELETE:	mov ecx, xCaret
							FOR3:	mov edx, cxBuffer
									dec edx
									cmp ecx, edx
									jge ENDFOR3
									
									mov eax, pBuffer
									add eax, ecx
									mov edx, yCaret
									mul edx, cxBuffer
									add eax, edx
									
									mov ebx, pBuffer
									add ebx, ecx
									inc ebx
									mov edx, yCaret
									mul edx, cxBuffer
									add ebx, edx
									
									mov [eax], [ebx]
									
									inc ecx
									jmp FOR3
							ENDFOR3:mov eax, pBuffer
									add eax, cxBuffer
									dec eax
									mov edx, yCaret
									mul edx, cxBuffer
									add eax, edx
									
									mov [eax], 0x20
									
							push hWnd
							Call HideCaret
							
							push hWnd
							Call GetDC
							mov hdc,eax
							
							push NULL
							push FIXED_PITCH
							push 0
							push 0
							push 0
							push dwCharSet
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
							mov edx, yCaret
							mul edx, cxBuffer
							add eax, edx
							push [eax]
							mov eax, yCaret
							mul eax, cyChar
							push eax
							mov eax, xCaret
							mul eax, cxChar
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
							
							jmp END2SWITCH
				
				END2SWITCH: mov eax, yCaret
							mul eax, cyChar
							push eax
							mov eax, xCaret
							mul eax, cxChar
							push eax
							Call SetCaretPos
							ret
			CHARMSG:	mov i, 0
						mov eax, lParam
						mov j, ax
						FOR_CHAR:	mov eax, i
									cmp eax, j
									jge ENDFOR_CHAR
									
										mov eax, wParam
										cmp eax, '\b'
										je BACKSPACE
										cmp eax, '\t'
										je TABSPACE
										cmp eax, '\n'
										je NEWLINE
										cmp eax, '\r'
										je CARRETURN
										cmp eax, '\x1B'
										je ESCAPE
										jmp DEFAULT
							
							BACKSPACE:	cmp xCaret, 0
										jle END_IF
											dec xCaret
											push 1
											push VK_DELETE
											push WM_KEYDOWN
											push hWnd
											Call SendMessage
										END_IF: jmp END3_SWITCH
							
							TABSPACE:	DO_WHILE:	push 1
													push 0x20
													push WM_CHAR
													push hWnd
													Call SendMessage
													DIV xCaret, 8
													cmp edx, 0
													jne DO_WHILE
										jmp END3_SWITCH
										
							NEWLINE:	inc yCaret
										mov eax, cxBuffer
										cmp eax, yCaret
										jne END3_SWITCH
										mov yCaret, 0
										jmp END3_SWITCH
							
							CARRETURN:	mov xCaret, 0
										inc yCaret
										mov eax, cxBuffer
										cmp eax, yCaret
										jne END3_SWITCH
										mov yCaret, 0
										jmp END3_SWITCH
										
							ESCAPE:		mov y, -1
										FOR_ESCAPE1:	inc y
														mov ecx, cyBuffer
														cmp ecx, y
														jge ENDFOR_ESCAPE1
										FOR_ESCAPE2:	mov ebx, cxBuffer
														cmp ebx, x
														jge FOR_ESCAPE1
														mov eax, pBuffer
														add eax, xCarret
														mov edx, cxBuffer
														mul edx, y
														add eax, edx
														mov [eax], 0x20
														inc x
														jmp FOR_ESCAPE2
										ENDFORESCAPE1: mov xCaret, 0
													   mov yCaret, 0
										
										push FALSE
										push NULL
										push hWnd
										Call InvalidateRect
										
										jmp END2_SWITCH
										
							DEFAULT:	mov eax, pBuffer
										add eax, xCaret
										mov edx, cxBuffer
										mul edx, yCaret
										add eax, edx
										
										mov [eax], wParam
										
										push hWnd
										Call HideCaret
										
										push hWnd
										Call GetDC
										
										mov hdc, eax
										
										push NULL
										push FIXED_PITCH
										push 0
										push 0
										push 0
										push dwCharSet
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
										mov edx, cxBuffer
										mul edx, yCaret
										add eax, edx
										push [eax]
										mov edx, cyChar
										mul edx, yCaret
										push edx
										mov edx, cxChar
										mul edx, xCaret
										push edx
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
										mov eax, cxBuffer
										
										cmp xCaret, eax
										jne ENDIFDEFAULT1
											mov xCaret, 0
											inc yCaret
											mov edx, cyBuffer
											cmp yCaret, edx
											jne ENDIFDEFAULT1
												mov yCaret, 0
								ENDIFDEFAULT1:jmp END3_SWITCH
								
							END3_SWITCH: xor eax, eax
							ENDFOR_CHAR:xor edx, edx
										mov eax, cxChar
										mul eax, xCaret
										
										mov edx, cyChar
										mul edx, yCaret
										
										push edx
										push eax
										Call SetCaretPos
										ret
													
										
										
			PAINT:	push offset ps
					push hWnd
					Call BeginPaint
					mov hdc, eax
					
					push NULL
					push FIXED_PITCH
					push 0
					push 0
					push 0
					push dwCharSet
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
					
					mov ecx, 0
				FORPAINT:	cmp ecx, cyBuffer
							jge ENDFORPAINT
								push cxBuffer
								mov eax, pBuffer
								mov edx, cxBuffer
								mul edx, ecx
								add eax, edx
								push [eax]
								mov edx, ecx
								mul edx, cyChar
								push edx
								push 0
								push hdc
								Call TextOut
								inc ecx
								jmp FORPAINT							
				ENDFORPAINT:	push SYSTEM_FONT
					Call GetStockObject
					push eax
					push hdc
					Call SelectObject
					push eax
					Call DeleteObject
					
					push offset ps
					push hWnd
					Call EndPaint
					
					ret					
											
											
							
							
			DESTROY:	jnz elsepart
						push 0
						Call PostQuitMessage
						xor eax, eax
						ret
			
		ENDPROC:push lParam
				push wParam
				push uMsg
				push hWnd
				Call DefWindowProc	
		Ret
		WndProc EndP 
	
	end start