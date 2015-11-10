;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Name:	PEValidation
;Author:	Harsha Kadekar
;Description:	This programs validates whether the given file is a valid PE file or not.
;Date:	28-12-2011
;Last Modified:	28-12-2011
;Source:	Iczelion
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.386
.model flat, stdcall
option casemap:none

include windows.inc
include kernel32.inc
include user32.inc
include comdlg32.inc

includelib kernel32.lib
includelib user32.lib
includelib comdlg32.lib

SEH struct
	PrevLink dd ?
	CurrentHandler dd ?
	SafeOffset dd ?
	PrevEsp dd ?
	PrevEbp dd ?
SEH EndS

.data
sAppName db "PEValidation App",0
ofn OPENFILENAME <>
sFilterString db "ExecutableFiles(*.exe, *.dll)",0,"*.exe,*.dll", 0
			  db "All Files", 0, "*.*", 0,0
sFileOpenError db "Cannot Open the file for reading",0
sFileOpenMappingError db "Cannot open the file for memory mapping", 0
sFileMappingError db "Cannot map the file to memory",0
sFileValidPE db "This file is a valid PE",0
sFilenotValidPE db "This file is not a valid PE",0

.data?
buffer db 512 dup(?)
hFile dd ?
hMapping dd ?
pMapping dd ?
ValidPE dd ?

.code
start proc
	LOCAL seh:SEH
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
				cmp ValidPE, TRUE
				jne ELSE6
					push MB_OK+MB_ICONINFORMATION
					push OFFSET sAppName
					push OFFSET sFileValidPE
					push 0
					Call MessageBox
					
					jmp AFTERIF2
				ELSE6:
					push MB_OK+MB_ICONINFORMATION
					push OFFSET sAppName
					push OFFSET sFilenotValidPE
					push 0
					Call MessageBox
				AFTERIF2:
					push seh.PrevLink
					pop fs:[0]
					
					push pMapping
					Call UnmapViewOfFile
					jmp AFTERIF3
				ELSE3:
					push MB_OK+MB_ICONERROR
					push OFFSET sAppName
					push OFFSET sFileMappingError
					push 0
					Call MessageBox
				AFTERIF3:
					
			push hMapping
			Call CloseHandle
			jmp AFTERIF4
			ELSE2:
				push MB_OK+MB_ICONERROR
				push OFFSET sAppName
				push OFFSET sFileOpenMappingError
				push 0
				Call MessageBox
		AFTERIF4:	
		push hFile
		Call CloseHandle
		jmp AFTERIF
		ELSE1:
			push MB_OK+MB_ICONERROR
			push OFFSET sAppName
			push OFFSET sFileOpenError
			push 0
			Call MessageBox
			
	AFTERIF:
		push 0
		Call ExitProcess
		
	;Ret
start EndP

SEHHandler proc C uses edx pExcept:DWORD, pFrame:DWORD, pContext:DWORD, pDispatch:DWORD
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

end start


