;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Name:	BasicServerSocket
;Author:	Harsha
;Description:	This is a basic server socket. It accepts connection from client and sends or recieves 
;				message to client 
;Date:	1-12-2011
;Last Modified:	2-12-2011
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.386
.model flat, stdcall

option casemap:none

include windows.inc
include kernel32.inc
include user32.inc
include ws2_32.inc
include crtlib.inc

includelib kernel32.lib
includelib user32.lib
includelib ws2_32.lib
includelib crtlib.lib

main proto argc:DWORD,argv:DWORD 

.const
	LISTENPORT equ 27500
	MAX_SIZE equ 512
	REQ_WINSOCK_VER equ 2
	
.data
	g_errInitialized db "Server: Failed to initialize: %d", 0dh, 0Ah, 0
	g_errAddressInfo db "Server: Failed to get address info: %d", 0dh, 0ah, 0
	g_errSocketCreate db "Server: Unable to create socket: %d", 0dh, 0ah, 0
	g_errSocketBind db "Server: Unable to bind to address: %d", 0dh, 0ah, 0
	g_errSocketAccept db "Server: Failed to accept clients connection: %d", 0dh, 0ah, 0
	g_errSocketListen db "Server: Failed to listen for client requests: %d", 0dh, 0ah, 0
	g_errSend db "Server: Failed to send message: %d", 0dh, 0ah, 0
	g_errRecv db "Server: Failed to recieve message: %d", 0dh, 0ah, 0
	g_errShutdown db "Server: Failed to shutdown socket: %d", 0dh, 0ah, 0
	g_msgClose db "Server: Client connection closing", 0dh, 0ah, 0
	g_msgRecv db "%s", 0dh, 0ah, 0
	sMessage db "Hi, How are you?Server", 0dh, 0ah,0
	
;.data?
;	hints ADDRINFO ?
;	result ADDRINFO ?
	
	
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
	call main
	
	push eax
	Call ExitProcess
	
	main proc argc:DWORD, argv:DWORD
		LOCAL wsadata:WSADATA
		LOCAL listenSocket:SOCKET
		LOCAL clientSocket:SOCKET
		;LOCAL hints:ADDRINFO
		;LOCAL result:ADDRINFO
		;LOCAL addrResult:DWORD
		LOCAL recvBuffer[MAX_SIZE]:BYTE
		LOCAL iResult:DWORD
		LOCAL sockAddr:sockaddr_in
		
		;lea eax, result
		;mov addrResult, eax 
		
		lea eax, wsadata
		push eax
		push REQ_WINSOCK_VER
		Call WSAStartup
		cmp eax, 0
		je MAINAFTERIF1
			Call WSAGetLastError
			push eax
			push OFFSET g_errInitialized
			Call printf
			
			push MB_OK
		push offset sMessage
		push offset sMessage
		push NULL
		Call MessageBox
		
			mov eax, -1
			Ret
		MAINAFTERIF1:
		
		;push sizeof hints
		;lea eax, hints
		;push eax
		;Call RtlZeroMemory
		
		push MAX_SIZE
		lea eax, recvBuffer
		push eax
		Call RtlZeroMemory
		
		;mov hints.ai_family, AF_INET
		;mov hints.ai_socktype, SOCK_STREAM
		;mov hints.ai_protocol, IPPROTO_TCP
		;mov hints.ai_flags, AI_PASSIVE
		
		;lea eax, addrResult
		;push eax
		;lea eax, hints
		;push eax
		;push LISTENPORT
		;push NULL
		;Call getaddrinfo
		
		;cmp eax, 0
		;je MAINAFTERIF2
		;	Call WSAGetLastError
		;	push eax
		;	push OFFSET g_errAddressInfo
		;	Call printf
		;	Call WSACleanup
			
		;	mov eax, -1
		;	Ret
		;MAINAFTERIF2:
		
		;push addrResult.result.ai_protocol
		;push addrResult.result.ai_socktype
		;push addrResult.result.ai_family
		push IPPROTO_TCP
		push SOCK_STREAM
		push AF_INET
		Call socket
		cmp eax, INVALID_SOCKET
		jne MAINAFTERIF3
			Call WSAGetLastError
			push eax
			push OFFSET g_errSocketCreate
			Call printf
			
			Call WSACleanup
			
			push MB_OK
		push offset sMessage
		push offset sMessage
		push NULL
		Call MessageBox
		
			mov eax, -1
			Ret
		MAINAFTERIF3:
		
		mov listenSocket, eax
		
		;push [addrResult].ai_addrlen
		;push [addrResult].ai_addr
		;push listenSocket
		lea eax,sockAddr
		mov		edx,eax 
		mov		ecx, LISTENPORT
		xchg 	cl, ch	; convert to network byte order
	
		mov		[edx][sockaddr_in.sin_family], AF_INET	
		mov		[edx][sockaddr_in.sin_port], cx
		mov		[edx][sockaddr_in.sin_addr.S_un.S_addr], INADDR_ANY
		
		push SIZEOF sockAddr
		lea eax, sockAddr
		push eax
		push listenSocket
		Call bind
		cmp eax, SOCKET_ERROR
		jne MAINAFTERIF4
			Call WSAGetLastError
			push eax
			push OFFSET g_errSocketBind
			Call printf
			
			;push addrResult
			;Call freeaddrinfo
			
			Call WSACleanup
			
			push MB_OK
		push offset sMessage
		push offset sMessage
		push NULL
		Call MessageBox
		
			mov eax, -1
			Ret
		MAINAFTERIF4:
		
		;push addrResult
		;Call freeaddrinfo
		
		push SOMAXCONN
		push listenSocket
		Call listen
		cmp eax, SOCKET_ERROR
		jne MAINAFTERIF5
			Call WSAGetLastError
			push eax
			push OFFSET g_errSocketListen
			Call printf
			
			push listenSocket
			Call closesocket
			
			Call WSACleanup
			
			push MB_OK
		push offset sMessage
		push offset sMessage
		push NULL
		Call MessageBox
		
			mov eax, -1
			Ret
		MAINAFTERIF5:
		
		push NULL
		push NULL
		push listenSocket
		Call accept
		cmp eax, INVALID_SOCKET
		jne MAINAFTERIF6
			Call WSAGetLastError
			push eax
			push OFFSET g_errSocketAccept
			Call printf
			
			push listenSocket
			Call closesocket
			
			Call WSACleanup
			
			push MB_OK
		push offset sMessage
		push offset sMessage
		push NULL
		Call MessageBox
		
			mov eax, -1
			Ret
		MAINAFTERIF6:
		
		mov clientSocket, eax
		
		push listenSocket
		Call closesocket
		
		DOLOOP:
			push 0
			push MAX_SIZE
			lea eax,recvBuffer
			push eax
			push clientSocket
			Call recv
			cmp eax, 0
			mov iResult, eax
			jg SERRECV
			je CLIENTCLOSE
			jmp RECVFAIL
			
			SERRECV:
				lea eax, recvBuffer
				push eax
				push OFFSET g_msgRecv
				Call printf
				
				push 0
				push MAX_SIZE
				lea eax, recvBuffer
				push eax
				push clientSocket
				Call send
				cmp eax, SOCKET_ERROR
				jne AFTERIFELSE
					Call WSAGetLastError
					push eax
					push OFFSET g_errSend
					Call printf
					
					push clientSocket
					Call closesocket
					
					Call WSACleanup
					
					push MB_OK
		push offset sMessage
		push offset sMessage
		push NULL
		Call MessageBox
		
					mov eax, -1
					Ret
				jmp AFTERIFELSE
			
			CLIENTCLOSE:
				push OFFSET g_msgClose
				Call printf
				jmp AFTERIFELSE
			
			RECVFAIL:
				Call WSAGetLastError
				push eax
				push OFFSET g_errRecv
				Call printf
				
				push clientSocket
				Call closesocket
				
				Call WSACleanup
				
				push MB_OK
		push offset sMessage
		push offset sMessage
		push NULL
		Call MessageBox
		
				mov eax, -1
				RET
			
			AFTERIFELSE:
			cmp iResult, 0
			jg DOLOOP
			
		ENDDOLOOP:
		
		push SD_SEND
		push clientSocket
		Call shutdown
		cmp eax, SOCKET_ERROR
		jne MAINAFTERIF7
			Call WSAGetLastError
			push eax
			push OFFSET g_errShutdown
			Call printf
			
			push clientSocket
			Call closesocket
			
			Call WSACleanup
			
			push MB_OK
		push offset sMessage
		push offset sMessage
		push NULL
		Call MessageBox
		
			mov eax, -1
			Ret
		MAINAFTERIF7:
		
		push clientSocket
		Call closesocket
		
		Call WSACleanup
		
		push MB_OK
		push offset sMessage
		push offset sMessage
		push NULL
		Call MessageBox
		
		xor eax, eax
		
		Ret
	main EndP	
end start