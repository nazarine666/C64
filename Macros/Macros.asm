

!source "..\CHIPLabels\MiscLabels.asm",once
!source "..\CHIPLabels\VICLabels.asm",once
!source "..\CHIPLabels\CIALabels.asm",once

!macro STORE_WORD value,location
  lda #<value
  sta location
  lda #>value
  sta location+1
!end

!macro ACK_RASTER_IRQ
  lda #1
  sta VIC_IRQ_STATUS
!end

!macro ALL_RAM_WITH_IO
  lda #ZERO_PAGE_PROCESSOR_PORT_ALL_RAM_WITH_IO
  sta ZERO_PAGE_PROCESSOR_PORT

  lda #ZERO_PAGE_PROCESSORT_PORT_DDR_DEFAULT
  sta ZERO_PAGE_PROCESSOR_PORT_DDR
!end

!macro CIA_IRQ_CONTROL_DISABLE
  ; Acknowledge CIA IRQs
  lda #$7f
  sta CIA_1_IRQ_CONTROL
  sta CIA_2_IRQ_CONTROL
  
  ; Acknowledge VIC IRQs
  lda #$ff
  sta VIC_IRQ_STATUS
!end

!macro ACK_ALL_IRQS
  ; Ack any IRQs fromt he CIAs
  lda CIA_1_IRQ_CONTROL
  lda CIA_2_IRQ_CONTROL
  lda #$ff
  sta VIC_IRQ_STATUS
!end

!macro VIC_IRQ_DISABLE
  lda #$0
  sta VIC_IRQ_STATUS
!end

!macro CIA_TIMER_DISABLE
  lda #$0
  sta VIC_IRQ_STATUS
!end

; Set machien up so that all ram available (kernal/basic switched off)
; I/O ram (sprites etc) are available for use
; interrupts are disabled
; all irqs are disabled
; IRQ and NMI interrupts are configured to point to dummy routines
!macro MACHINE_INIT
  sei
  cld
  ; Initialise RAM Setup
  +ALL_RAM_WITH_IO
  
  ; Clear CIA Chips / IRQs
  +CIA_IRQ_CONTROL_DISABLE
  +VIC_IRQ_DISABLE
  +CIA_TIMER_DISABLE
  +ACK_ALL_IRQS

  lda #<EmptyIRQRoutine
  sta IRQ_SERVICE_ROUTINE
  lda #>EmptyIRQRoutine
  sta IRQ_SERVICE_ROUTINE+1
  
  lda #<EmptyNMIRoutine
  sta KERNAL_IRQ_SERVICE_ROUTINE
  lda #>EmptyNMIRoutine
  sta KERNAL_IRQ_SERVICE_ROUTINE+1
!end

!macro SET_VIC_BANK mask
  lda #%11111100
  and CIA_2_DATA_PORT_A
  ora #mask
  sta CIA_2_DATA_PORT_A
  VIC_BANK_START=$4000*(3-mask)
!end

!macro SET_VIC_BANK_0
  +SET_VIC_BANK %11
!end
!macro SET_VIC_BANK_1
  +SET_VIC_BANK %10
!end
!macro SET_VIC_BANK_2
  +SET_VIC_BANK %01
!end
!macro SET_VIC_BANK_3
  +SET_VIC_BANK %00
!end

!macro SET_SCREEN_OFFSET offset_address
  lda #%00001111
  and VIC_MEMORY_CONFIG
  ora #(offset_address/1024)*16
  sta VIC_MEMORY_CONFIG
  VIC_SCREEN_ADDRESS = VIC_BANK_START+offset_address
  VIC_SCREEN_START_OFFSET=offset_address
!end  

; Set hires memory chunk - 0 for lower 8k, 1 = upper 8k of bank
; VIC sees character ROM at
;   $1000-$1FFF (bank 0 offset 1)
;   $8000-$9FFF (bank 2 offset 1)
;
!macro SET_HIRES_MEMORY chunk
  VIC_HIRES_ADDRESS = VIC_BANK_START + (8192 * chunk)
  !if chunk {
    ; second memory chunk
    lda VIC_MEMORY_CONFIG
    ora #$10
    sta VIC_MEMORY_CONFIG
  } else {
    ; first memory chunk
    lda VIC_MEMORY_CONFIG
    and #($ff-$10)
    sta VIC_MEMORY_CONFIG
  }
!end

; screen on
!macro VIC_SCREEN_ON
  lda #$10
  ora VIC_CONTROL_REGISTER_1
  sta VIC_CONTROL_REGISTER_1
!end

; screen off
!macro VIC_SCREEN_OFF
  lda #($ff-$10)
  and VIC_CONTROL_REGISTER_1
  sta VIC_CONTROL_REGISTER_1
!end

; change screen height to 25 rows
!macro VIC_SCREEN_HEIGHT_25
  lda #$8
  ora VIC_CONTROL_REGISTER_1
  sta VIC_CONTROL_REGISTER_1
!end

; change screen height to 24 rows
!macro VIC_SCREEN_HEIGHT_24
  lda #($ff-$8)
  and VIC_CONTROL_REGISTER_1
  sta VIC_CONTROL_REGISTER_1
!end

; Set hires mode
!macro VIC_SET_HIRES_MODE
  lda #$20
  ora VIC_CONTROL_REGISTER_1
  sta VIC_CONTROL_REGISTER_1
!end

; Change To HIRES Mode
; Set the VIC Bank and memory config to the appropriate
; settings for the full range memory addresses provided
; bitmap_address=0-$ffff, colour_address=0-$ffff
; following will be set as a result
; VIC_BANK_START              ; Where the VIC_BANK start is
; VIC_BITMAP_ADDRESS          ; the actual calculated VIC_BITMAP_ADDRESS
; VIC_COLOUR_ADDRESS          ; the actual caclulated colour address
; VIC_SCREEN_ADDRESS          ; same as VIC_COLOUR_ADDRESS
; VIC_COLOUR_START_OFFSET     ; where in the VIC_BANK the VIC_COLOUR_ADDRESS starts
; VIC_SCREEN_START_OFFSET     ; same as VIC_COLOUR_START_OFFSET
; VIC_BITMAP_START_OFFSET     ; where in the VIC_BANK the VIC_BITMAP_ADDRESS starts
!macro VIC_SET_HIRES_MODE_AND_MEMORY bitmap_address,colour_address
  VIC_BITMAP_ADDRESS = (bitmap_address/8192)*8192
  VIC_COLOUR_ADDRESS = (colour_address/1024)*1024
  !if ((VIC_COLOUR_ADDRESS/16384)-(VIC_BITMAP_ADDRESS/16384)) {
    !ERROR "Bitmap / Colour addresses not in same VIC_BANK"
  }
  
  VIC_SCREEN_ADDRESS = VIC_COLOUR_ADDRESS
  +SET_VIC_BANK (3-(bitmap_address/16384))

  VIC_SCREEN_START_OFFSET = VIC_SCREEN_ADDRESS-VIC_BANK_START
  VIC_COLOUR_START_OFFSET = VIC_SCREEN_START_OFFSET
  
  VIC_BITMAP_START_OFFSET = VIC_BITMAP_ADDRESS-VIC_BANK_START
  lda #((VIC_BITMAP_START_OFFSET/8192)*8)+((VIC_COLOUR_START_OFFSET/1024)*16)
  sta VIC_MEMORY_CONFIG
  +VIC_SET_HIRES_MODE
!end

; Set text mode
!macro VIC_SET_TEXT_MODE
  lda #($ff-$20)
  and VIC_CONTROL_REGISTER_1
  sta VIC_CONTROL_REGISTER_1
!end

; Change To Text Mode and change Character location
; Set the VIC Bank and memory config to the appropriate
; settings for the full range memory addresses provided
; text_address=0-$ffff
; following will be set as a result
; VIC_BANK_START              ; Where the VIC_BANK start is
; VIC_SCREEN_ADDRESS          ; same as VIC_COLOUR_ADDRESS
; VIC_SCREEN_START_OFFSET     ; where in the VIC_BANK the VIC_SCREEN_ADDRESS starts
; VIC_CHARACTER_ADDRESS       ; where the character ram is to be located
; VIC_CHARACTER_START_OFFSET  ; where in the VIC_BANK the VIC_CHARACTER_ADDRESS starts
;
; For VIC Bank 0 and 2 ($0000-$3FFF,$8000-$BFFF)
; The VIC Chip sees the character rom at offset $1000
; For VIC Bank 1 and 3 ($4000-$7FFF,$C000,$FFFF)
; this would be mapped to RAM allowing for custom
!macro VIC_SET_TEXT_MODE_AND_MEMORY_AND_CHARGEN screen_address,character_address
  VIC_SCREEN_ADDRESS = (screen_address/1024)*1024
  VIC_CHARACTER_ADDRESS = (character_address/2048)*2048
  
  !if ((VIC_SCREEN_ADDRESS/16384)-(VIC_CHARACTER_ADDRESS/16384)) {
    !ERROR "Screen / Character addresses not in same VIC_BANK"
  }
  

  +SET_VIC_BANK (3-(screen_address/16384))

  VIC_SCREEN_START_OFFSET = VIC_SCREEN_ADDRESS-VIC_BANK_START
  VIC_CHARACTER_START_OFFSET = VIC_CHARACTER_ADDRESS-VIC_BANK_START

  VIC_SCREEN_START_OFFSET = VIC_SCREEN_ADDRESS-VIC_BANK_START

  lda #((VIC_CHARACTER_START_OFFSET/2048)*2)+((VIC_SCREEN_START_OFFSET/1024)*16)
  sta VIC_MEMORY_CONFIG
  
  +VIC_SET_TEXT_MODE

!end

; Change To Text Mode and dont change character location
; Set the VIC Bank and memory config to the appropriate
; settings for the full range memory addresses provided
; text_address=0-$ffff
; following will be set as a result
; VIC_BANK_START              ; Where the VIC_BANK start is
; VIC_SCREEN_ADDRESS          ; same as VIC_COLOUR_ADDRESS
; VIC_SCREEN_START_OFFSET     ; where in the VIC_BANK the VIC_SCREEN_ADDRESS starts
;
; For VIC Bank 0 and 2 ($0000-$3FFF,$8000-$BFFF)
; The VIC Chip sees the character rom at offset $1000
; For VIC Bank 1 and 3 ($4000-$7FFF,$C000,$FFFF)
; this would be mapped to RAM allowing for custom
!macro VIC_SET_TEXT_MODE_AND_MEMORY screen_address
  VIC_SCREEN_ADDRESS = (screen_address/1024)*1024

  +SET_VIC_BANK (3-(screen_address/16384))

  VIC_SCREEN_START_OFFSET = VIC_SCREEN_ADDRESS-VIC_BANK_START

  lda VIC_MEMORY_CONFIG
  and #$0f
  ora #((VIC_SCREEN_START_OFFSET/1024)*16)
  sta VIC_MEMORY_CONFIG

  +VIC_SET_TEXT_MODE

!end



!macro VIC_SPRITE_MEMORY_POINTER_SET  sprite,screen_address,sprite_address
  lda # (sprite_address - ((sprite_address/$4000)*$4000))/64
  sta screen_address+VIC_SPRITE_MEMORY_POINTER_OFFSET+sprite
!end

!macro SET_SPRITE_X sprite,xcoord
  lda #<xcoord
  sta VIC_SPRITE_X_0+(sprite*2)
  !if xcoord>255 {
    lda VIC_SPRITE_X_MSB
    ora #(1<<sprite)
    sta VIC_SPRITE_X_MSB
  }
  !if xcoord<256 {
    lda VIC_SPRITE_X_MSB
    and #(255-(1<<sprite))
    sta VIC_SPRITE_X_MSB
  }
!end

!macro SET_SPRITE_Y sprite,ycoord
  lda #ycoord
  sta VIC_SPRITE_Y_0+(sprite*2)
!end

!macro WAIT_FOR_RASTER_MSB_0
  .wait_raster_msb_0
  lda VIC_CONTROL_REGISTER_1
  bmi .wait_raster_msb_0
!end

!macro WAIT_FOR_RASTER_MSB_1
  .wait_raster_msb_1
  lda VIC_CONTROL_REGISTER_1
  bpl .wait_raster_msb_1
!end

!macro WAIT_FOR_RASTER raster
  lda #<raster
  .wait_raster
  cmp VIC_RASTER
  bne .wait_raster
!end

!macro WAIT_FOR_RASTER_TOP_BORDER
  +WAIT_FOR_RASTER_MSB_0
  +WAIT_FOR_RASTER VIC_SPRITE_BORDER_TOP
!end

!macro WAIT_FOR_RASTER_BOTTOM_BORDER
  +WAIT_FOR_RASTER_MSB_0
  +WAIT_FOR_RASTER VIC_SPRITE_BORDER_BOTTOM
!end

!macro WAIT_FOR_RASTER_FULL raster
  !if raster>255 {
    +WAIT_FOR_RASTER_MSB_1
  }
  !if raster<256 {
    +WAIT_FOR_RASTER_MSB_0
  }
  +WAIT_FOR_RASTER <raster
}

!macro PUSH_REGISTERS_ON_STACK
  pha
  txa
  pha
  tya
  pha
!end

!macro POP_REGISTERS_OFF_STACK
  pla
  tay
  pla
  tax
  pla
!end

!macro EMPTY_IRQ_ROUTINE  
EmptyIRQRoutine
  pha
  +ACK_RASTER_IRQ
  pla
  rti
  
EmptyNMIRoutine
  rti
!end


