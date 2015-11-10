;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Name:	SimpleClientChat
;Descritption:	This is a simple chat application. It has a GUI and it uses sockets
;Date:	24-2-2012
;Last Modified:	24-2-2012
;Author:	Harsha Kadekar
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.386
.model flat, stdcall
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
InfoDlgProc proto :DWORD, :DWORD, :DWORD, :DWORD

.data
g_errInitialize db "Client: Error during initialisation", 0dh, 0ah, 0
g_errSocketCreate db "Client: Socket creation failed", 0dh, 0ah, 0
g_errSocketConnect db "Client: Unable to connect to server", 0dh, 0ah, 0
g_errSend db "Client: Sending data failed", 0dh, 0ah, 0
g_msgSent db "Client: Sent message successfully", 0dh, 0ah, 0
sMessage db "Hi How are you", 0ah, 0dh, 0
g_errRecv db "Client: Recieve from serve failed", 0dh, 0ah, 0
gServerAddr db "localhost",0
g_msgRecv db "%s",0dh, 0ah, 0
g_msgClose db "Connection is closing", 0dh, 0ah, 0
g_errShutdown db "Client: Error while closing socket", 0dh, 0ah, 0
g_errAsync db "Client: Error while making asynchronous initialisation", 0dh, 0ah, 0
g_IPaddr db "127.0.0.1",0
smsgform db "%d", 0
smsgform2 db "SERVER: %s",0dh,0ah,0
g_errRetrive db "Failed to retrieve the text in chat window",0dh, 0ah, 0


sDialogName db "IDD_MAINDLG", 0
sInfoDialogName db "IDD_SERVERINFO", 0
sAppName db "Dialogue", 0

wsadata WSADATA <>
SockAddr sockaddr_in <>

.data?

hInstance HINSTANCE ?
CommandLine LPSTR ?
sBuffer db 512 dup(?)
nError DWORD ?
ClientSocket SOCKET ?


.const

IDM_MNU equ 1000
IDM_ equ 1001
IDM_SERCONFIG equ 1002
IDM_EXIT equ 1003
IDM_ABOUT equ 1004
IDC_STATIC1009 equ 1009
IDC_STATIC1011 equ 1011
IDC_STATIC1013 equ 1013
IDD_MAINDLG equ 1001
IDC_CHATHISTORY equ 1002
IDC_EDITCHAT equ 1003
IDC_SENDBUTTON equ 1004
IDC_CONNECTBUTTON equ 1005
IDC_DISCONNECTBUTTON equ 1007
IDD_SERVERINFO equ 1008
IDC_IPADDRESS equ 1010
IDC_SEVNAMEEDIT equ 1012
IDC_PORTNOEDIT equ 1014
IDC_OKBUTTON equ 1015
IDC_CANCELBUTTON equ 1016

CONNECTPORT equ 27500
MAX_SIZE equ 512
REQ_WINSOCK_VERSION equ 2
WM_SOCKET equ WM_USER+100

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
		cmp eax, WM_COMMAND
		je COMMAND
		cmp eax, WM_CLOSE
		je CLOSE
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
				cmp ax, IDM_SERCONFIG
				je M_SERVERCONFIG
				
				
				jmp DEFAULT
				
				M_EXIT:
					Call WSACleanup
					push NULL
					push hWnd
					Call EndDialog
					
					jmp DIALOG_END
				
				M_SERVERCONFIG:
					push NULL
					push offset InfoDlgProc
					push NULL
					push offset sInfoDialogName
					push hInstance
					Call DialogBoxParam
					
					jmp DIALOG_END
					
								
			ELSEPART:
				cmp ax,IDC_CONNECTBUTTON
				je SOC_CONNECT
				cmp ax, IDC_SENDBUTTON
				je SEND 
				cmp ax, IDC_DISCONNECTBUTTON
				je SOC_DISCONNECT
				
				jmp DEFAULT
				
				SOC_CONNECT:
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
					
					mov ClientSocket, eax
					
					push FD_CLOSE + FD_READ + FD_CONNECT
					push WM_SOCKET
					push hWnd
					push ClientSocket
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
					
					mov SockAddr.sin_family, AF_INET
					push CONNECTPORT
					Call htons
					mov SockAddr.sin_port, ax
					
					push OFFSET g_IPaddr
					Call inet_addr
					mov SockAddr.sin_addr, eax
					
					push sizeof SockAddr
					lea eax, SockAddr
					push eax
					push ClientSocket
					Call connect
					cmp eax, SOCKET_ERROR
					jne MAINAFTER4
						Call WSAGetLastError
						
;						push eax
;						push offset smsgform
;						push addr temp
;						Call wsprintf
						cmp eax, WSAEWOULDBLOCK
						je MAINAFTER4
						
						;invoke wsprintf,addr temp, offset smsgform, eax
						
;						push MB_OK
;						push addr temp
;						;push OFFSET sAppName
;						;push eax
;						push OFFSET g_errSocketConnect
;						push hWnd
;						Call MessageBox
						
						invoke MessageBox, hWnd,addr temp, offset g_errSocketConnect, MB_OK 
						Call WSACleanup
						jmp DIALOG_END
					MAINAFTER4:
					
;					push MB_OK
;					push OFFSET sAppName
;					push OFFSET sMessage
;					push hWnd
;					Call MessageBox

					
					
					jmp DIALOG_END
					
				SEND:
					push 512
					push offset sBuffer
					push IDC_EDITCHAT
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
					
				SOC_DISCONNECT:
					push ClientSocket
					Call closesocket
					
					Call WSACleanup
					
					jmp DIALOG_END
					
		SOCKET_MSG:
			mov eax, lParam
			cmp ax, FD_CONNECT
			je SOCFD_CONNECT
			cmp ax, FD_READ
			je SOCFD_READ
			cmp ax, FD_CLOSE
			je SOCFD_CLOSE
			jmp DIALOG_END
			
			SOCFD_CONNECT:
				shr eax, 16
				cmp ax, NULL
				jne ELSEPART1
					jmp DIALOG_END
				ELSEPART1:
				jmp DIALOG_END
			
			SOCFD_READ:
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
					invoke SetDlgItemText, hWnd, IDC_CHATHISTORY, addr temp
					
										
					jmp DIALOG_END
					
				ELSEPART2:
				jmp DIALOG_END
				
			SOCFD_CLOSE:
				shr eax, 16
				cmp ax, NULL
				jne ELSEPART3
					jmp DIALOG_END
				ELSEPART3:
				jmp DIALOG_END

		DEFAULT:
			mov eax, FALSE
			ret
			
		DIALOG_END:
			
			mov eax, TRUE
			
	
		Ret
	DlgProc EndP
	
	InfoDlgProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
		mov eax, uMsg
		
		cmp eax, WM_INITDIALOG
		je INITDIALOG
		cmp eax, WM_COMMAND
		je COMMAND
		cmp eax, WM_CLOSE
		je CLOSE
		
		jmp DEFAULT
		
		INITDIALOG:
			jmp END_DIALOG
		
		COMMAND:
			mov eax, wParam
			cmp lParam, 0
			jne ELSEPART
				jmp DEFAULT
				
			ELSEPART:
			
			cmp ax,IDC_OKBUTTON
			je OKBUTTON
			cmp ax, IDC_CANCELBUTTON
			je CANCELBUTTON
				
			jmp DEFAULT
				
			OKBUTTON:
				push NULL
				push hWnd
				Call EndDialog
					
				jmp END_DIALOG
				
			CANCELBUTTON:
				push NULL
				push hWnd
				Call EndDialog
					
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
	InfoDlgProc EndP
	
end start	