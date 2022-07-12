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

spi_ctr		equ	$40
reg_pointer	equ	spi_ctr+1
uur		equ	reg_pointer+1
minuut		equ	uur+1
sec		equ	minuut+1
wdag		equ	sec+1
dag		equ	wdag+1
maand		equ	dag+1
jaar		equ	maand+1

;piaa bitmap software spi PORTA van pia board
;        B7    B6    B5    B4    B3    B2    B1    B0
;       CS04  CS03  CS02  CS01  MOSI  CS00  clck  MISO

initpia	lda	#%11111110	;Alle bits (poort A) zijn uitgang,
	sta	piaad		;behalve bit 0
	lda	#%11111111	;Alle bits (poort B) zijn uitgang.
	sta	piabd
	lda	#%11111110	;Alle CS lijnen moeten hoog zijn.
	sta	piaa
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

	lda	#rtsec			;Set seconds register.
	jsr	spi_write		;Send command.
	jsr	spi_read		;Read the result.
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
	jsr	byteot
	lda	maand
	cmpa	#$10
	bcs	nmonth
	suba	#$6
nmonth	deca
	ldx	#maand_tabel
	jsr	mesgot
	lda	#eeuw
	jsr	byteot
	lda	jaar
	jsr	byteot
	lda	#space
	jsr	ot
	jsr	ot
timot	lda	uur
	jsr	byteot
	lda	#':'
	jsr	ot
	lda	minuut
	jsr	byteot
	lda	#':'
	jsr	ot
	lda	sec
	jmp	byteot

ptime	jsr	get_time_spi
	bra	timot

dag_tabel	fcb	"Sun ",0
		fcb	"Mon ",0
		fcb	"Tue ",0
		fcb	"Wed ",0
		fcb	"Thu ",0
		fcb	"Fri ",0
		fcb	"Sat ",0

maand_tabel	fcb	" Jan ",0
		fcb	" Feb ",0
		fcb	" Mar ",0
		fcb	" Apr ",0
		fcb	" May ",0
		fcb	" Jun ",0
		fcb	" Jul ",0
		fcb	" Aug ",0
		fcb	" Sep ",0
		fcb	" Oct ",0
		fcb	" Nov ",0
		fcb	" Dec ",0

