	cpu	6809

dosbegin	equ	$8000
monitor		equ	$c01b
mtpa		equ	$0100

;Entry vector for dos functions

dos_entry_vect  equ     $80
end_of_ram	equ	$70
dma_register	equ	$72
buffer		equ	$fe

	org	dosbegin

	jmp	initdos

auto_start_flag	fcb	0
line		rmb	81
current_fat	rmb	2
current_dir	rmb	2
sect_ctr1	rmb	1


	include "basisio.asm"
	include	"spi.asm"
	include "cfcard.asm"
	include "bdos.asm"

nocard	fcb	cr,lf,"No card present, returning to monitor.",cr,lf,0

dosinittxt

	fcb	cr,lf,"Dos09 version 1.0 for the 6809 32 Kbytes memory",cr,lf
	fcb	"working on Scrumpel 8d.",cr,lf
	fcb	"(c) 2022 by N.L.P. Brok (PE1GOO) the Netherlands.",cr,lf,0

mtpa_info_text

	fcb	"TPA := [ ",0
	fcb	" ]",cr,lf,lf,0

initdos	sts	stack_pointer
dosini	lds	stack_pointer
	jsr	initpia		;Initialise PIA for RTC
	clr	current_drive
	lda	#$7e
	sta	dos_entry_vect
	ldd	#fdos
	std	dos_entry_vect+1
	ldx	#cfaddress
	lda	#5		;Test if card is present by writing
	sta	cfseccnt,x	;into sector count register from CF-card
	cmpa	cfseccnt,x	;Write succesfull? Then card present.
	beq	cardpresent
	ldx	#nocard
	jsr	ott
	jmp	monitor

cardpresent

	ldx	#info
	jsr	ott
	jsr	initcf		;Initialise CF-card
	jsr	cfinfo		;Get card info
	ldd	#dosbegin
	subd	#1
	std	end_of_ram
	ldx	#dosinittxt
	jsr	ott
	ldx	#mtpa_info_text
	jsr	ott
	pshs	x
	lda	#'$'
	jsr	ot
	ldx	#mtpa
	jsr	xot
	lda	#','
	jsr	ot
	lda	#'$'
	jsr	ot
	ldx	end_of_ram
	jsr	xot
	puls	x
	jsr	ott
	clr	lba0
	clr	lba1
	clr	lba2
	clra			;Initialize the disk and set to no files
	jsr	select_drive	;open
	clr	file_opened,y
	jmp	dos_reentry

sectorbuffer	rmb	512	;Sectorbuffer on end of OS 

	end
