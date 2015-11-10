;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Name:	PEFileExportTable
;Author:	Iczelion
;Programmer:	Harsha Kadekar
;Description:	This displays the exported functions of a dll
;Date:	15-1-2012
;Last Modified:	15-1-2012
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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

IDD_MAINDLG equ 101
IDC_EDIT equ 500
IDM_OPEN equ 1001
IDM_EXIT equ 1002

DlgProc proto :DWORD, :DWORD, :DWORD, :DWORD
ShowExportFunctions proto :DWORD
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
sAppName db "PEFileExportTable",0
ofn OPENFILENAME <>
FilterString db "Executable Files (*.exe, *.dll)",0,"*.exe;*.dll",0
			 db "All Files",0,"*.*",0,0
FileOpenError db "Cannot open file for reading",0
FileOpenMappingError db "Cannot open the file for memory mapping",0
FileMappingError db "Cannot map the file to memory",0
NotValidPE db "This file is not a valid PE",0
NoExportTable db "No export function in this file",0
CRLF db 0dh,0ah,0
ExportTable db 0dh,0ah, "===============================IMAGE EXPORT DIRECTORY=====================================",0dh,0ah
			db "Name of the Module: %s",0dh,0ah
			db "nBase: %lu",0dh,0ah
			db "Number of functions: %lu", 0dh, 0ah
			db "Number of Names: %lu", 0dh,0ah
			db "Address of functions: %lx",0dh,0ah
			db "Address of Names: %lx",0dh,0ah
			db "Address of Name Ordinals: %lx",0dh,0ah,0
Header db "RVA ord. Name",0dh,0ah
	   db "----------------------------------------------------------------------",0
template db "%lX %u %s",0

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
	
	invoke DialogBoxParam, eax, IDD_MAINDLG, NULL, OFFSET DlgProc, 0
	invoke ExitProcess, 0
	
	DlgProc proc hDlg:DWORD, uMsg:DWORD, wParam:WPARAM, lParam:LPARAM
		.if uMsg==WM_INITDIALOG
			invoke SendDlgItemMessage, hDlg, IDC_EDIT, EM_SETLIMITTEXT, 0,0
		.elseif uMsg==WM_CLOSE
			invoke EndDialog, hDlg, 0
		.elseif uMsg==WM_COMMAND
			.if lParam == 0
				mov eax, wParam
				.if eax==IDM_OPEN
					invoke ShowExportFunctions, hDlg
				.else
					invoke SendMessage, hDlg, WM_CLOSE, 0,0
				.endif
			.endif
		.else
			mov eax, FALSE
			ret
		.endif
		mov eax, TRUE
		Ret
	DlgProc EndP

	SEHHandler proc c pExcept:DWORD, pFrame:DWORD, pContext:DWORD, pDispatch:DWORD
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
	
	ShowExportFunctions proc uses edi hDlg:DWORD
		LOCAL seh:SEH
		mov ofn.lStructSize, sizeof ofn
		mov ofn.lpstrFilter, OFFSET FilterString
		mov ofn.lpstrFile, OFFSET buffer
		mov ofn.nMaxFile, 512
		mov ofn.Flags, OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST or OFN_LONGNAMES or OFN_EXPLORER or OFN_HIDEREADONLY
		invoke GetOpenFileName, ADDR ofn
		.if eax==TRUE
			invoke CreateFile, ADDR buffer, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
			.if eax != INVALID_HANDLE_VALUE
				mov hFile, eax
				invoke CreateFileMapping, hFile, NULL, PAGE_READONLY, 0,0,0
				.if eax != NULL
					mov hMapping, eax
					invoke MapViewOfFile, hMapping, FILE_MAP_READ, 0, 0, 0
					.if eax != NULL
						mov pMapping, eax
						
						assume fs:nothing
						push fs:[0]
						pop seh.PrevLink
						mov seh.CurrentHandler, OFFSET SEHHandler
						mov seh.SafeOffset, OFFSET FINALEXIT
						lea eax, seh
						mov fs:[0], eax
						mov seh.PrevEsp, esp
						mov seh.PrevEbp, ebp
						mov edi, pMapping
						assume edi:ptr IMAGE_DOS_HEADER
						.if [edi].e_magic == IMAGE_DOS_SIGNATURE
							add edi, [edi].e_lfanew
							assume edi:ptr IMAGE_NT_HEADERS
							.if [edi].Signature == IMAGE_NT_SIGNATURE
								mov ValidPE, TRUE
							.else
								mov ValidPE, FALSE
							.endif
						.endif
		FINALEXIT:
						push seh.PrevLink
						pop fs:[0]
						.if ValidPE == TRUE
							invoke ShowTheFunctions, hDlg, edi
						.else
							invoke MessageBox, 0, addr NotValidPE, addr sAppName, MB_OK+MB_ICONERROR
						.endif
						
						invoke UnmapViewOfFile, pMapping
					.else
						invoke MessageBox, 0, addr FileMappingError, addr sAppName, MB_OK+MB_ICONERROR
					.endif
					
					invoke CloseHandle, hMapping
				.else
					invoke MessageBox, 0, addr FileOpenMappingError, addr sAppName, MB_OK+MB_ICONERROR
				.endif
				invoke CloseHandle, hFile
				
			.else
				invoke MessageBox, 0, addr FileOpenError, addr sAppName, MB_OK+MB_ICONERROR
			.endif
		.endif
			
					 
		Ret
	ShowExportFunctions EndP
	
	AppendText proc hDlg:DWORD, pText:DWORD
		invoke SendDlgItemMessage, hDlg, IDC_EDIT, EM_REPLACESEL, 0, pText
		invoke SendDlgItemMessage, hDlg, IDC_EDIT, EM_REPLACESEL, 0, addr CRLF
		invoke SendDlgItemMessage, hDlg, IDC_EDIT, EM_SETSEL, -1, 0 
		Ret
	AppendText EndP
	
	RVAToFileMap proc uses edi esi edx ecx pFileMap:DWORD, RVA:DWORD
		mov esi, pFileMap
		assume esi:ptr IMAGE_DOS_HEADER
		add esi, [esi].e_lfanew
		assume esi:ptr IMAGE_NT_HEADERS
		mov edi, RVA
		mov edx, esi
		add edx, sizeof IMAGE_NT_HEADERS
		mov cx, [esi].FileHeader.NumberOfSections
		movzx ecx, cx
		assume edx:ptr IMAGE_SECTION_HEADER
		.while ecx>0
			.if edi >= [edx].VirtualAddress
				mov eax, [edx].VirtualAddress
				add eax, [edx].SizeOfRawData
				.if edi < eax
					mov eax, [edx].VirtualAddress
					sub edi, eax
					mov eax, [edx].PointerToRawData
					add eax, edi
					add eax, pFileMap
					ret
				.endif
			.endif
			add edx, sizeof IMAGE_SECTION_HEADER
			dec ecx
		.endw
		
		assume edx:nothing
		assume esi:nothing
		mov eax, edi
						
		Ret
	RVAToFileMap EndP
	
	ShowTheFunctions proc uses esi ecx ebx hDlg:DWORD, pNTHdr:DWORD
		LOCAL temp[512]:BYTE
		LOCAL NumberOfNames:DWORD
		LOCAL Base:DWORD
		
		mov edi,pNTHdr
		assume edi:ptr IMAGE_NT_HEADERS
		
		mov edi, [edi].OptionalHeader.DataDirectory.VirtualAddress
		.if edi == 0
			invoke MessageBox, 0, addr NoExportTable, addr sAppName, MB_OK+MB_ICONERROR
			ret
		.endif
		
		invoke SetDlgItemText, hDlg, IDC_EDIT, 0
		invoke AppendText, hDlg, addr buffer
		invoke RVAToFileMap, pMapping, edi
		mov edi, eax
		
		assume edi:ptr IMAGE_EXPORT_DIRECTORY
		mov eax, [edi].NumberOfFunctions
		
		invoke RVAToFileMap, pMapping, [edi].nName
		invoke wsprintf, addr temp, addr ExportTable, eax, [edi].nBase, [edi].NumberOfFunctions, [edi].NumberOfNames, [edi].AddressOfFunctions, [edi].AddressOfNames, [edi].AddressOfNameOrdinals
		
		invoke AppendText, hDlg, addr temp
		invoke AppendText, hDlg, addr Header
		
		push [edi].NumberOfNames
		pop NumberOfNames
		
		push [edi].nBase
		pop Base
		
		invoke RVAToFileMap, pMapping, [edi].AddressOfNames
		mov esi, eax
		invoke RVAToFileMap, pMapping, [edi].AddressOfNameOrdinals
		mov ebx, eax
		invoke RVAToFileMap, pMapping, [edi].AddressOfFunctions
		mov edi, eax
		
		.while NumberOfNames> 0
			invoke RVAToFileMap, pMapping, DWORD ptr [esi]
			mov dx, [ebx]
			movzx edx, dx
			mov ecx, edx
			shl edx, 2
			add edx, edi
			add ecx, Base
			
			invoke wsprintf, addr temp, addr template, DWORD ptr [edx], ecx, eax
			invoke AppendText, hDlg, addr temp
			dec NumberOfNames
			add esi, 4
			add ebx, 2
		.endw
			
		Ret
	ShowTheFunctions EndP

end start