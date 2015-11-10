;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Name:	PEFileInfo
;Author:	Harsha Kadekar
;Description:	This app will give you the description of the Portable executable file.
;Date:	1-1-2012
;Last Modified:	1-1-2012
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.386
.model flat, stdcall

option casemap:none

include windows.inc
include kernel32.inc
include comdlg32.inc
include user32.inc
include comctl32.inc
includelib comctl32.lib
includelib user32.lib
includelib kernel32.lib
includelib comdlg32.lib

;include windows.inc
;include user32.inc
;include kernel32.inc
;include comctl32.inc
;include comdlg32.inc
;
;includelib user32.lib
;includelib kernel32.lib
;includelib comctl32.lib
;includelib comdlg32.lib

.const
IDD_SECTIONTABLE equ 104
IDC_SECTIONLIST equ 1001

SEH struct
	PrevLink dd ?
	CurrentHandler dd ?
	SafeOffset dd ?
	PrevEsp dd ?
	PrevEbp dd ?
SEH EndS

.data
sAppName db "PEFILEINFOAPP",0
ofn OPENFILENAME <>
sFilterString db "Executable Files(*.exe, *.dll)", 0, "*.exe","*.dll",0
			  db "All Files",0, "*.*", 0,0
sFileOpenError db "Cannot open the file",0
sFileOpenMappingError db "Cannot open the file for memory mapping",0
sFileMappingError db "Cannot map the file to memory",0
sFileInValidPE db "This file is not a valid PE file",0
template db "%08lx",0
sSectionName db "Section",0
sVirtualSize db "V.Size",0
sVirtualAddress db "V.address",0
SizeOfRawData db "Raw Size",0
RawOffset db "Raw Offset",0
Characteristics db "Characteristics",0

.data?
hInstance dd ?
buffer db 512 dup(?)
hFile dd ?
hMapping dd ?
pMapping dd ?
ValidPE dd ?
NumberOfSections dd ?

.code
start:
Firststart proc
	LOCAL seh:SEH
	push NULL
	Call GetModuleHandle
	mov hInstance, eax
	
	mov ofn.lStructSize, SIZEOF ofn
	mov ofn.lpstrFilter, OFFSET sFilterString
	mov ofn.lpstrFile, OFFSET buffer
	mov ofn.nMaxFile, 512
	mov ofn.Flags, OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST or OFN_LONGNAMES or OFN_EXPLORER or OFN_HIDEREADONLY
	
	lea eax, ofn
	push eax
	Call GetOpenFileName
	
	cmp eax, TRUE
	jne AFTERIF
		push NULL
		push FILE_ATTRIBUTE_NORMAL
		push OPEN_EXISTING
		push NULL
		push FILE_SHARE_READ
		push GENERIC_READ
		lea eax, buffer
		push eax
		Call CreateFile
		
		cmp eax, INVALID_HANDLE_VALUE
		je ELSE1
			mov hFile, eax
			
			push 0
			push 0
			push 0
			push PAGE_READONLY
			push NULL
			push hFile
			Call CreateFileMapping
			
			cmp eax, NULL
			je ELSE2
				mov hMapping, eax
				
				push 0
				push 0
				push 0
				push FILE_MAP_READ
				push hMapping
				Call MapViewOfFile
				
				cmp eax, NULL
				je ELSE3
					mov pMapping, eax
					
					assume fs:nothing
					push fs:[0]
					pop seh.PrevLink
					mov seh.CurrentHandler, offset SEHHandler
					mov seh.SafeOffset, offset FinalExit
					lea eax, seh
					mov fs:[0], eax
					mov seh.PrevEsp, esp
					mov seh.PrevEbp, ebp
					mov edi, pMapping
					
					assume edi:ptr IMAGE_DOS_HEADER
					cmp [edi].e_magic, IMAGE_DOS_SIGNATURE
					jne ELSE4
						add edi, [edi].e_lfanew
						assume edi:ptr IMAGE_NT_HEADERS
						cmp [edi].Signature, IMAGE_NT_SIGNATURE
						jne ELSE5
							mov ValidPE, TRUE
							jmp FinalExit
						ELSE5:
							mov ValidPE, FALSE
							jmp FinalExit
					ELSE4:
						mov ValidPE, FALSE
						jmp FinalExit
	FinalExit:
				push seh.PrevLink
				pop fs:[0]
				cmp ValidPE, TRUE
				jne ELSE6
					Call ShowSectionInfo
					jmp AFTERIFELSE
				ELSE6:
					push MB_ICONINFORMATION+MB_OK
					push OFFSET sAppName
					push OFFSET sFileInValidPE
					push 0
					Call MessageBox
					
				AFTERIFELSE:
					push pMapping
					Call UnmapViewOfFile
					jmp AFTERELSE3
				ELSE3:
					push MB_ICONERROR+MB_OK
					push OFFSET sAppName
					push OFFSET sFileMappingError
					push 0
					Call MessageBox
				
				AFTERELSE3:
				push hMapping
				Call CloseHandle
				jmp AFTERELSE2
			ELSE2:
				push MB_ICONERROR+MB_OK
				push OFFSET sAppName
				push OFFSET sFileOpenMappingError
				push 0
				Call MessageBox
			AFTERELSE2:
				push hMapping
				Call CloseHandle
				jmp AFTERELSE1
		ELSE1:
			push MB_ICONERROR+MB_OK
			push OFFSET sAppName
			push OFFSET sFileOpenError
			push 0
			Call MessageBox
		AFTERELSE1:
			push hFile
			Call CloseHandle
	AFTERIF:
		push 0
		Call ExitProcess
		
		Call InitCommonControls

	
;	Ret
Firststart EndP


SEHHandler proc C uses edx pExcept:DWORD,pFrame:DWORD,pContext:DWORD,pDispatch:DWORD

	mov edx, pFrame
	assume edx:ptr SEH
	mov eax, pContext
	assume eax:ptr CONTEXT
	push [edx].SafeOffset
	pop [eax].regEip
	push [edx].PrevEsp
	pop [eax].regEsp
	push [edx].PrevEbp
	pop [eax].regEbp
	mov ValidPE, FALSE
	mov eax, ExceptionContinueExecution
	
	
	Ret
SEHHandler EndP

DlgProc proc uses edi esi hDlg:DWORD, uMsg:DWORD, wParam:WPARAM, lParam:LPARAM
	LOCAL lvc:LV_COLUMN
	LOCAL lvi:LV_ITEM
	
	mov eax, uMsg
	cmp eax, WM_INITDIALOG
	je INITDIALOG
	cmp eax, WM_CLOSE
	je CLOSE
	
	jmp DEFAULT
	
	INITDIALOG:
		mov esi, lParam
		mov lvc.imask, LVCF_FMT or LVCF_TEXT or LVCF_WIDTH or LVCF_SUBITEM 
		mov lvc.fmt, LVCFMT_LEFT
		mov lvc.lx, 80
		mov lvc.iSubItem, 0
		mov lvc.pszText, OFFSET sSectionName
		
		lea eax, lvc
		push eax
		push 0
		push LVM_INSERTCOLUMN
		push IDC_SECTIONLIST
		push hDlg
		Call SendDlgItemMessage
		
		inc lvc.iSubItem
		mov lvc.fmt, LVCFMT_RIGHT
		mov lvc.pszText, OFFSET sVirtualSize
		lea eax, lvc
		push eax
		push 1
		push LVM_INSERTCOLUMN
		push IDC_SECTIONLIST
		push hDlg
		Call SendDlgItemMessage
		
		inc lvc.iSubItem
		mov lvc.pszText, OFFSET sVirtualAddress
		lea eax, lvc
		push eax
		push 2
		push LVM_INSERTCOLUMN
		push IDC_SECTIONLIST
		push hDlg
		Call SendDlgItemMessage
		
		inc lvc.iSubItem
		mov lvc.pszText, OFFSET SizeOfRawData
		lea eax, lvc
		push eax
		push 3
		push LVM_INSERTCOLUMN
		push IDC_SECTIONLIST
		push hDlg
		Call SendDlgItemMessage
		
		inc lvc.iSubItem
		mov lvc.pszText, OFFSET RawOffset
		lea eax, lvc
		push eax
		push 4
		push LVM_INSERTCOLUMN
		push IDC_SECTIONLIST
		push hDlg
		Call SendDlgItemMessage
		
		inc lvc.iSubItem
		mov lvc.pszText, OFFSET Characteristics
		lea eax, lvc
		push eax
		push 5
		push LVM_INSERTCOLUMN
		push IDC_SECTIONLIST
		push hDlg
		Call SendDlgItemMessage
		
		mov eax, NumberOfSections
		movzx eax, ax
		mov edi, eax
		mov lvi.imask, LVIF_TEXT
		mov lvi.iItem, 0
		assume esi:ptr IMAGE_SECTION_HEADER
		STARTWHILE:
			cmp edi, 0
			jle ENDWHILE
			
			mov lvi.iSubItem, 0
			push 9
			lea eax, buffer
			Call RtlZeroMemory
			
			push 8
			lea eax, [esi].Name1
			push eax
			lea eax, buffer
			push eax
			Call lstrcpyn
			
			lea eax, buffer
			mov lvi.pszText, eax
			
			lea eax, lvi
			push eax
			push 0
			push LVM_INSERTITEM
			push IDC_SECTIONLIST
			push hDlg
			Call SendDlgItemMessage
			
			push [esi].Misc.VirtualSize
			lea eax, template
			push eax
			lea eax, buffer
			push eax
			Call wsprintf
			
			lea eax, buffer
			mov lvi.pszText, eax
			inc lvi.iSubItem
			
			lea eax, lvi
			push eax
			push 0
			push LVM_SETITEM
			push IDC_SECTIONLIST
			push hDlg
			Call SendDlgItemMessage
			
			push [esi].VirtualAddress
			lea eax, template
			push eax
			lea eax, buffer
			push eax
			Call wsprintf
			
			lea eax, buffer
			mov lvi.pszText, eax
			inc lvi.iSubItem
			
			lea eax, lvi
			push eax
			push 0
			push LVM_SETITEM
			push IDC_SECTIONLIST
			push hDlg
			Call SendDlgItemMessage
			
			push [esi].SizeOfRawData
			lea eax, template
			push eax
			lea eax, buffer
			push eax
			Call wsprintf
			
			lea eax, buffer
			mov lvi.pszText, eax
			inc lvi.iSubItem
			
			lea eax, lvi
			push eax
			push 0
			push LVM_SETITEM
			push IDC_SECTIONLIST
			push hDlg
			Call SendDlgItemMessage
			
			push [esi].PointerToRawData
			lea eax, template
			push eax
			lea eax, buffer
			push eax
			Call wsprintf
			
			lea eax, buffer
			mov lvi.pszText, eax
			inc lvi.iSubItem
			
			lea eax, lvi
			push eax
			push 0
			push LVM_SETITEM
			push IDC_SECTIONLIST
			push hDlg
			Call SendDlgItemMessage
			
			push [esi].Characteristics
			lea eax, template
			push eax
			lea eax, buffer
			push eax
			Call wsprintf
			
			lea eax, buffer
			mov lvi.pszText, eax
			inc lvi.iSubItem
			
			lea eax, lvi
			push eax
			push 0
			push LVM_SETITEM
			push IDC_SECTIONLIST 
			push hDlg
			Call SendDlgItemMessage
			
			inc lvi.iItem
			dec edi
			add esi, sizeof IMAGE_SECTION_HEADER
			
			jmp STARTWHILE
		
		ENDWHILE:
			jmp EndProc
	
	CLOSE:
		push NULL
		push hDlg
		Call EndDialog
		
		jmp EndProc
		
	DEFAULT:
		mov eax, FALSE
		Ret
		
	EndProc:
		mov eax, TRUE
			
	Ret
DlgProc EndP

ShowSectionInfo proc uses edi
	mov edi, pMapping
	
	assume edi:ptr IMAGE_DOS_HEADER
	add edi, [edi].e_lfanew
	
	assume edi:ptr IMAGE_NT_HEADERS
	mov ax, [edi].FileHeader.NumberOfSections
	movzx eax, ax
	mov NumberOfSections, eax
	add edi, sizeof IMAGE_NT_HEADERS
	
	push edi
	lea eax, DlgProc
	push eax
	push NULL
	push IDD_SECTIONTABLE
	push hInstance
	Call DialogBoxParam
	
	Ret
ShowSectionInfo EndP

end start