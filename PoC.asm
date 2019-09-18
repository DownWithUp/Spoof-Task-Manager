; The following code worked on Windows 10 x64, Version: 1709
; How it works. Uses TaskManager (taskmgr.exe) Mutex
; Returns message 0xD43
; Any taskmanager starting up, thinks it's already running and exits.
format PE64 GUI 5.0
entry start
include 'win64a.inc'
section '.text' code readable executable
  start:
        sub rsp, 8 ; qword align stack
        invoke CreateMutexW, 0, TRUE, szTaskMgrMutex ; Create taskmgr.exe's mutex
        ;The code to CreateWindowEx, is not mine
        invoke GetModuleHandle,0
        mov [wc.hInstance],rax
        invoke LoadIcon,0,IDI_APPLICATION
        mov [wc.hIcon],rax
        mov [wc.hIconSm],rax
        invoke LoadCursor,0,IDC_ARROW
        mov [wc.hCursor],rax
        invoke RegisterClassEx,wc
        test rax, rax
        jz error
        invoke CreateWindowEx, 0 , szClass, szTitle, WS_VISIBLE + WS_TILEDWINDOW, 128, 128, 128, 128,\
                               NULL, NULL, [wc.hInstance], NULL  ; You could remove WS_VISIBLE
        test rax, rax
        jz error

  msg_loop:
        invoke GetMessage, msg, NULL, 0, 0
        cmp eax,1
        jb end_loop
        jne msg_loop
        invoke TranslateMessage, msg
        invoke DispatchMessage, msg
        jmp msg_loop

  error:
        invoke MessageBox, NULL, szError, NULL, MB_ICONERROR+MB_OK

  end_loop:
        invoke ExitProcess, [msg.wParam]

proc WindowProc uses rbx rsi rdi, hwnd,wmsg,wparam,lparam

; Note that first four parameters are passed in registers,
; while names given in the declaration of procedure refer to the stack
; space reserved for them - you may store them there to be later accessible
; if the contents of registers gets destroyed. This may look like:
;       mov     [hwnd],rcx
;       mov     [wmsg],edx
;       mov     [wparam],r8
;       mov     [lparam],r9

; When we recive msg 0x4D3, from a taskmgr.exe process, just reply with the same code
     cmp edx, 0x4D3
     je .replyMsg
     cmp edx, WM_DESTROY
     je .wmdestroy
  .defwndproc:
        invoke  DefWindowProc,rcx,rdx,r8,r9
        jmp     .finish
  .wmdestroy:
        invoke  PostQuitMessage,0
        xor     eax,eax
  .finish:
        ret
  .replyMsg:
        invoke ReplyMessage, 0x4D3 ; Send reply
        jmp .finish

endp

section '.data' data readable writeable

szTaskMgrMutex du "Local\TM.750ce7b0-e5fd-454f-9fad-2f66513dfa1b", 0 ; Must be UNICODE,
                                                                     ; From what I can tell, this is constant
  szTitle TCHAR 'Task Manager',0 ;MUST BE THIS
  szClass TCHAR 'TaskManagerWindow',0 ;MUST BE THIS
  szError TCHAR 'Startup failed.',0

  wc WNDCLASSEX sizeof.WNDCLASSEX, 0, WindowProc, 0, 0, NULL, NULL, NULL, COLOR_BTNFACE+1, NULL, szClass, NULL

  msg MSG

section '.idata' import data readable writeable

library kernel32,'KERNEL32.DLL',\
        user32,'USER32.DLL'

include 'api\kernel32.inc'
include 'api\user32.inc'
