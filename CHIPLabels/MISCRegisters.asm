
; $A000-$BFFF = BASIC
; $E000-$FFFF = Kernal
; $D000-$DFFF = I/O
;     $A000 $D000     $D000 $E000
;     BASIC CHAR ROM  I/O   KERNAL
; B012
; %000 -  N   N       N     N       0 - all ram
; %001 -  N   Y       N     N       1
; %010 -  N   Y       N     Y       2
; %011 -  Y   Y       N     Y       3 - char,basic,kernal
; %100 -  N   N       N     N       4 - all ram
; %101 -  N   N       Y     N       5 - ram,io
; %110 -  N   N       Y     Y       6 - kernal, io
; %111 -  Y   N       Y     Y       7 - basic, kernal,io

; combinations =
;#		basic	kernal	i/o	Character	
;0	:	[False,	False,	False,	False],			# 000
;1	:	[False,	False,	False,	True],			# 001
;2	:	[False,	True,	False,	True],			# 010
;3	:	[True,	True,	False,	True],			# 011
;4	:	[False,	False,	False,	False],			# 100
;5	:	[False,	False,	True,	False],			# 101 Invalid / Undocumented
;6	:	[False,	True,	True,	False],			# 110
;7	:	[True,	True,	True,	False],			# 111
						
ZERO_PAGE_PROCESSOR_PORT          = $1


IRQ_SERVICE_ROUTINE             = $314
BRK_SERVICE_ROUTINE             = $316
NMI_SERVICE_ROUTINE             = $318

NMI_ADDRESS          		= $fffa
COLD_RESET_ADDRESS          	= $fffc
KERNAL_IRQ_SERVICE_ROUTINE      = $fffe
