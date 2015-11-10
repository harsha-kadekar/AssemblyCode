;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Name: 	MenuExample
;;Purpose:	To check how to add menu in assembly language.
;;Author:	Harsha kadekar B M
;;Date:		6-10-2011
;;Modified:	8-10-2010
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


.386
.model flat, stdcall
option casemap	:none 

include windows.inc
include user32.inc
include kernel32.inc
include gdi32.inc

includelib user32.lib
includelib kernel32.lib
includelib gdi32.lib


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Local Proto types
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WinMain PROTO	:DWORD, :DWORD, :DWORD, :DWORD
WndProc PROTO	:DWORD, :DWORD, :DWORD, :DWORD
TopXY PROTO		:DWORD, :DWORD
Paint_Proc PROTO	:DWORD, hDC:DWORD
Frame3D PROTO	:DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
PushButton PROTO	:DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD


;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Initiaized Data Section
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.data
szDisplayName db "3D Frames", 0
szClassName db "Template_Class", 0
szSimpleText db "Assembler, simple and pure", 0
szExitMessage db "Please Confirm the exit", 0
szButtonClass db "BUTTON", 0
CommandLine dd 0
hWnd dd 0
hInstance dd 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Code Section
;;;;;;;;;;;;;;;;;;;;;;;;;;
.code
start:
	push NULL
	Call GetModuleHandle		;Used to retrieve the handle of the file used to create the calling process(.exe)
	mov hInstance, eax
	
	Call GetCommandLine			;Obtain the command line arguments
	mov CommandLine, eax
	
	push SW_SHOWDEFAULT
	push CommandLine
	push NULL
	push hInstance
	Call WinMain
	
	push eax
	Call ExitProcess
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	WinMain proc hInst		:DWORD,
				 hPrevInst	:DWORD,
				 CmdLine	:DWORD,
				 CmdShow	:DWORD
		
		
		LOCAL wcWndClass	:WNDCLASSEX
		LOCAL msgMsg		:MSG
		LOCAL dwWndWidth	:DWORD
		LOCAL dwWndHeight	:DWORD
		LOCAL dwWndX		:DWORD
		LOCAL dwWndY		:DWORD
		
		;Initialize the Windows Class
		mov wcWndClass.cbSize, sizeof WNDCLASSEX
		mov wcWndClass.style, CS_HREDRAW or CS_VREDRAW
		mov wcWndClass.lpfnWndProc, offset WndProc
		mov wcWndClass.cbClsExtra, NULL
		mov wcWndClass.cbWndExtra, NULL
		mov wcWndClass.hbrBackground, COLOR_BTNFACE+1
		push IDC_ARROW
		push NULL
		Call LoadCursor
		mov wcWndClass.hCursor, eax
		push  500
		push hInst
		Call LoadIcon
		mov wcWndClass.hCursor, eax
		mov wcWndClass.hIconSm, 0
		mov eax, hInst
		mov wcWndClass.hInstance, eax
		mov wcWndClass.lpszClassName, offset szClassName
		mov wcWndClass.lpszMenuName, NULL
		
		;Register the WindowClass
		;push wcWndClass
		lea eax, wcWndClass
		push eax
		Call RegisterClassEx
		
		
		;Setting the Windows [starting point]x,y, height and width
		mov dwWndWidth, 500
		mov dwWndHeight, 350
		
		push SM_CXSCREEN
		Call GetSystemMetrics
		
		push eax
		push dwWndWidth
		Call TopXY
		mov dwWndX, eax
		
		push SM_CYSCREEN
		Call GetSystemMetrics
		
		push eax
		push dwWndHeight
		Call TopXY
		mov dwWndY, eax
		
		;Creating the window based on the above window class
		push NULL
		push hInst
		push NULL
		push NULL
		push dwWndHeight
		push dwWndWidth
		push dwWndY
		push dwWndX
		push WS_OVERLAPPEDWINDOW
		push offset szDisplayName
		push offset szClassName
		push WS_EX_LEFT
		Call CreateWindowEx
		mov hWnd, eax
		
		push 600
		push hInst
		Call LoadMenu
		
		push eax
		push hWnd
		Call SetMenu
		
		push SW_SHOWNORMAL
		push hWnd
		Call ShowWindow
		
		push hWnd
		Call UpdateWindow
		
		;Message Processing loop
		MessageLoop:	push 0
						push 0
						push NULL
						;push msgMsg
						lea eax, msgMsg
						push eax
						Call GetMessage
						
						cmp eax, 0
						je ExitLoop
						
						;push msgMsg
						lea eax, msgMsg
						push eax
						Call TranslateMessage
						;push msgMsg
						lea eax, msgMsg
						push eax
						Call DispatchMessage
						
						jmp MessageLoop
		ExitLoop:	mov eax, msgMsg.wParam
		
		
		Ret
	WinMain EndP
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	WndProc proc hWin	:DWORD,
				 uMsg	:DWORD,
				 wParam	:DWORD,
				 lParam :DWORD
				 
		LOCAL hDC		:HDC
		LOCAL psPaint	:PAINTSTRUCT
		
		
		;Switch statement for processing different messages
		mov eax, uMsg
		cmp eax, WM_COMMAND
		je MenuCommand
		cmp eax, WM_PAINT
		je PAINT
		cmp eax, WM_CREATE
		je CREATE
		cmp eax, WM_CLOSE
		je CLOSE
		cmp eax, WM_DESTROY
		je DESTROY
		
		jmp EndWndProc
		
		MenuCommand:
			mov eax, wParam
			cmp eax, 1000
			je CMD1000
			cmp eax, 1900
			je CMD1900
			jmp EndWndProc
			
			CMD1000:
				push NULL
				push SC_CLOSE
				push WM_SYSCOMMAND
				push hWin
				Call SendMessage
				jmp EndWndProc
			
			CMD1900:
				push MB_OK
				push offset szDisplayName
				push offset szSimpleText
				push hWin
				Call MessageBox
				jmp EndWndProc
		
		PAINT:
			;push ADDR psPaint
			lea eax, psPaint
			push eax
			;push psPaint
			push hWin
			Call BeginPaint
			
			mov hDC, eax
			
			push hDC
			push hWin
			Call Paint_Proc
			
			;push ADDR psPaint
			;push [psPaint]
			;lea psPaint, eax
			;push psPaint
			lea eax, psPaint
			push eax
			push hWin
			Call EndPaint
			
			mov eax, 0
			ret
			
		CREATE:
			jmp @F										;Still dont know what does this mean......
				Buttn1 db "&Save", 0
				Buttn2 db "&Cancel", 0
			@@:
			
			push 500
			push 25
			push 100
			push 30
			push 350
			push hWin
			push offset Buttn1
			Call PushButton
			
			push 500
			push 25
			push 100
			push 60
			push 350
			push hWin
			push offset Buttn2
			Call PushButton
			
			jmp EndWndProc
			
		CLOSE:
			push MB_YESNO
			push offset szDisplayName
			push offset szExitMessage
			push hWin
			Call MessageBox
			
			cmp eax, IDNO
			jne EndWndProc
			mov eax, 0
			ret
			
		DESTROY:
			push NULL
			Call PostQuitMessage
			mov eax, 0
			ret
			
		EndWndProc:
			push lParam
			push wParam
			push uMsg
			push hWin
			Call DefWindowProc
	
		Ret
	WndProc EndP
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	TopXY proc wDim	:DWORD,
			   sDim	:DWORD
		
		shr sDim, 1
		shr wDim, 1
		mov eax, wDim
		sub sDim, eax
		
		mov eax, sDim
		Ret
	TopXY EndP
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	Paint_Proc proc hWin	:DWORD,
					hDC		:DWORD
	
		LOCAL btn_hi	:DWORD
		LOCAL btn_lo	:DWORD
		LOCAL Rct 		:RECT
		
		push COLOR_BTNHIGHLIGHT
		Call GetSysColor
		mov btn_hi, eax
		
		push COLOR_BTNSHADOW
		Call GetSysColor
		mov btn_lo, eax
		
		push 2
		push 125
		push 460
		push 20
		push 340
		push btn_hi
		push btn_lo
		push hDC
		Call Frame3D
		
		push 2
		push 128
		push 463
		push 17
		push 337
		push btn_lo
		push btn_hi
		push hDC
		Call Frame3D
		
		push 2
		push 290
		push 328
		push 17
		push 17
		push btn_hi
		push btn_lo
		push hDC
		Call Frame3D
		
		push 1
		push 287
		push 325
		push 20
		push 20
		push btn_lo
		push btn_hi
		push hDC
		Call Frame3D
		
		
		;push ADDR Rct
		lea eax, Rct
		push eax
		;push Rct
		push hWin
		Call GetClientRect
		
		add Rct.bottom, 1
		add Rct.left, 1
		add Rct.right, 1
		add Rct.top, 1
		
		push 2
		push Rct.bottom
		push Rct.right
		push Rct.top
		push Rct.left
		push btn_hi
		push btn_lo
		push hDC
		Call Frame3D
		
		add Rct.bottom, 4
		add Rct.left, 4
		add Rct.right, 4
		add Rct.top, 4
		
		push 2
		push Rct.bottom
		push Rct.right
		push Rct.top
		push Rct.left
		push btn_lo
		push btn_hi
		push hDC
		Call Frame3D
		
		mov eax, 0
		Ret
	Paint_Proc EndP
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	PushButton proc lpText	:DWORD,
					hParent	:DWORD,
					a		:DWORD,
					b		:DWORD,
					wd		:DWORD,
					ht		:DWORD,
					ID		:DWORD
					
		push NULL
		push hInstance
		push ID
		push hParent
		push ht
		push wd
		push b
		push a
		push WS_CHILD or WS_VISIBLE
		push lpText
		push offset szButtonClass
		push 0
		Call CreateWindowEx
						
		Ret
	PushButton EndP
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	Frame3D proc hDC	:DWORD,
				 btn_hi	:DWORD,
				 btn_lo	:DWORD,
				 tx		:DWORD,
				 ty		:DWORD,
				 lx		:DWORD,
				 ly		:DWORD,
				 bdrWid	:DWORD
				 
		LOCAL hPen	:DWORD
		LOCAL hPen2 :DWORD
		LOCAL hpenOld:DWORD
		
		push btn_hi
		push 1
		push 0
		Call CreatePen
		mov hPen, eax
		
		push hPen
		push hDC
		Call SelectObject
		mov hpenOld, eax
		
		push tx
		push ty
		push lx
		push ly
		push bdrWid
		
		loopOne:	
			push NULL
			push ty
			push tx
			push hDC
			Call MoveToEx
			
			push ty
			push lx
			push hDC
			Call LineTo
			
			dec tx
			dec ty
			inc lx
			inc ly
			
			dec bdrWid
			cmp bdrWid, 0
			je loopOneOut
			jmp loopOne
		
		loopOneOut:
		push btn_lo
		push 1
		push 0
		Call CreatePen
		mov hPen2, eax
		
		push hPen2
		push hDC
		Call SelectObject
			
		mov hPen, eax
			
		push hPen
		Call DeleteObject
			
		pop bdrWid
		pop ly
		pop lx
		pop ty
		pop tx
		
		loopTwo:
			push NULL
			push ly
			push tx
			push hDC
			Call MoveToEx
			
			push ly
			push lx
			push hDC
			Call LineTo
			
			push NULL
			push ty
			push lx
			push hDC
			Call MoveToEx
			
			inc ly
			
			push ly
			push lx
			push hDC
			Call LineTo
			
			dec ly
			
			dec tx
			dec ty
			inc lx
			inc ly
			
			dec bdrWid
			cmp bdrWid, 0
			je loopTwoOut
			jmp loopTwo
			
		loopTwoOut:
		push hpenOld
		push hDC
		Call SelectObject
		
		push hPen2
		Call DeleteObject
						 
		Ret
	Frame3D EndP
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
end start
	
	
	
	
	
	
	
	