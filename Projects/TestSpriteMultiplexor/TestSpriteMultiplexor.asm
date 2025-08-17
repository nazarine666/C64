*=$0801
!basic startofprogram

Multiplexor.MPX_X_MSB_ALLOWED         =1
Multiplexor.MPX_X_EXPANSION_ALLOWED   =0
Multiplexor.MPX_Y_EXPANSION_ALLOWED   =0
Multiplexor.MPX_MULTICOLOUR_ALLOWED   =0
Multiplexor.MPX_DATA_PRIORITY_ALLOWED =0
Multiplexor.MPX_ENABLED_ALLOWED       =0


!source "..\..\MACROS\Macros.asm",once
!source "..\..\CHIPLabels\VICLabels.asm",once

!source "..\..\Libraries\SpriteMulitplexor.asm",once



startofprogram
  +MACHINE_INIT
  lda #VIC_CONTROL_REGISTER_1_DEFAULT
  sta VIC_CONTROL_REGISTER_1

  ; if i use bank 3 then i would lose the character rom
  
  +SET_VIC_BANK_2     ; Sets the label VIC_BANK_START
  
  +SET_SCREEN_OFFSET 2048   ; sets the label  VIC_SCREEN_START_OFFSET to same value
  
  VIC_SCREEN_START=VIC_BANK_START+VIC_SCREEN_START_OFFSET ; the actual address where the screen is located
  lda #32
  ldx #0
.FillScreenLoop  
  sta VIC_SCREEN_START,x
  sta VIC_SCREEN_START+250,x
  sta VIC_SCREEN_START+500,x
  sta VIC_SCREEN_START+750,x
  inx
  cpx #250
  bne .FillScreenLoop
  
  ; Set up some initial sprites
  lda #$ff
  sta VIC_SPRITE_ENABLE

  +MPX_INITIATE VIC_SCREEN_START
  !for sprite = 0 to 7
    +MPX_SET_FLAG sprite,Multiplexor.FLAG_ENABLED
    +MPX_SET_XCOORD sprite, 50+sprite*30
    +MPX_SET_YCOORD sprite,60+sprite
    +MPX_SET_MEMORY_POINTER sprite,sprite
    +MPX_SET_COLOUR sprite,1
  !end
  !for sprite = 0 to 7
    +MPX_SET_XCOORD sprite+8, 30+sprite*25
    +MPX_SET_YCOORD sprite+8,100+sprite
    +MPX_SET_MEMORY_POINTER sprite+8,sprite+8
    +MPX_SET_COLOUR sprite+8,1
  !end
  !for sprite = 0 to 7
    +MPX_SET_XCOORD sprite+16, 30+sprite*25
    +MPX_SET_YCOORD sprite+16,160-sprite
    +MPX_SET_MEMORY_POINTER sprite+16,sprite+16
    +MPX_SET_COLOUR sprite+16,1
  !end
  +MPX_SET_FLAG 2, Multiplexor.FLAG_Y_EXPAND
  
  lda #<Multiplexor.EntryPoint
  sta KERNAL_IRQ_SERVICE_ROUTINE
  lda #>Multiplexor.EntryPoint
  sta KERNAL_IRQ_SERVICE_ROUTINE+1
  
  ; initiate the raster interrupt
  lda #0
  sta VIC_RASTER
  lda #$7f
  and VIC_CONTROL_REGISTER_1
  sta VIC_CONTROL_REGISTER_1
  
  lda #1
  sta VIC_IRQ_CONTROL
  cli

  jmp .gameloop
  
  lda #<.RasterIRQEntry
  sta KERNAL_IRQ_SERVICE_ROUTINE
  lda #>.RasterIRQEntry
  sta KERNAL_IRQ_SERVICE_ROUTINE+1
  
  ; initiate the raster interrupt
  lda #70
  sta VIC_RASTER
  lda #1
  sta VIC_IRQ_CONTROL
  cli
  
.gameloop
  +WAIT_FOR_RASTER_BOTTOM_BORDER
  lda #4
  sta VIC_BORDER_COLOUR
  +WAIT_FOR_RASTER_FULL VIC_RASTER_LINES_PAL-1
  lda #5
  sta VIC_BORDER_COLOUR
  jmp .gameloop
  
.RasterIRQEntry
  inc VIC_BORDER_COLOUR
  +PUSH_REGISTERS_ON_STACK
  +ACK_RASTER_IRQ

  ; Line 1
   !for sprite = 0 to 7
    +SET_SPRITE_Y sprite,80
   !end

  lda #<.RasterIRQEntry2
  sta KERNAL_IRQ_SERVICE_ROUTINE
  lda #>.RasterIRQEntry2
  sta KERNAL_IRQ_SERVICE_ROUTINE+1
  lda #110
  sta VIC_RASTER

  +POP_REGISTERS_OFF_STACK
  dec VIC_BORDER_COLOUR
  rti

.RasterIRQEntry2
  inc VIC_BORDER_COLOUR
  +PUSH_REGISTERS_ON_STACK
  +ACK_RASTER_IRQ

  ; Line 1
   !for sprite = 0 to 7
    +SET_SPRITE_Y sprite,120
   !end

  lda #<.RasterIRQEntry
  sta KERNAL_IRQ_SERVICE_ROUTINE
  lda #>.RasterIRQEntry
  sta KERNAL_IRQ_SERVICE_ROUTINE+1
  lda #70
  sta VIC_RASTER

  +POP_REGISTERS_OFF_STACK
  dec VIC_BORDER_COLOUR
  rti

.loop
  lda #VIC_COLOUR_BLACK
  sta VIC_BORDER_COLOUR
  !for sprite = 0 to 7
    +SET_SPRITE_Y sprite,40
  !end
  +WAIT_FOR_RASTER_TOP_BORDER
  lda #VIC_COLOUR_WHITE
  sta VIC_BORDER_COLOUR

  +WAIT_FOR_RASTER 100

  !for sprite = 0 to 7
    +SET_SPRITE_Y sprite,140
  !end

  +WAIT_FOR_RASTER_BOTTOM_BORDER
  lda #VIC_COLOUR_RED
  sta VIC_BORDER_COLOUR
  +WAIT_FOR_RASTER_MSB_1
  +WAIT_FOR_RASTER_MSB_0

  jmp .loop
  
  
SPRITE_DEFINITION_START=$8000
*=SPRITE_DEFINITION_START
!media "NumberSprites.spriteproject", sprite,0,24
