;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Name:	PEFileImportTable
;Programmer:	Harsha Kadekar
;Author:	Iczelion
;Description:	This will list all the imported functions of an PE file
;Date:	15-1-2012
;Last Modified:	15-1-2012
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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

IDD_MAINDLG equ 111
IDC_EDIT equ 2001
IDM_OPEN equ 1001
IDM_EXIT equ 1002

DlgProc proto :DWORD, :DWORD, :DWORD, :DWORD
ShowImportFunctions proto :DWORD
ShowTheFunctions proto :DWORD, :DWORD
AppendText proto :DWORD, :DWORD

SEH struct
	PrevLink dd ?
	CurrentHandler dd ?
	SafeOffset dd ?
	PrevEsp dd ?
	PrevEbp dd ?
SEH EndS

.data

sAppName db "PEInfoImportTableApp",0
ofn OPENFILENAME <>
FilterString db "Executable Files (*.exe, *.dll)",0, "*.exe;*.dll",0
			 db "All files",0, "*.*",0,0
sFileOpenError db "Error while openning the file",0
sFileOpenMappingError db "Cannot the open the file for memory mapping",0
sFileMappingError db "Error while mapping file to memory",0
NotValidPE db "This file is not a valid PE file",0
CRLF db 0dh,0ah,0
ImportDescriptor db 0dh,0ah,"=======================IMAGE IMPORT DESCRIPTOR=========================",0
IDTemplate db "OriginalFirstThunk = %lX",0dh,0ah
		   db "TimeDateStamp = %lX",0dh,0ah
		   db "ForwardChain = %lX",0dh,0ah
		   db "Name = %s",0dh,0ah
		   db "FirstThunk = %lX",0dh, 0ah
NameHeader db 0dh,0ah, "Hint Function",0dh,0ah
		   db "------------------------------------------------------------------------------------------------",0
NameTemplate db "%u %s",0
OrdinalTemplate db "%u (ord.)",0
DebugMessage db "I am here",0

.data?
buffer db 512 dup(?)
hFile dd ?
hMapping dd ?
pMapping dd ?
ValidPE dd ?

.code
start:
	push NULL
	Call GetModuleHandle
	
	push 0
	push OFFSET DlgProc
	push NULL
	push IDD_MAINDLG
	push eax
	Call DialogBoxParam
	
	push 0
	Call ExitProcess
	
	DlgProc proc hDlg:DWORD, uMsg:DWORD, wParam:WPARAM, lParam:LPARAM
		mov eax, uMsg
		
		cmp eax, WM_INITDIALOG
		je INITDIALOG
		cmp eax, WM_CLOSE
		je CLOSE
		cmp eax, WM_COMMAND
		je COMMAND
		
		jmp DEFAULT
		
		INITDIALOG:
			push 0
			push 0
			push EM_SETLIMITTEXT
			push IDC_EDIT
			push hDlg
			Call SendDlgItemMessage
			jmp EndProc
			
		CLOSE:
			push 0
			push hDlg
			Call EndDialog
			jmp EndProc
			
		COMMAND:
			cmp lParam, 0
			jne EndProc
				mov eax, wParam
				cmp ax, IDM_OPEN
				je OPEN
				cmp ax, IDM_EXIT
				je EXIT
				jmp EndProc
				
				OPEN:
					push hDlg
					Call ShowImportFunctions
					jmp EndProc
				
				EXIT:
					push 0
					push 0
					push WM_CLOSE
					push hDlg
					Call SendMessage
					
					jmp EndProc
		
		DEFAULT:
			mov eax, FALSE
			ret
			
		EndProc:
			mov eax, TRUE
				
		Ret
	DlgProc EndP


	

	SEHHandler proc pExcept:DWORD, pFrame:DWORD, pContext:DWORD, pDispatch:DWORD
		mov edx,pFrame
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
	
	ShowImportFunctions proc uses edi hDlg:DWORD
		LOCAL seh:SEH
		mov ofn.lStructSize, SIZEOF ofn
		mov ofn.lpstrFilter, OFFSET FilterString
		mov ofn.lpstrFile, OFFSET buffer
		mov ofn.nMaxFile, 512
		mov ofn.Flags, OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST or OFN_LONGNAMES or OFN_EXPLORER or OFN_HIDEREADONLY
		
		lea eax, ofn
		push eax
		Call GetOpenFileName
		
		cmp eax, TRUE
		jne ELSE1
			push NULL
			push FILE_ATTRIBUTE_NORMAL
			push OPEN_EXISTING
			push NULL
			push FILE_SHARE_READ
			push GENERIC_READ
			lea eax, buffer
			push eax
			Call CreateFile
			
			cmp eax,INVALID_HANDLE_VALUE
			je ELSE2
				mov hFile, eax
				
				push 0
				push 0
				push 0
				push PAGE_READONLY
				push NULL
				push hFile
				Call CreateFileMapping
				
				cmp eax, NULL
				je ELSE3
					mov hMapping, eax
					
					push 0
					push 0
					push 0
					push FILE_MAP_READ
					push hMapping
					Call MapViewOfFile
					
					cmp eax, NULL
					je FinalExit
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
						jne FinalExit
							add edi, [edi].e_lfanew
							assume edi:ptr IMAGE_NT_HEADERS
							cmp [edi].Signature, IMAGE_NT_SIGNATURE
							jne ELSE6
								mov ValidPE, TRUE
								jmp AFTERIF6
							ELSE6:
								mov ValidPE, FALSE
								jmp AFTERIF6
								
					AFTERIF6:
					FinalExit:
						push seh.PrevLink
						pop fs:[0]
						cmp ValidPE, TRUE
						jne ELSE7
							push edi
							push hDlg
							Call ShowTheFunctions
							jmp AFTERELSE7
						 ELSE7:
						 	push MB_OK+MB_ICONERROR
						 	push OFFSET sAppName
						 	push OFFSET NotValidPE
						 	push 0
						 	Call MessageBox
						 	
						 AFTERELSE7:
						 
						 push pMapping
						 Call UnmapViewOfFile
						 jmp AFTERELSE5
							 
				ELSE3:
					push MB_OK+MB_ICONERROR
					push OFFSET sAppName
					push OFFSET sFileMappingError
					push 0
					Call MessageBox
				AFTERELSE5:
					
					push hMapping
					Call CloseHandle
					jmp AFTERELSE4
							
			ELSE2:
				push MB_OK+MB_ICONERROR
				push OFFSET sAppName
				push OFFSET sFileOpenMappingError
				push 0
				Call MessageBox
				
			AFTERELSE4:
				push hFile
				Call CloseHandle
			jmp AFTERALL
						
		ELSE1:
			push MB_OK+MB_ICONERROR
			push OFFSET sAppName
			push OFFSET sFileOpenError
			push 0
			Call MessageBox
				
		AFTERALL:
				
							 	
					
		Ret
	ShowImportFunctions EndP
	
	
	AppendText proc hDlg:DWORD, pText:DWORD
		
		push pText
		push 0
		push EM_REPLACESEL
		push IDC_EDIT
		push hDlg
		Call SendDlgItemMessage
		
		push OFFSET CRLF
		push 0
		push EM_REPLACESEL
		push IDC_EDIT
		push hDlg
		Call SendDlgItemMessage
		
		push 0
		push -1
		push EM_SETSEL
		push IDC_EDIT
		push hDlg
		Call SendDlgItemMessage
		
		
		Ret
	AppendText EndP

	RVAToOffset PROC uses edi esi edx  ecx pFileMap:DWORD, RVA:DWORD
		mov esi, pFileMap
		assume esi:ptr IMAGE_DOS_HEADER
		add esi, [esi].e_lfanew
		assume esi:ptr IMAGE_NT_HEADERS
		mov edi, RVA
		mov edx, esi
		add edx, sizeof IMAGE_NT_HEADERS
		mov cx, [esi].FileHeader.NumberOfSections
		movzx ecx,cx
		assume edx:ptr IMAGE_SECTION_HEADER
		START_WHILE:
			cmp ecx,0
			jle END_WHILE
			cmp edi, [edx].VirtualAddress
			jl AFTERIF1
				;cmp edi, eax
				;jge AFTERIF1
				mov eax, [edx].VirtualAddress
				add eax, [edx].SizeOfRawData
				cmp edi, eax
				jge AFTERIF1
					mov eax,[edx].VirtualAddress
					sub edi, eax
					mov eax, [edx].PointerToRawData
					add eax,edi
					ret
			AFTERIF1:
				add edx, sizeof IMAGE_SECTION_HEADER
				dec ecx
			jmp START_WHILE
		END_WHILE:
		
		assume edx:nothing
		assume esi:nothing
		
		mov eax, edi
					
		Ret
	RVAToOffset EndP
	


	
	ShowTheFunctions proc uses esi ecx ebx hDlg:DWORD, pNTHdr:DWORD
	
		LOCAL temp[512]:BYTE
		
		push 0
		push IDC_EDIT
		push hDlg
		Call SetDlgItemText
		
		lea eax, buffer
		push eax
		push hDlg
		Call AppendText
		
		mov edi, pNTHdr
		assume edi:ptr IMAGE_NT_HEADERS
		mov edi, [edi].OptionalHeader.DataDirectory[sizeof IMAGE_DATA_DIRECTORY].VirtualAddress
		push edi
		push pMapping
		Call RVAToOffset
		
		mov edi,eax
		add edi, pMapping
		assume edi:ptr IMAGE_IMPORT_DESCRIPTOR
		
		
		
		
	;	.while !([edi].OriginalFirstThunk==0 && [edi].TimeDateStamp==0 && [edi].ForwarderChain==0 [edi].Name1==0 && [edi].FirstThunk==0)
		.while !([edi].OriginalFirstThunk==0 && [edi].TimeDateStamp==0 && [edi].ForwarderChain==0 && [edi].Name1==0 && [edi].FirstThunk==0)
	
			lea eax, ImportDescriptor
			push eax
			push hDlg
			Call AppendText
			
			push [edi].Name1
			push pMapping
			Call RVAToOffset
			
		
			
			mov edx, eax
			add edx, pMapping
			
			push [edi].FirstThunk
			push edx
			push [edi].ForwarderChain
			push [edi].TimeDateStamp
			push [edi].OriginalFirstThunk
			lea ebx, IDTemplate
			push ebx
			lea ebx, temp
			push ebx
			Call wsprintf
			
			lea ebx, temp
			push ebx
			push hDlg
			Call AppendText
			
			.if [edi].OriginalFirstThunk==0
				mov esi, [edi].FirstThunk
			.else
				mov esi, [edi].OriginalFirstThunk
			.endif
			
			push esi
			push pMapping
			Call RVAToOffset
			add eax, pMapping
			mov esi, eax
			
			lea eax, NameHeader
			push eax
			push hDlg
			Call AppendText
			
			.while dword ptr [esi]!= 0
				test dword ptr [esi], IMAGE_ORDINAL_FLAG32
				jnz ImportByOrdinal
				
				push dword ptr [esi]
				push pMapping
				Call RVAToOffset
				
				mov edx, eax
				add edx, pMapping
				
				assume edx:ptr IMAGE_IMPORT_BY_NAME
				mov cx, [edx].Hint
				movzx ecx, cx
				
				lea eax, [edx].Name1
				push eax
				push ecx
				lea eax, NameTemplate
				push eax
				lea eax, temp
				push eax
				Call wsprintf
				
				jmp ShowTheText
				
				ImportByOrdinal:
					mov edx, dword ptr [esi]
					and edx, 0FFFFh
					invoke wsprintf, addr temp, addr OrdinalTemplate, edx
					
				ShowTheText:
					lea eax, temp
					push eax
					push hDlg
					Call AppendText
					
					add esi,4
					
			.endw
			add edi, sizeof IMAGE_IMPORT_DESCRIPTOR
		.endw
		Ret
	ShowTheFunctions EndP


end start