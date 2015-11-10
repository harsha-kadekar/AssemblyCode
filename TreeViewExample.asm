;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Name:	TreeViewExample
;Author:	Harsha Kadekar
;Date:	20-11-2011
;LastModified:	20-11-2011
;Description:	To know the working of Tree view and how to create it.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.386
.model flat, stdcall

option casemap:none

include user32.inc
include kernel32.inc
include windows.inc
include comctl32.inc
include gdi32.inc

includelib user32.lib
includelib kernel32.lib
includelib comctl32.lib
includelib gdi32.lib

WinMain proto :DWORD, :DWORD, :DWORD, :DWORD
WndProc proto :DWORD, :DWORD, :DWORD, :DWORD

.const
IDB_TREE equ 4006

.data
sClassName db "TreeViewClass",0
sAppName db "Tree View Demo",0
sTreeViewClass db "SysTreeView32",0
sParent db "Parent Item",0
sChild1 db "child1",0
sChild2 db "child2",0
DragMode dd FALSE

.data?

hInstance HINSTANCE ?
hwndTreeView dd ?
hParent HANDLE ?
hImageList HANDLE ?
hDragImageList HANDLE ?

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
	
	WinMain proc hInst:HINSTANCE, hPrevInst:HINSTANCE, sCmdLine:LPSTR, CmdShow:DWORD
		LOCAL wc:WNDCLASSEX
		LOCAL msg:MSG
		LOCAL hwnd:HWND
		
		mov wc.cbSize,SIZEOF WNDCLASSEX
		mov wc.style, CS_HREDRAW or CS_VREDRAW
		mov wc.lpfnWndProc, OFFSET WndProc
		mov wc.cbClsExtra, NULL
		mov wc.cbWndExtra, NULL
		mov eax, hInst
		mov wc.hInstance, eax
		mov wc.hbrBackground, COLOR_APPWORKSPACE
		mov wc.lpszMenuName, NULL
		mov wc.lpszClassName, OFFSET sClassName
		push IDI_APPLICATION
		push NULL
		Call LoadIcon
		mov wc.hIcon,eax
		push IDC_ARROW
		push NULL
		Call LoadCursor
		mov wc.hCursor, eax
		mov wc.hIconSm, NULL
		
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
		push WS_OVERLAPPED+WS_CAPTION+WS_VISIBLE+WS_MINIMIZEBOX+WS_MAXIMIZEBOX+WS_SYSMENU
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
				lea eax,msg
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
	
	WndProc proc uses edi hWnd:HWND,uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	
		LOCAL tvinsert:TV_INSERTSTRUCT
		LOCAL hBitmap:DWORD
		LOCAL tvhit:TV_HITTESTINFO
		
		mov eax, uMsg
		cmp eax, WM_DESTROY
		je DESTROY
		cmp eax, WM_CREATE
		je CREATE
		cmp eax, WM_MOUSEMOVE
		je MOUSEMOVE
		cmp eax, WM_LBUTTONUP
		je LBUTTONUP
		cmp eax, WM_NOTIFY
		je NOTIFY
		
		jmp DEFAULT
		
		CREATE:
			push NULL
			push hInstance
			push NULL
			push hWnd
			push 400
			push 200
			push 0
			push 0
			push WS_CHILD+WS_VISIBLE+TVS_HASLINES+TVS_HASBUTTONS+TVS_LINESATROOT
			push NULL
			push OFFSET sTreeViewClass
			push NULL
			Call CreateWindowEx
			mov hwndTreeView, eax
			
			push 10
			push 2
			push ILC_COLOR16
			push 16
			push 16
			Call ImageList_Create
			mov hImageList, eax
			
			push IDB_TREE
			push hInstance
			Call LoadBitmap
			mov hBitmap, eax
			
			push NULL
			push hBitmap
			push hImageList
			Call ImageList_Add
			
			push hBitmap
			Call DeleteObject
			
			push hImageList
			push 0
			push TVM_SETIMAGELIST
			push hwndTreeView
			Call SendMessage
			
			mov tvinsert.hParent, NULL
			mov tvinsert.hInsertAfter, TVI_ROOT
			mov tvinsert.item.imask, TVIF_TEXT+TVIF_IMAGE+TVIF_SELECTEDIMAGE
			mov tvinsert.item.pszText, OFFSET sParent
			mov tvinsert.item.iImage, 0
			mov tvinsert.item.iSelectedImage, 1
			
			lea eax, tvinsert
			push eax
			push 0
			push TVM_INSERTITEM
			push hwndTreeView
			Call SendMessage
			mov hParent, eax
			
			mov tvinsert.hParent, eax
			mov tvinsert.hInsertAfter, TVI_LAST
			mov tvinsert.item.pszText, OFFSET sChild1
			lea eax, tvinsert
			push eax
			push 0
			push TVM_INSERTITEM
			push hwndTreeView
			Call SendMessage
			
			mov tvinsert.item.pszText, OFFSET sChild2
			lea eax, tvinsert
			push eax
			push 0
			push TVM_INSERTITEM
			push hwndTreeView
			Call SendMessage
			
			jmp EndProc
			
		MOUSEMOVE:
			cmp DragMode, TRUE
			jne EndProc
				mov eax, lParam
				and eax, 0ffffh
				mov ecx, lParam
				shr ecx, 16
				mov tvhit.pt.x, eax
				mov tvhit.pt.y, ecx
				
				push ecx
				push eax
				Call ImageList_DragMove
				
				push FALSE
				Call ImageList_DragShowNolock
				
				lea eax, tvhit
				push eax
				push NULL
				push TVM_HITTEST
				push hwndTreeView
				Call SendMessage
				
				cmp eax, NULL
				je AFTERIF
					push eax
					push TVGN_DROPHILITE
					push TVM_SELECTITEM
					push hwndTreeView
					Call SendMessage
				AFTERIF:
				
				push TRUE
				Call ImageList_DragShowNolock
				
				jmp EndProc
				
		LBUTTONUP:
			cmp DragMode, TRUE
			jne EndProc
				push hwndTreeView
				Call ImageList_DragLeave
				
				Call ImageList_EndDrag
				
				push hDragImageList
				Call ImageList_Destroy
				
				push 0
				push TVGN_DROPHILITE
				push TVM_GETNEXTITEM
				push hwndTreeView
				Call SendMessage
				
				push eax
				push TVGN_CARET
				push TVM_SELECTITEM
				push hwndTreeView
				Call SendMessage
				
				push 0
				push TVGN_DROPHILITE
				push TVM_SELECTITEM
				push hwndTreeView
				Call SendMessage
				
				Call ReleaseCapture
				
				mov DragMode, FALSE
			
			jmp EndProc
		
		NOTIFY:
			mov edi,lParam
			
			assume edi:ptr NM_TREEVIEW
			
			cmp [edi].hdr.code, TVN_BEGINDRAG
			jne NOTIFY_AFTERIF
				push [edi].itemNew.hItem
				push 0
				push TVM_CREATEDRAGIMAGE
				push hwndTreeView
				Call SendMessage
				mov hDragImageList, eax
				
				push 0
				push 0
				push 0
				push hDragImageList
				Call ImageList_BeginDrag
				
				push [edi].ptDrag.y
				push [edi].ptDrag.x
				push hwndTreeView
				Call ImageList_DragEnter
				
				push hWnd
				Call SetCapture
				
				mov DragMode, TRUE
			NOTIFY_AFTERIF:
			
			assume edi:nothing
			
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
	


