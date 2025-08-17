ZERO_PAGE_PROCESSOR_PORT_DDR        = $0
ZERO_PAGE_PROCESSORT_PORT_DDR_DEFAULT   = %00101111

; $A000-$BFFF = BASIC
; $E000-$FFFF = Kernal
; $D000-$DFFF = I/O
;     $A000 $D000     $D000 $E000
;     BASIC CHAR ROM  I/O   KERNAL
; %000 -  N   N       N     N       0 - all ram
; %001 -  N   Y       N     N       1
; %010 -  N   Y       N     Y       2
; %011 -  Y   Y       N     Y       3 - char,basic,kernal
; %100 -  N   N       N     N       4 - all ram
; %101 -  N   N       Y     N       5 - ram,io
; %110 -  N   N       Y     Y       6 - kernal, io
; %111 -  Y   N       Y     Y       7 - basic, kernal,io
ZERO_PAGE_PROCESSOR_PORT          = $1

ZERO_PAGE_PROCESSOR_PORT_DEFAULT            = %00110111;    7
ZERO_PAGE_PROCESSOR_PORT_ALL_RAM            = %00100000;    0
ZERO_PAGE_PROCESSOR_PORT_ALL_RAM_WITH_IO    = %00100101;    5
ZERO_PAGE_PROCESSOR_PORT_KERNAL_WITH_IO     = %00100110;    6
ZERO_PAGE_PROCESSOR_PORT_CHAR_BASIC_KERNAL  = %00110011;    3

IRQ_SERVICE_ROUTINE             = $314
BRK_SERVICE_ROUTINE             = $316
NMI_SERVICE_ROUTINE             = $318

KERNAL_IRQ_SERVICE_ROUTINE          = $fffe
