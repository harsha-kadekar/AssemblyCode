;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Name:			SimplePaint
;Author:		Harsha Kadekar
;Date:			15-10-2011
;Description:	Just describes how to process the WM_PAINT messages
;Last Modified:	5-11-2011
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


.386
.Model Flat, STDCALL
option CASEMAP:	NONE

;Files containg the PROTOS and structures and different windows API proto
include windows.inc
include kernel32.inc
include user32.inc
include gdi32.inc
include comdlg32.inc

;Import the libraries which has many apis used in this program
includelib kernel32.lib
includelib user32.lib
includelib gdi32.lib 
includelib comdlg32.lib

WinMain PROTO :DWORD, :DWORD, :DWORD, :DWORD
WndProc	PROTO :DWORD, :DWORD, :DWORD, :DWORD

.Const

IDM_NEW equ 1
IDM_SAVE equ 2
IDM_OPEN equ 3
IDM_EXIT equ 4
IDM_UNDO equ 5
IDM_COPY equ 6
IDM_CUT equ 7
IDM_PASTE equ 8
IDM_HELP equ 9
MAXSIZE equ 260
;MEMSIZE equ 65535
EDITID equ 1

.Data

sClassName db "SimplePaintClass",0
sAppName   db "SimpleTextViewer",0
sSampleText db "Hi this is just begining", 0
sEditClass db "edit",0
MenuName db "FirstMenu", 0
;Test_String db "You selected Test Menu item", 0
;HelloString db "Hello, Welcome", 0
;GoodByeString db "Ok, GoodBye, sorry it wont close!!!", 0
sConstruction db "Sorry, Under Construction !!!!", 0
sExitString db "Are You Sure? You want to exit", 0
sHelpString db "This is a basic Notepad, Still Under construction", 0
sRightClick db "Context Menu still under construction", 0
;char WPARAM 20h
;xPos DWORD 0
MouseClick db 0
RMouseClick db 0
sFilterString db "All Files",0, "*.*", 0
			  db "Text Files",0,"*.txt",0
sTitleOpenBox db "Choose the file to open",0
sFullPathName db "Choosen files full path: ",0
sFullName db "Name of file chosen: ",0
sExtension db "Extension of file: ",0
sBuffer db MAXSIZE dup(0)

;CrLf db 0Dh, 0Ah, 0 

.Data?

hInstance HINSTANCE ?
psCommandLine	LPSTR ?
hitPoint POINT <>
ofn OPENFILENAME <>
hWndEdit HWND ?
hMemory HANDLE ?
pMemory DWORD ?
SizeReadWrite DWORD ?
hFileRead HANDLE ?
hFileWrite HANDLE ?
hMapFile HANDLE ?
hMenu HANDLE ?



.Code

start:
	push NULL
	call GetModuleHandle
	mov hInstance, eax

	call GetCommandLine
	mov psCommandLine, eax

	push SW_SHOWDEFAULT
	push psCommandLine
	push NULL
	push hInstance
	Call WinMain

	push eax
	Call ExitProcess
	
	WinMain proc hInst:HINSTANCE, hprevInstance:HINSTANCE, sCommandLine:LPSTR, CmdShow:DWORD
		
		LOCAL wndClass: WNDCLASSEX
		LOCAL hWnd:	HWND
		LOCAL msg:	MSG
		
		mov wndClass.cbClsExtra, NULL
		mov wndClass.cbSize, SIZEOF WNDCLASSEX
		mov wndClass.cbWndExtra, NULL
		mov wndClass.hbrBackground, COLOR_WINDOW+1
		push IDC_ARROW
		push NULL
		call LoadCursor
		mov wndClass.hCursor,eax
		push IDI_APPLICATION
		push hInstance
		Call LoadIcon 
		mov wndClass.hIcon, eax
		mov wndClass.hIconSm, NULL
		mov eax, hInst
		mov wndClass.hInstance, eax
		mov wndClass.lpfnWndProc, OFFSET WndProc
		mov wndClass.lpszClassName, OFFSET sClassName
		;mov wndClass.lpszMenuName, NULL
		mov wndClass.lpszMenuName, OFFSET MenuName
		mov wndClass.style, CS_HREDRAW or CS_VREDRAW
		
		lea eax, wndClass
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
		push WS_OVERLAPPEDWINDOW
		push OFFSET sAppName
		push OFFSET sClassName
		push NULL
		Call CreateWindowEx
		mov hWnd, eax
		
		jmp $
		
		push SW_SHOWNORMAL
		push hWnd
		Call ShowWindow
		
		push hWnd
		Call UpdateWindow
		
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
	
	WndProc proc uses ebx hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	
		mov eax, uMsg
		cmp eax, WM_CREATE
		je CREATE
		cmp eax, WM_COMMAND
		je COMMAND
;		cmp eax, WM_SIZE
;		je WND_SIZE
		cmp eax, WM_DESTROY
		je DESTROY
		
		jmp LASTWndProc
		
		CREATE:
;			push NULL
;			push hInstance
;			push EDITID
;			push hWnd
;			push 0
;			push 0
;			push 0
;			push 0
;			push ES_AUTOVSCROLL or ES_AUTOHSCROLL or ES_MULTILINE or ES_LEFT or WS_CHILD or WS_VISIBLE
;			push NULL
;			push OFFSET sEditClass
;			push NULL
;			Call CreateWindowEx
;			
;			mov hWndEdit, eax
;			push hWndEdit
;			Call SetFocus

			push hWnd
			Call GetMenu
			
			mov hMenu, eax
			
			
			mov ofn.lStructSize, SIZEOF ofn
			mov eax, hWnd
			mov ofn.hWndOwner, eax
			mov eax, hInstance
			mov ofn.hInstance, eax
			mov ofn.lpstrFilter, OFFSET sFilterString
			mov ofn.lpstrFile, OFFSET sBuffer
			mov ofn.nMaxFile, MAXSIZE
			xor eax, eax
			ret
		
;		WND_SIZE:
;			mov eax, lParam
;			mov edx, eax
;			shr edx, 16
;			and eax, 0ffffh
;			
;			push TRUE
;			push edx
;			push eax
;			push 0
;			push 0
;			push hWndEdit
;			Call MoveWindow
;			
;			xor eax, eax
;			ret
			
		DESTROY:
		
			cmp hMapFile, 0
			je DESTROYAFTERIF
				Call CloseMapFile
			DESTROYAFTERIF:
			
			push NULL
			Call PostQuitMessage
			
			xor eax, eax
			ret
		
		COMMAND:
			mov eax, wParam
			cmp lParam, 0
			jne AFTERIFCOM
				cmp ax, IDM_OPEN
				je M_OPEN
				cmp ax, IDM_SAVE
				je M_SAVE
				cmp ax, IDM_EXIT
				je M_EXIT
				cmp ax, IDM_NEW
				je M_NEW
				cmp eax, IDM_UNDO
				je M_UNDO
				cmp eax, IDM_COPY
				je M_COPY
				cmp eax, IDM_CUT
				je M_CUT
				cmp eax, IDM_PASTE
				je M_PASTE
				cmp eax, IDM_HELP
				je M_HELP
				
				M_NEW:
					push MB_OK
					push OFFSET sAppName
					push OFFSET sConstruction
					push NULL
					Call MessageBox
					
					xor eax, eax
					ret
					
				M_OPEN:
					mov ofn.Flags, OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST or OFN_LONGNAMES or OFN_EXPLORER or OFN_HIDEREADONLY
					lea eax, ofn
					push eax
					Call GetOpenFileName
					
					cmp eax, TRUE
					jne OPENELSE
						push NULL
						push FILE_ATTRIBUTE_ARCHIVE
						push OPEN_EXISTING
						push NULL
						push 0
						push GENERIC_READ
						push OFFSET sBuffer
						Call CreateFile
						mov hFileRead, eax
						
						push NULL
						push 0
						push 0
						push PAGE_READONLY
						push NULL
						push hFileRead
						Call CreateFileMapping
						
						mov hMapFile, eax
						mov eax, OFFSET sBuffer
						movzx edx, ofn.nFileOffset
						add eax, edx
						
						push eax
						push hWnd
						Call SetWindowText
						
						push MF_GRAYED
						push IDM_OPEN
						push hMenu
						Call EnableMenuItem
						
						push MF_ENABLED
						push IDM_SAVE
						push hMenu
						Call EnableMenuItem
						
					OPENELSE:
						xor eax, eax
						ret
				M_SAVE:
					mov ofn.Flags, OFN_LONGNAMES or OFN_EXPLORER or OFN_HIDEREADONLY
					lea eax, ofn
					push eax
					Call GetSaveFileName
					
					cmp eax, TRUE
					jne SAVEELSE
						push NULL
						push FILE_ATTRIBUTE_ARCHIVE
						push CREATE_NEW
						push NULL
						push FILE_SHARE_READ or FILE_SHARE_WRITE
						push GENERIC_READ or GENERIC_WRITE
						push OFFSET sBuffer
						Call CreateFile
						
						mov hFileWrite, eax
						
						push 0
						push 0
						push 0
						push FILE_MAP_READ
						push hMapFile
						Call MapViewOfFile
						mov pMemory, eax
						
						push NULL
						push hFileRead
						Call GetFileSize
						
						push NULL
						push OFFSET SizeReadWrite
						push eax
						push pMemory
						push hFileWrite
						Call WriteFile
						
						push pMemory
						Call UnmapViewOfFile
						Call CloseMapFile
						
						push hFileWrite
						Call CloseHandle
						
						push OFFSET sAppName
						push hWnd
						Call SetWindowText
						
						push MF_ENABLED
						push IDM_OPEN
						push hMenu
						Call EnableMenuItem
						
						push MF_GRAYED
						push IDM_SAVE
						push hMenu
						Call EnableMenuItem
						
					SAVEELSE:
						xor eax, eax
						ret
						
						
						
				
;				M_OPEN:
;					mov ofn.Flags, OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST or OFN_LONGNAMES or OFN_EXPLORER or OFN_HIDEREADONLY
;					lea eax, ofn
;					push eax
;					Call GetOpenFileName
;					
;					cmp eax, TRUE
;					jne OPENELSE
;						push NULL
;						push FILE_ATTRIBUTE_ARCHIVE 
;						push OPEN_EXISTING
;						push NULL
;						push FILE_SHARE_READ or FILE_SHARE_WRITE
;						push GENERIC_READ or GENERIC_WRITE
;						push OFFSET sBuffer
;						Call CreateFile
;						
;						mov hFile, eax
;						
;						push MEMSIZE
;						push GMEM_ZEROINIT or GMEM_MOVEABLE
;						Call GlobalAlloc
;						mov hMemory, eax
;						
;						push hMemory
;						Call GlobalLock
;						mov pMemory, eax
;						
;						push NULL
;						push OFFSET SizeReadWrite
;						push MEMSIZE-1
;						push pMemory
;						push hFile
;						Call ReadFile
;						
;						push pMemory
;						push NULL
;						push WM_SETTEXT
;						push hWndEdit
;						Call SendMessage
;						
;						push hFile
;						Call CloseHandle
;						
;						push pMemory
;						Call GlobalUnlock
;						
;						push hMemory
;						Call GlobalFree
;					OPENELSE:
;						push hWndEdit
;						Call SetFocus
;					
;					xor eax, eax
;					ret
;				
;				M_SAVE:
;					mov ofn.Flags, OFN_LONGNAMES or OFN_EXPLORER or OFN_HIDEREADONLY
;					lea eax, ofn
;					push eax
;					Call GetSaveFileName
;					
;					cmp eax, TRUE
;					jne SAVEAFTERIF
;						push NULL
;						push FILE_ATTRIBUTE_ARCHIVE
;						push CREATE_NEW
;						push NULL
;						push FILE_SHARE_READ or FILE_SHARE_WRITE
;						push GENERIC_READ or GENERIC_WRITE
;						push OFFSET sBuffer
;						Call CreateFile
;						
;						mov hFile, eax
;						
;						push MEMSIZE
;						push GMEM_MOVEABLE or GMEM_ZEROINIT
;						Call GlobalAlloc
;						mov hMemory, eax
;						
;						push hMemory
;						Call GlobalLock
;						mov pMemory, eax
;						
;						push pMemory
;						push MEMSIZE-1
;						push WM_GETTEXT
;						push hWndEdit
;						Call SendMessage
;						
;						push NULL
;						push OFFSET SizeReadWrite
;						push eax
;						push pMemory
;						push hFile
;						Call WriteFile
;						
;						push hFile
;						Call CloseHandle
;						
;						push pMemory
;						Call GlobalUnlock
;						
;						push hMemory
;						Call GlobalFree
;					SAVEAFTERIF:
;						push hWndEdit
;						Call SetFocus
;					
;					xor eax, eax
;					ret
					
				M_UNDO:
					push MB_OK
					push OFFSET sAppName
					push OFFSET sConstruction
					push NULL
					Call MessageBox
					
					xor eax, eax
					ret
				M_COPY:
					push MB_OK
					push OFFSET sAppName
					push OFFSET sConstruction
					push NULL
					Call MessageBox
					
					xor eax, eax
					ret
				M_CUT:
					push MB_OK
					push OFFSET sAppName
					push OFFSET sConstruction
					push NULL
					Call MessageBox
					
					xor eax, eax
					ret
				M_PASTE:
					push MB_OK
					push OFFSET sAppName
					push OFFSET sConstruction
					push NULL
					Call MessageBox
					
					xor eax, eax
					ret
				M_HELP:
					push MB_OK
					push OFFSET sAppName
					push OFFSET sHelpString
					push NULL
					Call MessageBox
					
					xor eax, eax
					ret	
				
				M_EXIT:
					push MB_YESNO
					push OFFSET sAppName
					push OFFSET sExitString
					push NULL
					Call MessageBox
					
					cmp eax, 6
					jne AFTERIFEXIT
						push hWnd
						Call DestroyWindow
					AFTERIFEXIT:
					
					xor eax, eax
					ret
					
			AFTERIFCOM:
				xor eax, eax
				ret
		LASTWndProc:
			push lParam
			push wParam
			push uMsg
			push hWnd
			Call DefWindowProc	
		Ret
	WndProc EndP
	
	
	CloseMapFile proc 
		push hMapFile
		Call CloseHandle
		
		mov hMapFile, 0
		
		push hFileRead
		Call CloseHandle
		
		Ret
	CloseMapFile EndP
	
	
;	WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
;	
;		LOCAL hDC: HDC
;		LOCAL ps: PAINTSTRUCT
;		LOCAL rect: RECT
;		
;		mov eax, uMsg
;		cmp eax, WM_PAINT
;		je PAINT
;		cmp eax, WM_CHAR
;		je WMCHAR
;		cmp eax, WM_LBUTTONDOWN
;		je LBUTTONDOWN
;		cmp eax, WM_RBUTTONDOWN
;		je RBUTTONDOWN
;		cmp eax, WM_COMMAND
;		je COMMAND
;		cmp eax, WM_DESTROY
;		je DESTROY
;		jmp ENDWndProc
;		
;		PAINT:
;			lea eax, ps
;			push eax
;			push hWnd
;			Call BeginPaint
;			mov hDC, eax
;			
;			;lea eax, rect
;			;push eax
;			;push hWnd
;			;Call GetClientRect
;			
;			;push DT_CENTER or DT_SINGLELINE or DT_VCENTER
;			;lea eax, rect
;			;push eax
;			;push -1
;			;push OFFSET sSampleText
;			;push hDC
;			;Call DrawText
;			
;			
;			push 1
;			lea eax, char
;			push eax
;			push 0
;			push xPos
;			push hDC
;			Call TextOut
;			
;			cmp MouseClick, TRUE
;			jne AFTERIF
;				push OFFSET sAppName
;				Call lstrlen
;				push eax
;				push OFFSET sAppName
;				push hitPoint.y
;				push hitPoint.x
;				push hDC
;				Call TextOut
;				mov MouseClick, FALSE
;			AFTERIF:
;			
;			cmp RMouseClick, TRUE
;			jne AFTERIF2
;				push OFFSET sRightClick
;				Call lstrlen 
;				push eax
;				push OFFSET sRightClick
;				push hitPoint.y
;				push hitPoint.x
;				push hDC
;				Call TextOut
;				mov RMouseClick, FALSE
;			AFTERIF2:
;			
;			lea eax, ps
;			push eax
;			push hWnd
;			Call EndPaint
;			
;			inc xPos
;			
;			xor eax, eax
;			ret
;			
;		WMCHAR:
;			push wParam
;			pop char
;			
;			push TRUE
;			push NULL
;			push hWnd
;			Call InvalidateRect
;			
;			xor eax, eax
;			ret
;			
;		LBUTTONDOWN:
;			mov eax, lParam
;			and eax, 0FFFFh
;			mov hitPoint.x, eax
;			mov eax, lParam
;			shr eax, 16
;			mov hitPoint.y, eax
;			mov MouseClick, TRUE
;			push TRUE
;			push NULL
;			push hWnd
;			Call InvalidateRect
;			
;			xor eax, eax
;			ret
;			
;		RBUTTONDOWN:
;			mov eax, lParam
;			and eax, 0FFFFh
;			mov hitPoint.x, eax
;			mov eax, lParam
;			shr eax, 16
;			mov hitPoint.y, eax
;			mov RMouseClick, TRUE
;			
;			push TRUE
;			push NULL
;			push hWnd
;			Call InvalidateRect
;			
;			xor eax, eax
;			ret
;		
;		COMMAND:
;			mov eax, wParam
;			cmp ax, IDM_NEW
;			je M_NEW
;			cmp ax, IDM_SAVE
;			je M_SAVE
;			cmp ax, IDM_OPEN
;			je M_OPEN
;			cmp eax, IDM_EXIT
;			je M_EXIT
;			cmp eax, IDM_UNDO
;			je M_UNDO
;			cmp eax, IDM_COPY
;			je M_COPY
;			cmp eax, IDM_CUT
;			je M_CUT
;			cmp eax, IDM_PASTE
;			je M_PASTE
;			cmp eax, IDM_HELP
;			je M_HELP
;			jmp ENDWndProc
;			
;			M_NEW:
;				push MB_OK
;				push OFFSET sAppName
;				push OFFSET sConstruction
;				push NULL
;				Call MessageBox
;				
;				xor eax, eax
;				ret
;			M_SAVE:
;				push MB_OK
;				push OFFSET sAppName
;				push OFFSET sConstruction
;				push NULL
;				Call MessageBox
;				
;				xor eax, eax
;				ret
;			M_OPEN:
;				;push MB_OK
;				;push OFFSET sAppName
;				;push OFFSET sConstruction
;				;push NULL
;				;Call MessageBox
;				mov ofn.lStructSize, SIZEOF ofn
;				mov eax, hWnd
;				mov ofn.hWndOwner, eax
;				mov eax, hInstance
;				mov ofn.hInstance, eax
;				mov ofn.lpstrFilter, OFFSET sFilterString
;				mov ofn.lpstrFile, OFFSET sBuffer
;				mov ofn.nMaxFile, MAXSIZE
;				mov ofn.Flags, OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST or OFN_LONGNAMES or OFN_EXPLORER or OFN_HIDEREADONLY
;				mov ofn.lpstrTitle, OFFSET sTitleOpenBox
;				lea eax, ofn
;				push eax
;				Call GetOpenFileName
;				
;				cmp eax, TRUE
;				jne OPENCANCEL
;					push OFFSET sFullPathName
;					push OFFSET sOutputString
;					Call lstrcat
;					
;					push ofn.lpstrFile
;					push OFFSET sOutputString
;					Call lstrcat
;					
;					push OFFSET CrLf
;					push OFFSET sOutputString
;					Call lstrcat
;					
;					push OFFSET sFullName
;					push OFFSET sOutputString
;					Call lstrcat
;					
;					mov eax, ofn.lpstrFile
;					push ebx
;					xor ebx, ebx
;					mov bx, ofn.nFileOffset
;					add eax, ebx
;					pop ebx
;					
;					push eax
;					push OFFSET sOutputString
;					Call lstrcat
;					
;					push OFFSET CrLf
;					push OFFSET sOutputString
;					Call lstrcat
;					
;					push OFFSET sExtension
;					push OFFSET sOutputString
;					Call lstrcat
;					
;					mov eax, ofn.lpstrFile
;					push ebx
;					xor ebx, ebx
;				    mov bx, ofn.nFileExtension
;				    add eax, ebx
;				    pop ebx
;				    
;				    push eax
;				    push OFFSET sOutputString
;				    Call lstrcat
;				    
;				    push MB_OK
;				    push OFFSET sAppName
;				    push OFFSET sOutputString
;				    push hWnd
;				    Call MessageBox
;				    
;				    push OUTPUTSIZE
;				    push OFFSET sOutputString
;				    Call RtlZeroMemory
;				    
;				
;				OPENCANCEL:	    
;				    
;				
;				xor eax, eax
;				ret
;			M_EXIT:
;				push MB_OK
;				push OFFSET sAppName
;				push OFFSET sExitString
;				push NULL
;				Call MessageBox
;				
;				push hWnd
;				Call DestroyWindow
;				
;				xor eax, eax
;				ret
;			M_UNDO:
;				push MB_OK
;				push OFFSET sAppName
;				push OFFSET sConstruction
;				push NULL
;				Call MessageBox
;				
;				xor eax, eax
;				ret
;			M_COPY:
;				push MB_OK
;				push OFFSET sAppName
;				push OFFSET sConstruction
;				push NULL
;				Call MessageBox
;				
;				xor eax, eax
;				ret
;			M_CUT:
;				push MB_OK
;				push OFFSET sAppName
;				push OFFSET sConstruction
;				push NULL
;				Call MessageBox
;				
;				xor eax, eax
;				ret
;			M_PASTE:
;				push MB_OK
;				push OFFSET sAppName
;				push OFFSET sConstruction
;				push NULL
;				Call MessageBox
;				
;				xor eax, eax
;				ret
;			M_HELP:
;				push MB_OK
;				push OFFSET sAppName
;				push OFFSET sHelpString
;				push NULL
;				Call MessageBox
;				
;				xor eax, eax
;				ret	
;			
;		DESTROY:
;			push NULL
;			Call PostQuitMessage
;			xor eax, eax
;			ret
;		
;		ENDWndProc:
;			push lParam
;			push wParam
;			push uMsg
;			push hWnd
;			Call DefWindowProc
;			
;		Ret
;	WndProc EndP

end start


