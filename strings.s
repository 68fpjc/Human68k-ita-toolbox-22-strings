* strings - extract strings from binary files
*
* Itagaki Fumihiko 26-Feb-93  Create.
* 1.0
* Itagaki Fumihiko 04-Jan-94  �œK���ƍ�����
* Itagaki Fumihiko 04-Jan-94  �g���V�t�gJIS��������
* Itagaki Fumihiko 06-Jan-94  count �𕶎����Ƃ���̂���߂ăo�C�g���Ƃ���
* Itagaki Fumihiko 06-Jan-94  �A���S���Y����啝�ɕύX
* Itagaki Fumihiko 06-Jan-94  ���Ƃ��� -s�w�莞�A92 83 80 42 43 44 0D 0A ���X�L���������
*                             v1.0 �ł́C9283(��) �̎��� 80 �� fail ���āC�����܂ł��̂āC
*                             ���ɂ� 42 ����X�L�������Ă����D
*                             ������C83 ����X�L�������Ȃ����悤�ɏC�����C
*                             8380(��)42(A)43(B)44(C) �𕶎���Ƃ��Č��m����悤�ɂ����D
* Itagaki Fumihiko 03-Apr-94  UJIS�̃R�[�h�Z�b�g2�i1�o�C�g�J�i�j�ƃR�[�h�Z�b�g3�i�O���j��ǉ�
* Itagaki Fumihiko 17-Sep-94  -t�I�v�V������ǉ�
* Itagaki Fumihiko 17-Sep-94  -n�I�v�V������ǉ�
* 1.1
* Itagaki Fumihiko 30-Sep-94  �o�͂��[���łȂ��Ɛ���ɓ��삵�Ȃ��s��i1.1�ł̃G���o�O�j���C��
* 1.2
*
* Usage: strings [-asuqvo] [-t {doxX}] [-n <N>] [-<N>] [--] [<�t�@�C��>] ...

.include doscall.h
.include chrcode.h

.xref DecodeHUPAIR
.xref issjis
.xref isdigit
.xref atou
.xref utoa
.xref utoao
.xref utoaxl
.xref utoaxu
.xref strlen
.xref strfor1
.xref memmovi
.xref printfi
.xref strip_excessive_slashes

STACKSIZE	equ	2048

READ_MAX_TO_OUTPUT_TO_COOKED	equ	8192
INPBUFSIZE_MIN	equ	258
OUTBUF_SIZE	equ	8192

X_HEADER_SIZE	equ	64

DEFAULT_MINIMUM_LENGTH	equ	4

MAX_LETTER_SIZE	equ	3

FLAG_a		equ	0	*  -a
FLAG_o		equ	1	*  -o
FLAG_s		equ	2	*  -s
FLAG_u		equ	3	*  -u
FLAG_q		equ	4	*  -q
FLAG_v		equ	5	*  -v
FLAG_eof	equ	6

.text

start:
		bra.s	start1
		dc.b	'#HUPAIR',0
start1:
		lea	bss_top(pc),a6
		lea	stack_bottom(a6),a7		*  A7 := �X�^�b�N�̒�
		lea	$10(a0),a0			*  A0 : PDB�A�h���X
		move.l	a7,d0
		sub.l	a0,d0
		move.l	d0,-(a7)
		move.l	a0,-(a7)
		DOS	_SETBLOCK
		addq.l	#8,a7
	*
		move.l	#-1,stdin(a6)
	*
	*  �������ъi�[�G���A���m�ۂ���
	*
		lea	1(a2),a0			*  A0 := �R�}���h���C���̕�����̐擪�A�h���X
		bsr	strlen				*  D0.L := �R�}���h���C���̕�����̒���
		addq.l	#1,d0
		bsr	malloc
		bmi	insufficient_memory

		movea.l	d0,a1				*  A1 := �������ъi�[�G���A�̐擪�A�h���X
	*
	*  �������f�R�[�h���C���߂���
	*
		moveq	#0,d6				*  D6.W : �G���[�E�R�[�h
		bsr	DecodeHUPAIR			*  �������f�R�[�h����
		movea.l	a1,a0				*  A0 : �����|�C���^
		move.l	d0,d7				*  D7.L : �����J�E���^
		moveq	#0,d5				*  D5.B : �t���O
		move.l	#DEFAULT_MINIMUM_LENGTH,minimum_length(a6)
		move.l	#DEFAULT_MINIMUM_LENGTH+MAX_LETTER_SIZE-1,minimum_refill_length(a6)
decode_opt_loop1:
		tst.l	d7
		beq	decode_opt_done

		cmpi.b	#'-',(a0)
		bne	decode_opt_done

		tst.b	1(a0)
		beq	decode_opt_done

		subq.l	#1,d7
		addq.l	#1,a0
		move.b	(a0),d0
		bsr	isdigit
		beq	decode_minimum_length

		addq.l	#1,a0
		cmp.b	#'-',d0
		bne	decode_opt_loop2

		tst.b	(a0)+
		beq	decode_opt_done

		subq.l	#1,a0
decode_opt_loop2:
		cmp.b	#'a',d0
		beq	option_a

		cmp.b	#'o',d0
		beq	option_o

		cmp.b	#'s',d0
		beq	option_s

		cmp.b	#'u',d0
		beq	option_u

		cmp.b	#'q',d0
		beq	option_q

		cmp.b	#'v',d0
		beq	option_v

		cmp.b	#'t',d0
		beq	option_t

		cmp.b	#'n',d0
		beq	option_n

		moveq	#1,d1
		tst.b	(a0)
		beq	bad_option_1

		bsr	issjis
		bne	bad_option_1

		moveq	#2,d1
bad_option_1:
		move.l	d1,-(a7)
		pea	-1(a0)
		move.w	#2,-(a7)
		lea	msg_bad_option(pc),a0
		bsr	werror_myname_and_msg
		DOS	_WRITE
		lea	10(a7),a7
usage:
		lea	msg_usage(pc),a0
		bsr	werror
		moveq	#1,d6
		bra	exit_program

option_t:
		bsr	optarg
		move.b	(a0)+,d0
		tst.b	(a0)
		bne	bad_arg

		lea	utoao(pc),a1
		cmp.b	#'o',d0
		beq	set_format

		lea	utoa(pc),a1
		cmp.b	#'d',d0
		beq	set_format

		lea	utoaxl(pc),a1
		cmp.b	#'x',d0
		beq	set_format

		lea	utoaxu(pc),a1
		cmp.b	#'X',d0
		beq	set_format
bad_arg:
		lea	msg_bad_arg(pc),a0
werror_usage:
		bsr	werror_myname_and_msg
		bra	usage

option_o:
		lea	utoa(pc),a1
set_format:
		move.l	a1,format(a6)
		bset	#FLAG_o,d5
		bra	set_option_done

option_s:
		bset	#FLAG_s,d5
		bclr	#FLAG_u,d5
		bra	set_option_done

option_u:
		bset	#FLAG_u,d5
		bclr	#FLAG_s,d5
		bra	set_option_done

option_q:
		bset	#FLAG_q,d5
		bclr	#FLAG_v,d5
		bra	set_option_done

option_v:
		bset	#FLAG_v,d5
		bclr	#FLAG_q,d5
		bra	set_option_done

option_a:
		moveq	#FLAG_a,d1
set_option:
		bset	d1,d5
set_option_done:
		move.b	(a0)+,d0
		bne	decode_opt_loop2
		bra	decode_opt_loop1

option_n:
		bsr	optarg
decode_minimum_length:
		bsr	atou
		bne	bad_arg

		tst.b	(a0)+
		bne	bad_arg

		move.l	d1,minimum_length(a6)
		beq	bad_arg

		addq.l	#MAX_LETTER_SIZE-1,d1
		bcs	bad_arg

		move.l	d1,minimum_refill_length(a6)
		bra	decode_opt_loop1

optarg:
		tst.b	(a0)
		bne	optarg_ok

		subq.l	#1,d7
		bcs	too_few_args

		addq.l	#1,a0
optarg_ok:
		rts

too_few_args:
		lea	msg_too_few_args(pc),a0
		bra	werror_usage

decode_opt_done:
	*
	*  ���o�̓o�b�t�@���m�ۂ���
	*
		moveq	#1,d0				*  �o�͂�
		bsr	is_chrdev			*  �L�����N�^�E�f�o�C�X���H
		seq	do_buffering
		bne	outbuf_ok			*  -- �L�����N�^�E�f�o�C�X�ł���

		*  �o�̓o�b�t�@���m�ۂ���
		move.l	#OUTBUF_SIZE,d0
		move.l	d0,outbuf_free
		bsr	malloc
		bmi	insufficient_memory

		move.l	d0,outbuf_top
		move.l	d0,outbuf_ptr
outbuf_ok:
		*  ���̓o�b�t�@���m�ۂ���
		move.l	#$00ffffff,d0
		bsr	malloc
		sub.l	#$81000000,d0
		cmp.l	#INPBUFSIZE_MIN,d0
		blo	insufficient_memory

		cmp.l	#X_HEADER_SIZE,d0
		blo	insufficient_memory

		cmp.l	#MAX_LETTER_SIZE,d0
		blo	insufficient_memory

		cmp.l	minimum_refill_length(a6),d0
		blo	insufficient_memory

		move.l	d0,inpbuf_size(a6)
		bsr	malloc
		bmi	insufficient_memory
inpbuf_ok:
		move.l	d0,inpbuf_top(a6)

		lea	msg_header2(pc),a1
		st	show_header(a6)
		btst	#FLAG_v,d5
		bne	do_files

		sf	show_header(a6)
		btst	#FLAG_q,d5
		bne	do_files

		cmp.l	#1,d7
		shi	show_header(a6)
do_files:
	*
	*  �W�����͂�؂�ւ���
	*
		clr.w	-(a7)				*  �W�����͂�
		DOS	_DUP				*  ���������n���h��������͂��C
		addq.l	#2,a7
		move.l	d0,stdin(a6)
		bmi	start_do_files

		clr.w	-(a7)
		DOS	_CLOSE				*  �W�����͂̓N���[�Y����D
		addq.l	#2,a7				*  �������Ȃ��� ^C �� ^S �������Ȃ�
start_do_files:
	*
	*  �J�n
	*
		tst.l	d7
		beq	do_stdin
for_file_loop:
		subq.l	#1,d7
		movea.l	a0,a2
		bsr	strfor1
		exg	a0,a2
		move.l	a2,-(a7)
		cmpi.b	#'-',(a0)
		bne	do_file

		tst.b	1(a0)
		bne	do_file
do_stdin:
		lea	msg_stdin(pc),a0
		move.l	stdin(a6),d0
		bmi	open_fail

		bsr	strings_one
		bra	for_file_continue

do_file:
		bsr	strip_excessive_slashes
		clr.w	-(a7)
		move.l	a0,-(a7)
		DOS	_OPEN
		addq.l	#6,a7
		tst.l	d0
		bmi	open_fail

		bsr	strings_one
		move.w	handle(a6),-(a7)
		DOS	_CLOSE
		addq.l	#2,a7
for_file_continue:
		movea.l	(a7)+,a0
		tst.l	d7
		beq	all_done

		lea	msg_header1(pc),a1
		bra	for_file_loop

all_done:
exit_program:
		move.l	stdin(a6),d0
		bmi	exit_program_1

		clr.w	-(a7)				*  �W�����͂�
		move.w	d0,-(a7)			*  ����
		DOS	_DUP2				*  �߂��D
		DOS	_CLOSE				*  �����̓N���[�Y����D
exit_program_1:
		move.w	d6,-(a7)
		DOS	_EXIT2

open_fail:
		lea	msg_open_fail(pc),a2
		bra	werror_exit_2
****************************************************************
* strings_one
****************************************************************
strings_one:
		move.l	a0,name(a6)
		move.w	d0,handle(a6)

		tst.b	show_header(a6)
		beq	strings_one_1

		movea.l	a1,a0
		bsr	puts
		movea.l	name(a6),a0
		bsr	puts
		lea	msg_header3(pc),a0
		bsr	puts
strings_one_1:
		*  �擪�ɃV�[�N���Ă���
		*  ���łɁC�V�[�N�\���ǂ������ׂ�
		st	d1
		moveq	#1,d0
		bsr	seek_absolute
		subq.l	#1,d0
		beq	strings_one_2

		sf	d1
strings_one_2:
		moveq	#0,d0
		bsr	seek_absolute
		beq	strings_one_3

		sf	d1
strings_one_3:
		bclr	#FLAG_eof,d5
		move.l	#-1,scan_size(a6)
		clr.l	scan_offset(a6)
		bsr	reset_inpbuf
		btst	#FLAG_a,d5
		bne	strings_one_loop

		move.l	#X_HEADER_SIZE,d0		*  .X�^�C�v�t�@�C���̃w�b�_�̒�������
		bsr	read				*  �ǂݍ����
		*  .X�^�C�v�t�@�C�����ǂ����𒲂ׂ�
		cmp.l	#X_HEADER_SIZE,d0
		blo	strings_one_loop

		cmpi.b	#'H',(a2)
		bne	strings_one_loop

		cmpi.b	#'U',1(a2)
		bne	strings_one_loop

		*  .X�^�C�v�t�@�C�� -- data section �������X�L��������
		bsr	reset_inpbuf
		move.l	$10(a2),scan_size(a6)
		move.l	d0,scan_offset(a6)
		move.l	$0c(a2),d0
		add.l	d0,scan_offset(a6)
		tst.b	d1
		beq	skip_text_section

		bsr	seek_relative
		cmp.l	scan_offset(a6),d0
		bne	strings_one_done
		bra	strings_one_loop

skip_text_section:
		move.l	d0,d1
skip_text_section_loop:
		move.l	inpbuf_size(a6),d0
		cmp.l	d1,d0
		bls	skip_text_section_1

		move.l	d1,d0
skip_text_section_1:
		move.l	d0,-(a7)
		move.l	inpbuf_top(a6),-(a7)
		move.w	handle(a6),-(a7)
		DOS	_READ
		lea	10(a7),a7
		tst.l	d0
		bmi	strings_one_done
		beq	strings_one_done

		sub.l	d0,d1
		bne	skip_text_section_loop
strings_one_loop:
		*
		*  �X�L����
		*
		move.l	minimum_refill_length(a6),d1
		bsr	refill_buffer
		move.l	minimum_length(a6),d4
		cmp.l	d4,d2
		blo	strings_one_done

		movea.l	a2,a3
check_buffer_loop1:
		tst.l	d4
		beq	check_buffer_ok

		move.b	(a2)+,d0
		subq.l	#1,d4
		bsr	isstr1
		beq	check_buffer_loop1

		movea.l	a2,a4
		btst	#FLAG_s,d5
		bne	check_buffer_2

		btst	#FLAG_u,d5
		bne	check_buffer_2
check_buffer_fail:
		movea.l	a4,a2
		move.l	a4,d0
		sub.l	a3,d0
		add.l	d0,scan_offset(a6)
		sub.l	d0,d2
		bra	strings_one_loop

check_buffer_2:
		subq.l	#1,a2
		addq.l	#1,d4
		move.l	a3,d3
		add.l	d2,d3
		sub.l	a2,d3
check_buffer_loop2:
		move.l	d3,d1
		bsr	isstr2
		beq	check_buffer_fail

		adda.l	d1,a2
		sub.l	d1,d3
		sub.l	d1,d4
		bhi	check_buffer_loop2
check_buffer_ok:
		exg	a2,a3
		move.l	a3,d1
		sub.l	a2,d1
		btst	#FLAG_o,d5
		beq	strings_one_output_string

		movem.l	d1-d2/a2,-(a7)
		move.l	scan_offset(a6),d0
		moveq	#0,d1				*  �E�l��
		moveq	#' ',d2				*  pad����
		moveq	#7,d3				*  �ŏ��t�B�[���h��
		moveq	#1,d4				*  �ŏ��ϊ�����
		movea.l	format(a6),a0
		lea	putc(pc),a1			*  output function
		suba.l	a2,a2				*  prefix string
		bsr	printfi
		movem.l	(a7)+,d1-d2/a2
		moveq	#' ',d0
		bsr	putc
strings_one_output_string:
		bsr	put_d1
strings_one_output_remainder:
		moveq	#MAX_LETTER_SIZE,d1
		bsr	refill_buffer
		move.l	d2,d1
		bsr	isstr2
		beq	strings_one_output_done

		bsr	put_d1
		bra	strings_one_output_remainder

strings_one_output_done:
		moveq	#CR,d0
		bsr	putc
		moveq	#LF,d0
		bsr	putc
		bra	strings_one_loop

strings_one_done:
flush_outbuf:
		move.l	d0,-(a7)
		tst.b	do_buffering
		beq	flush_done

		move.l	#OUTBUF_SIZE,d0
		sub.l	outbuf_free,d0
		beq	flush_done

		move.l	d0,-(a7)
		move.l	outbuf_top,-(a7)
		move.w	#1,-(a7)
		DOS	_WRITE
		lea	10(a7),a7
		tst.l	d0
		bmi	write_fail

		cmp.l	-4(a7),d0
		blo	write_fail

		move.l	outbuf_top,outbuf_ptr
		move.l	#OUTBUF_SIZE,outbuf_free
flush_done:
		move.l	(a7)+,d0
		rts
*****************************************************************
isstr1:
		cmp.b	#HT,d0
		beq	isstr1_return

		cmp.b	#$20,d0
		blo	isstr1_return

		cmp.b	#$7e,d0
		bhi	isstr1_return

		cmp.b	d0,d0
isstr1_return:
		rts
*****************************************************************
isstr2:
		subq.l	#1,d1
		bcs	isstr2_0

		move.b	(a2),d0
		bsr	isstr1
		beq	isstr2_1

		btst	#FLAG_s,d5
		bne	isstr2_sjis

		btst	#FLAG_u,d5
		beq	isstr2_0

		subq.l	#1,d1
		bcs	isstr2_0

		cmp.b	#$8e,d0
		beq	isstr2_euc8e

		cmp.b	#$8f,d0
		beq	isstr2_euc8f

		bsr	is_a1fe
		bne	isstr2_0

		move.b	1(a2),d0
		bsr	is_a1fe
		bne	isstr2_0
		bra	isstr2_2

isstr2_euc8e:
		move.b	1(a2),d0
		cmp.b	#$a1,d0
		blo	isstr2_0

		cmp.b	#$df,d0
		bhi	isstr2_0
		bra	isstr2_2

isstr2_euc8f:
		subq.l	#1,d1
		bcs	isstr2_0

		move.b	1(a2),d0
		bsr	is_a1fe
		bne	isstr2_0

		move.b	2(a2),d0
		bsr	is_a1fe
		bne	isstr2_0
isstr2_3:
		moveq	#3,d1
		rts

isstr2_sjis:
		cmp.b	#$81,d0
		blo	isstr2_0

		cmp.b	#$9f,d0
		bls	isstr2_sjis2

		cmp.b	#$a1,d0
		blo	isstr2_0

		cmp.b	#$df,d0
		bls	isstr2_1

		cmp.b	#$fc,d0
		bhi	isstr2_0
isstr2_sjis2:
		subq.l	#1,d1
		bcs	isstr2_0

		move.b	1(a2),d0
		cmp.b	#$40,d0
		blo	isstr2_0

		cmp.b	#$7f,d0
		beq	isstr2_0

		cmp.b	#$fc,d0
		bhi	isstr2_0
isstr2_2:
		moveq	#2,d1
		rts

isstr2_1:
		moveq	#1,d1
		rts

isstr2_0:
		moveq	#0,d1
		rts
*****************************************************************
is_a1fe:
		cmp.b	#$a1,d0
		blo	return			* ZF=0

		cmp.b	#$fe,d0
		bhi	return			* ZF=0
true:
		cmp.b	d0,d0			* ZF=1
return:
		rts
*****************************************************************
reset_inpbuf:
		movea.l	inpbuf_top(a6),a2
		moveq	#0,d2
		rts
*****************************************************************
* refill_buffer
*
* CALL
*      A2     �f�[�^�擪�A�h���X
*      D1.L   �K�v�Ƃ���o�C�g��
*
* RETURN
*      A2     �V�����f�[�^�擪�A�h���X
*
* DESCRIPTION
*      D2 �� D1 �����Ȃ�f�[�^��ǂݑ���
*****************************************************************
refill_buffer:
		cmp.l	d1,d2
		bhs	refill_buffer_return

		move.l	inpbuf_top(a6),d0
		add.l	inpbuf_size(a6),d0
		sub.l	a2,d0				*  D0.L : D2 + �󂫗e��
		cmp.l	d1,d0
		bhs	refill_buffer_read

		movea.l	a2,a1
		movea.l	inpbuf_top(a6),a0
		movea.l	a0,a2
		move.l	d2,d0
		bsr	memmovi
		move.l	inpbuf_size(a6),d0
refill_buffer_read:
		sub.l	d2,d0				*  D0.L : �󂫗e��
		bsr	read
refill_buffer_return:
		rts
*****************************************************************
* read
* 
* CALL
*      A2     �f�[�^�擪�A�h���X
*      D0.L   �ǂݍ��ރo�C�g��
*
* RETURN
*      D0.L   �ǂݍ��񂾃o�C�g��
*      D2.L   RETURN �� D0.L �����Z�����
*
* DESCRIPTION
*      A2 + D2 �A�h���X�� D0.L �o�C�g�ǂݍ���
*****************************************************************
read:
		btst	#FLAG_eof,d5
		bne	read_eof

		cmp.l	scan_size(a6),d0
		bls	read_1

		move.l	scan_size(a6),d0
		beq	read_eof
read_1:
		move.l	d0,-(a7)
		pea	(a2,d2.l)
		move.w	handle(a6),-(a7)
		DOS	_READ
		lea	10(a7),a7
		tst.l	d0
		bmi	read_fail
		beq	read_eof

		sub.l	d0,scan_size(a6)
		add.l	d0,d2
		rts

read_eof:
		bset	#FLAG_eof,d5
		moveq	#0,d0
		rts

read_fail:
		bsr	flush_outbuf
		movea.l	name(a6),a0
		lea	msg_read_fail(pc),a2
werror_exit_2:
		bsr	werror_myname_and_msg
		movea.l	a2,a0
		bsr	werror
		moveq	#2,d6
		bra	exit_program
*****************************************************************
putc:
		tst.b	do_buffering
		bne	putc_do_buffering

		move.l	d0,-(a7)

		move.w	d0,-(a7)
		move.l	#1,-(a7)
		pea	5(a7)
		move.w	#1,-(a7)
		DOS	_WRITE
		lea	12(a7),a7
		cmp.l	#1,d0
		bne	write_fail

		move.l	(a7)+,d0
		bra	putc_done

putc_do_buffering:
		tst.l	outbuf_free
		bne	putc_do_buffering_1

		bsr	flush_outbuf
putc_do_buffering_1:
		move.l	a0,-(a7)
		movea.l	outbuf_ptr,a0
		move.b	d0,(a0)+
		move.l	a0,outbuf_ptr
		movea.l	(a7)+,a0
		subq.l	#1,outbuf_free
putc_done:
puts_done:
		rts
*****************************************************************
puts:
		move.b	(a0)+,d0
		beq	puts_done

		bsr	putc
		bra	puts
*****************************************************************
put_d1:
		add.l	d1,scan_offset(a6)
		sub.l	d1,d2
put_d1_loop:
		move.b	(a2)+,d0
		bsr	putc
		subq.l	#1,d1
		bne	put_d1_loop
		rts
*****************************************************************
write_fail:
		lea	msg_write_fail(pc),a0
		bsr	werror
		bra	exit_3
*****************************************************************
insufficient_memory:
		lea	msg_no_memory(pc),a0
		bsr	werror_myname_and_msg
exit_3:
		moveq	#3,d6
		bra	exit_program
*****************************************************************
werror_myname:
		move.l	a0,-(a7)
		lea	msg_myname(pc),a0
		bsr	werror
		movea.l	(a7)+,a0
		rts
*****************************************************************
werror_myname_and_msg:
		bsr	werror_myname
werror:
		movem.l	d0/a1,-(a7)
		movea.l	a0,a1
werror_1:
		tst.b	(a1)+
		bne	werror_1

		subq.l	#1,a1
		suba.l	a0,a1
		move.l	a1,-(a7)
		move.l	a0,-(a7)
		move.w	#2,-(a7)
		DOS	_WRITE
		lea	10(a7),a7
		movem.l	(a7)+,d0/a1
		rts
*****************************************************************
seek_relative:
		move.w	#1,-(a7)
		bra	seeksub
*****************************************************************
seek_absolute:
		clr.w	-(a7)
seeksub:
		move.l	d0,-(a7)
		move.w	handle(a6),-(a7)
		DOS	_SEEK
		addq.l	#8,a7
		tst.l	d0
		rts
*****************************************************************
is_chrdev:
		move.w	d0,-(a7)
		clr.w	-(a7)
		DOS	_IOCTRL
		addq.l	#4,a7
		tst.l	d0
		bpl	is_chrdev_1

		moveq	#0,d0
is_chrdev_1:
		btst	#7,d0
		rts
*****************************************************************
malloc:
		move.l	d0,-(a7)
		DOS	_MALLOC
		addq.l	#4,a7
		tst.l	d0
		rts
*****************************************************************
.data

	dc.b	0
	dc.b	'## strings 1.2 ##  Copyright(C)1993-94 by Itagaki Fumihiko',0

msg_myname:		dc.b	'strings: ',0
msg_no_memory:		dc.b	'������������܂���',CR,LF,0
msg_open_fail:		dc.b	': �I�[�v���ł��܂���',CR,LF,0
msg_read_fail:		dc.b	': ���̓G���[',CR,LF,0
msg_write_fail:		dc.b	'strings: �o�̓G���[',CR,LF,0
msg_stdin:		dc.b	'- �W������ -',0
msg_bad_option:		dc.b	'�s���ȃI�v�V���� -- ',0
msg_too_few_args:	dc.b	'����������܂���',0
msg_bad_arg:		dc.b	'�������s���ł�',0
msg_header1:		dc.b	CR,LF
msg_header2:		dc.b	'==> ',0
msg_header3:		dc.b	' <=='
msg_newline:		dc.b	CR,LF,0
msg_usage:		dc.b	CR,LF,'�g�p�@:  strings [-asuqvo] [-t {doxX}] [-n <N>] [-<N>] [--] [<�t�@�C��>] ...',CR,LF,0
*****************************************************************
.offset 0
stdin:			ds.l	1
inpbuf_top:		ds.l	1
inpbuf_size:		ds.l	1
minimum_length:		ds.l	1
minimum_refill_length:	ds.l	1
scan_offset:		ds.l	1
scan_size:		ds.l	1
format:			ds.l	1
name:			ds.l	1
handle:			ds.w	1
show_header:		ds.b	1
.even
			ds.b	STACKSIZE
.even
stack_bottom:

.bss
outbuf_top:		ds.l	1
outbuf_ptr:		ds.l	1
outbuf_free:		ds.l	1
do_buffering:		ds.b	1
.even
bss_top:
		ds.b	stack_bottom
*****************************************************************

.end start
