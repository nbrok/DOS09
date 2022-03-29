;*************************************************
;* SPI rtc routines
;*************************************************

piaa		equ	$cf41
piab		equ	$cf40
piabd		equ	$cf42
piaad		equ	$cf43

eeuw		equ	$20	;21e eeuw.
ruur		equ	$2
rmin		equ	$1
rtsec		equ	$0
rwdag		equ	$3
rdag		equ	$4
rmaand		equ	$5
rjaar		equ	$6

;piaa bitmap software spi PORTA van pia board
;        B7    B6    B5    B4    B3    B2    B1    B0
;       CS04  CS03  CS02  CS01  MOSI  CS00  clck  MISO

initpia	lda	#%11111110	;Alle bits (poort A) zijn uitgang,
	sta	piaad		;behalve bit 0
	lda	#%11111111	;Alle bits (poort B) zijn uitgang.
	sta	piabd
	rts

spi_write

	pshs	a		;Bewaar A
	lda	piaa
	anda	#%11111011	;Maak CS laag
	sta	piaa
	puls	a		;Haal A terug
	ldb	#8		;Zet in B het aantal bits (8) te halen
wr_lp	lsla			;Haal bit naar carry
	bcs	bith		;Als 1 dan bit is 1
bitl	pshs	a		;Bewaar A
	lda	piaa		;Als 0 dan bit is 0
	anda	#%11110111	;MOSI is 0
	sta	piaa
	bra	nxtw
bith	pshs	a		;Bewaar A
	lda	piaa
	ora	#%00001000	;MOSI is 1
	sta	piaa
nxtw	lda	piaa		;Genereer klok puls
	anda	#%11111101	;Klok is 0
	sta	piaa
	ora	#%00000010	;Klok is 1
	sta	piaa		;--__--
	puls	a		;Haal A terug
	decb			;8 bits gehad?
	bne	wr_lp		;Nee? Haal volgende bit
	rts

spi_read

	lda	#8
	sta	spi_ctr
	ldb	#0
rd_lp	lda	piaa		;Genereer klok puls
	anda	#%11111101	;Klok is 0
	sta	piaa
	ora	#%00000010	;Klok is 1
	sta	piaa		;--__--
	lda	piaa
	anda	#%00000001	;Lees MISO bit
	lsra
	rolb			;Shift in B
	lda	spi_ctr
	deca
	sta	spi_ctr		;8 bits gehad?
	bne	rd_lp		;Nee? Haal volgend bit
	lda	piaa
	ora	#%00000100	;Maak CS hoog
	sta	piaa
	tfr	b,a		;Kopieer ingelezen waarde in B naar A
	rts

get_time_spi

	lda	#rtsec
	jsr	spi_write
	jsr	spi_read
	sta	sec
	lda	#rmin
	jsr	spi_write
	jsr	spi_read
	sta	minuut
	lda	#ruur
	jsr	spi_write
	jsr	spi_read
	anda	#$3f
	sta	uur
	lda	#rwdag
	jsr	spi_write
	jsr	spi_read
	sta	wdag
	lda	#rdag
	jsr	spi_write
	jsr	spi_read
	sta	dag
	lda	#rmaand
	jsr	spi_write
	jsr	spi_read
	anda	#$3f
	sta	maand
	lda	#rjaar
	jsr	spi_write
	jsr	spi_read
	sta	jaar
	rts

bcd_output

	pshs	a,b		;Bewaar A en B
	tfr     a,b             ;Copy A naar B
	lsra                    ;Shift hoger nibble 4 bits naar rechts
	lsra
	lsra
	lsra
	ora     #'0'		;Tel er '0' bij op
	jsr     ot		;Print het nibble
	tfr     b,a
	anda	#$f		;Haal lager nibble
	ora	#'0'		;Tel er '0' bij op
	jsr	ot		;Print het nibble
	puls	a,b		;Haal A en B weer terug
	rts

mesgot	pshs	b
	tsta
	beq	mesdi
meslp1	ldb	0,x+
	tstb
	bne	meslp1
	deca
	bne	meslp1
mesdi	jsr	ott
	puls	b
	rts

pdate	jsr	get_time_spi
	lda	wdag
	deca
	ldx	#dag_tabel
	jsr	mesgot
	lda	dag
	jsr	bcd_output
	lda	maand
	cmpa	#$10
	bcs	nmonth
	suba	#$6
nmonth	deca
	ldx	#maand_tabel
	jsr	mesgot
	lda	#eeuw
	jsr	bcd_output
	lda	jaar
	jsr	bcd_output
	lda	#space
	jsr	ot
	jsr	ot
        lda     uur
        jsr     bcd_output
        lda     #':'
        jsr     ot
        lda     minuut
        jsr     bcd_output
        lda     #':'
        jsr     ot
        lda     sec
        jsr     bcd_output
	rts

dag_tabel       fcb     "zondag    ",0
                fcb     "maandag   ",0
                fcb     "dinsdag   ",0
                fcb     "woensdag  ",0
                fcb     "donderdag ",0
                fcb     "vrijdag   ",0
                fcb     "zaterdag  ",0

maand_tabel     fcb     " januari   ",0
                fcb     " februari  ",0
                fcb     " maart     ",0
                fcb     " april     ",0
                fcb     " mei       ",0
                fcb     " juni      ",0
                fcb     " juli      ",0
                fcb     " augustus  ",0
                fcb     " september ",0
                fcb     " oktober   ",0
                fcb     " november  ",0
                fcb     " december  ",0

spi_ctr		rmb	1
reg_pointer	rmb	1
uur		rmb	1
minuut		rmb	1
sec		rmb	1
wdag		rmb	1
dag		rmb	1
maand		rmb	1
jaar		rmb	1

