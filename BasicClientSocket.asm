;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Name:	BasicClientSocket
;Author:	Harsha Kadekar
;Description:	This is the basic client socket which connects to server, then it will send and
;				recieve messages from server.
;Date:	2-12-2011
;Last Modified:	2-12-2011
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.386
.model flat, stdcall

option casemap: none

include windows.inc
include kernel32.inc
include user32.inc
include ws2_32.inc
include crtlib.inc

includelib kernel32.lib
includelib user32.lib
includelib ws2_32.lib
includelib crtlib.lib

main proto :DWORD, :DWORD

.const 
	CONNECTPORT equ 27500
	MAX_SIZE equ 512
	REQ_WINSOCK_VERSION equ 2

.data
	g_errInitialize db "Client: Error during initialisation: %d", 0dh, 0ah, 0
	g_errSocketCreate db "Client: Socket creation failed: %d", 0dh, 0ah, 0
	g_errSocketConnect db "Client: Unable to connect to server: %d", 0dh, 0ah, 0
	g_errSend db "Client: Sending data failed: %d", 0dh, 0ah, 0
	g_msgSent db "Client: Sent message successfully", 0dh, 0ah, 0
	sMessage db "Hi How are you", 0ah, 0dh, 0
	g_errRecv db "Client: Recieve from serve failed: %d", 0dh, 0ah, 0
	gServerAddr db "localhost",0
	g_msgRecv db "%s",0dh, 0ah, 0
	g_msgClose db "Connection is closing", 0dh, 0ah, 0
	g_errShutdown db "Client: Error while closing socket: %d", 0dh, 0ah, 0
	g_IPaddr db "127.0.0.1",0
	
	
.code
start:
	sub esp, 12
	lea eax, [esp+0]
	lea ecx, [esp+4]
	lea edx, [esp+8]
	
	push 0
	push eax
	push edx
	push ecx
	Call getmainargs
	
	add esp, 4
	Call main
	
	push eax
	Call ExitProcess
	
	main proc uses ebx argc:DWORD, argv:DWORD
		LOCAL wsadata:WSADATA
		LOCAL connectSocket:SOCKET
		LOCAL recvBuffer[MAX_SIZE]:BYTE
		LOCAL iResult:DWORD
		LOCAL sockAddr:sockaddr_in
		
		lea eax, wsadata
		push eax
		push REQ_WINSOCK_VERSION
		Call WSAStartup
		cmp eax, 0
		je MAINAFTERIF1
			Call WSAGetLastError
			push eax
			push OFFSET g_errInitialize
			Call printf
			
			mov eax, -1
			Ret
		MAINAFTERIF1:
		
		push MAX_SIZE
		lea eax, recvBuffer
		push eax
		Call RtlZeroMemory
		
		push IPPROTO_TCP
		push SOCK_STREAM
		push AF_INET
		Call socket
		cmp eax, INVALID_SOCKET
		jne MAINAFTERIF2
			Call WSAGetLastError
			push eax
			push OFFSET g_errSocketCreate
			Call printf
			
			Call WSACleanup
			
			mov eax, -1
			Ret
		MAINAFTERIF2:
		
		mov connectSocket, eax
		
		lea eax, sockAddr
		mov edx, eax
		mov ecx, CONNECTPORT
		xchg cl, ch
		
		mov [edx][sockaddr_in.sin_family], AF_INET
		mov [edx][sockaddr_in.sin_port], cx
		;mov [edx][sockaddr_in.sin_addr.S_un.S_addr], OFFSET g_IPaddr
		push OFFSET g_IPaddr
		Call inet_addr
		mov [edx][sockaddr_in.sin_addr], eax
		push SIZEOF sockAddr
		lea eax, sockAddr
		push eax
		push connectSocket
		Call 	connect
		cmp eax, SOCKET_ERROR
		jne MAINAFTERIF3
			Call WSAGetLastError
			push eax
			push OFFSET g_errSocketConnect
			Call printf
			
			push connectSocket
			Call closesocket
			
			Call WSACleanup
			mov eax, -1
			Ret
		MAINAFTERIF3:
		
		push 0
		push MAX_SIZE
		push OFFSET sMessage
		push connectSocket
		Call send
		cmp eax, SOCKET_ERROR
		jne MAINAFTERIF4
			Call WSAGetLastError
			push eax
			push OFFSET g_errSend
			Call printf
			
			push connectSocket
			Call closesocket
			
			Call WSACleanup
			mov eax, -1
			Ret
		MAINAFTERIF4:
		
		push 0
		push MAX_SIZE
		lea eax, recvBuffer
		push eax
		push connectSocket
		Call recv
		mov iResult, eax
		cmp eax, 0
		je CONNECTIONCLOSED
		jl RECVERROR
		jg RECIEVED
		
		jmp AFTERIFELSE
		
		CONNECTIONCLOSED:
			push OFFSET g_msgClose
			Call printf
			jmp AFTERIFELSE
		
		RECVERROR:
			Call WSAGetLastError
			push eax
			push OFFSET g_errRecv
			Call printf
			
			push connectSocket
			Call socket
			
			Call WSACleanup
			mov eax, -1
			Ret
		
		RECIEVED:
			push OFFSET g_msgRecv
			lea eax, recvBuffer
			push eax
			Call printf
			
		AFTERIFELSE:
		
		push SD_SEND
		push connectSocket
		Call shutdown
		cmp eax, SOCKET_ERROR
		jne MAINAFTERIF5
			Call WSAGetLastError
			push eax
			push OFFSET g_errShutdown
			Call printf
			
			push connectSocket
			Call closesocket
			
			Call WSACleanup
			mov eax, -1
			Ret 
		MAINAFTERIF5:
		
		push connectSocket
		Call closesocket
		
		Call WSACleanup
		
		push MB_OK
		push OFFSET sMessage
		push OFFSET sMessage
		push NULL
		Call MessageBox
		
		
		
		xor eax, eax
		
		
		
		Ret
	main EndP
end start
	
