	jmp	initdos

auto_start_flag		fcb	0	;This must be in RAM
line			rmb	81

;memory locations of variables and buffers used in dos09

current_fat		rmb	2	;SAT in use
current_dir		rmb	2	;DIR in use
sect_ctr1		rmb	1
sectorbuffer		rmb	512     ;Sectorbuffer
stack_pointer		rmb	2
interpreter_pointer	rmb	2
ctr			rmb	1
temp_t			rmb	2
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

decimal_fstring		rmb	12
decimal_string		rmb	12


