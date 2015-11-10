.386
.model flat, stdcall

option casemap :none

include windows.inc
include kernel32.inc
include masm32.inc

includelib kernel32.lib
includelib masm32.lib

.data
	HelloWorld db "Hey I am using push/pop for hello world", 0

.code
	start:
		push offset HelloWorld
		call StdOut
		push 0 
		call ExitProcess
	end start
	
	
		
