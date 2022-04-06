;********************************
;* Disk parameters
;********************************

directory_sector	equ	5	;Begin van de directory op drive
FAT_sector		equ	0	;Begin van de FAT.
DIR_len			equ	8	;Grootte van de root directory.
FAT_len			equ	5	;Grootte van de FAT.
bytes_sector		equ	512	;512 bytes per sector.
sectors_block		equ	4	;4 sectoren per blok.
max_sector		equ	2560	;1,3 MByte
max_disks		equ	1

;********************************
;* CF Registers
;********************************

cfaddress	equ	$cf60
cfdata		equ	$00	; Data port
cferror		equ	$01	; Error code (read)
cffeature	equ	$01	; Feature set (write)
cfseccnt	equ	$02	; Number of sectors to transfer
cflba0		equ	$03	; Sector address LBA 0 [0:7]
cflba1		equ	$04	; Sector address LBA 1 [8:15]
cflba2		equ	$05	; Sector address LBA 2 [16:23]
cflba3		equ	$06	; Sector address lba 3 [24:27 (LSB)]
cfstatus	equ	$07	; Status (read)
cfcommand	equ	$07	; Command register (write)
cfstatusl	equ	cfaddress+cfstatus

;********************************
;* CF CARD commands
;********************************

driveid		equ	$ec

;********************************
;* Internal variables and buffer
;********************************

lba2		fcb	$00
lba1		fcb	$00
lba0		fcb	$00
sector_pointer	rmb	2

;********************************
;* CF-card I/O routines
;********************************

;****************************************************
;* Error Initialising the CF Card
;****************************************************

cferr	ldb	cfstatusl
	bitb	#$01		; Isolate the error bit
	beq	erexit
	ldx	#initerror
	jsr	ott
erexit	rts

initerror

	fcb	cr,lf,esc,"[31m","Error initialising CF-Card",esc,"[0m",cr,lf,0

init	fcb	"Initialising CF-card",cr,lf,0

;****************************************************
;* Wait for CF Card ready when reading/writing to it
;* Check for BUSY = 0 (bit 7)
;****************************************************

datwait	ldb	cfstatusl	; Read the status register
	bitb	#$80		; Isolate the ready bit
	bne	datwait		; Wait for the bit to clear
	rts

;****************************************************
;* Wait for CF Card ready when reading/writing
;* to CF Card
;* Check for RDY = 0 (bit 6)
;****************************************************

cmdwait	ldb	cfstatusl	; Read the status register
        bitb	#$c0		; Isolate the ready bit
        beq	cmdwait		; Wait for the bit to clear
        rts

;********************************
;* Initialise the CF Card
;********************************

initcf  ldx	#init
	jsr	ott
	ldx	#cfaddress
	jsr	cmdwait
	ldb	#$01		; Set 8-bit bus-width
	stb	cffeature,x
	bsr	cmdwait
	ldb	#$ef
	stb	cfcommand,x
	jsr	cmdwait
	ldb	#$82
	stb	cffeature,x
	ldb	#$ef
	stb	cfcommand,x
	jsr	cmdwait
	ldb	#$e0		; Clear LBA3, set Master & LBA mode
	stb	cflba3,x
	ldb	#$01		; Read only one sector at a time.
	stb	cfseccnt,x
	ldb	lba0
	stb	cflba0,x
	ldb	lba1
	stb	cflba1,x
	ldb	lba2
	stb	cflba2,x
	jsr	datwait
	rts

;****************************************************
;* Write a 512 bytes block of data 
;* to CF Card
;****************************************************

writecf	pshs	y,x,b,a
	jsr	cmdwait
	ldx	#cfaddress              
	ldb	lba0		; Load the LBA addresses with the current
	stb	cflba0,x	; settings before issuing the write command
	ldb	lba1
	stb	cflba1,x
	ldb	lba2
	stb	cflba2,x
	ldb	#$e0		; LBA3 is not used so set to $E0
	stb	cflba3,x
	ldb	#$01
	stb	cfseccnt,x
	jsr	cmdwait
	ldb	#$30		; Send write command to the CF Card
	stb	cfcommand,x
	jsr	datwait
	ldy	dma_register	; Point to the start of the memory
wrloop	lda	,y+		; Read the byte from the buffer
	sta	cfdata,x	; Write the data byte to the CF Card
	jsr	datwait
	lda	cfstatus,x
	bita	#$08
	bne	wrloop
	puls	y,x,b,a
	rts

;****************************************************
;* Read a 512 bytes block of data from the CF Card
;* Loop until the Drq bit = 0 (bit 3)
;****************************************************

readcf	pshs	y,x,b,a
	ldx	#cfaddress
	jsr	cmdwait
	ldb	lba0		; Load the LBA addresses with the current
	stb	cflba0,x	; settings before issuing the read command
	ldb	lba1
	stb	cflba1,x
	ldb	lba2
	stb	cflba2,x
	ldb	#$e0
	stb	cflba3,x	; LBA3 is not used so set to $E0
	ldb	#$01
	stb	cfseccnt,x
	jsr	cmdwait
	ldb	#$20		; Send read command to the CF Card
	stb	cfcommand,x
	jsr	datwait

	ldy	dma_register	; Point to the start of the sector buffer
rdloop	jsr     datwait
	lda	cfdata,x	; Read the data byte
	sta	,y+		; Write it to the buffer
	jsr	datwait
	lda	cfstatus,x
	bita	#$08
	bne	rdloop
rdexit	puls	y,x,b,a
	rts

read_sector

	jsr	readcf		; Alias for reading a sector from CF
rdsec1	ldd	dma_register
	addd	#bytes_sector
	std	dma_register
	rts

write_sector

	jsr	writecf		; Alias for writing a sector to CF
	bra	rdsec1

cfinfo	pshs	y,x,b,a
	ldx	#decimal_buffer
	stx	d_ptr
	jsr	cmdwait
	ldx	#cfaddress
	ldb	#driveid	; Issue Drive ID command
	stb	cfcommand,x
                
	ldy	#sectorbuffer	; Point to the start of the buffer
infocf	jsr	datwait
	ldb	cfstatus,x	; Check the DRQ bit for available dsts
	bitb	#$08
	beq	infnext
	ldb	cfdata,x	; Read the data byte
	stb	,y+		; Write it to the buffer
	bra	infocf

infnext	ldx	#modelno	; Print the card model number
	jsr	ott
	ldy	#sectorbuffer+54
	ldb	#20
modno	lda	1,y
	jsr	ot
	lda	,y++
	jsr	ot
	decb
	bne	modno

	ldx	#firmrev	; Print the card firmware revision
	jsr	ott
	ldy     #sectorbuffer+46
	ldb	#4
firm	lda	1,y
	jsr	ot
	lda	,y++
	jsr	ot
	decb
	bne	firm

        ldx     #serno		; Print the card serial number
	jsr	ott
	ldy	#sectorbuffer+20
	ldb	#10
serial	lda	1,y
	jsr	ot
	lda	,Y++
	jsr	ot
	decb
	bne	serial

	ldx	#lbasize	; Print the card LBA details
	jsr	ott
	ldy     #sectorbuffer+120
	ldb     #02
lbacnt	leax	1,y
	lda	0,x
	jsr	putdbuf
	leax	,y++
	lda	0,x
	jsr	putdbuf
	decb
	bne	lbacnt
	ldd	decimal_buffer
	ldx	decimal_buffer+2
	std	decimal_buffer+2
	stx	decimal_buffer
	jsr	dec32_ot
	ldx	#defcol
	jsr	ott
	puls	y,x,b,a
	rts

putdbuf	pshs	x
	ldx	d_ptr
	sta	0,x+
	stx	d_ptr
	puls	x
	rts

d_ptr	rmb	2

info	fcb	"Found a CF card",cr,lf,$0
serno	fcc	" Serial No.: "
	fcb	$0
firmrev	fcb	cr,lf,"Firmware Rev.: "
	fcb	$0
modelno	fcb	esc,"[33m",cr,lf,"Model No.: "
	fcb	$0
lbasize	fcb	cr,lf,"LBA Size : "
	fcb	$0

set_lba_sector

	ldd	sector_pointer
	cmpd	#max_sector
	bcc	select_error
	stb	lba0
	sta	lba1
	clr	lba2
	andcc	#$fe
	rts

select_error

	orcc	#1
	rts

select_absolute_sector_fdos

	pshs	x
	exg	d,x
	puls	x

select_absolute_sector

	pshs	x,a,b
	std	sector_pointer
	bsr	set_lba_sector
	puls	x,a,b
	bcs	error_sas
	rts

error_sas

	ldx	#err01
	jsr	ott
	jmp	dos_reentry

err01	fcb	esc,"[31m","Sector not available, aborting operation.",esc,"[0m",cr,lf,0

set_dma	stx	dma_register
	andcc	#$fe
	rts

parameter_tables

	fdb	dir_buffer1
	fdb	fat_buffer1
	fdb	internal_drive_parameters_a
	rmb	10

internal_drive_parameters_a

	fcb	0
	fdb	max_sector	
	fdb     directory_sector
        fcb     DIR_len
        fcb     FAT_len
        fcb     0
        fdb     bytes_sector
	fcb	0
        fdb     $ffff

select_drive_bios

;	input   A:=drive nummer 0-255.
;	output IY:=parameter tabel voor geselecteerde disk.
;	error in selectie := carry = 1

	cmpa	#max_disks
	bcc	sel_err
	pshs	a
	tfr	a,b
	clra
	lslb
	rola
	lslb
	rola
	lslb
	rola
	lslb
	rola
	andcc	#$fe
	addd	#Parameter_tables
	exg	d,y
        puls	a
        andcc	#$fe
	rts

sel_err

	orcc	#1
	rts

