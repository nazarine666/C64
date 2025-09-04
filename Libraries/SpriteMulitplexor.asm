!source "..\..\MACROS\Macros.asm",once
!source "..\..\CHIPLabels\VICLabels.asm",once


!zone Multiplexor

; Set these flags in your main program befre including the assembly file
;Multiplexor.MPX_X_MSB_ALLOWED         =1
;Multiplexor.MPX_X_EXPANSION_ALLOWED   =1
;Multiplexor.MPX_Y_EXPANSION_ALLOWED   =1
;Multiplexor.MPX_MULTICOLOUR_ALLOWED   =1
;Multiplexor.MPX_DATA_PRIORITY_ALLOWED =1
;Multiplexor.MPX_ENABLED_ALLOWED       =1


Multiplexor.FLAG_X_MSB          =1
Multiplexor.FLAG_X_EXPAND       =2
Multiplexor.FLAG_Y_EXPAND       =4
Multiplexor.FLAG_MULTICOLOUR    =8
Multiplexor.FLAG_PRIORITY       =16
Multiplexor.FLAG_ENABLED        =128


Multiplexor.FLAGS_ALLOWED = Multiplexor.MPX_X_MSB_ALLOWED + Multiplexor.MPX_X_EXPANSION_ALLOWED + Multiplexor.MPX_Y_EXPANSION_ALLOWED + Multiplexor.MPX_MULTICOLOUR_ALLOWED + Multiplexor.MPX_DATA_PRIORITY_ALLOWED + Multiplexor.MPX_ENABLED_ALLOWED 

Multiplexor.VirtualSpriteCount    =16     ; Must be a multiple of 8

; amount iof lines before a sprite we need to schedule the raster to give things enough time
.RASTERS_PROCESSING_DURATION=11 ; number of lines to process the hardware sprites excluding the vic flags
.RASTERS_PER_VIC_FLAG=5         ; how many lines it takes to process a single vic flag
.RASTERS_VIC_FLAG_OVERHEAD=1    ; the minimum number of lines to process >0 vic flags
.RASTERS_VIC_LINES=0
!if Multiplexor.FLAGS_ALLOWED {
.RASTERS_VIC_LINES = Multiplexor.RASTERS_VIC_FLAG_OVERHEAD+(Multiplexor.FLAGS_ALLOWED * Multiplexor.RASTERS_PER_VIC_FLAG)
}

.RASTER_SAFE_OFFSET=.RASTERS_PROCESSING_DURATION+.RASTERS_VIC_LINES




!macro MPX_SET_FLAGS sprite,mask    
  lda #mask
  sta Multiplexor.Flags+sprite
!end

!macro MPX_SET_FLAG sprite,flag
  lda Multiplexor.Flags+sprite
  ora #flag
  sta Multiplexor.Flags+sprite
!end

!macro MPX_CLEAR_FLAG sprite,flag
  lda Multiplexor.Flags+sprite
  and #(255-flag)
  sta Multiplexor.Flags+sprite
!end

!macro MPX_INITIATE screen_address
  lda #<(screen_address+VIC_SPRITE_MEMORY_POINTER_OFFSET)
  sta Multiplexor.StoreScreenPointer+1
  lda #>(screen_address+VIC_SPRITE_MEMORY_POINTER_OFFSET)
  sta Multiplexor.StoreScreenPointer+2
!end

!Macro MPX_SET_XCOORD sprite,xcoord
  lda #<xcoord
  sta Multiplexor.XCoords+sprite
  
  !if xcoord>255 {
    +MPX_SET_FLAG sprite,Multiplexor.FLAG_X_MSB
  }
  !if xcoord<256 {
    +MPX_CLEAR_FLAG sprite,Multiplexor.FLAG_X_MSB
  }
!end

!Macro MPX_SET_YCOORD sprite,ycoord
  lda #ycoord
  sta Multiplexor.YCoords+sprite
!end

!macro MPX_SET_MEMORY_POINTER  sprite,sprite_pointer
  lda #sprite_pointer
  sta Multiplexor.Pointers+sprite
!end

!Macro MPX_SET_COLOUR sprite,colour
  lda #colour
  sta Multiplexor.Colours+sprite
!end

!macro MPX_ENABLE_SPRITE sprite
  lda #1
  sta Multiplexor.Enabled+sprite
!end
!macro MPX_DISABLE_SPRITE sprite
  lda #0
  sta Multiplexor.Enabled+sprite
!end



.EntryPoint
  inc VIC_BORDER_COLOUR
  +PUSH_REGISTERS_ON_STACK

  ldy .CurrentVirtualIndex
  bne .AfterVirtualSpritesSorted
  ; When the virtual sprite index is 0 it means we are starting a new list
  ; so we need to sort it
  jsr .SortSpriteList

  ldx #0
  
.AfterVirtualSpritesSorted
  !ifdef Multiplexor.FLAGS_ALLOWED {
  jsr .HandleVICFlags
  }
  ldx #0    ; Hardware sprite index

.HardwareSpriteLoop
  ; x register holds the current hardware sprite number
  ldy .CurrentVirtualIndex
  
  lda .Colours,y
  sta  VIC_SPRITE_COLOUR_0,x
  lda .Pointers,y
  .StoreScreenPointer
  sta $FFFF,x
  ; Multiply X by 2 as X/Y VIC Coords Mem Locations are in x/y pairs as opposed to sequential
  clc
  txa
  rol
  tax
  lda .XCoords,y
  sta VIC_SPRITE_X_0,x
  lda .YCoords,y
  sta VIC_SPRITE_Y_0,x
  ; divide x by 2 to get back to normal
  txa
  ror
  tax
  
.AdvanceToNextVirtualSprite
  ; Advancing to the next hardware / virtual sprite
  inc .CurrentVirtualIndex

  lda .CurrentVirtualIndex
  cmp #.VirtualSpriteCount
  beq .EndVirtualSpriteList 
  
  
  inx
  cpx #8
  beq .SpriteListExhausted
  jmp .HardwareSpriteLoop
  
.SpriteListExhausted
  ; At this point we have run out of hardware sprites
  ; we set our next raster interrupt to the next virtual sprites Y coord - safe line amount
  clc
  ldy .CurrentVirtualIndex
  lda .YCoords,y
  sbc #.RASTER_SAFE_OFFSET
  jmp .ScheduleNextRaster
.EndVirtualSpriteList
  ; Here we have run out of virtual sprites - so we need to schedule the initiator again at line 0
  lda #0
  sta .CurrentVirtualIndex

.ScheduleNextRaster
  ; The A register holds the value of the next raster line schedule
  sta VIC_RASTER
  lda #$7f
  and VIC_CONTROL_REGISTER_1
  sta VIC_CONTROL_REGISTER_1
  

  
  +ACK_RASTER_IRQ  
  +POP_REGISTERS_OFF_STACK
  dec VIC_BORDER_COLOUR
  rti

.SortSpriteList
  ; Bubble Sort
  inc VIC_BORDER_COLOUR
.SortLoop
  lda #1
  sta .SortComplete
  ldy #1
.SortComparePair
  lda .YCoords,y
  cmp .YCoords-1,y
  bcs .PairSorted
  ; swap pair
  jsr .SwapPair

  ; flag as not sorted
  lda #0
  sta .SortComplete
.PairSorted
  iny
  cpy #.VirtualSpriteCount
  bne .SortComparePair
  lda .SortComplete
  beq .SortLoop
  rts


.SwapPair  
  lda .YCoords-1,y
  pha
  lda .YCoords,y
  sta .YCoords-1,y
  pla
  sta .YCoords,y
  
  lda .XCoords-1,y
  pha
  lda .XCoords,y
  sta .XCoords-1,y
  pla
  sta .XCoords,y

  lda .Colours-1,y
  pha
  lda .Colours,y
  sta .Colours-1,y
  pla
  sta .Colours,y

  lda .Pointers-1,y
  pha
  lda .Pointers,y
  sta .Pointers-1,y
  pla
  sta .Pointers,y
  
  lda .Flags-1,y
  pha
  lda .Flags,y
  sta .Flags-1,y
  pla
  sta .Flags,y

  rts

.ProcessSpriteFlag
  ldy .CurrentVirtualIndex
  lda #0
  sta .FlagTemp
  ldx #8

.FlagLoop
  ; find out what this virtual sprites flag is
  clc
  lda .Flags,y
  and .FlagToCheck
  beq .EndFlagLoop
  sec
  ; The virtual sprite flag is set so set the carry so the ror will load it
.EndFlagLoop
  ror .FlagTemp
  dex
  beq .FlagCalcuationOver    ; no more hardware sprites
  iny
  jmp .FlagLoop

.FlagCalcuationOver
  lda .FlagTemp
  rts

.HandleVICFlags
  inc VIC_BORDER_COLOUR
  
  !if Multiplexor.MPX_X_MSB_ALLOWED {
  lda #.FLAG_X_MSB
  sta .FlagToCheck
  jsr .ProcessSpriteFlag
  sta VIC_SPRITE_X_MSB
  }
  
  !if Multiplexor.MPX_X_EXPANSION_ALLOWED {
  lda #.FLAG_X_EXPAND
  sta .FlagToCheck
  jsr .ProcessSpriteFlag
  sta VIC_SPRITE_X_EXPANSION
  }

  !if Multiplexor.MPX_Y_EXPANSION_ALLOWED {
  lda #.FLAG_Y_EXPAND
  sta .FlagToCheck
  jsr .ProcessSpriteFlag
  sta VIC_SPRITE_Y_EXPANSION
  }

  !if Multiplexor.MPX_MULTICOLOUR_ALLOWED {
  lda #.FLAG_MULTICOLOUR
  sta .FlagToCheck
  jsr .ProcessSpriteFlag
  sta VIC_SPRITE_MULTICOLOUR
  }

  !if Multiplexor.MPX_DATA_PRIORITY_ALLOWED {
  lda #.FLAG_PRIORITY
  sta .FlagToCheck
  jsr .ProcessSpriteFlag
  sta VIC_SPRITE_DATA_PRIORITY
  }

  !if Multiplexor.MPX_ENABLED_ALLOWED {
  lda #.FLAG_ENABLED
  sta .FlagToCheck
  jsr .ProcessSpriteFlag
  sta VIC_SPRITE_ENABLE
  }
  dec VIC_BORDER_COLOUR
  
  rts

.XCoords
!fill  Multiplexor.VirtualSpriteCount,$00
.YCoords
!fill  Multiplexor.VirtualSpriteCount,$00
.Colours
!fill  Multiplexor.VirtualSpriteCount,$01
.Pointers
!fill  Multiplexor.VirtualSpriteCount,$00
.Enabled
!fill  Multiplexor.VirtualSpriteCount,$01
.SortComplete
!byte 0

.SortTemp               !byte 0
.FlagTemp               !byte 0
.FlagToCheck            !byte 0

.Flags
!fill Multiplexor.VirtualSpriteCount,$00

.FlagMaskValues
!byte 1
!byte 2
!byte 4
!byte 8
!byte 16
!byte 32
!byte 64
!byte 128
.FlagMaskValuesNegative
!byte 255 - 1
!byte 255 - 2
!byte 255 - 4
!byte 255 - 8
!byte 255 - 16
!byte 255 - 32
!byte 255 - 64
!byte 255 - 128

.CurrentVirtualIndex    !Byte 0
.CurrentHardwareIndex   !byte 0



