

!source "..\CHIPLabels\MiscLabels.asm",once
!source "..\CHIPLabels\VICLabels.asm",once
!source "..\CHIPLabels\CIALabels.asm",once

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
!end

!macro SET_VIC_BANK_0
  +SET_VIC_BANK %11
  VIC_BANK_START=VIC_BANK_0
!end
!macro SET_VIC_BANK_1
  +SET_VIC_BANK %10
  VIC_BANK_START=VIC_BANK_1
!end
!macro SET_VIC_BANK_2
  +SET_VIC_BANK %01
  VIC_BANK_START=VIC_BANK_2
!end
!macro SET_VIC_BANK_3
  +SET_VIC_BANK %00
  VIC_BANK_START=VIC_BANK_3
!end

!macro SET_SCREEN_OFFSET offset_address
  lda #%00001111
  and VIC_MEMORY_CONFIG
  ora #(offset_address/1024)*16
  sta VIC_MEMORY_CONFIG
  VIC_SCREEN_START_OFFSET=offset_address
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


EmptyIRQRoutine
  pha
  +ACK_RASTER_IRQ
  pla
  rti
  
EmptyNMIRoutine
  rti

