.386
.model flat, stdcall

option casemap :none

include kernel32.inc
include windows.inc
include user32.inc

includelib kernel32.lib
includelib user32.lib

.data
	Message db "Hey I am using Push/Pop for this program", 0
	HelloWorld db "HelloWorld!!", 0
	
.code
	start:
		push MB_OK
		push offset HelloWorld
		push offset Message
		push NULL
		Call MessageBox
		
		push 0
		Call ExitProcess
	end start
	

	