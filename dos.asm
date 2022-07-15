	cpu	6809

;This program must be placed into RAM, altough some parts can be placed in ROM

dosbegin	equ	$8000
monitor		equ	$c01b
mtpa		equ	$0100
DIR_len		equ	8		;Size of root directory.
FAT_len		equ	5		;Size of SAT.
bytes_sector	equ	512		;512 bytes per sector.

;Entry vector for dos functions

dos_entry_vect  equ     $80
end_of_ram	equ	$70
dma_register	equ	$72
buffer		equ	$fe
dosversion	equ	$0103		;BCD 01.03

	org	dosbegin

	include	"dosvar.asm"
	include "basisio.asm"
	include	"spi.asm"
	include "cfcard.asm"
	include "bdos.asm"

dosinittxt

	fcb	cr,lf,"Dos09 version ",0," for the 6809 working with 32 Kbytes memory "
	fcb	"on Scrumpel 8d.",cr,lf
	fcb	"(c) 2022 by N.L.P. Brok (PE1GOO) the Netherlands.",cr,lf,0

mtpa_info_text

	fcb	"TPA := [ ",0
	fcb	" ]",cr,lf,lf,esc,"[33mCF card info:",0

initdos	sts	stack_pointer
dosini	lds	stack_pointer
	jsr	initpia		;Initialise PIA for RTC.
	clr	current_drive
	lda	#$7e
	sta	dos_entry_vect
	ldd	#fdos
	std	dos_entry_vect+1
	ldd	#dosbegin
	subd	#1
	std	end_of_ram
	ldx	#dosinittxt
	jsr	ott
	ldd	#dosversion	;Get version number of OS.
	ora	#$30		;Is BCD, so OR with $30 to get ASCII digit.
	jsr	ot
	lda	#'.'
	jsr	ot
	tfr	b,a
	ora	#$30		;Is BCD, so OR with $30 to get ASCII digit.
	jsr	ot
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
	jsr	cfinfo		;Get card info
	jsr	crlf
	jsr	crlf
	clr	lba0
	clr	lba1
	clr	lba2
	clra			;Initialize the disk and set to no files
	jsr	select_drive	;open
	clr	file_opened,y
	jmp	dos_reentry

	end
