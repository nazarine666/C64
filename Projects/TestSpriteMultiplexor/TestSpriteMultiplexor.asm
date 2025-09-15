*=$0801
!basic startofprogram

!source "..\..\CHIPLabels\VICLabels.asm",once
!source "..\..\CHIPLabels\CIALabels.asm",once
!source "..\..\CHIPLabels\MiscLabels.asm",once

!source "..\..\Macros\Macros.asm",once

Multiplexor.MPX_X_MSB_ALLOWED         =1
Multiplexor.MPX_X_EXPANSION_ALLOWED   =1
Multiplexor.MPX_Y_EXPANSION_ALLOWED   =1
Multiplexor.MPX_MULTICOLOUR_ALLOWED   =1
Multiplexor.MPX_DATA_PRIORITY_ALLOWED =0
Multiplexor.MPX_ENABLED_ALLOWED       =0
Multiplexor.MPX_DEBUG_BORDER          =1



!source "..\..\Libraries\SpriteMulitplexorV2.asm",once


!source "circle.asm",once
!source "sinwave.asm",once

+EMPTY_IRQ_ROUTINE

startofprogram
  lda #VIC_COLOUR_BLACK
  sta VIC_BORDER_COLOUR
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
  
  ;jmp BasicSpriteTest
  jmp LineTest
  ;jmp ClockTest
  ;jmp SinTest
  
SetupRasterIRQ

  +STORE_WORD Multiplexor.EntryPoint,KERNAL_IRQ_SERVICE_ROUTINE
  
  lda #1
  sta VIC_IRQ_CONTROL
  ;lda #VIC_SPRITE_BORDER_BOTTOM
  ;sta VIC_RASTER
  ;lda #$7f
  ;and VIC_CONTROL_REGISTER_1
  ;sta VIC_CONTROL_REGISTER_1

  rts

EmptyGameLoop
  jmp EmptyGameLoop

LineTest
  +MPX_SET_NUMBER_OF_SPRITES 24
  !for sprite = 0 to 23
    +MPX_SET_FLAG sprite,Multiplexor.FLAG_ENABLED
    +MPX_SET_MEMORY_POINTER sprite,sprite
    +MPX_SET_COLOUR sprite,1 +(sprite and 3)
    ;+MPX_SET_XCOORD sprite,VIC_SPRITE_BORDER_LEFT+(12*sprite)
    ;+MPX_SET_YCOORD sprite,VIC_SPRITE_BORDER_TOP+(sprite*10)
  !end
  !for sprite = 0 to 7
    +MPX_SET_XCOORD sprite,VIC_SPRITE_BORDER_LEFT+(30*sprite)
    +MPX_SET_XCOORD sprite+8,VIC_SPRITE_BORDER_LEFT+(30*sprite)
    +MPX_SET_XCOORD sprite+16,VIC_SPRITE_BORDER_LEFT+(30*sprite)
    
SPRITE_GAP=7
    +MPX_SET_YCOORD sprite+8,VIC_SPRITE_BORDER_TOP+(sprite*SPRITE_GAP)
    +MPX_SET_YCOORD sprite,VIC_SPRITE_BORDER_TOP+70+(sprite*SPRITE_GAP)
    +MPX_SET_YCOORD sprite+16,VIC_SPRITE_BORDER_TOP+140+(sprite*SPRITE_GAP)
  !end

  
  jsr SetupRasterIRQ
  cli
  
  jmp EmptyGameLoop


BasicSpriteTest
  +MPX_SET_NUMBER_OF_SPRITES 16
  +MPX_SET_FLAG 13,Multiplexor.FLAG_X_EXPAND
  +MPX_SET_FLAG 12,Multiplexor.FLAG_Y_EXPAND
  +MPX_SET_FLAG 11,Multiplexor.FLAG_MULTICOLOUR
  +MPX_CLEAR_FLAG 10,Multiplexor.FLAG_ENABLED

  !for sprite = 0 to 15
    +MPX_SET_FLAG sprite,Multiplexor.FLAG_ENABLED
    +MPX_CLEAR_FLAG sprite,Multiplexor.FLAG_PRIORITY
    +MPX_SET_YCOORD sprite,VIC_SPRITE_BORDER_TOP+(sprite*10)
  !end
  !for sprite = 0 to 7
    +MPX_SET_COLOUR sprite,VIC_COLOUR_WHITE
    +MPX_SET_COLOUR 8+sprite,VIC_COLOUR_GREEN
  !end
  !for sprite = 0 to 7
    +MPX_SET_XCOORD sprite,VIC_SPRITE_BORDER_LEFT+(40*sprite)
    +MPX_SET_XCOORD 8+sprite,VIC_SPRITE_BORDER_RIGHT-40 -(40*sprite)
  !end

  !for sprite = 0 to 15
    +MPX_SET_MEMORY_POINTER sprite,sprite
  !end
  
  jsr SetupRasterIRQ
  cli
  
  jmp EmptyGameLoop

SinTest
  +MPX_SET_NUMBER_OF_SPRITES SinWave.SPRITE_COUNT
  !for spriteIndex = 0 to SinWave.SPRITE_COUNT-1
    +MPX_SET_MEMORY_POINTER spriteIndex,spriteIndex
    +MPX_SET_COLOUR spriteIndex,1 +(spriteIndex and 3)    
    ;+MPX_SET_FLAG sprite,Multiplexor.FLAG_ENABLED
    ; +MPX_SET_YCOORD spriteIndex,VIC_SPRITE_BORDER_TOP+(15*spriteIndex)
  !end
  ;lda #0
  !for spriteIndex = 0 to SinWave.SPRITE_COUNT-1
    +MPX_SET_XCOORD spriteIndex,VIC_SPRITE_BORDER_LEFT+(16*spriteIndex)
  !end

  lda #$ff
  sta VIC_SPRITE_ENABLE
  jsr SpriteSetCoordsSinWave
  ;jsr Multiplexor.CopyStagingAreaToActive
  jsr SetupRasterIRQ
  cli

SinGameLoop
  ;!for spriteIndex = 0 to SinWave.SPRITE_COUNT-1
  ;  inc SinWave.SpriteIndexes+spriteIndex
  ;!end
  ;jsr SpriteSetCoordsSinWave
  ;+WAIT_FOR_RASTER_MSB_0
  ;+WAIT_FOR_RASTER 30
  jmp SinGameLoop
  
SpriteSetCoordsSinWave
  ldx #0
SpriteSetSinWaveYCoordsLoop
  lda SinWave.SpriteIndexes,x
  tay
  
  lda SinWave.YCoords,y
  sta Multiplexor.YCoords,x

  inx
  cpx #SinWave.SPRITE_COUNT
  bcc SpriteSetSinWaveYCoordsLoop

  rts
  
  
  
  
  
  
ClockTest
  +MPX_SET_NUMBER_OF_SPRITES CLOCK_SPRITE_COUNT
  !for sprite = 0 to CLOCK_SPRITE_COUNT-1
    +MPX_SET_MEMORY_POINTER sprite,sprite
  !end

  lda #$ff
  sta VIC_SPRITE_ENABLE
  jsr SpriteSetCoordsClock
  jsr SetupRasterIRQ
  cli

ClockGameLoop
  jsr SpriteAdvanceIndexes
  jmp ClockGameLoop
  
SpriteSetCoordsClock
  ldx #0
SpriteSetCoordsLoop
  lda SpriteIndexes,x
  tay
  
  lda CircleYCoords,y
  sta Multiplexor.YCoords,x
  
  lda CircleXCoordsLSB,y
  sta Multiplexor.XCoords,x
  
  lda CircleXCoordsMSB,y
  bne XHasMSB
  ; Turn off MSB
  lda Multiplexor.Flags,x
  and #(255-Multiplexor.FLAG_X_MSB)
  sta Multiplexor.Flags,x
  jmp AfterXMSBCheck
XHasMSB
  ; turn on MSB
  lda Multiplexor.Flags,x
  ora #Multiplexor.FLAG_X_MSB
  sta Multiplexor.Flags,x
AfterXMSBCheck  
  inx
  cpx #CLOCK_SPRITE_COUNT
  bcc SpriteSetCoordsLoop
  rts

SpriteAdvanceIndexes
  ldx #0
SpriteAdvanceIndexesLoop
  inc SpriteIndexes,x
  inx
  cpx CLOCK_SPRITE_COUNT
  bne SpriteAdvanceIndexesLoop
  rts
  
SPRITE_DEFINITION_START=$8000
*=SPRITE_DEFINITION_START
!media "NumberSprites.spriteproject", sprite,0,24
