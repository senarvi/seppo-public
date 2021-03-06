        %title  "Copyright (c) Seppo Enarvi  1996,1997"
        %subttl "DOS Protected Mode Interface"

        include "declare.mac"


        include "dpmi.inc"


;北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北�
; Code
;北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北�
; [fold]  (

        _code

;哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪�
; [fold]  [
; Set interrupt vector

        proc    setintvec uses eax ecx edx ebx, intnum:dword,inthandler:dword
        mov     eax,DPMI_SETINTVEC
        mov     ebx,[intnum]
        mov     cx,cs
        mov     edx,[inthandler]
        int     DPMI_INT
        ret
        endp
; [fold]  ]

;哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪�
; [fold]  (
; Get current PIC mappings
;
; This procedure should be called before any of the IRQ functions

        proc    getpicmappings uses eax ecx edx ebx
        mov     eax,DPMI_GETVERSION
        int     DPMI_INT
        xor     eax,eax
        mov     al,dh
        mov     [master_pic_base],eax
        mov     al,dl
        mov     [slave_pic_base],eax
        ret
        endp
; [fold]  )

        ends
; [fold]  )

;北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北�
; Uninitialized data
;北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北�
; [fold]  [

                _udata

;哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪
                label   rmregs dpmi_regs
                dpmi_regs ?

;哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪
master_pic_base dd      ?
slave_pic_base  dd      ?

                ends
; [fold]  ]

        end
; [fold]  4
