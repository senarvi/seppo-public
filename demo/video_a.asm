	%title	"Copyright (c) Seppo Enarvi  1996,1997"
	%subttl "Video routines"

	include "declare.mac"


	include "video.inc"
	include "math.inc"
	include "memory.inc"
	include "system.inc"

	include "system.mac"
	include "math.mac"


;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; Code
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; [fold]  [

	_code

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; [fold]  [
; Set video palette

	proc	setpalette
	pushad
	mov	ecx,GR_COLORS-1

@@loop:
	mov	edx,3c8h
	mov	eax,ecx
	out	dx,al

	mov	edx,3c9h
	mov	al,[ecx*2+ecx+palette.r]
	out	dx,al
	mov	al,[ecx*2+ecx+palette.g]
	out	dx,al
	mov	al,[ecx*2+ecx+palette.b]
	out	dx,al

	dec	ecx
	jge	@@loop

	popad
	ret
	endp
; [fold]  ]

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; [fold]  [
; Set palette for phong
;
; In:
;   dword - offset to material

	proc	setphongpal_
	pushad

	BASE = 0
	VALUES = 256
	BITS = 8
	MAX = 63

	mov	esi,eax
	mov	edi,VALUES - 1				; é shl BITS
@@loop:
	macro	setcolor color
	local	@@f0
	mov	eax,[(smaterial esi).diffuse.color]	; Diffuse
	mul	edi					; * é
	mov	ebx,eax

	mov	eax,edi
	chgfrac eax,BITS,FRACBITS
	call	fixpow,eax,[(smaterial esi).shine]	; é^n
	chgfrac eax,FRACBITS,BITS
	mul	[(smaterial esi).specular.color]	; * Specular
	add	eax,ebx					; + (Diffuse * é)
	shr	eax,BITS
	add	eax,[(smaterial esi).ambient.color]	; + Ambient

	cmp	eax,MAX
	jb	@@f0
	mov	eax,MAX
@@f0:
	mov	[BASE + edi*2+edi + palette.color],al
	endm

	setcolor r
	setcolor g
	setcolor b

	dec	edi
	jnz	@@loop

	mov	[palette.r],0			; Background color
	mov	[palette.g],0
	mov	[palette.b],0

	call	setpalette
	popad
	ret
	endp
; [fold]  ]

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; [fold]  [
; Set linear palette

	proc	setlinearpal_
	pushad

	mov	ecx,GR_COLORS-1
@@loop:
	mov	eax,ecx
	mov	[ecx*2+ecx+palette.r],al
	mov	[ecx*2+ecx+palette.g],al
	mov	[ecx*2+ecx+palette.b],al
	dec	ecx
	jge	@@loop
	call	setpalette

	popad
	ret
	endp
; [fold]  ]

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; [fold]  [
; Write ASCIIZ string to screen
;
; In:
;   [esi] - string

	alignstart
	proc	writestr
	pushad

	mov	ah,07h				; Color
@@loop:
	mov	al,[esi]
	or	al,al				; End of string?
	jz	@@done
	inc	esi
	cmp	al,CR				; Carriage return?
	je	@@return

	; Calculate address and write character
	mov	edi,[text_cursor.y]
	cmul	edi,TXT_X
	add	edi,[text_cursor.x]
	mov	[gs:_VGA_text_buffer+edi*2],ax

	cmp	[text_cursor.x],TXT_X-1		; Are we at the end of row?
	jae	@@return
	inc	[text_cursor.x]			; Next column
	jmp	@@loop

@@return:
	mov	[text_cursor.x],0		; Start of row
	cmp	[text_cursor.y],TXT_Y-1		; Are we at the end of screen?
	jae	@@scroll
	inc	[text_cursor.y]			; Next row
	jmp	@@loop

@@scroll:
	mov	edi,(TXT_Y-1)*TXT_X*2-dword	; Last row - dword
@@scrloop:
	mov	eax,[gs:_VGA_text_buffer+edi+TXT_X*2] ; Read from next row
	mov	[gs:_VGA_text_buffer+edi],eax	; Write to current row
	sub	edi,dword			; Previous dword
	jge	@@scrloop
@@clrloop:
	mov	edi,TXT_X*2-dword		; Last dword of row
	; Zero the dword in the last row
	mov	[dword gs:_VGA_text_buffer+(TXT_Y-1)*TXT_X*2+edi],0
	sub	edi,dword			; Previous dword
	jge	@@clrloop
	jmp	@@loop

@@done:
	popad
	ret
	endp 
; [fold]  ]

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; [fold]  [
; Clear text mode screen

	alignstart
	proc	cleartext
	push	ecx

	mov	ecx,TXT_X*TXT_Y*2-dword
@@loop:
	mov	[dword gs:_VGA_text_buffer+ecx],07000700h
	sub	ecx,dword
	jge	@@loop
	mov	[text_cursor.x],0
	mov	[text_cursor.y],0

	pop	ecx
	ret 
	endp
; [fold]  ]

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; [fold]  [
; Clear video memory

	alignstart
	proc	clearvideo
	push	ecx
	mov	ecx,GR_SIZE-dword

	aligncode
@@loop:
	mov	[dword gs:_VGA_graphics_buffer+ecx],00000000h
	sub	ecx,dword
	jge	@@loop

	pop	ecx
	ret 
	endp
; [fold]  ]

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; [fold]  [
; Clear video buffer

	alignstart
	proc	clearbuffer_
	push	ecx ebx
	mov	ebx,[destbufoff]
	mov	ecx,GR_SIZE-12

	aligncode
@@loop:
	mov	[dword ebx+ecx],0			; 8 bytes
	mov	[dword ebx+ecx+4],0			; 9 bytes
	mov	[dword ebx+ecx+8],0			; 9 bytes
	sub	ecx,12					; 3 bytes
	jge	@@loop					; 2 bytes
							; --------
							; 31 bytes
	pop	ebx ecx
	ret 
	endp
; [fold]  ]

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; [fold]  [
; Clear all video buffers

	alignstart
	proc	clearbuffers
	push	ecx
	mov	ecx,GR_BUFFERS*GR_SIZE-dword

	aligncode
@@loop:
	mov	[dword screenbuf+ecx],00000000h
	sub	ecx,dword
	jge	@@loop

	pop	ecx
	ret 
	endp
; [fold]  ]

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; [fold]  [
; Copy video buffer to screen
;
; Registers modified:
;   ecx ebx

	alignstart
	proc	copybuffer_
	push	ecx ebx
	mov	ebx,[destbufoff]
	mov	ecx,GR_SIZE-dword

	aligncode
@@loop:
	mov	eax,[ebx+ecx]
	mov	[_VGA_graphics_buffer+ecx],eax
	sub	ecx,dword
	jge	@@loop

	pop	ebx ecx
	ret 
	endp
; [fold]  ]

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; [fold]  [
; Clear quadrangle area from video buffer
;
; Registers modified:
;   all

	alignstart
	proc	cleararea_
	mov	ecx,[bufferarea.a.y]
	mov	edx,[bufferarea.b.x]
	mov	ebx,[bufferarea.b.y]

	sub	ebx,ecx
	sub	edx,[bufferarea.a.x]

	cmul	ecx,GR_X
	add	ecx,[bufferarea.a.x]

	cdiv	edx,8
	aligncode
@@loop2:
	mov	eax,edx			; deltax / 4
@@loop1:
	mov	[dword screenbuf+ecx+eax*8],0
	mov	[dword screenbuf+ecx+eax*8+4],0
	dec	eax
	jge	@@loop1
	add	ecx,GR_X
	dec	ebx			; deltay
	jge	@@loop2
	ret
	endp
; [fold]  ]

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; [fold]  [
; Copy quadrangle area to screen
;
; Registers modified:
;   all

	alignstart
	proc	copyarea_
	mov	eax,[screenarea.a.x]
	cmp	eax,[bufferarea.a.x]
	jb	@@copyareaf0
	mov	eax,[bufferarea.a.x]
@@copyareaf0:

	mov	ecx,[screenarea.a.y]
	cmp	ecx,[bufferarea.a.y]
	jb	@@copyareaf1
	mov	ecx,[bufferarea.a.y]
@@copyareaf1:

	mov	edx,[screenarea.b.x]
	cmp	edx,[bufferarea.b.x]
	ja	@@copyareaf2
	mov	edx,[bufferarea.b.x]
@@copyareaf2:

	mov	ebx,[screenarea.b.y]
	cmp	ebx,[bufferarea.b.y]
	ja	@@copyareaf3
	mov	ebx,[bufferarea.b.y]
@@copyareaf3:

	mov	ebp,[bufferarea.a.x]
	mov	[screenarea.a.x],ebp
	mov	ebp,[bufferarea.a.y]
	mov	[screenarea.a.y],ebp
	mov	ebp,[bufferarea.b.x]
	mov	[screenarea.b.x],ebp
	mov	ebp,[bufferarea.b.y]
	mov	[screenarea.b.y],ebp


	sub	ebx,ecx
	sub	edx,eax

	cmul	ecx,GR_X
	add	ecx,eax

	cdiv	edx,4
	aligncode
@@loop2:
	mov	eax,edx			; deltax / 4
@@loop1:
	mov	esi,[dword screenbuf+ecx+eax*dword]
	mov	[gs:_VGA_graphics_buffer+ecx+eax*dword],esi
	dec	eax
	jge	@@loop1
	add	ecx,GR_X
	dec	ebx			; deltay
	jge	@@loop2
	ret
	endp
; [fold]  ]

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; [fold]  [
; Copy video buffer to screen with motion blur
;
; Registers modified:
;   all

	alignstart
	proc	motionblur_
	pushad
	mov	esi,[prevbufoff]
	mov	edi,[destbufoff]
	mov	ecx,GR_SIZE-byte

	aligncode
@@loop:
	movzx	eax,[byte esi+ecx]
	cmul	eax,9
	movzx	edx,[byte edi+ecx]
	cmul	edx,8
	add	eax,edx
	cdiv	eax,16
	cmp	eax,0ffh
	jbe	@@f0
	mov	eax,0ffh
@@f0:
	mov	[gs:_VGA_graphics_buffer+ecx],al
	mov	[edi+ecx],al
	dec	ecx
	jge	@@loop

	mov	eax,[destbufoff]
	mov	ecx,[prevbufoff]
	mov	[prevbufoff],eax
	mov	[destbufoff],ecx
	popad
	ret
	endp
; [fold]  ]

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; [fold]  [
; Draw line
;
; In:
;   ecx = X2
;   edx = Y2
;   ebx = highword 0
;   esi = X1
;   edi = Y1
;
; Registers modified:
;   all

	proc	drawbrsline
	sub	ecx,esi		 ; u = x2 - x1
	mov	ebx,1		 ; d1x = sgn u
	jg	@@drawlinef0
	mov	ebx,-1
	neg	ecx		 ; m = abs u
@@drawlinef0:
	lea	esi,[edi*4+edi]
	cmul	esi,64

	sub	edx,edi		 ; v = y2 - y1
	mov	eax,GR_X	 ; d1y = sgn v
	jg	@@drawlinef1
	mov	eax,-GR_X
	neg	edx		 ; n = abs v
@@drawlinef1:
	lea	edi,[eax+ebx]	 ; d1 = x + d1x

	cmp	ecx,edx
	jge	@@drawlinef2
	xchg	ecx,edx		 ; ecx >= edx
	mov	ebx,eax		 ; d2 = y + d1y
@@drawlinef2:


	mov	eax,ecx
	cdiv	eax,2
	mov	ebp,ecx
	sub	edx,ecx
	sub	ebx,edi

@@loop:
	mov	[screenbuf+esi],0ffh
	dec	ecx
	jl	@@done

	add	esi,edi
	add	eax,edx
	jge	@@loop
	add	eax,ebp
	add	esi,ebx
	jmp	@@loop


@@done:
	ret
	endp
; [fold]  ]

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
	proc	drawline x1:dword,y1:dword,x2:dword,y2:dword,color:dword
	pushad

	mov	ecx,[x1]
	mov	edx,[y1]
	mov	esi,[x2]
	mov	edi,[y2]

	cmul	ecx,GR_X
	cmul	ebx,GR_X
	mov	eax,[color]
	mov	[byte screenbuf+ecx+edx],al
	mov	[byte screenbuf+esi+edi],al

	popad
	ret
	endp

	ends
; [fold]  ]

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; Data
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; [fold]  [

		_data

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
		label	screenbufoff dword

COUNT = offset screenbuf
rept GR_BUFFERS
  dd COUNT
  COUNT = COUNT+GR_SIZE
endm

prevbufoff	dd	offset screenbuf+GR_SIZE
destbufoff	dd	offset screenbuf
;destbufnum	 dd	 0

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
		label	text_cursor spixel
		spixel	?

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
		label	bufferarea squad
		squad	?
		label	screenarea squad
		squad	?

	ends 
; [fold]  ]

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; Uninitialized data
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; [fold]  [

		_udata

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
screenbuf	db	GR_BUFFERS*GR_SIZE dup (?)

		label	palette svideomem
		svideomem GR_COLORS dup (?)

		ends
; [fold]  ]

	end

; [fold]  16
