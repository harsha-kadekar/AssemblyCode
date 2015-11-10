;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Name: HttpClientReq
;Author:	Harsha
;Description:	This uses the sockets to communicate with a web server to retrive the http header
;				In this www.google.com 's header has been retrieved.
;Date:	30-11-2011
;LastModified:	30-11-2011
;Source: www.madwizard.org
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.386
.model flat, stdcall

option casemap:none

include windows.inc
include user32.inc
include kernel32.inc
include crtlib.inc
include ws2_32.inc

includelib kernel32.lib
includelib user32.lib
includelib crtlib.lib
includelib ws2_32.lib

RequestHeader proto :DWORD
FindHostIP proto :DWORD
main proto :DWORD, :DWORD
FillSockAddr proto :DWORD, :DWORD, :DWORD


.const

CR equ 0dh
LF equ 0ah
SERVER_PORT equ 80
TEMP_BUFFER_SIZE equ 128
REQ_WINSOCK_VER equ 2

.data

	g_defaultServerName db "www.google.com",0
	g_request_part1 db "HEAD / HTTP/1.1",CR,LF
					db "Host: "
	REQUEST_SIZE1 equ $-g_request_part1
	g_request_part2 db CR,LF
					db "User-agent: HeadReqSample", CR,LF
					db "Connection:close", CR, LF
					db CR,LF
	REQUEST_SIZE2 equ $-g_request_part2
	
	g_msgLookupHost db "Looking up hostname %s......", 0
	g_msgFound db "FOUND.",CR,LF,0
	g_msgCreateSock db "Creating socket....",0
	g_msgCreated db "Created.",CR,LF,0
	g_msgConnect db "Attempting to connect to %s:%d......",0
	g_msgConnected db "Connected.", CR, LF,0
	g_msgSendReq db "Sending request......",0
	g_msgReqSent db "Request sent.", CR, LF, 0
	g_msgDumpData db "Dumping recieved data.....",CR,LF,CR,LF,0
	g_msgInitWinsock db "Initializing the winsock.......",0
	g_msgInitialized db "Initialized.", CR,LF,0
	g_msgDone db "done.",CR, LF,0
	g_msgCleanup db "Cleanning up winsock.....",0
	
	g_errHostName db "Could not resolve hostname.",CR, LF, 0
	g_errCreatSock db "Could not create socket.", CR, LF, 0
	g_errConnect db "Could not connect to server.", CR, LF,0
	g_errSend db "Failed to send data", CR, LF, 0
	g_errRecv db "Failed to revcieve data", CR, LF, 0
	g_errStartup db "Startup failed", 0
	g_errVersion db "Required verion not available",0
	g_errCleanup db "Cleanup failed",0

.code
start:

	sub esp, 12
	lea eax, [esp+0]
	lea ecx, [esp+4]
	lea edx, [esp+8]
	push 0
	push eax
	push ecx
	push edx
	Call getmainargs
	
	add esp, 4
	Call main
	
	push eax
	Call ExitProcess
	
	FindHostIP proc uses ebx pServerName:DWORD
	
		push [pServerName]
		Call gethostbyname
		test eax, eax
		jz RETURN
		
		mov eax, [(hostent ptr[eax]).h_list]
		test eax, eax
		jz RETURN
		
		mov eax, [eax]
		test eax, eax
		jz RETURN
		
		mov eax, [eax]
		
		RETURN:
		Ret
	FindHostIP EndP


	FillSockAddr proc pSockAddr:DWORD, pServerName:DWORD, portNumber:DWORD
		push [pServerName]
		Call FindHostIP
		test eax, eax
		jz DONE
		
		mov edx, [pSockAddr]
		mov ecx, [portNumber]
		
		xchg cl, ch
		
		mov [edx][sockaddr_in.sin_family], AF_INET
		mov [edx][sockaddr_in.sin_port], cx
		mov [edx][sockaddr_in.sin_addr.S_un.S_addr], eax
		
		DONE:
		Ret
	FillSockAddr EndP
	
	main proc uses ebx argc:DWORD, argv:DWORD
	
		local wsadata:WSADATA
		
		push OFFSET g_msgInitWinsock
		Call printf
		
		lea eax, wsadata
		push eax
		push REQ_WINSOCK_VER
		Call WSAStartup
		
		mov ecx, OFFSET g_errStartup
		test eax, eax
		jnz SINGLE_ERROR
			
			cmp byte ptr [wsadata.wVersion], REQ_WINSOCK_VER
			mov ecx, OFFSET g_errVersion
			jb ERROR_CLEANUP
				
				push OFFSET g_msgInitialized
				Call printf
				
				mov ecx, OFFSET g_defaultServerName
				cmp [argc], 2
				mov eax, [argv]
				jb @F
					mov ecx, [eax][1*4]
			@@:	push ecx
				Call RequestHeaders
				mov ebx, eax
				xor ebx, 1
				
		CLEANUP:
			push OFFSET g_msgCleanup
			Call printf
			
			Call WSACleanup
			
			test eax, eax
			jz MAIN_DONE
			
			push OFFSET g_errCleanup
			Call printf
		
		MAIN_DONE:
			push OFFSET g_msgDone
			Call printf
			
			mov eax, ebx
			ret
			
		ERROR_CLEANUP:
			mov ebx, CLEANUP
			jmp PRINT_ERROR
		
		SINGLE_ERROR:
			mov ebx, MAIN_DONE
			
		PRINT_ERROR:
			push ecx
			Call printf
			
			mov eax, ebx
			mov ebx, 1
			jmp eax

		;Ret
	main EndP
	
	RequestHeaders proc uses ebx esi pServerName:DWORD
	
		local tempBuffer[TEMP_BUFFER_SIZE]:BYTE
		local socAddr:sockaddr_in
		
		mov esi, INVALID_SOCKET
		
		mov ebx, [pServerName]
		push ebx
		push OFFSET g_msgLookupHost
		Call printf
		
		push SERVER_PORT
		push ebx
		lea eax,socAddr
		push eax
		Call FillSockAddr
		
		mov ecx, OFFSET g_errHostName
		test eax, eax
		jz REQHEADERROR
		push OFFSET g_msgFound
		Call printf
		
		push OFFSET g_msgCreateSock
		Call printf
		push IPPROTO_TCP
		push SOCK_STREAM
		push AF_INET
		Call socket
		mov ecx, OFFSET g_errCreatSock
		cmp eax, INVALID_SOCKET
		je REQHEADERROR
		mov esi, eax
		push OFFSET g_msgCreated
		Call printf
		
		push [socAddr.sin_addr.S_un.S_addr]
		Call inet_ntoa
		push SERVER_PORT
		push eax
		push OFFSET g_msgConnect
		Call printf
		
		push SIZEOF socAddr
		lea eax, socAddr
		push eax
		push esi
		Call connect
		mov ecx, OFFSET g_errConnect
		test eax, eax
		jnz REQHEADERROR
		push OFFSET g_msgConnected
		Call printf
		
		push OFFSET g_msgSendReq
		Call printf
		
		push 0
		push REQUEST_SIZE1
		push OFFSET g_request_part1
		push esi
		Call send
		mov ecx, OFFSET g_errSend
		cmp eax, SOCKET_ERROR
		je REQHEADERROR
		
		push [pServerName]
		Call lstrlen
		push 0
		push eax
		push [pServerName]
		push esi
		Call send
		mov ecx, OFFSET g_errSend
		cmp eax, SOCKET_ERROR
		je REQHEADERROR
		
		push 0
		push REQUEST_SIZE2
		push OFFSET g_request_part2
		push esi
		Call send
		mov ecx, OFFSET g_errSend
		cmp eax, SOCKET_ERROR
		je REQHEADERROR
		
		push OFFSET g_msgReqSent
		Call printf
		
		push OFFSET g_msgDumpData
		Call printf
		
		RECIEVE_LOOP:
			push 0
			push TEMP_BUFFER_SIZE -1
			lea eax, tempBuffer
			push eax
			push esi
			Call recv
			
			test eax, eax
			mov ecx, OFFSET g_errRecv
			jz CONNECTIONCLOSED
			cmp eax, SOCKET_ERROR
			je REQHEADERROR
			
			mov [tempBuffer][eax], 0
			lea eax, tempBuffer
			push eax
			Call printf
			
			jmp RECIEVE_LOOP
		
		CONNECTIONCLOSED:
			mov ebx, 1
		
		CLEANUP:
			cmp esi, INVALID_SOCKET
			je @F
				push esi
				Call closesocket
			@@:
			mov eax, ebx
			ret
		
		REQHEADERROR:
			push ecx
			Call printf
			xor ebx, ebx
			jmp CLEANUP
			
		
		;Ret
	RequestHeaders EndP

end start
