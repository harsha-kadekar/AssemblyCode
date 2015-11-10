;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Name:	SimpleServer
;Description:	This is a simple server. It uses socket and can communicate with only one client.
;Author:	Harsha Kadekar
;Date:	3-3-2012
;Last Modified:	4-3-2012
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.386
.model flat,stdcall
option casemap:none

include windows.inc
include kernel32.inc
include user32.inc
include gdi32.inc
include ws2_32.inc

includelib kernel32.lib
includelib user32.lib
includelib gdi32.lib
includelib ws2_32.lib

DlgProc proto :DWORD, :DWORD, :DWORD, :DWORD
SeverConfigDlgProc proto :DWORD, :DWORD, :DWORD, :DWORD

.data
g_errInitialize db "Server: Failed to initialize: %d", 0dh, 0Ah, 0
g_errAddressInfo db "Server: Failed to get address info: %d", 0dh, 0ah, 0
g_errSocketCreate db "Server: Unable to create socket: %d", 0dh, 0ah, 0
g_errSocketBind db "Server: Unable to bind to address: %d", 0dh, 0ah, 0
g_errSocketAccept db "Server: Failed to accept clients connection: %d", 0dh, 0ah, 0
g_errSocketListen db "Server: Failed to listen for client requests: %d", 0dh, 0ah, 0
g_errSend db "Server: Failed to send message: %d", 0dh, 0ah, 0
g_errRecv db "Server: Failed to recieve message: %d", 0dh, 0ah, 0
g_errShutdown db "Server: Failed to shutdown socket: %d", 0dh, 0ah, 0
g_msgClose db "Server: Client connection closing", 0dh, 0ah, 0
g_errAsync db "SERVER: Error while making asynchronous initialisation", 0dh, 0ah, 0
g_msgRecv db "%s", 0dh, 0ah, 0
sMessage db "Hi, How are you?Server", 0dh, 0ah,0
sDialogName db "IDD_MAINDLG",0
sServerConfigDialogName db "IDD_SERVERCONFIG",0
sAppName db "SimpleServerChat",0

smsgform db "%d", 0
smsgform2 db "CLIENT: %s",0dh,0ah,0
g_errRetrive db "Failed to retrieve the text in chat window",0dh, 0ah, 0

wsadata WSADATA <>
SockAddr sockaddr_in <>

.data?

hInstance HINSTANCE ?
CommandLine LPSTR ?
sBuffer db 512 dup(?)
nError DWORD ?
ClientSocket SOCKET ?
ListenSocket SOCKET ?

.const
LISTENPORT equ 27500
MAX_SIZE equ 512
REQ_WINSOCK_VERSION equ 2
WM_SOCKET equ WM_USER+100

SHOW_HISTEDIT equ 1002
SERSEND_EDIT equ 1003
SEND_BUTTON equ 1004
START_BUTTON equ 1005
STOP_BUTTON equ 1006
;#define IDM_MNU 1000
IDM_MENU equ 1001
IDM_CONFIG equ 1002
IDM_EXIT equ 1003
IDM_ABOUT equ 1004
;#define IDD_MAINDLG 1001
IDC_STATIC1008 equ 1008
IDC_STATIC1009 equ 1009
IDC_EDITPORTNO equ 1012
IDC_EDITSEVNAME equ 1013
IDC_BUTTONOK equ 1010
IDC_BUTTONCANCEL equ 1011
	
.code

start:
	push NULL
	Call GetModuleHandle
	mov hInstance, eax
	
	push NULL
	push offset DlgProc
	push NULL
	push offset sDialogName
	push hInstance
	Call DialogBoxParam
	
	Call GetLastError
	mov nError, eax
	
	push eax
	Call ExitProcess
	
	DlgProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
		
		LOCAL temp[512]:BYTE
		LOCAL tempsize:DWORD 
		mov eax, uMsg
		
		cmp eax, WM_INITDIALOG
		je INITDIALOG
		cmp eax, WM_CLOSE
		je CLOSE
		cmp eax, WM_COMMAND
		je COMMAND
		cmp eax, WM_SOCKET
		je SOCKET_MSG
		
		jmp DEFAULT
		
		INITDIALOG:
			jmp DIALOG_END
		
		CLOSE:
			push 0
			push IDM_EXIT
			push WM_COMMAND
			push hWnd
			Call SendMessage
			
			jmp DIALOG_END
			
		COMMAND:
			mov eax, wParam
			cmp lParam, 0
			jne ELSEPART
				cmp ax, IDM_EXIT
				je M_EXIT
				cmp ax, IDM_CONFIG
				je M_SERVERCONFIG
				
				
				jmp DEFAULT
				
				M_EXIT:
					;Call WSACleanup
					push NULL
					push hWnd
					Call EndDialog
					
					jmp DIALOG_END
				
				M_SERVERCONFIG:
					push NULL
					push offset SeverConfigDlgProc
					push NULL
					push offset sServerConfigDialogName
					push hInstance
					Call DialogBoxParam
				
					
					jmp DIALOG_END
			ELSEPART:
				cmp ax, START_BUTTON
				je START_SERVER
				cmp ax, STOP_BUTTON
				je STOP_SERVER
				cmp ax, SEND_BUTTON
				je SEND
				
				jmp DEFAULT
				
				START_SERVER:
					lea eax, wsadata
					push eax
					push REQ_WINSOCK_VERSION
					Call WSAStartup
					cmp eax, 0
					je MAINAFTERIF1
						Call WSAGetLastError
						;push eax
						push MB_OK
						push OFFSET sAppName
						push OFFSET g_errInitialize
						push hWnd
						Call MessageBox
						jmp DIALOG_END
					MAINAFTERIF1:
			
					push IPPROTO_TCP
					push SOCK_STREAM
					push AF_INET
					Call socket
					cmp eax, INVALID_SOCKET
					jne MAINAFTERIF2
						Call WSAGetLastError
						push eax
						push MB_OK
						push OFFSET sAppName
						push OFFSET g_errSocketCreate
						push hWnd
						Call MessageBox
						Call WSACleanup
						jmp DIALOG_END
					MAINAFTERIF2:
					
					mov ListenSocket, eax
					
					push FD_CLOSE + FD_READ + FD_ACCEPT
					push WM_SOCKET
					push hWnd
					push ListenSocket
					Call WSAAsyncSelect
					
					cmp eax, SOCKET_ERROR
					jne MAINAFTER3
						Call WSAGetLastError
						;push eax
						push MB_OK
						push OFFSET sAppName
						push OFFSET g_errAsync
						push hWnd
						Call MessageBox
						Call WSACleanup
						jmp DIALOG_END
					MAINAFTER3:
					
					lea eax,SockAddr
					mov		edx,eax 
					mov		ecx, LISTENPORT
					xchg 	cl, ch	; convert to network byte order
				
					mov		[edx][sockaddr_in.sin_family], AF_INET	
					mov		[edx][sockaddr_in.sin_port], cx
					mov		[edx][sockaddr_in.sin_addr.S_un.S_addr], INADDR_ANY
					
					push SIZEOF SockAddr
					
					lea eax, SockAddr
					push eax
					push ListenSocket
					Call bind
					
					cmp eax, SOCKET_ERROR
					jne MAINAFTERIF4
						Call WSAGetLastError
						;push eax
						push MB_OK
						push OFFSET sAppName
						push OFFSET g_errSocketBind
						push hWnd
						Call MessageBox
						
						
					
						
						Call WSACleanup
						
						jmp DIALOG_END
					
					MAINAFTERIF4:
					
					push SOMAXCONN
					push ListenSocket
					Call listen
					cmp eax, SOCKET_ERROR
					jne MAINAFTERIF5
						Call WSAGetLastError
						;push eax
						push MB_OK
						push OFFSET sAppName
						push OFFSET g_errSocketListen
						push hWnd
						Call MessageBox
						
						push ListenSocket
						Call closesocket
						
						Call WSACleanup
						
						jmp DIALOG_END
					MAINAFTERIF5:
					
					jmp DIALOG_END
				
				STOP_SERVER:
				
					push SD_SEND
					push ClientSocket
					Call shutdown
					cmp eax, SOCKET_ERROR
					jne MAINAFTERIF8
						Call WSAGetLastError
						;push eax
						push MB_OK
						push OFFSET sAppName
						push OFFSET g_errShutdown
						push hWnd
						Call MessageBox
						
						push ListenSocket
						Call closesocket
						
						push ClientSocket
						Call closesocket
						
						Call WSACleanup
				
					MAINAFTERIF8:
					push ListenSocket
					Call closesocket
					
					push ClientSocket
					Call closesocket
					
					Call WSACleanup
					
					jmp DIALOG_END
				
				SEND:
				
					push 512
					push offset sBuffer
					push SERSEND_EDIT
					push hWnd
					Call GetDlgItemText
					
					cmp eax, 0
					jne SEND_AFTERIF
						push MB_OK
						push OFFSET sAppName
						push OFFSET g_errRetrive
						push hWnd
						Call MessageBox
						
						jmp DIALOG_END
					
					SEND_AFTERIF:
					
					inc eax
					push 0
					push eax
					push OFFSET sBuffer
					push ClientSocket
					Call send
					
					cmp eax, SOCKET_ERROR
					jne SEND_AFTERIF2
						Call WSAGetLastError
						
						push MB_OK
						push OFFSET sAppName
						push OFFSET g_errSend
						push hWnd
						Call MessageBox
						
						jmp DIALOG_END
					SEND_AFTERIF2:
				
;					push MB_OK
;					push OFFSET sAppName
;					push OFFSET sMessage
;					push hWnd
;					Call MessageBox
					

					jmp DIALOG_END
		
		SOCKET_MSG:
			mov eax, lParam
			cmp ax, FD_ACCEPT
			je ACCEPT
			cmp ax, FD_READ
			je READ
			cmp ax, FD_CLOSE
			je SOC_CLOSE
			
			jmp DEFAULT
			
			ACCEPT:
				shr eax, 16
				cmp ax, NULL
				jne ELSEPART1
				
					push NULL
					push NULL
					push ListenSocket
					Call accept
					cmp eax, INVALID_SOCKET
					jne MAINAFTERIF6
						Call WSAGetLastError
						;push eax
						push OFFSET sAppName
						push OFFSET g_errSocketAccept
						push hWnd
						Call MessageBox
						
						push ListenSocket
						Call closesocket
						
						Call WSACleanup
						
						jmp DIALOG_END
				
					MAINAFTERIF6:
					
					mov ClientSocket, eax
			
					push ListenSocket
					Call closesocket
					
					jmp DIALOG_END
				ELSEPART1:
					jmp DIALOG_END
			
			READ:
				shr eax, 16
				cmp ax, NULL
				jne ELSEPART2
					lea eax, tempsize
					push eax
					push FIONREAD
					push ClientSocket
					Call ioctlsocket
					
					cmp eax, SOCKET_ERROR
					jne READ_AFTERIF
						Call WSAGetLastError
						
						push MB_OK
						push offset sAppName
						push offset g_errRecv
						push hWnd
						Call MessageBox
						
						jmp DIALOG_END
					READ_AFTERIF:
					
					push 0
					push tempsize
					push offset sBuffer
					push ClientSocket
					Call recv
					
					cmp eax, SOCKET_ERROR
					jne READ_AFTERIF2
						Call WSAGetLastError
						
						push MB_OK
						push offset sAppName
						push offset g_errRecv
						push hWnd
						Call MessageBox
						
						jmp DIALOG_END
					READ_AFTERIF2:
					
;					push offset sBuffer
;					push offset smsgform2
;					push offset temp
;					Call wsprintf
					invoke wsprintf, addr temp, addr smsgform2, addr sBuffer
					
;					push offset temp
;					push IDC_CHATHISTORY
;					push hWnd
;					Call SetDlgItemText
					invoke SetDlgItemText, hWnd, SHOW_HISTEDIT, addr temp
					
										
					jmp DIALOG_END
					
				ELSEPART2:
				jmp DIALOG_END
			
			SOC_CLOSE:
				
				push MB_OK
				push OFFSET sAppName
				push OFFSET g_msgClose
				push hWnd
				Call MessageBox
				
				push SD_SEND
				push ClientSocket
				Call shutdown
				cmp eax, SOCKET_ERROR
				jne MAINAFTERIF7
					Call WSAGetLastError
					;push eax
					push MB_OK
					push OFFSET sAppName
					push OFFSET g_errShutdown
					push hWnd
					Call MessageBox
					
					push ClientSocket
					Call closesocket
					
					Call WSACleanup
			
				MAINAFTERIF7:
				
				push ClientSocket
				Call closesocket
			
				Call WSACleanup
				jmp DIALOG_END
				
		
		DEFAULT:
			mov eax, FALSE
			ret
			
		DIALOG_END:
			mov eax, TRUE
			
	
		Ret
	DlgProc EndP
	
	SeverConfigDlgProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
		
		mov eax, uMsg
		
		cmp eax, WM_INITDIALOG
		je INITDIALOG
		cmp eax, WM_CLOSE
		je CLOSE
		
		jmp DEFAULT
		
		INITDIALOG:
			jmp END_DIALOG
		
		CLOSE:
			push NULL
			push hWnd
			Call EndDialog
			
			jmp END_DIALOG
			
		DEFAULT:
			mov eax, FALSE
			ret
			
		END_DIALOG:
			mov eax, TRUE
		Ret
SeverConfigDlgProc EndP
end start
