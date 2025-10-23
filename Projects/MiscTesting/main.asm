bitmap_address = 49152
colour_address = 49152+8192

*=bitmap_address
!binary "e:\nso.bin",8000

*=colour_address
!binary "e:\nso.bin",1000,8000

SPRITE_DEFINITION_START=colour_address+1024

*=SPRITE_DEFINITION_START
!media "MiscSprites.spriteproject", sprite,0,24

*=$0801
!basic startofprogram
; 66 @ 14:28

!source "..\..\CHIPLabels\VICLabels.asm",once
!source "..\..\CHIPLabels\CIALabels.asm",once
!source "..\..\CHIPLabels\MiscLabels.asm",once

!source "..\..\Macros\Macros.asm",once



startofprogram
  +MACHINE_INIT


  ; HIRES MODE EXAMPLE
  +VIC_SET_HIRES_MODE_AND_MEMORY bitmap_address,colour_address
  
  ; Joystick Example
  lda #(1+2+4+8+16)
  sta VIC_SPRITE_ENABLE
  
  !for sprite_index = 0 to 4
    lda #((SPRITE_DEFINITION_START-VIC_BANK_START)/64)+sprite_index
    sta VIC_SCREEN_ADDRESS+VIC_SPRITE_MEMORY_POINTER_OFFSET+sprite_index
  !end
  lda #VIC_COLOUR_BLACK
  !for sprite_index = 0 to 4
    sta VIC_SPRITE_COLOUR_0+sprite_index
  !end
  ldy #VIC_SPRITE_BORDER_TOP+VIC_HARDWARE_SPRITE_HEIGHT
  sty VIC_SPRITE_Y_0
  sty VIC_SPRITE_Y_1

  ldx #VIC_SPRITE_BORDER_LEFT
  stx VIC_SPRITE_X_0
  ldx #VIC_SPRITE_BORDER_LEFT+VIC_HARDWARE_SPRITE_WIDTH*2
  stx VIC_SPRITE_X_1
  
  ldx #VIC_SPRITE_BORDER_LEFT+VIC_HARDWARE_SPRITE_WIDTH*1
  stx VIC_SPRITE_X_2
  stx VIC_SPRITE_X_3
  stx VIC_SPRITE_X_4
  
  ldy #VIC_SPRITE_BORDER_TOP
  sty VIC_SPRITE_Y_2
  ldy #VIC_SPRITE_BORDER_TOP+VIC_HARDWARE_SPRITE_HEIGHT*2
  sty VIC_SPRITE_Y_3
  ldy #VIC_SPRITE_BORDER_TOP+VIC_HARDWARE_SPRITE_HEIGHT*1
  sty VIC_SPRITE_Y_4
  
GameLoop
  lda CIA_1_DATA_PORT_B
  sta VIC_BORDER_COLOUR
  tax
  
  ; LEFT Check
  txa
  and #JOYSTICK_LEFT_MASK
  beq +
  lda #VIC_COLOUR_BLACK
  jmp ++
+
  lda #VIC_COLOUR_WHITE
++
  sta VIC_SPRITE_COLOUR_0


  ; RIGHT Check
  txa
  and #JOYSTICK_RIGHT_MASK
  beq +
  lda #VIC_COLOUR_BLACK
  jmp ++
+
  lda #VIC_COLOUR_WHITE
++
  sta VIC_SPRITE_COLOUR_1


  ; UP Check
  txa
  and #JOYSTICK_UP_MASK
  beq +
  lda #VIC_COLOUR_BLACK
  jmp ++
+
  lda #VIC_COLOUR_WHITE
++
  sta VIC_SPRITE_COLOUR_2

  ; DOWN Check
  txa
  and #JOYSTICK_DOWN_MASK
  beq +
  lda #VIC_COLOUR_BLACK
  jmp ++
+
  lda #VIC_COLOUR_WHITE
++
  sta VIC_SPRITE_COLOUR_3


  ; FIRE Check
  txa
  and #JOYSTICK_FIRE_MASK
  beq +
  lda #VIC_COLOUR_BLACK
  jmp ++
+
  lda #VIC_COLOUR_WHITE
++
  sta VIC_SPRITE_COLOUR_4


  jmp GameLoop
  
+EMPTY_IRQ_ROUTINE



