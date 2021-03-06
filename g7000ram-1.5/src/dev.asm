; Downloadprogram for the G7000 RAM cart by Soeren Gust
; Version 1.5

; $Id: dev.a48,v 1.14 2003/07/19 12:55:12 sgust Exp $

; Copyright (C) 1997-2002 by Soeren Gust, sgust@ithh.informationstheater.de

; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program; if not, write to the Free Software
; Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

; You can always get the latest version at http://soeren.informationstheater.de

; This program receives 12KBytes at 9600 bps or 19200 bps and puts it into
; the usable RAM Space of the G7000RAM (0400h-0fffh in 4 banks).
; When using 19200 you have to send with 2 stop bits, the G7000 is too slow
; to handle 19200 with only 1 stop bit.

; This is only tested on PAL machines, the NTSC mode is not tested, if you
; run this on NTSC, please give me some feedback.
;
; History:
; Version 1.5
;  added NTSC mode
;
; Version 1.4
;  fixed bug that trashed downloaded program at 0f00h-0fffh.
;  display version number of firmware in top right corner
;  flash background color when getting startbit
;
; Version 1.3
;  fixed stupid display bug at 19200: 2 stop bits
;  changed serial parameter display to DOS MODE command order
;
; Version 1.2
;  fixed display bug at power on
;  wait with download until keyclick sound has stopped
;
; Version 1.1
;  added messages
;  implemented 19200,N,8,2
;
; Version 1.0
;   first release
	
	cpu	8048

	org	400h

	include	"g7000.h"

	jmp	selectgame
	jmp	irq
	jmp	timer
	jmp	vsyncirq
	jmp	start
	jmp	soundirq

timer	retr

start
	jz	todown96p	; 0 = 9600
	dec	a
	jz	todown192p	; 1 = 19200
	dec	a
	jz	todown96n	; 2 = 9600 NTSC
	dec	a
	jz	todown192n	; 3 = 19200 NTSC
	jmp	selectgame	; rest restart

todown96p
	jmp	down96p

todown192p
	jmp	down192p

todown96n
	jmp	down96n

todown192n
	jmp	down192n

down96p	section down96pal
	; wait for end of keyclick
	mov	r0,#03fh
	mov	a,@r0
	jb6	down96p

	call	drawtext

	; display strings: 9600,N,8,1P
	mov	r0,#vdc_quad2
	mov	r1,#text96_1 & 0ffh
	mov	r3,#008h
	mov	r4,#040h
	call	printstr

	mov	r0,#vdc_quad3
	mov	r1,#text96_2 & 0ffh
	mov	r3,#010h
	mov	r4,#040h
	call	printstr

	mov	r0,#vdc_char3
	mov	r1,#text96_3p & 0ffh
	mov	r3,#048h
	mov	r4,#040h
	call	printstr

	call	gfxon

	call	extramenable	; we write to RAM

	dis	i		; interrupts and time-critical
	dis	tcnti		; code don't work together

	mov	r3,#000h	; bank
loop96
	in	a,P1		; [2] get port 1
	anl	a,#0fch		; [2] mask out bankswitch
	orl	a,r3		; [1] set bank
	outl	P1,a		; [2] do it

	mov	r2,#004h	; [2] begin with page 4 (0400h)

loopbank96
	mov	r0,#0		; [2] start with address 0
looppage96
	call	receive96p	; [2] get one byte
	; 9 cycles have passed since middle of last bit
	; wait until bit has ended until next start bit
	nop			; [1] 
	nop			; [1] 
	nop			; [1]
	nop			; [1]
	nop			; [1]
	movx	@r0,a		; [2] write it
	inc	r0		; [1] next byte
	mov	a,r0		; [1] test for pageend
	jnz	looppage96	; [2] get the next byte

	inc	r2		; [1] next page
	mov	a,r2		; [1] get pagenum
	xrl	a,#010h		; [2] last page ?
	jnz	loopbank96	; [2] not yet

	inc	r3		; [1] next bank
	mov	a,r3		; [1] get bank
	xrl	a,#004h		; [2] last bank ?
	jnz	loop96		; [2] not yet
	
	jmp	complete

	endsection down96pal

	align	128

down96n	section down96ntsc
	; wait for end of keyclick
	mov	r0,#03fh
	mov	a,@r0
	jb6	down96n

	call	drawtext

	; display strings: 9600,N,8,1N
	mov	r0,#vdc_quad2
	mov	r1,#text96_1 & 0ffh
	mov	r3,#008h
	mov	r4,#040h
	call	printstr

	mov	r0,#vdc_quad3
	mov	r1,#text96_2 & 0ffh
	mov	r3,#010h
	mov	r4,#040h
	call	printstr

	mov	r0,#vdc_char3
	mov	r1,#text96_3n & 0ffh
	mov	r3,#048h
	mov	r4,#040h
	call	printstr

	call	gfxon

	call	extramenable	; we write to RAM

	dis	i		; interrupts and time-critical
	dis	tcnti		; code don't work together

	mov	r3,#000h	; bank
loop96
	in	a,P1		; [2] get port 1
	anl	a,#0fch		; [2] mask out bankswitch
	orl	a,r3		; [1] set bank
	outl	P1,a		; [2] do it

	mov	r2,#004h	; [2] begin with page 4 (0400h)

loopbank96
	mov	r0,#0		; [2] start with address 0
looppage96
	call	receive96n	; [2] get one byte
	; 8 cycles have passed since middle of last bit
	; wait until bit has ended until next start bit
	nop			; [1]
	nop			; [1]
	nop			; [1]
	movx	@r0,a		; [2] write it
	inc	r0		; [1] next byte
	mov	a,r0		; [1] test for pageend
	jnz	looppage96	; [2] get the next byte

	inc	r2		; [1] next page
	mov	a,r2		; [1] get pagenum
	xrl	a,#010h		; [2] last page ?
	jnz	loopbank96	; [2] not yet

	inc	r3		; [1] next bank
	mov	a,r3		; [1] get bank
	xrl	a,#004h		; [2] last bank ?
	jnz	loop96		; [2] not yet
	
	jmp	complete

	endsection down96ntsc

	align	128

down192p section down192pal
	; wait for end of keyclick
	mov	r0,#03fh
	mov	a,@r0
	jb6	down192p

	call	drawtext

	; display strings: 19200,N,8,2P
	mov	r0,#vdc_quad2
	mov	r1,#text192_1 & 0ffh
	mov	r3,#008h
	mov	r4,#040h
	call	printstr

	mov	r0,#vdc_quad3
	mov	r1,#text192_2 & 0ffh
	mov	r3,#010h
	mov	r4,#040h
	call	printstr

	mov	r0,#vdc_char3
	mov	r1,#text192_3p & 0ffh
	mov	r3,#048h
	mov	r4,#040h
	call	printstr

	call	gfxon

	call	extramenable	; we write to RAM

	dis	i		; interrupts and time-critical
	dis	tcnti		; code don't work together

	mov	r4,#0		; background color
	mov	r3,#000h	; bank

loop192
	in	a,P1		; [2] get port 1
	anl	a,#0fch		; [2] mask out bankswitch
	orl	a,r3		; [1] set bank
	outl	P1,a		; [2] do it

	mov	r2,#004h	; [2] begin with page 4 (0400h)

loopbank192
	mov	r0,#0		; [2] start with address 0
looppage192
	call	receive192p	; [2] get one byte
	movx	@r0,a		; [2] write it
	inc	r0		; [1] next byte
	mov	a,r0		; [1] test for pageend
	jnz	looppage192	; [2] get the next byte

	inc	r2		; [1] next page
	mov	a,r2		; [1] get pagenum
	xrl	a,#010h		; [2] last page ?
	jnz	loopbank192	; [2] not yet

	inc	r3		; [1] next bank
	mov	a,r3		; [1] get bank
	xrl	a,#004h		; [2] last bank ?
	jnz	loop192		; [2] not yet

	jmp	complete

	endsection down192pal

	align	128

down192n section down192ntsc
	; wait for end of keyclick
	mov	r0,#03fh
	mov	a,@r0
	jb6	down192n

	call	drawtext

	; display strings: 19200,N,8,2N
	mov	r0,#vdc_quad2
	mov	r1,#text192_1 & 0ffh
	mov	r3,#008h
	mov	r4,#040h
	call	printstr

	mov	r0,#vdc_quad3
	mov	r1,#text192_2 & 0ffh
	mov	r3,#010h
	mov	r4,#040h
	call	printstr

	mov	r0,#vdc_char3
	mov	r1,#text192_3n & 0ffh
	mov	r3,#048h
	mov	r4,#040h
	call	printstr

	call	gfxon

	call	extramenable	; we write to RAM

	dis	i		; interrupts and time-critical
	dis	tcnti		; code don't work together

	mov	r4,#0		; background color
	mov	r3,#000h	; bank

loop192
	in	a,P1		; [2] get port 1
	anl	a,#0fch		; [2] mask out bankswitch
	orl	a,r3		; [1] set bank
	outl	P1,a		; [2] do it

	mov	r2,#004h	; [2] begin with page 4 (0400h)

loopbank192
	mov	r0,#0		; [2] start with address 0
looppage192
	call	receive192n	; [2] get one byte
	movx	@r0,a		; [2] write it
	inc	r0		; [1] next byte
	mov	a,r0		; [1] test for pageend
	jnz	looppage192	; [2] get the next byte

	inc	r2		; [1] next page
	mov	a,r2		; [1] get pagenum
	xrl	a,#010h		; [2] last page ?
	jnz	loopbank192	; [2] not yet

	inc	r3		; [1] next bank
	mov	a,r3		; [1] get bank
	xrl	a,#004h		; [2] last bank ?
	jnz	loop192		; [2] not yet

	endsection down192ntsc

complete
	clr	a
	outl	P2,a		; let all movx trash page 0 of ram
	call	vdcenable	; we need the vdc, ints are also enabled!!

	; set colors
	mov	r0,#vdc_color
	mov	a,#col_bck_black | col_grd_white
	movx	@r0,a

	mov	a,#04ah		; the startup-sound
	call	playsound	; play it

	call	gfxoff		; we change gfx
	call	clearchar	; clear chars
	; clear quads
	mov	r0,#vdc_quad0
	mov	r1,#64		; 4 quads * 16 bytes = 64
	mov	a,#0f8h
loopqc
	movx	@r0,a
	inc	r0
	djnz	r1,loopqc
	
	; display end message
	mov	r0,#vdc_char0
	mov	r1,#finished & 0ffh
	mov	r3,#030h
	mov	r4,#020h
	call	printstr

	call	gfxon

stop	jmp	stop		; thats all

	align	256

; receive 1 byte from T0 (async, 19200 bps, 2 stop bits!)
; 19200 in PAL: (2.5us per cycle)
; 1 bit = 52.1 usec = 21 clocks
; 1.5 bits = 78.2 usec = 31 clocks
; alters a, r6, r7

receive192p section receive192pal
	jt0	receive192p
; startbit found
; wait for 1.5 bits to hit middle of other bits
	clr	a		; [1] prevent RAM..
	outl	P2,a		; [2] ..trashing
	mov	a,r4		; [1] get background color
	add	a,#8		; [2] next color
	anl	a,#038h		; [2] mask out relevant bits
	mov	r4,a		; [1] store for next time
	mov	r1,#vdc_color	; [2] color register
	orl	P1,#0bch	; [2] switch..
	anl	P1,#0b7h	; [2] ..to vdc
	movx	@r1,a		; [2] set new background color
	orl	P1,#0bch	; [2] switch..
	anl	P1,#0afh	; [2] ..to extram
	mov	a,r2		; [1] get pageno
	outl	P2,a		; [2] do it
	clr	a		; [1] received byte stored here
	nop			; [1] waste cylce
	nop			; [1] waste cycle
	mov	r6,#08h		; [2] number of bit
	jmp	rd192		; [2] jump into loop
getbit192
	mov	r7,#06h		; [2]
wait192_2
	djnz	r7,wait192_2	; [6*2] wait
	rr	a		; [1] rotate next bit into position
rd192	jt0	receive192_1	; [2] decide if 0/1 bit received
	nop			; [1] adjustment nop
	nop			; [1] adjustment nop
receive192_0
	djnz	r6,getbit192	; [2] bit loop
	ret			; [2] finished
receive192_1
	add	a,#080h		; [2] new bit was set
	djnz	r6,getbit192	; [2] bit loop
	ret			; [2] finished

	endsection receive192pal

; receive 1 byte from T0 (async, 19200 bps, 2 stop bits!)
; 19200 in NTSC: (2.8us per cycle)
; 1 bit = 52.1 usec = 19 clocks
; 1.5 bits = 78.2 usec = 28 clocks, doing 29 clocks
; alters a, r6, r7

receive192n section receive192ntsc
	jt0	receive192n
; startbit found
; wait for 1.5 bits to hit middle of other bits
	clr	a		; [1] prevent RAM..
	outl	P2,a		; [2] ..trashing
	mov	a,r4		; [1] get background color
	add	a,#8		; [2] next color
	anl	a,#038h		; [2] mask out relevant bits
	mov	r4,a		; [1] store for next time
	mov	r1,#vdc_color	; [2] color register
	orl	P1,#0bch	; [2] switch..
	anl	P1,#0b7h	; [2] ..to vdc
	movx	@r1,a		; [2] set new background color
	orl	P1,#0bch	; [2] switch..
	anl	P1,#0afh	; [2] ..to extram
	mov	a,r2		; [1] get pageno
	outl	P2,a		; [2] do it
	clr	a		; [1] received byte stored here
	mov	r6,#08h		; [2] number of bit
	jmp	rd192		; [2] jump into loop
getbit192
	mov	r7,#05h		; [2]
wait192_2
	djnz	r7,wait192_2	; [5*2] wait
	rr	a		; [1] rotate next bit into position
rd192	jt0	receive192_1	; [2] decide if 0/1 bit received
	nop			; [1] adjustment nop
	nop			; [1] adjustment nop
receive192_0
	djnz	r6,getbit192	; [2] bit loop
	ret			; [2] finished
receive192_1
	add	a,#080h		; [2] new bit was set
	djnz	r6,getbit192	; [2] bit loop
	ret			; [2] finished

	endsection receive192ntsc

; receive 1 byte from T0 (async, 9600 bps)
; 9600 in PAL: (2.5us per cycle)
; 1 bit = 104.2 usec = 42 clocks
; 1.5 bits = 156.3 usec = 63 clocks
; alters a, r6, r7

receive96p section receive96pal
	jt0	receive96p
; startbit found
; wait for 1.5 bits to hit middle of other bits
	clr	a		; [1] prevent RAM..
	outl	P2,a		; [2] ..trashing
	mov	a,r4		; [1] get background color
	add	a,#8		; [2] next color
	anl	a,#038h		; [2] mask out relevant bits
	mov	r4,a		; [1] store for next time
	mov	r1,#vdc_color	; [2] color register
	orl	P1,#0bch	; [2] switch..
	anl	P1,#0b7h	; [2] ..to vdc
	movx	@r1,a		; [2] set new background color
	orl	P1,#0bch	; [2] switch..
	anl	P1,#0afh	; [2] ..to extram
	mov	a,r2		; [1] get pageno
	outl	P2,a		; [2] do it
	clr	a		; [1] received byte stored here
	nop			; [1] waste cycle
	mov	r6,#08h		; [2] 8 bits in one byte
getbit96
	mov	r7,#10h		; [2]
wait96_2	
	djnz	r7,wait96_2	; [16*2] wait
	rr	a		; [1] rotate next bit into position
	jt0	receive96_1	; [2] 0 or 1 bit received?
	nop			; [1] adjustment nop
	nop			; [1] adjustment nop
receive96_0
	nop			; [1] adjustment nop
	djnz	r6,getbit96	; [2] bit loop
	ret			; [2] byte finished
receive96_1
	nop			; [1] adjustment nop
	add	a,#080h		; [2] bit was 1
	djnz	r6,getbit96	; [2] bit loop
	ret			; [2] byte finished

	endsection receive96pal

; receive 1 byte from T0 (async, 9600 bps)
; 9600 in NTSC: (2.8us per cycle)
; 1 bit = 104.2 usec = 37 clocks
; 1.5 bits = 156.3 usec = 56 clocks
; alters a, r6, r7

receive96n section receive96ntsc
	jt0	receive96n
; startbit found
; wait for 1.5 bits to hit middle of other bits
	clr	a		; [1] prevent RAM..
	outl	P2,a		; [2] ..trashing
	mov	a,r4		; [1] get background color
	add	a,#8		; [2] next color
	anl	a,#038h		; [2] mask out relevant bits
	mov	r4,a		; [1] store for next time
	mov	r1,#vdc_color	; [2] color register
	orl	P1,#0bch	; [2] switch..
	anl	P1,#0b7h	; [2] ..to vdc
	movx	@r1,a		; [2] set new background color
	orl	P1,#0bch	; [2] switch..
	anl	P1,#0afh	; [2] ..to extram
	mov	a,r2		; [1] get pageno
	outl	P2,a		; [2] do it
	clr	a		; [1] received byte stored here
	nop			; [1] waste cycle
	mov	r6,#08h		; [2] 8 bits in one byte
	mov	r7,#0ch		; [2]
wait96_1
	djnz	r7,wait96_1	; [12*2]
	jmp	rd96		; [2] jump into loop
getbit96
	mov	r7,#0eh		; [2]
wait96_2	
	djnz	r7,wait96_2	; [14*2] wait
	rr	a		; [1] rotate next bit into position
rd96	jt0	receive96_1	; [2] 0 or 1 bit received?
	nop			; [1] adjustment nop
	nop			; [1] adjustment nop
receive96_0
	djnz	r6,getbit96	; [2] bit loop
	ret			; [2] byte finished
receive96_1
	add	a,#080h		; [2] bit was 1
	djnz	r6,getbit96	; [2] bit loop
	ret			; [2] byte finished

	endsection receive96ntsc

	align	256		; start new page

drawtext section drawtext
	call	vdcenable
	call	gfxoff

	; set colors
	mov	r0,#vdc_color
	mov	a,#col_bck_black | col_grd_white
	movx	@r0,a

	; display strings: downloading
	mov	r0,#vdc_quad0
	mov	r1,#down1 & 0ffh
	mov	r3,#008h
	mov	r4,#020h
	call	printstr

	mov	r0,#vdc_quad1
	mov	r1,#down2 & 0ffh
	mov	r3,#010h
	mov	r4,#020h
	call	printstr

	mov	r0,#vdc_char0
	mov	r1,#down3 & 0ffh
	mov	r3,#048h
	mov	r4,#020h
	call	printstr

	; show version number
	call	setshapes
	mov	r0,#vdc_spr0_ctrl
	mov	a,#01eh
	movx	@r0,a
	inc	r0
	mov	a,#088h
	movx	@r0,a
	inc	r0
	mov	a,#col_spr_white
	movx	@r0,a
	inc	r0
	inc	r0
	mov	a,#01eh
	movx	@r0,a
	inc	r0
	mov	a,#090h
	movx	@r0,a
	inc	r0
	mov	a,#col_spr_white
	movx	@r0,a

	ret

	endsection drawtext

; Input: R0: first char R1: pointer to string, R3/R4 position
printstr section printstr
	mov	a,r1		; string starts with length byte
	movp	a,@a		; get length
	mov	r2,a		; into R2
	inc	r1		; advance pointer
loopps	mov	a,r1		; get pointer
	movp	a,@a		; get char
	mov	r5,a		; into the right register
	inc	r1		; advance pointer
	mov	r6,#col_chr_white
	call	printchar	; print it
	djnz	r2,loopps	; do it again

	endsection printstr

	ret

down1	; DOWNLOADING first quad: D W L A
	db	4,26,17,14,32
down2	; DOWNLOADING second quad: O N O D
	db	4,23,45,23,26
down3	; DOWNLOADING chars: ING
	db	3,22,45,28

text96_1
	; 9600,N,8,1 first quad: 9 0 , ,
	db	4,9,0,39,39
text96_2
	; 9600,N,8,1 second quad: 6 0 8 N
	db	4,6,0,45,8
text96_3p
	; 9600,N,8,1 chars: ,1 PAL
	db	6,39,1,12,15,32,14
text96_3n
	; 9600,N,8,1 chars: ,1 NTSC
	db	7,39,1,12,45,20,25,35

text192_1
	; 19200,N,8,2 first quad: 1 2 0 N
	db	4,1,2,0,45
text192_2
	; 19200,N,8,2 second quad: 9 0 , ,
	db	4,9,0,39,39
text192_3p
	; 19200,N,8,2 chars: 8,2 PAL
	db	7,8,39,2,12,15,32,14
text192_3n
	; 19200,N,8,2 chars: 8,2 NTSC
	db	8,8,39,2,12,45,20,25,35

finished
	; FINISHED
	db	8,27,22,45,22,25,29,18,26

; set the shape of sprites 0 and 1 to the version number
setshapes section setshapes
	mov	r0,#vdc_spr0_shape
	mov	r1,#(vnumber & 0ffh)
	mov	r2,#16
.loop	mov	a,r1
	movp	a,@a
	movx	@r0,a
	inc	r0
	inc	r1
	djnz	r2,.loop
	ret

	endsection setshapes

vnumber
	; V1.5
	db	00000000b
	db	00000000b
	db	00010001b
	db	10010001b
	db	00010001b
	db	00010001b
	db	00001010b
	db	10000100b

	db	00000000b
	db	00000000b
	db	11100001b
	db	00100001b
	db	11100001b
	db	10000001b
	db	10100001b
	db	01001011b

	db	0,"$Id: dev.a48,v 1.14 2003/07/19 12:55:12 sgust Exp $",10,13

	end
