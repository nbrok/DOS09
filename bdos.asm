;File Control Block:

;00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F 10 11 12
;<Filename                                     > < EXT  >
;13 14 15 16 17 18 19 1A 1B 1C 1D 1E 1F 20 21 22 29 2A
;DR Lh Ll Bh Bl Dh Dl DMAPT AC ct cusec ollen MF RNSEC

;Lh,Ll    = Filelengte #sectors van 512 bytes (pointer).
;DR       = Drive nummer := op welke drive staat deze file.
;AC       = AllocationCode := toegewezen volgnummer in allocatie tabel.
;Bh,Bl    = Block pointer := momenteel in gebruik zijnde block.
;Dh,Dl    = Directoryentry RAM addres, hier staat de entry van deze file.
;DMAPT    = DMA pointer.
;CT       = Internal sector_block_counter.
;cusec    = Momentele sector.
;ollen    = Old filelength, voor intern gebruik.
;MF       = Mode_flag, geeft voor intern gebruik aan wat er met deze file gebeurt.
;rnd_sect = Random sectornummer.

;Standaard offsets gebruikt in DOS.

; de FCB is 48 bytes lang, hierin wordt alles bijgehouden van de gespecficeerde
; file, in principe kan er net zo veel files geopend worden als er geheugen is,
; let wel op dat er geheugen over blijft voor de file!

FCB_drive               equ     $13
FCB_length              equ     $14
FCB_block_pointer       equ     $16
FCB_dir_entry           equ     $18
FCB_DMA                 equ     $1a
FCB_alloc_code          equ     $1c
FCB_sect_count          equ     $1d
FCB_cur_sect_ptr        equ     $1e
FCB_length_ctr          equ     $20     ;Vanaf nu als tussenpointer in gebruik.
FCB_mode                equ     $22
FCB_dir_ptr             equ     $23
FCB_drive_param_ptr     equ     $25
FCB_delete_ptr          equ     $27     ;Temp pointers voor delete en random R/W.
FCB_rnd_calc            equ     $27     ;Gelijk aan delete_ptr.
FCB_rnd_sect            equ     $29
FCB_rnd_rest            equ     $2b
FCB_rnd_quotient        equ     $2d

; Directory entry

DIR_acces_code          equ     $13
DIR_alloc_code          equ     $14
DIR_length              equ     $17
DIR_t_h                 equ     $19
DIR_t_m                 equ     $1a
DIR_t_s                 equ     $1b
DIR_d_d                 equ     $1c
DIR_d_m                 equ     $1d
DIR_d_y                 equ     $1e

;************************************
;* Bdos routines
;************************************

functionkey3	equ	1
functionkey2	equ	2
ctlx		equ	$18
ctlc		equ	$03
bs		equ	8
space		equ	$20
FCBlength	equ	48
dir_entry_len	equ	32
max_drive	equ	1
i_d_p		equ	4

stack_pointer		rmb	2
interpreter_pointer	rmb	2
ctr			rmb	1
temp_t			rmb	2
max_fun			equ	39
file_opened		equ	6
temp2			rmb	1
dsector			rmb	2
rest			rmb	1
internal_ptr1		rmb	2
entry_counter		rmb	1
direntries		rmb	2
dir_buffer1		rmb	DIR_len*bytes_sector
			fdb	$ffff
FAT_buffer1		rmb	FAT_len*bytes_sector
			fdb	$ffff
internal_fcb1		rmb	48
internal_fcb2		rmb	48
current_drive		rmb	1
i_fcb_ptr1		rmb	2
i_fcb_ptr2		rmb	2
i_fcb_ptr3		rmb	2
dflag			rmb	1
d_ctr			rmb	1

;BDOS_foutcodes.

no_error		equ     0
r_w_failed_error	equ	1
file_not_found_error	equ	2
file_already_exist_err	equ	3
EOF_reached_error	equ	4
DIR_full_error		equ	5
DISK_full_error		equ	6
BDOS_function_error	equ	7
random_function_error	equ	8

; *****************************************************
; De dos functies.
;	register organisatie in fdos INPUT.
;	Alle registers worden gebruikt!

;	B :=<function_code>.
;	IX:=<FCB> of IX:=<16 bits word>

;	register organisatie in fdos OUTPUT.

;	IX:=<16 bits_number> of <FCB>.
;	IY:=<Entry address> IX:=<table address>.
; ******************************************************

fdos	pshs	a
	cmpb	#max_fun
	bcc	fun_err
	lslb
	clra
	std	buffer
	ldd	#fdos_table
	addd	buffer
	exg	d,y
	ldy	0,y
	puls	a
	jsr	0,y
	rts

fun_err

	puls	a
	lda	#BDOS_function_error
	orcc	#1
	rts

fdos_table

	fdb	external_warm			;1
	fdb	set_dma				;2
	fdb	select_absolute_sector_fdos	;3
	fdb	read_sector			;4
	fdb	write_sector			;5
	fdb	restore				;6
	fdb	write				;7
	fdb	read				;8
	fdb	open_file			;9
	fdb	create_file			;10
	fdb	close_file			;11
	fdb	rename_file			;12
	fdb	delete_file			;13
	fdb	decimal_ot			;14
	fdb	disk_param			;15
	fdb	read_fat_s			;16
	fdb	write_fat_s			;17
	fdb	get_fat_address			;18
	fdb	make_external_fcb		;19
	fdb	search_first			;20
	fdb	search_next			;21
	fdb	line_input			;22
	fdb	zoek_deleted_first		;23
	fdb	zoek_deleted_next		;24
	fdb	write_dir_function		;25
	fdb	select_current_disk		;26
	fdb	get_current_disk		;27
	fdb	get_dos_version			;28
	fdb	decimal_ot32			;29
	fdb	random_read			;30
	fdb	random_write			;31
	fdb	init_terug			;32
	fdb	get_end_of_mtpa			;33
	fdb	join_file			;34
	fdb	get_batch_parameters		;35
	fdb	get_dos_begin			;36
	fdb	conin				;37
	fdb	conot				;38

fill_internal_fcb

	pshs	x
	ldb	#fcblength

clear_loop1

	clr	0,x+			;Clear de FCB en FILL filename met spaties.
	decb
	bne     clear_loop1
	puls	x
	pshs	x
	ldb	#19
lfd0	lda	#space
	sta	0,x+
	decb
	bne	lfd0
	puls	x
	rts

wild_card1

	ldb	#'?'
	stb	0,x+
	deca
	bne	wild_card1
	bra	lifll0

make_internal_fcb2

	sty	interpreter_pointer
	ldx	#internal_fcb2
	bra     mkfcb2

make_internal_fcb1

	ldx	#internal_fcb1
mkfcb2	stx	i_fcb_ptr1
	jsr	fill_internal_fcb
	ldy	interpreter_pointer
	lda	current_drive
	sta	FCB_drive,x
	ldb	0,y
	bne	continue_making_fcb

nothing_more

	orcc	#1
	andcc	#$fd
	rts

nothing_more_p

	orcc	#3
	rts

continue_making_fcb

;	jsr	get_select_token
;	bcs	g_token
;	ldb	0,y
;	beq	nothing_more_p

g_token

	lda	#16

make_internal_fcb_loop

	ldb	0,y
	beq	without_extend
	cmpb	#space
	beq	without_extend
	cmpb	#'.'
	beq	with_extend_imm
	cmpb	#'*'
	beq	wild_card1
	pshs	a
	jsr	conluc1
	puls	a
	stb	0,x
	leax	1,x
	leay	1,y
	deca
	bne	make_internal_fcb_loop

lifll0	ldb	0,y
	beq	without_extend
	cmpb	#space
	beq	without_extend
	leay	1,y
	cmpb	#'.'
	bne	lifll0
	leay	-1,y

with_extend_imm

	leay	1,y
	ldx	i_fcb_ptr1
	lda	#3

extend_loop

	ldb	0,y
	beq	without_extend
	cmpb	#space
	beq	without_extend
	cmpb    #'*'
	beq	wild_card2
	pshs	a
	jsr	conluc1
	puls	a
	stb	16,x
	leax	1,x
	leay	1,y
	deca
	bne	extend_loop

without_extend

	orcc	#$fc
	rts

wild_card2

	leay	1,y
wch2	ldb	#'?'
	stb	16,x
	leax	1,x
	deca
	bne     wch2
	bra     without_extend

make_external_fcb

	cmpx	#0
	beq	mef_ok
	stx	interpreter_pointer

mef_ok	jsr	make_internal_fcb1
	bcs	mef_er
	ldx	#internal_fcb1
	clra
mef_er	rts

line_input

	jsr	inputline
	ldx	#line
	clra
	rts

select_current_disk

	exg	d,x
	tfr	b,a
	sta	current_drive
	jsr	select_drive
	clra
	rts

get_current_disk

	ldb	current_drive
	clra
	rts

disk_param

	exg	d,x
	tfr	b,a
	jsr	select_drive
	ldx	i_d_p,y
	clra
	rts

get_fat_address

	exg	d,x
	tfr	b,a
	jsr	select_drive
	ldx	current_FAT
	clra
	rts

search_first

	jsr	search_in_directory

no_fault_1

	bcs	fault_1

copy_dir_entry_to_fcb

	pshs	y
	ldb	#19
braaf	lda	0,y+
	sta	0,x+
	decb
	bne	braaf
	puls	y
	clra
	rts

fault_1	lda	#file_not_found_error
	orcc	#1
	rts

search_next

	jsr	search_for_next_entry
	bra	no_fault_1

read_fat_s

	exg	d,x
	tfr	b,a
	jsr	select_drive
	jsr	read_fat
	clra
        rts

write_fat_s

	exg	d,x
	tfr	b,a
	jsr	select_drive
	jsr	write_fat
	clra
	rts

read_FAT

	pshs	x,y

read_FAT0

	ldx	current_fat
	jsr	set_dma
	lda	#fat_len
	sta	sect_ctr1
	ldd	#fat_sector

read_FAT_loop

	std	dsector
	jsr	select_absolute_sector
	jsr	read_sector
	bcc	read_FAT_ok

read_FAT_ok

	ldd	dsector
	addd	#1
	dec	sect_ctr1
	bne	read_FAT_loop
fat_ex	puls	x,y
	clra
	rts

write_FAT

	pshs	x,y

write_FAT0

	jsr     restore
	ldx     current_FAT
	jsr     set_dma
	lda	#fat_len
	sta	sect_ctr1
	ldd	#Fat_sector

write_FAT_loop

	std	dsector
	jsr	select_absolute_sector
	jsr	write_sector
	bcc	write_FAT_ok
	jsr	fatal_error
	bra	write_FAT0

write_FAT_ok

	ldd	dsector
	addd	#1
	dec	sect_ctr1
	bne	write_FAT_loop
	bra	fat_ex

read_directory

	pshs	x,y

read_directory0

	lda	#DIR_len
	sta	sect_ctr1
	ldx	current_dir
	jsr	set_dma
	ldd	#directory_sector

dirrd_loop

	std	dsector
	jsr	select_absolute_sector
	jsr	read_sector
	bcc	read_dir_ok
	jsr	fatal_error
	bra	read_directory0

read_dir_ok

	ldd	dsector
	addd	#1
	dec	sect_ctr1
	bne	dirrd_loop
	bra	dir_ex

write_directory

	pshs	x,y

write_directory0

	lda	#DIR_len
	sta	sect_ctr1
	ldx	current_dir
	jsr	set_dma
	ldd     #directory_sector

dirwr_loop

	std	dsector
	jsr	select_absolute_sector
	jsr	write_sector
	bcc	write_dir_ok
	jsr	fatal_error
	bra	write_directory0

write_dir_ok

	ldd	dsector
	addd	#1
	dec     sect_ctr1
	bne	dirwr_loop
dir_ex  andcc	#$fe
	puls	x,y
	rts

fatal_error

	ldx	#f_error_txt
	jsr	ott
	jsr	in
	jsr	ot
	pshs	a
	jsr	crlf
	puls	a
	cmpa	#'Y'
	beq	dfag
	cmpa	#'y'
	beq	dfag
	bra	fatal_error_exit
dfag	rts

fatal_error_exit

	clra

reset_loop

	pshs	a
	jsr	select_drive
	clr	file_opened,y
	puls	a
	inca
	cmpa	#max_drive
	bne	reset_loop
	jmp	dos_reentry

F_error_txt

	fcb	"Directory and/or FAT R/W failed.",cr,lf
	fcb	"Retry? (Y/N) : ",0

decimal_ot

	pshs	a,b,y
	ldy	#decimal_buffer
	clr	0,y
	clr	1,y
	stx	2,y
	jsr	dec32_ot
        puls	a,b,y
	rts

decimal_ot32

        lda	0,x
        sta	temp2
        ldy	#decimal_buffer
	ldb	#4

d32_loop

        lda	1,x
        sta	0,y+
        leax	1,x
	decb
	bne	d32_loop
	jsr	bin_omzetting
	lda	temp2
	bne	d32l1
	ldx	#decimal_fstring
	bra	d32l2
d32l1	ldx	#decimal_string
d32l2	jsr	ott
	clra
	rts

get_dos_version

	ldx	#0100		;(BCD) 1.0
	clra
	rts

external_warm

	jsr	crlf
	jmp	dos_reentry

init_terug

	jsr	crlf
	jmp	dosini

restore	rts

zoek_deleted_first

	jsr	check_file_opened
	beq	zis_ok
	lda	#BDOS_function_error
	orcc	#1
	rts
zis_ok	jsr	read_directory
	jsr	search_deleted_file
	bcs	zfout
zgoed	jsr	copy_dir_entry_to_fcb
	clra
	rts
zfout	lda	#file_not_found_error
	orcc	#1
	rts

zoek_deleted_next

	jsr	check_file_opened
	beq	bzis_ok
	lda	#BDOS_function_error
	orcc	#1
	rts
bzis_ok	jsr	read_directory
	jsr	search_deleted_file_next
	bcs	zfout
	bra	zgoed

write_dir_function

	exg	d,x
	tfr	b,a
	jsr	select_drive
	lda	file_opened,y
	beq     can_write
	lda	#BDOS_function_error
	orcc	#1
	rts

can_write

	jsr	write_directory
	clra
	rts

get_end_of_mtpa

	ldx	end_of_ram
	clra	
	rts

fserr	orcc	#1
	rts

join_file

	jsr	open_file
	bne	fserr
	ldd	FCB_length,x
	std	FCB_rnd_sect,x
	clra
	rts

open_file

;       IX staat op FCB.

	jsr	check_file_opened
	bne	open_file_ok
	jsr	read_FAT

open_file_ok

	jsr	search_in_directory
	bcs	file_cant_open
	pshs	x
	ldx     FCB_drive_param_ptr,x
	inc     file_opened,x
	puls	x
        lda	DIR_alloc_code,y
	sta	FCB_alloc_code,x
	ldd	DIR_length,y
	std	FCB_length,x
	clr	FCB_rnd_sect,x
	clr	FCB_rnd_sect+1,x
	clr	FCB_mode,x
	clr	FCB_block_pointer,x
	clr	FCB_block_pointer+1,x
	sty	FCB_dir_entry,x
	clra
	rts

file_cant_open

	lda	#file_not_found_error
	orcc	#1
	rts

file_already_exists

	lda	#file_already_exist_err
	orcc	#1
	rts

create_file

;       IX staat op FCB.

	jsr	check_file_opened
	bne	create_file_ok
	jsr	read_FAT

create_file_ok

	pshs	a
	lda	FCB_mode,x
	ora	#$80
	sta	FCB_mode,x		;bset    FCB_mode,x,$80
	puls	a
	jsr	search_in_directory
	tfr	cc,a
	sta	rest
	tfr	a,cc
        bvs	file_dont_exist_special
        bcc	file_already_exists

file_dont_exist_special

	pshs	x
	ldx	FCB_drive_param_ptr,x
	inc	file_opened,x
	puls	x
	jsr	search_deleted_file
	bcs	new_entry
	lda	DIR_alloc_code,y
	sta	FCB_alloc_code,x
	tfr	a,b
	jsr	delete_old_allocation_codes
	bra	wend

new_entry

	lda	rest
        tfr	a,cc
	bvs	directory_is_erg_vol_vandaag
	pshs	x
	ldx	current_fat
	lda	0,x
	sta	DIR_alloc_code,y
	inc     0,x
	lda	0,x
	puls	x
	cmpa	#$ff
	beq	FAT_full
	lda	DIR_alloc_code,y
	sta	FCB_alloc_code,x
wend	exg	d,y
	std	FCB_dir_entry,x
	exg	d,y
	ldd	#0
	std	FCB_length,x
	std	DIR_length,y
	std	FCB_block_pointer,x
	std	FCB_rnd_sect,x
	jsr	copy_filename_to_directory
	jsr	get_time
	jsr	write_directory
	jsr	write_FAT
	clra
	rts

directory_is_erg_vol_vandaag

	lda	#DIR_full_error
	orcc	#1
	rts

FAT_full

	pshs	x
	ldx	#fat_full_txt
nb	jsr	ott
	puls	x
	ldx	FCB_drive_param_ptr,x
	clr	file_opened,x
	jmp	dos_reentry

dir_full

	pshs	x
	ldx	#DIR_full_txt
	bra	nb

fat_full_txt

        fcb	cr,lf,"FAT error, returning to DOS.",cr,lf,0

DISK_full_txt

	fcb	cr,lf,"Allocation table full.",cr,lf,0

DIR_full_txt

	fcb	cr,lf,"Directory-entry-space full.",cr,lf,0

close_file

	jsr	check_file_opened
	bne	close_file_ok
	lda	#BDOS_function_error
	orcc	#1
	rts

close_file_ok

	pshs	x
	ldx     FCB_drive_param_ptr,x
	dec     file_opened,x
	puls	x
	ldy	FCB_dir_entry,x         ;Haal directoryentry.
	lda	FCB_mode,x              ;Haal mode: 0=read $ff=write.
	bpl     do_nothing_w_d_f        ;Close een READ operatie.
	ldd     FCB_length,x
	std     DIR_length,y
	lda	FCB_alloc_code,x
	sta	DIR_alloc_code,y
	jsr	get_time
	jsr	write_FAT
	jsr	write_directory

do_nothing_w_d_f

	clra
	rts

no_matching_drives

	lda	#BDOS_function_error
	orcc	#1	
	rts

rename_f_not_found

	lda	#file_not_found_error
	orcc	#1
	rts

rename_file

	jsr	check_file_opened
	stx	i_fcb_ptr2
	exg	d,x
	addd	#FCBlength
	std	i_fcb_ptr3
	exg	d,x
	lda	FCB_drive,x
	ldx	i_fcb_ptr2
	ldb	FCB_drive,x
        pshs	b
	cmpa	,s+
	bne	no_matching_drives
	jsr	search_in_directory
	bcs	rename_f_not_found
	pshs	x
	ldx	FCB_drive_param_ptr,x
	inc	file_opened,x
	puls	x

rename_loop

	pshs	y
	pshs	y
	puls	x
	ldy	#sectorbuffer         ;Tijdelijk hier neerzetten.
	jsr	copy_filename_to_directory
	ldx	i_fcb_ptr3
	lda	FCB_drive,x
	ldy	#sectorbuffer
	sta	FCB_drive,y
	jsr	rename_entry
	ldx	#sectorbuffer
	jsr	search_in_directory
	bcc	overwrite_error
	puls	y
	ldx	#sectorbuffer
	jsr	rename_entry
	jsr	write_directory
	ldx	i_fcb_ptr2
	jsr	search_for_next_entry
	bcc	rename_loop
	ldx	FCB_drive_param_ptr,x
	dec	file_opened,x
	clra
	rts

overwrite_error

	puls	y
	ldx	i_fcb_ptr2
	ldx	FCB_drive_param_ptr,x
	dec	file_opened,x
	lda	#file_already_exist_err
	orcc	#1
	rts

rename_entry

	pshs	y
	pshs	x
	ldb	#19			;16 bytes voor filenaam, 3 bytes voor extend.

copy_loop_ren

	lda	0,x
	cmpa	#'?'
	beq	clrn1
	sta	0,y
clrn1	leax	1,x
	leay	1,y
	decb
	bne	copy_loop_ren
	puls	x
	puls	y
	rts

get_time

	pshs	x
	pshs	y
	jsr	get_time_spi
	puls	y
	lda	sec
	sta	DIR_t_s,y		;Seconde
	lda	minuut
	sta	DIR_t_m,y		;Minuut
	lda	uur
	sta	DIR_t_h,y		;Uur
	lda	dag
	sta	DIR_d_d,y		;Dag
	lda	maand
	sta	DIR_d_m,y		;Maand
	lda	#eeuw			;dit is de eeuw codebyte.
	ldb	jaar
	std	DIR_d_y,y		;Eeuw+Jaar
	puls	x
        rts

conin	jmp	in


conot	jmp	ot

get_dos_begin

	ldx	#dosbegin
	clra
	rts

get_batch_parameters

	ldx	#dos_reentry
	ldy	#parser
	clra
	rts

select_error_txt

	fcb	cr,lf,"Invalid drive number."
	fcb	cr,lf,"Returning to DOS2.",cr,lf,0

select_drive

	jsr	select_drive_bios
	bcc	d_sel_ok
	ldx	#select_error_txt
	jsr	ott
	jmp	dos_reentry

d_sel_ok

	ldd	0,y
	std	current_dir
	ldd	2,y
	std	current_fat
	rts

search_in_directory

	lda	FCB_drive,x
	jsr	select_drive
	ldy	current_dir
	sty	FCB_dir_ptr,x

search_for_next_entry

	stx	internal_ptr1
	lda	FCB_drive,x
	pshs	y
	jsr	select_drive
	lda	file_opened,y
	puls	y
	bne	search_ok
	jsr	read_directory

search_ok

	ldy	FCB_dir_ptr,x
	lda	0,y
	cmpa	#$e5
	bne	snuffel_in_entry
        orcc	#1
        andcc	#$fd
	rts

snuffel_in_entry

	ldb	#19			;16 bytes filenaam, 3 bytes extend.
	ldx	internal_ptr1
	pshs	y

snuffel

	lda	0,y
	bmi	zoek_next_entry
	lda	0,x
	cmpa	#'?'
	beq	is_equal
	cmpa	0,y
	bne	zoek_next_entry

is_equal

	leax	1,x
	leay	1,y
	decb
	bne	snuffel
	puls	y			;IY staat op begin van de gevonden entry.
	pshs	y
	exg	d,y
	addd	#dir_entry_len
	ldx	internal_ptr1           ;IX staat op begin van FCB.
	std	FCB_dir_ptr,x           ;Bewaar next entry in pointer.
	puls	y
	andcc	#$fc
	rts

zoek_next_entry

	puls	y
	ldd	current_dir                     ;Calculate compare value
	addd	#dir_len*bytes_sector-32        ;For the end of directory.
	std	decimal_string
	exg	d,y
	addd	#dir_entry_len
	cmpd	decimal_string
	bcc	directory_full
	exg	d,y
	lda	0,y
	cmpa	#$e5
	beq	entry_not_found
	bra	snuffel_in_entry

entry_not_found

	ldx	internal_ptr1		;IX staat op begin van FCB.
	orcc	#1			;IY staat op schone entry.
        andcc	#$fd
        rts

directory_full

	ldx	internal_ptr1           ;IX staat op begin van FCB.
	orcc	#3
	rts

search_deleted_file_next

	pshs	x
	pshs	y
	ldy	FCB_delete_ptr,x
	bra	search_deleted_file_loop

search_deleted_file

	pshs	x
	pshs	y
	ldy	current_dir

search_deleted_file_loop

	lda	0,y
	cmpa	#$e5
	beq	end_of_directory
	lda	0,y
	bmi	deleted_file_found
	exg	d,y
	addd	#dir_entry_len
	exg	d,y
	bra	search_deleted_file_loop

end_of_directory

        orcc	#1
	puls	y
	puls	x
	rts

deleted_file_found

	pshs	y
	exg	d,y
	addd	#dir_entry_len
	std	FCB_delete_ptr,x
	puls	y
	puls	x
	puls	x
	andcc	#$fe
	rts			;IY staat op deleted entry.

delete_old_allocation_codes

;B:= te deleten Allocation code.

	pshs	x
	ldx	current_FAT

del_o_a_loop

	leax	1,x
	lda	0,x
	cmpa	#$ff
	beq	end_of_FAT
	pshs	b
	cmpa	,s+
	bne	del_o_a_loop
	clr	0,x
	bra	del_o_a_loop

end_of_FAT

	puls	x
	rts

copy_filename_to_directory

	pshs	y
	pshs	x
	ldb	#19			;16 bytes voor filenaam, 3 bytes voor extend.

copy_loop

	lda	0,x+
	sta	0,y+
	decb
	bne	copy_loop
	puls	x
	puls	y
	rts

check_file_opened

	lda	FCB_drive,x
	jsr	select_drive
	sty	FCB_drive_param_ptr,x
	lda	file_opened,y
	rts

delete_file

	jsr	check_file_opened
	jsr     search_in_directory
	bcs     file_n_found
	pshs	x	
	ldx	FCB_drive_param_ptr,x
	inc	file_opened,x
	puls	x

delete_file_loop

	lda	0,y
	ora	#$80
	sta	0,y
	jsr	search_for_next_entry
	bcc	delete_file_loop
	pshs	x
	ldx	FCB_drive_param_ptr,x
	dec	file_opened,x
	puls	x
	jsr	write_directory
	clra
	rts

file_n_found

	lda	#file_not_found_error
	orcc	#1
	rts

cant_read_random

	lda	#BDOS_function_error
crre	orcc	#1
	rts

random_error

	lda	#random_function_error
        bra	crre

random_read

	jsr	check_file_opened
	beq	cant_read_random
	ldd	FCB_length,x
	cmpd	FCB_rnd_sect,x
	beq	random_error
	bcs	random_error
	pshs	a
	lda	FCB_mode,x
	ora	#1
	sta	FCB_mode,x
	puls	a

random_read_l0

	jsr	search_for_allocated_block
	bcs	cant_read_random
	ldd	FCB_cur_sect_ptr,x
	jsr	select_absolute_sector
	pshs	x,d,y
	ldx	FCB_dma,x
	jsr	set_dma
	jsr	read_sector
	puls	x,d,y
	bcc	end_random_read
	lda	#r_w_failed_error
	orcc	#1
	rts

end_random_read

	clra
	rts

cant_write_random

	lda	#BDOS_function_error
	orcc	#1
	rts

random_full

	ldd	FCB_length_ctr,x
	std	FCB_length,x
	lda	#DISK_full_error
	orcc	#1
	rts

;Elke byte in de FAT is gelijk aan een sector op disk. Het eerste byte (sector)
;wordt gebruikt als eerste vrije fat code. (1-FF)
;absolute sector = (fat_buffer+rnd_sect)-fat_buffer

random_write

	jsr	check_file_opened
	beq	cant_write_random
	pshs	a
	lda	FCB_mode,x
	ora	#$81
	sta	FCB_mode,x
	puls	a
;	bset    FCB_mode,x,$81

random_write_l1

	lda	FCB_alloc_code,x
	jsr	search_for_unallocated_block
	bcs	random_full

rnd_over_sw

	ldd	FCB_cur_sect_ptr,x
	jsr	select_absolute_sector
	pshs	x,y,d
	pshs	x
	ldx	FCB_dma,x
	jsr	set_dma
	puls	x
	jsr	write_sector
	puls	x,y,d
	bcc	end_random_write
	lda	#r_w_failed_error
        orcc	#1
	rts

end_random_write

	ldd	FCB_rnd_sect,x
	addd	#1
	cmpd	FCB_length,x
	bcs	no_length_update
	beq	no_length_update
	std	FCB_length,x

no_length_update

	clra
	rts

end_of_file_rd

	lda	#EOF_reached_error

error_rd

	orcc	#1
	rts

read	jsr	random_read
	cmpa	#random_function_error
	beq	end_of_file_rd
	tsta
	bne	error_rd

exit_write

	ldd	FCB_rnd_sect,x
	addd	#1
	std	FCB_rnd_sect,x
	ldd	FCB_DMA,x
	addd	#bytes_sector
	std	FCB_DMA,x
	clra
	rts

write	jsr	random_write
	bne	error_rd
	bra	exit_write

search_for_allocated_sector
search_for_allocated_block

	ldd	current_fat
	addd	FCB_block_pointer,x
	exg	d,y
	leay	1,y

sfas_loop

	lda	FCB_alloc_code,x
	ldb	0,y+
	cmpb	#$ff
	beq	no_more_entry
	pshs	b
	cmpa	,s+
	bne	sfas_loop
	leay	-1,y
	exg	d,y
	subd	current_FAT
	std	FCB_block_pointer,x
	std	FCB_cur_sect_ptr,x
	andcc	#$fe
	rts

no_more_entry

	orcc	#1
	rts

search_for_unallocated_block
search_for_unallocated_sector

	pshs	a
	ldy	current_FAT
	bra	search_un_al_loop

	ldy	current_FAT

search_un_al_loop

	leay	1,y
	ldb	0,y
	cmpb	#$ff
	beq	eod
	tstb
	bne	search_un_al_loop

unallocated_sector_found

	puls	a
	sta	0,y
	exg	d,y
	subd	current_FAT
	std	FCB_cur_sect_ptr,x
        andcc	#$fc
	rts

eod	puls	a
	orcc	#1
	rts

inputline

	ldx	#line

inputline_loop

	jsr	in
	cmpa	#lf
	beq	inputline_loop
	cmpa	#cr
	beq	inputline_end
	cmpa	#bs
	beq	inputline_backspace
	cmpa	#ctlc
	bne	inputline_0
	ldx	#tctlc
	jsr	ott
	lds	stack_pointer
	jmp	dosini

inputline_0

	cmpa	#ctlx
	bne	inputline_1
	ldx	#tctlx
	jsr	ott
	bra	inputline

inputline_1

	cmpa	#functionkey3
        bne	inputline_2
	lda	0,x
	beq	inputline_loop

inputline_p_lp1

	lda	0,x
	beq	inputline_loop
	jsr	ot
	leax	1,x
	cmpx	#line+81
	bcs	inputline_p_lp1
	bra	inputline

inputline_2

	cmpa	#functionkey2
	bne	inputline_3
	lda	0,x
	beq	inputline_loop
	bra	inputline_4

inputline_3

	cmpa	#space
	bcs	inputline_loop

	sta	0,x

inputline_4

	leax	1,x
	cmpx	#line+81
	beq	inputline_ring
	jsr	ot
	bra	inputline_loop

inputline_ring

	leax	-1,X
	bra	inputline_loop

inputline_end

	clr	0,x+
	cmpx	#line+81
	bcs	inputline_end
	jmp	crlf

inputline_backspace

	leax	-1,x
	cmpx	#line-1
	beq	inputline
	pshs	x
	ldx	#bstxt
	jsr	ott
	puls	x
	jmp	inputline_loop

bstxt	fcb	bs,space,bs,0
tctlx	fcb	"^X",cr,lf,0
tctlc	fcb	"^C",cr,lf,0

prompt	fcb	"DOS09> ",0

dos_reentry

	lda	current_drive
	jsr	select_drive
	lds	stack_pointer
	jsr	initpia
	ldx	#prompt
	jsr	ott
	lda	auto_start_flag
	bne	auto_input
	jsr	inputline

dos_cont

	jsr	parser
	bra	dos_reentry

auto_input

	clr	auto_start_flag
	ldx	#line
	jsr	ott
	jsr	crlf
	bra	dos_cont

;COMPARE TOKEN.
;Vergelijkt het token waar IX op wijst met het token waar IY op wijst.
;Het token waar IX naar wijst moet voorafgegaan worden door een byte dat
;de lengte van het token aangeeft.
;Voorbeeld :
;x_indexed      db      $2,',X'
;
;De $2 geeft aan dat de string (het token) 2 karakters lang is.
;Van het token waar IY op wijst wordt de lengte bepaald en deze wordt
;met de andere lengte vergeleken.

compare_token

	sty	temp_t			;Bewaar IY voor indien niet gevonden.
	bsr	calc_str_length		;Wat is de lengte van token op IY
	lda	0,x
	pshs	b
	cmpa	,s+			;Vergelijk deze met de lengte op IX.
	bne	not_equal		;Lengte verschillend : ongelijk.
	leax	1,x			;Hoog IX met 1 op.
	stb	ctr			;De lengte in CTR bewaren.

comp_token_loop

	jsr	conluc			;Haal en converteer naar upper-case.
	cmpb	0,x			;Vergelijk de twee strings.
	bne	not_equal		;Niet gelijk? Dan set NE flag.
	leax	1,x
	leay	1,y
	dec	ctr			;Lengte:=lengte-1.
        bne	comp_token_loop		;Lengte nog niet bereikt : doorgaan.
	jsr	eet_spaties_op
	clra				;Ze zijn gelijk, set EQUAL flag.
	rts

not_equal

	ldy	temp_t			;Haal IY terug.
	lda	#$ff			;Set NOT EQUAL flag.
	rts

;Bereken de lengte van een string, de lengte komt in B.

calc_str_length

	pshs	y			;Bewaar IY.
	clrb				;B op nul zetten.

calc_str_length_loop

	lda	0,y+			;Haal eerste karakter.
	cmpa	#'_'			;Bekijk of het een legaal karakter is.
	beq	calc_ok
	cmpa	#'-'
	beq	calc_ok
	cmpa	#'['
	bcs	calc_tst
	cmpa    #'a'
	bcs	terminate_calc

calc_tst

	cmpa	#'0'
	bcs	terminate_calc
	cmpa	#'9'+1
	bcs	calc_ok
	cmpa	#'A'
	bcs	terminate_calc
	cmpa	#'z'+1
	bcc	terminate_calc
calc_ok incb				;Hoog B met 1 op.
	bra	calc_str_length_loop	;Ga door met tellen.

terminate_calc

;De lengte van de string is nu bekend.

	puls	y			;Haal IY terug.
	rts

conluc	ldb	0,y
conluc1	cmpb	#'z'
	beq	conup
	bcs	nolc
	rts
conup	andb	#$5f
	rts
nolc	cmpb	#'a'
	beq	conup
	bcc	conup
	rts

eet_spaties_op

	ldb	0,y
	cmpb	#space
	bne	spaties_opgegeten
	leay	1,y
	bra     eet_spaties_op

spaties_opgegeten

	rts

command_from_disk_jmp

	jsr	execute_from_disk
	jmp	crlf

parser	ldy	#line
	sty	interpreter_pointer
	jsr	eet_spaties_op
	sty	interpreter_pointer
	ldx	#commands_list
	lda	0,y
	bne	interprete_next
	rts

interprete_next

	lda	0,x
	beq	command_from_disk_jmp
	bmi	special
	jsr	conluc
	pshs	b
	cmpa	,s+
	bne	not_correct_statement
	leax	1,x
	leay	1,y
	bra	interprete_next

not_correct_statement

	leax	1,x
	lda	0,x
	bpl	not_correct_statement

not_correct_statement_direkt

	leax	3,x
	ldy	interpreter_pointer
	bra	interprete_next

special	anda	#$7f
	jsr	conluc
	pshs	b
	cmpa	,s+
	bne	not_correct_statement_direkt
	leax	1,x
	ldx	0,x

eat_spaces_end

	leay	1,y
	lda	0,y
	cmpa	#space
	beq	eat_spaces_end
	sty	interpreter_pointer
	jsr	0,x
	jmp	crlf

commands_list

	fcb	"?"+$80
	fdb	chelp
	fcb	"HELP",$80
	fdb	chelp
	fcb	"MONITOR",$80
	fdb	mon
	fcb	"DATE",$80
	fdb	pdate
	fcb	"SAVE",$a0
	fdb	save_file
	fcb	"L","S"+$80
	fdb	disp_dir
	fcb	"REN",$a0
	fdb	crename
	fcb	"RENAME",$a0
	fdb	crename
	fcb	"RM",$a0
	fdb	cdelete
	fcb	"REMOVE",$a0
	fdb	cdelete
	fcb	"TYPE",$a0
	fdb	ctype
	fcb	"HEXLOAD",$80
	fdb	cloadser1
	fdb	0,0

mon	jmp	monitor		;Warm return to monitor

cloadser1

	ldx	#inready
	jsr	ott
	jmp	transfer_in

inready	fcb	cr,lf,"Intel-hex transfer ready.",0

chelp	ldx	#cmdstxt
	jsr	ott
	ldx	#commands_list

helplp	lda	0,x
	beq	klmhlp
	bmi	nctxt
	jsr	ot
	leax	1,x
	bra	helplp

nctxt	anda	#$7f
	beq	nctxtn
	jsr	ot
nctxtn	leax	3,x
	jsr	crlf
	bra	helplp

klmhlp	rts

cmdstxt	fcb	"Available internal commands:",cr,lf,lf,0

cdelete

	jsr	make_internal_fcb1
	bcc	cdel1
	jmp	missing_filename
cdel1	ldx	#internal_fcb1
	jsr	delete_file
	cmpa	#file_not_found_error
	bne	cdel3
	jmp	exec_not_found
cdel3	rts

ctype	jsr	make_internal_fcb1
	bcc	ctyp1
	jmp	missing_filename
ctyp1	ldx	#internal_fcb1
	jsr	open_file
	beq	type_loop1
	jmp	exec_not_found

type_loop1

	ldx	#internal_fcb1
	ldd	#sectorbuffer
	std	FCB_DMA,x
	jsr	read
	cmpa	#EOF_reached_error
	beq	type_ready
	tsta
	beq	type_the_file
	jmp	failure

type_ready

	ldx	#internal_fcb1
	jsr	close_file
	jmp	crlf

type_the_file

	ldx	#sectorbuffer

type_loop2

	lda	0,x+
	cmpa	#eof
	beq	type_ready
	jsr	ot
	cmpa	#cr
	bne	tp1
	lda	#lf
	jsr	ot
tp1
	cmpx	#sectorbuffer+512
	bne	type_loop2
	bra	type_loop1

minl_token      fcb     2,"-L"

check_options

	pshs	x
	ldy	interpreter_pointer
	ldx	#minl_token
	jsr	compare_token
	sta	dflag
	sty	interpreter_pointer
	puls	x
	rts

display_d_filename

	pshs	x
	ldb	#16

d_file_name_loop

	lda	0,x
	pshs	b
	jsr	ot
	puls	b
        leax	1,x
	decb
        bne	d_file_name_loop
	lda	#space
	jsr	ot
	ldb	#3

d_file_name_loop1

	lda	0,x
	pshs	b
	jsr     ot
	puls	b
	leax	1,x
	decb
	bne	d_file_name_loop1
	lda	#space
	jsr	ot
	puls	x
	rts

get_file_lengths

	ldx	current_dir
	ldd	#0
	std	i_fcb_ptr3

get_file_length_loop

	lda	0,x
	cmpa	#$e5
	beq	ready_lengths
	tsta
	bmi	get_file_length_next
	ldd	DIR_length,x
	addd	i_fcb_ptr3
	std	i_fcb_ptr3

get_file_length_next

	exg	d,x
	addd	#dir_entry_len
	exg	d,x
	bra	get_file_length_loop

ready_lengths

	rts

disp_dir

	bsr	check_options
	clr	entry_counter
	lda	#3
	sta	d_ctr
	jsr	make_internal_fcb1
	bvs	kl_0
	bcc	kl1
kl_0	ldx	#internal_fcb1
	ldb	#19
kl0	lda	#'?'
	sta	0,x
	leax	1,x
	decb
	bne	kl0
kl1	lda	dflag
	bne	kl4

kl3	ldx	#dir_text
	jsr	ott
kl4	sty	interpreter_pointer
	ldx	#internal_fcb1
	lda	FCB_drive,x
	jsr	select_drive
	sty	FCB_drive_param_ptr,x
	jsr	search_in_directory
	pshs	y
	puls	x
	bcc	kl2
	ldx	#enftxt
	jmp	ott

kl2	pshs	x
	ldx	#internal_fcb1
	ldx	FCB_drive_param_ptr,x
	inc	file_opened,x
	ldx	4,x
	ldb	5,x
	lda	#512/32			;Per sector 512/32 entries
	mul
	subd	#1
	std	direntries
	puls	x

d_n_entry

	jsr	display_d_filename
	lda	dflag
	bne	kl5
	pshs	x
	ldd	DIR_length,x
	lslb
	rola
	andcc   #$fe
	ldx	#decimal_buffer
	std	1,x
	clr	0,x
	clr	3,x
	jsr	dec32_ot
	lda	#space
	jsr	ot
	puls	x
	lda	DIR_t_h,x
	jsr	byteot
	lda	#':'
	jsr	ot
	lda	DIR_t_m,x
	jsr	byteot
	lda	#':'
	jsr	ot
	lda	DIR_t_s,x
	jsr	byteot
	lda	#space
	jsr	ot
	lda	DIR_d_d,x
	jsr	byteot
	lda	#'-'
	jsr	ot
	lda	DIR_d_m,x
	jsr	byteot
	lda	#'-'
	jsr	ot
	ldx	DIR_d_y,x
	jsr	xot
	jsr	crlf
kl5	ldx	#internal_fcb1
	jsr	search_for_next_entry
	pshs	y
	puls	x
	bcs	klq
	lda	dflag
	beq	d_n_entry
	lda	d_ctr
	deca
	sta	d_ctr
	beq	klq1
	jmp	d_n_entry
klq1	lda	#3
	sta	d_ctr
	jsr	crlf
	bra	d_n_entry1
klq	lda	dflag
	beq	kl6
	pshs	x
	ldx	#internal_fcb1
	ldx	FCB_drive_param_ptr,x
	dec	file_opened,x
	puls	x
	rts

d_n_entry1

	jmp	d_n_entry
kl6	pshs	x
	ldx	#internal_fcb1
	ldx	FCB_drive_param_ptr,x
	dec	file_opened,x
	puls	x
	jsr	cnt_act_entries
	jsr	crlf
	jsr	get_file_lengths
	ldd	i_fcb_ptr3
	lslb
	rola
	ldx	#decimal_buffer
	std	1,x
	clr	0,x
	clr	3,x
	jsr	dec32_ot
	ldx	#dir_end_txt
	jsr	ott
	pshs	x
	ldx	#internal_fcb1
	ldx	FCB_drive_param_ptr,x
	ldx	4,x
	ldd	1,x
	subd	i_fcb_ptr3
	subd	#dir_len+fat_len
	lslb
	rola
	ldx	#decimal_buffer
	std	1,x
	clr	0,x
	clr	3,x
	jsr     dec32_ot
	puls	x
	jsr	ott
	ldb	entry_counter
	clra
	exg	d,x
	jsr	decimal_ot
	ldx	#number_entrytxt
	jsr	ott
	ldx	direntries
	jsr	decimal_ot
	jmp	crlf

number_entrytxt

	fcb	" directory entries used of",0

cnt_act_entries

	pshs	d,x,y
	ldx	#dir_buffer1
cntlp0	lda	0,x
	cmpa	#$e5
	beq	cnt_ready
	tsta
	bmi	notcnt
	inc	entry_counter
notcnt	exg	d,x
	addd	#32
	exg	d,x
	bra	cntlp0

cnt_ready

	puls	d,x,y
	rts

parameter_error

	fcb	"Illegal parameter.",cr,lf,0

illegal_parameter

	ldx	#parameter_error
	bra     illpar1

missing_parameter

        ldx     #parameter_missing
illpar1 jsr     ott
        jmp     dos_reentry

parameter_missing

	fcb	"Missing parameter.",cr,lf,0

save_file

	jsr     make_internal_fcb1
	bcc	csv00
	jmp	missing_filename
csv00	jsr	check_fcb
	bcc	csv01
	jmp	illegal_parameter
csv01	jsr	eet_spaties_op
	lda	0,y
	beq	missing_parameter
	jsr	decimal_in
	bcc	csv02
	rts
csv02	cmpa	#101			;Niet meer dan 100 sectoren toestaan
	bcs	csv001			;Anders lees je het I/O gebied ($CF00)
	ldx	#teveeltxt
	jmp	ott
csv001	sta	decimal_buffer

save_loop2

	ldx	#internal_fcb1
	ldd	#mtpa
	std	FCB_DMA,x
	jsr	create_file
	cmpa	#file_already_exist_err
	beq	delete_to_save
	tsta
	beq	csv03
	jmp	dir_full
csv03	lda	decimal_buffer
	beq	save_empty_file

save_loop1

	ldx	#internal_fcb1
        jsr	write
	beq	write_is_ok
	cmpa	#DISK_full_error
        bne	csv04
	jmp	DISK_full
csv04	jmp	failure

write_is_ok

	dec	decimal_buffer
	bne	save_loop1

save_empty_file

	ldx	#internal_fcb1
	jmp	close_file

delete_to_save

        ldx	#internal_fcb1
	jsr	delete_file
	bra	save_loop2

teveeltxt

	fcb	"No more then 100 sectors allowed!",0

check_fcb

	pshs	x
	ldx	#internal_fcb1
	clrb

check_fcb_next

	lda	0,x
	cmpa	#'?'
	bne	cfbn1
	incb
cfbn1	leax	1,x
	cmpx	#internal_fcb1+19
	bne	check_fcb_next
	puls	x
	tstb
	bne	cfbn2
	andcc	#$fe
	rts
cfbn2	orcc	#1
	rts

crename	jsr	make_internal_fcb1
	bcc	cren1
	jmp	missing_filename
cren1	jsr	eet_spaties_op
	jsr	make_internal_fcb2
	bcc	cren2
	jmp	missing_filename
cren2	ldx	#internal_fcb1
	jsr	rename_file
	cmpa	#file_already_exist_err
	beq	overwritten
	cmpa	#file_not_found_error
	bne	cren3
	jmp	exec_not_found
cren3	cmpa	#BDOS_function_error
	bne	same
	jmp	illegal_parameter
same	rts

overwritten

	ldx	#overwr
	jmp	ott

overwr	fcb	"File already exists.",0

execute_from_disk

	jsr	make_internal_fcb1
	bvc	continue_with_execute
	ldx	#internal_fcb1
	lda	FCB_drive,x
	sta	current_drive
	jmp	select_drive

continue_with_execute

	sty	interpreter_pointer
	jsr	check_fcb
	bcc	cwe01
	jmp	illegal_parameter
cwe01	ldx	#internal_fcb1
	lda	#'E'
	sta	16,x
	lda	#'X'
	sta	17,x
	lda	#'E'
	sta	18,x
	ldd	#mtpa
	std	FCB_dma,x
	jsr	open_file
	cmpa	#file_not_found_error
	beq	exec_not_found
	ldd	DIR_length,y
	tfr	b,a
	clrb
	addd	#mtpa
        cmpd	end_of_ram
	beq	load_executable_loop
	bcc	to_long

load_executable_loop

	ldx	#internal_fcb1
	jsr	read
	cmpa	#EOF_reached_error
	beq	load_ready
	tsta
	bne	failure
	bra	load_executable_loop
to_long	ldx	#file_to_longt
	jsr	ott
	ldx	#internal_fcb1
	jmp	close_file

load_ready

	ldx	#internal_fcb1
	jsr	close_file
	ldy	interpreter_pointer
	jsr	eet_spaties_op
	sty	interpreter_pointer
	exg	d,y
	exg	d,x
	jmp	mtpa

missing_filename

	ldx	#miss_txt
	bra	fail1

exec_not_found
disp_file_not_found

	ldx	#enftxt
	bra	fail1

DISK_full

	ldx	#DISK_full_txt
	bra	fail1

failure

	ldx	#err01t
fail1	jsr	ott
	ldx	#internal_fcb1
	jmp	close_file

enftxt		fcb	"File not found.",0
err01t		fcb	"Disk I/O failed.",0
miss_txt	fcb	"Missing filename.",0
file_to_longt	fcb	"File to long.",0

missing_decimal

	fcb	"Decimal number expected.",0

decimal_missing

	ldx	#missing_decimal
	jsr	ott
	orcc	#$1
	rts

decimal_in

	lda	0,y
	cmpa	#'0'
	bcs	decimal_missing
	cmpa	#$3a
	bcc	decimal_missing
	ldd	#0
	std	decimal_buffer

decimal_in_loop

	lda	decimal_buffer
	bne	error_dec_in
	lda	0,y
	beq	decimal_in_ok
	suba	#'0'
	bcs	decimal_in_ok
	cmpa	#10
	bcc	decimal_in_ok
	pshs	a,b
	lda	#10
	ldb	decimal_buffer+1
	mul
	std	decimal_buffer
	puls	a,b
	tfr	a,b
	clra
	addd	decimal_buffer
	std	decimal_buffer
	leay	1,y
	bra	decimal_in_loop

decimal_in_ok

	lda	decimal_buffer+1
	andcc	#$fe
	rts

error_dec_in

	ldx     #dec_ovf
	jsr     ott
	clra
        orcc	#$1
	rts

dec_ovf

	fcb	"Decimal number must be in [0-255].",0

dir_text

	fcb	cr,lf,"Directory of CF-card",cr,lf,lf,0

dir_end_txt

	fcb	" byte(s) used in files.",cr,lf,0
	fcb	" byte(s) free on disk.",cr,lf,0

