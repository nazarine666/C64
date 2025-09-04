; Sprite memory pointers are offset from the current Screen Address - as dictated by the VIC Bank and Memory Configuration (VIC_SPRITE_MEMORY_CONFIG)
; Memory addresses $1000-$2000 and $9000-$a000 are always interpreted as Character ROM by the VIC
VIC_SPRITE_MEMORY_POINTER_OFFSET  =$03f8

VIC_HARDWARE_SPRITE_COUNT    =8
VIC_HARDWARE_SPRITE_HEIGHT   =21
VIC_HARDWARE_SPRITE_WIDTH    =24
VIC_SPRITE_BORDER_LEFT       =24
VIC_SPRITE_BORDER_LEFT_38    =32
VIC_SPRITE_BORDER_RIGHT      =VIC_SPRITE_BORDER_LEFT+(40*8)     ; inside SPRITE_BORDER 344
VIC_SPRITE_BORDER_RIGHT_38   =VIC_SPRITE_BORDER_LEFT_38+(38*8)  ; inside SPRITE_BORDER 336
VIC_SPRITE_BORDER_TOP        =50
VIC_SPRITE_BORDER_TOP_24     =54
VIC_SPRITE_BORDER_BOTTOM     =VIC_SPRITE_BORDER_TOP+(25*8)      ; inside SPRITE_BORDER 250
VIC_SPRITE_BORDER_BOTTOM_24  =VIC_SPRITE_BORDER_TOP_24+(24*8)   ; inside SPRITE_BORDER 246

VIC_RASTER_LINES_PAL  =312
VIC_RASTER_LINES_NTSC =263

VIC_BANK_0            =$0000
VIC_BANK_1            =$4000
VIC_BANK_2            =$8000
VIC_BANK_3            =$C000

VIC_SPRITE_X_0        =$D000
VIC_SPRITE_Y_0        =$D001
VIC_SPRITE_X_1        =$D002
VIC_SPRITE_Y_1        =$D003
VIC_SPRITE_X_2        =$D004
VIC_SPRITE_Y_2        =$D005
VIC_SPRITE_X_3        =$D006
VIC_SPRITE_Y_3        =$D007
VIC_SPRITE_X_4        =$D008
VIC_SPRITE_Y_4        =$D009
VIC_SPRITE_X_5        =$D00A
VIC_SPRITE_Y_5        =$D00B
VIC_SPRITE_X_6        =$D00C
VIC_SPRITE_Y_6        =$D00D
VIC_SPRITE_X_7        =$D00E
VIC_SPRITE_Y_7        =$D00F
VIC_SPRITE_X_MSB      =$D010  ; Bit 7=Sprite 7 Bit 0=Sprite 0

; Bit 2-0 = Y Scroll
; Bit 3 = Screen Height: 24 rows(0), 25 rows(1)
; Bit 4 = Screen Off(0), Screen On(1)
; Bit 5 = Text Mode(0) Bitmap Mode(1)
; Bit 6 = Extended Background Mode On(1), Off(0)
; Bit 7 = Current Raster Position Bit 9 - Read=Current Value, Write=IRQ set
; Default %00011011
VIC_CONTROL_REGISTER_1    =$D011

VIC_CONTROL_REGISTER_1_DEFAULT  =$1B


VIC_RASTER            =$D012
VIC_LIGHT_PEN_X       =$D013
VIC_LIGHT_PEN_Y       =$D014
VIC_SPRITE_ENABLE     =$D015  ; Bit 7=Sprite 7 Bit 0=Sprite 0

; Bit 2-0 = X Scroll
; Bit 3 = Screen Width: 38 Columns(0), 40 Columns(1)
; Bit 4 = Multicolour Mode: Off (0), On(1)
; Bit 5-7 = Unused
; Default %11001000
VIC_CONTROL_REGISTER_2    =$D016
VIC_CONTROL_REGISTER_2_DEFAULT  =$C8

VIC_SPRITE_Y_EXPANSION    =$D017; Bit 7=Sprite 7 - Not Expanded(0), Expanded(1)

; Bit 0 = Unused
; text mode
; Bit 1-3 = Character Memory Location 0-7 for the CHARGEN within the current VIC Bank (each os 2048 bytes)
; Bitmap Mode
; Bit 3 = Memory location (0=0,1=8192) of the bitmap within the current VIC Bank
;
; Bit 4-7 Memory location of the screen (1024 byte chunks) within the current VIC Bank
; Default     %00010101 ; default uppercase
; Lowercase   %00010110
VIC_MEMORY_CONFIG  =$D018


; Read
; Bit 0 = Raster Event
; Bit 1 = Sprite = Background Collision event
; Bit 2 = Sprite - Sprite Collision event
; Bit 3 = Light pen signal event
; Bit 7 = An event occurred
; Write
; Bit 0 = Raster Ack
; Bit 1 = Sprite = Background Collision Ack
; Bit 2 = Sprite - Sprite Collision Ack
; Bit 3 = Light pen signal Ack
VIC_IRQ_STATUS     =$D019


; Bit 0 = Raster IRQ Enabled
; Bit 1 = Sprite - Background IRQ Enabled
; Bit 2 = Sprite - Sprite IRQ Enabled
; Bit 3 = Light Pen IRQ Enabled
VIC_IRQ_CONTROL   =$D01A


VIC_SPRITE_DATA_PRIORITY    =$D01B  ; Bit 7=Sprite 7: Sprite In front of Screen(0), Sprite behind Screen (1)

VIC_SPRITE_MULTICOLOUR      =$D01C  ; Bit 7=Sprite 7: Multicolour Off(0), Multicolour On(1)

VIC_SPRITE_X_EXPANSION      =$D01D  ; Bit - Not Expanded(0), Expanded(1)

; Read = Each bit specifies this sprite collided with another
; Write = For each bit another collision is allowed
VIC_SPRITE_SPRITE_COLLISION =$D01E

; Read = Each bit specifies this sprite collided with background
; Write = For each bit another collision is allowed
VIC_SPRITE_BACKGROUND_COLLISION =$D01F

VIC_BORDER_COLOUR             =$D020
VIC_SCREEN_COLOUR             =$D021
VIC_EXTRA_BACKGROUND_COLOUR_1 =$D022
VIC_EXTRA_BACKGROUND_COLOUR_2 =$D023
VIC_EXTRA_BACKGROUND_COLOUR_3 =$D024
VIC_EXTRA_SPRITE_COLOUR_1     =$D025
VIC_EXTRA_SPRITE_COLOUR_2     =$D026

VIC_SPRITE_COLOUR_0       =$D027
VIC_SPRITE_COLOUR_1       =$D028
VIC_SPRITE_COLOUR_2       =$D029
VIC_SPRITE_COLOUR_3       =$D02a
VIC_SPRITE_COLOUR_4       =$D02b
VIC_SPRITE_COLOUR_5       =$D02c
VIC_SPRITE_COLOUR_6       =$D02d
VIC_SPRITE_COLOUR_7       =$D02e


VIC_COLOUR_BLACK          =0
VIC_COLOUR_WHITE          =1
VIC_COLOUR_RED            =2
VIC_COLOUR_CYAN           =3
VIC_COLOUR_PURPLE         =4
VIC_COLOUR_GREEN          =5
VIC_COLOUR_BLUE           =6
VIC_COLOUR_YELLOW         =7
VIC_COLOUR_ORANGE         =8
VIC_COLOUR_BROWN          =9
VIC_COLOUR_LIGHT_RED      =10
VIC_COLOUR_DARK_GREY      =11
VIC_COLOUR_GREY           =12
VIC_COLOUR_LIGHT_GREEN    =13
VIC_COLOUR_LIGHT_BLUE     =14
VIC_COLOUR_LIGHT_GREY     =15

VIC_COLOUR_RAM            =$D800
