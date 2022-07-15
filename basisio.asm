
aciainit	equ	%00010101	;8N1 @ 115200 Baud
acia_status	equ	$cf00		;ACIA Status/Command register
acia_data	equ	$cf01		;ACIA Data register
cr		equ	$0d		;Cariage return
lf		equ	$0a		;Line feed
mbyte		equ	$10
eof		equ	$1a
esc		equ	$1b		;Escape character
bin_ctr		equ	$13
divtenr		equ	$14
crc		equ	$18
teller		equ	$19
decimal_buffer	equ	sector_pointer+2

;****************************************************
;* Ansi code for character default colour
;****************************************************

defcol	fcb	esc,"[0m",0	;Go back to default colour

;****************************************************
;* Basic I/O routines
;****************************************************

in	pshs	b		;Save B
inlp	ldb	acia_status	;Get ACIA status
	bitb	#$1		;Check receiver full
	beq	inlp		;Full? No, then check again
	lda	acia_data	;Yes? Get the character
	puls	b		;Restore B
	rts

crlf	lda	#cr
	bsr	ot		;Sent CR
	lda	#lf		;Sent LF
ot	pshs	b		;Save B
otlp	ldb	acia_status	;Get ACIA status
	bitb	#$2		;Check transmitter empty
	beq	otlp		;Transmitter empty? No, check again
	sta	acia_data	;Yes, sent the character
	puls	b		;Restore B
	rts

ott	lda	0,x+		;Display character pointed by X and inc X
	beq	exott		;Is character=0 The stop
	bsr	ot		;Print the character
	bra	ott		;Get next character
exott	rts

xot	pshs	a,b
	exg	d,x
	pshs	b
	bsr	byteot		;Print highbyte
	puls	a
	bsr	byteot		;Print lowbyte
	puls	a,b
	rts

getnibble

	bsr	in		;Get character
	tfr	a,b
	jsr	conluc1		;Convert to uppercase
	tfr	b,a
	cmpa	#'0'		;Is it a 0?
	bcs	gnerr		;No, then error.
	cmpa	#$3a
	bcs	sub0
	cmpa	#'A'
	bcs	gnerr
	cmpa	#'G'
	bcc	gnerr
	bsr	ot		;Echo character
	suba	#7
	bra	add0
sub0	bsr	ot		;Echo character
add0	suba	#'0'
	andcc	#$fe		;Clear carry
	rts
gnerr	orcc	#1		;Set carry
	rts

bytein	bsr	getnibble	;Get high nibble.
	bcs	bytein
	sta	mbyte
bytin1	bsr	getnibble	;Get low nibble.
	bcs	bytin1
	tfr	a,b
	lda	mbyte
	lsla
	lsla
	lsla
	lsla
	pshs	b
	adda	,s+		;Combine both to byte in A.
	rts

byteot	pshs	a,b		;Save A and B.
	sta	mbyte		;Save hex-byte.
	ldb	#2		;Print two nibbles.
	lsra
	lsra
	lsra
	lsra
bytlp	anda	#$0f		;Mask lower byte.
	andcc	#%11011100	;Reset some flags in CC to do a good DAA.
        daa			;Decimal adjust.
        adda	#$f0
        adca	#$40
        bsr	ot		;Print the HEX digit.
        lda	mbyte		;Restore hex-byte.
        decb
        bne	bytlp		;Get next nibble.
	puls	a,b		;Restore A and B.
	rts

dec32_ot

	bsr	bin_omzetting
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

chksum	adda	crc		;Calculate checksum.
	sta	crc
	rts

transfer_in

	jsr	crlf
trl1	jsr	in
	cmpa	#':'
	bne	trl1
	jsr	ot
	jsr	bytein
	beq	trend		;A :00 means end of transfer.
	sta	teller		;Store first byte in counter (number of bytes).
	clr	crc		;Clear CRC.
	jsr	chksum		;Calculate checksum.
	jsr	bytein		;Get address high byte.
	sta	buffer		;Store it in buffer (= load address).
	jsr	chksum		;Calculate checksum.
	jsr	bytein		;Get Address low byte.
	sta	buffer+1	;Store it in buffer.
	jsr	chksum		;Calculate checksum.
	ldx	buffer		;Get load address into X.
	jsr	bytein		;Get control byte.
	jsr	chksum		;Calculate checksum.
trl0	jsr	bytein		;Get byte to load.
	sta	0,x+		;Store data.
	jsr	chksum		;Calculate checksum.
	dec	teller		;Decrement counter.
	bne	trl0		;Get next byte until all done.
	jsr	bytein		;Get checksum.
	nega
	cmpa	crc		;Check checksum.
	beq	transfer_in	;Correct? Get next line.
chkerr	ldx	#transfererr	;Print CRC error message.
	jsr	ott
	orcc	#1		;Set the carry.
	rts
trend	jsr	in		;Wait for CR.
	cmpa	#cr
	bne	trend
	andcc	#$fe		;Reset the carry.
	rts

transfererr

	fcb	esc,"[31m",cr,lf,"Intel-hex checksum error.",esc,"[0m",0

