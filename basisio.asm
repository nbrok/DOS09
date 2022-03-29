
aciainit	equ	%00010101	;8N1 @ 115200 Baud
acia_status	equ	$cf00		;ACIA Status/Command register
acia_data	equ	$cf01		;ACIA Data register
cr		equ	$0d		;Cariage return
lf		equ	$0a		;Line feed
mbyte		equ	$10
eof		equ	$1a

;****************************************************
;* Basic I/O routines
;****************************************************

in	pshs	b
inlp	ldb	acia_status
	bitb	#$1
	beq	inlp
	lda	acia_data
	puls	b
	rts

crlf	lda	#cr
	bsr	ot
	lda	#lf
ot	pshs	b
otlp	ldb	acia_status
	bitb	#$2
	beq	otlp
	sta	acia_data
	puls	b
	rts

acia_init

	pshs	b
	ldb	#%00000011
	stb	acia_status	;RESET acia
	ldb	#aciainit	;Set baudrate
	stb	acia_status
	puls	b
	rts

ott	lda	0,x+		;Display character pointed by X and inc X
	beq	exott		;Is character=0 The stop
	bsr	ot		;Print the character
	bra	ott		;Get next character
exott	rts

xot	pshs	a,b
	exg	d,x
	pshs	b
	bsr	byteot
	puls	a
	bsr	byteot
	puls	a,b
	rts

byteot	pshs	a,b		;Save A and B
	sta	mbyte		;Save hex-byte.
	ldb	#2		;Print two nibbles
	lsra
	lsra
	lsra
	lsra
bytlp	anda	#$0f		;Mask lower byte
	pshs	a		;Save A
	tfr	cc,a
	anda	#%11011100
	tfr	a,cc
        puls	a		;Restore A
        daa			;Decimal adjust
        adda	#$f0
        adca	#$40
        jsr	ot		;Print the HEX digit.
        lda	mbyte		;Restore hex-byte
        decb
        bne	bytlp		;Get next nibble
	puls	a,b		;Restore A and B
	rts

decimal_fstring	rmb	12
decimal_string	rmb	12
decimal_buffer	rmb	4

dec32_ot

	jsr	bin_omzetting
	pshs	x
	ldx	#decimal_fstring
	jsr	ott
	puls	x
	rts

bin_omzetting

	pshs	y,x
	ldx	#decimal_fstring
	ldb	#12
bin_lp	lda	#space
	sta	0,x+
	decb
	bne	bin_lp
	ldy	#decimal_string
	ldx	#decimal_buffer
	jsr     bin_rec
	clr	0,y
	ldx	#decimal_fstring

bin_omzetting_dloop1

	lda	0,y
	sta	11,x
	leay	-1,y
	leax	-1,x
	cmpy	#decimal_string-1
	bne	bin_omzetting_dloop1
	puls	y,x
	rts

bin_rec

	jsr	deel_10
	ora	#'0'
	pshs	a
	clra
	ora	0,x
	ora	1,x
	ora	2,x
	ora	3,x
	tsta
	beq	binr1
	jsr	bin_rec
binr1	puls	a
	sta	0,y
	leay	1,y
	rts

deel_10

        clr     divtenr
        lda     #32
        sta     bin_ctr
        andcc   #$fe

deel_lus

        ldd     2,x             ;Low word16
        rolb
        rola
        std     2,x
        ldd     0,x             ;High word16
        rolb
        rola
        std     0,x
        lda     divtenr
        rola
        sta     divtenr
        suba    #10
        bcs     deel_eind
        sta     divtenr
        orcc    #$1
        bra     deel_eind1

deel_eind

        andcc   #$fe

deel_eind1

        dec     bin_ctr
        bne     deel_lus
        ldd     2,x
        rolb
        rola
        std     2,x
        ldd     0,x
        rolb
        rola
        std     0,x
        lda     divtenr
        rts

chksum	adda	crc			;Bereken checksum.
	sta	crc
	rts

transfer_in

	jsr	crlf
trl1	jsr	in
	cmpa	#':'
	bne	trl1
	jsr	ot
	jsr	bytein
	beq	trend
	sta	teller
	clr	crc
	jsr	chksum
	jsr	bytein
	sta	buffer
	jsr	chksum
	jsr	bytein
	sta	buffer+1
	jsr	chksum
	ldx	buffer
	jsr	bytein
	jsr	chksum
trl0	jsr	bytein
	sta	0,x+
	jsr	chksum
	dec	teller
	bne	trl0
	jsr	bytein
	nega
	cmpa	crc
	beq	transfer_in
chkerr	ldx	#transfererr
	jsr	ott
	orcc	#1
	rts
trend	jsr	in
	cmpa	#cr
	bne	trend
	andcc	#$fe
	rts

transfererr

	fcb	cr,lf,"Intel-hex checksum error.",0

bin_ctr	rmb	1
divtenr	rmb	1
crc	rmb	1
teller	rmb	1
