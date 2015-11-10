;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Name:	DLLExample
;Author: Harsha Kadekar
;Description:	To understand the working of dll
;Last modified: 18-11-2011
;Date:	18-11-2011
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




.386
.model FLAT, STDCALL
option casemap: none

include windows.inc
include user32.inc
include kernel32.inc
;include windows.inc

includelib kernel32.lib
includelib user32.lib

.data
InsideMsg db "I am inside Function", 0
DllName db "DllExample",0
sLoadMessage db "Dll loaded to memory",0
sUnloadMessage db "Dll unloaded from memory",0
sThreadAttach db "Thread attached in memory",0
sThreadDetach db "Thread deattached in memory",0
.code

DllEntry proc hInstDll:HINSTANCE, reason:DWORD, reserved1:DWORD
	.if reason==DLL_PROCESS_ATTACH
		invoke MessageBox,NULL,addr sLoadMessage,addr DllName,MB_OK
	.elseif reason==DLL_PROCESS_DETACH
		invoke MessageBox,NULL,addr sUnloadMessage,addr DllName,MB_OK
	.elseif reason==DLL_THREAD_ATTACH
		invoke MessageBox,NULL,addr sThreadAttach,addr DllName,MB_OK
	.else        ; DLL_THREAD_DETACH
		invoke MessageBox,NULL,addr sThreadDetach,addr DllName,MB_OK
	.endif

	mov eax, TRUE
	Ret
DllEntry EndP

TestFunc proc
	push MB_OK
	push OFFSET DllName
	push OFFSET InsideMsg
	push NULL
	Call MessageBox
	
	Ret
TestFunc EndP

END DllEntry

