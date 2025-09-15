!source "..\Macros\Macros.asm",once
!source "..\CHIPLabels\VICLabels.asm",once


!zone Multiplexor

Multiplexor.MAX_VIRTUAL_SPRITES           = 32


; Set these flags in your main program befre including the assembly file
;Multiplexor.MPX_X_MSB_ALLOWED         =1
;Multiplexor.MPX_X_EXPANSION_ALLOWED   =1
;Multiplexor.MPX_Y_EXPANSION_ALLOWED   =1
;Multiplexor.MPX_MULTICOLOUR_ALLOWED   =1
;Multiplexor.MPX_DATA_PRIORITY_ALLOWED =1
;Multiplexor.MPX_ENABLED_ALLOWED       =1
;Multiplexor.MPX_DEBUG_BORDER          =1


Multiplexor.CLOSE_RASTER_SEPARATION                =3

Multiplexor.MPX_FLAGS_ALLOWED = Multiplexor.MPX_X_MSB_ALLOWED + Multiplexor.MPX_X_EXPANSION_ALLOWED + Multiplexor.MPX_Y_EXPANSION_ALLOWED + Multiplexor.MPX_MULTICOLOUR_ALLOWED + Multiplexor.MPX_DATA_PRIORITY_ALLOWED + Multiplexor.MPX_ENABLED_ALLOWED

Multiplexor.FLAG_X_MSB          =1
Multiplexor.FLAG_X_EXPAND       =2
Multiplexor.FLAG_Y_EXPAND       =4
Multiplexor.FLAG_MULTICOLOUR    =8
Multiplexor.FLAG_PRIORITY       =16
Multiplexor.FLAG_ENABLED        =128



  
!macro MPX_TRUE_Y_INDEX_TO_Y
  lda Multiplexor.Indexes,y
  tay
!end
!macro MPX_TRUE_Y_INDEX_TO_X
  lda Multiplexor.Indexes,y
  tax
!end


!macro MPX_SET_NUMBER_OF_SPRITES spriteCount
  lda #spriteCount
  sta Multiplexor.VirtualSpriteCount
  lda #0
  sta Multiplexor.CurrentVirtualSpriteIndex

!end

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
  sta Multiplexor.StoreScreenPointerInitial+1
  lda #>(screen_address+VIC_SPRITE_MEMORY_POINTER_OFFSET)
  sta Multiplexor.StoreScreenPointerInitial+2

  lda #<(screen_address+VIC_SPRITE_MEMORY_POINTER_OFFSET)
  sta Multiplexor.StoreScreenPointerUpdate+1
  lda #>(screen_address+VIC_SPRITE_MEMORY_POINTER_OFFSET)
  sta Multiplexor.StoreScreenPointerUpdate+2
  
  +MPX_INTIATE_SPRITE_INDEXES
!end

!Macro MPX_SET_XCOORD sprite,xcoord
  lda #<xcoord
  sta Multiplexor.XCoords+sprite
  
  !if xcoord<256 {
    lda Multiplexor.Flags+sprite
    and #(255-Multiplexor.FLAG_X_MSB)
    sta Multiplexor.Flags+sprite
  }
  !if xcoord >255 {
    lda Multiplexor.Flags+sprite
    ora #Multiplexor.FLAG_X_MSB
    sta Multiplexor.Flags+sprite
  }
!end

!Macro MPX_SET_YCOORD sprite,ycoord
  lda #ycoord
  sta Multiplexor.YCoords+sprite
  +MPX_SET_YCOORD_OVERFLOW sprite
!end

!Macro MPX_SET_YCOORD_OVERFLOW sprite
  ldx #VIC_HARDWARE_SPRITE_HEIGHT
  lda Multiplexor.Flags + sprite
  and #Multiplexor.FLAG_Y_EXPAND
  beq +     ; Flag Not Set
  ldx #VIC_HARDWARE_SPRITE_HEIGHT*2
  ; Flag Not Set
  +
  txa
  clc
  adc Multiplexor.YCoords+sprite
  bcs + ; Overflowed into border
  cmp #VIC_SPRITE_BORDER_BOTTOM
  bcc ++ ; no overflow
  +  
  lda #VIC_SPRITE_BORDER_BOTTOM
  ++
  sta Multiplexor.YCoordsBottom+sprite
!end

!Macro MPX_SET_YCOORD_OVERFLOW_ALL
  !For sprite=0 to Multiplexor.MAX_VIRTUAL_SPRITES
    +MPX_SET_YCOORD_OVERFLOW sprite
  !end
!End


!macro MPX_SET_MEMORY_POINTER  sprite,pointer
  lda #pointer
  sta Multiplexor.Pointers+sprite
!end

!Macro MPX_SET_COLOUR sprite,colour
  lda #colour
  sta Multiplexor.Colours+sprite
!end

!macro MPX_ENABLE_SPRITE sprite
  lda Multiplexor.Flags+sprite
  ora #Multiplexor.FLAG_ENABLED
  sta Multiplexor.Flags+sprite
!end

!macro MPX_DISABLE_SPRITE sprite
  lda Multiplexor.Flags+sprite
  and #(255-Multiplexor.FLAG_ENABLED)
  sta Multiplexor.Flags+sprite
!end

; Pseudocode
; Push Registers
; if virtual sprite index is 0
;   sort sprite list
;   flag as on initial sprite loop
; else
;   flag as not on intiial sprite loop

; SPRITE LOOP
;   increment oldest sprite index value
;   and #7 oldest sprite index value
;
;   draw virtual sprite on hardware sprite
;
;   increment virtual sprite index
;   increment hardware sprite index
;   and hardware sprite index with #7
;
;   if on initial sprite loop need to do the following
;     if virtual index has reached zero
;       we have displayed all we can
;     if hardware index has reached 0
;       we have displayed all we can
;     if more to display
;       jmp to SPRITE LOOP
;
;     no more to display
;     set oldest sprite to be #0
;     set virtual sprite index to #0
;     Jmp to SCHEDULE RASTER
;
;   if not on initial sprite loop
;     if virtual sprite index has reached the sprite count
;       set virtual sprite index to be #0
; SCHEDULE RASTER
;   schedule raster for oldest sprite y position + height
;   acknowledge interrupts
;   Pop Registers
;   rti
  
;
; 817


Multiplexor.EntryPoint
  ; 835
  +PUSH_REGISTERS_ON_STACK

  !if Multiplexor.MPX_DEBUG_BORDER {
    lda #VIC_COLOUR_RED
    sta VIC_BORDER_COLOUR
  }

  ; we are creating the initial sprite list here

  jsr Multiplexor.SortSpriteList
  !if Multiplexor.MPX_DEBUG_BORDER {
    lda #VIC_COLOUR_BLACK
    sta VIC_BORDER_COLOUR
  }
  ;inc VIC_BORDER_COLOUR
  ldy #0

  +MPX_TRUE_Y_INDEX_TO_Y      ; translate the current y index t0 an actual y index
  ; initial sprite flags
  !if Multiplexor.MPX_FLAGS_ALLOWED {
    jsr Multiplexor.HandleInitialSpriteFlags
    ; y changed after this routine
    ldy #0
    sty Multiplexor.CurrentVirtualSpriteIndex
    +MPX_TRUE_Y_INDEX_TO_Y
  }
  
  ldx #0

Multiplexor.InitialHardwareSpriteLoop
  lda Multiplexor.Colours,y
  sta VIC_SPRITE_COLOUR_0,x
  lda Multiplexor.Pointers,y
.StoreScreenPointerInitial ; The address gets overwritten during the MPX_INIT macro
  sta $ffff,x

  ; Multiply X by 2 as X/Y hardware coordinates are stored in pairs, not sequentially
  txa
  asl
  tax
  
  ; X/Y coordinates
  lda Multiplexor.XCoords,y
  sta VIC_SPRITE_X_0,x
  lda Multiplexor.YCoords,y
  sta VIC_SPRITE_Y_0,x
  
  ; divide X by 2 to get back to normal
  clc
  txa
  ror
  tax
  
  ; increment hardware sprite index
  inx
  
  ; increment virtual sprite index
  inc Multiplexor.CurrentVirtualSpriteIndex
  ldy Multiplexor.CurrentVirtualSpriteIndex
  cpy Multiplexor.VirtualSpriteCount
  bne Multiplexor.CheckHardwareIndex
  ldy #0;  Virtual Sprite Index has wrapped around to 0
  sty Multiplexor.CurrentVirtualSpriteIndex
  jmp Multiplexor.InitialSpriteListFinished  
Multiplexor.CheckHardwareIndex
  
  cpx #8
  beq Multiplexor.InitialSpriteListFinished
  ;at this point the y register points to the virtual sprite index
  ;but not the actual sprite data index - so need to translate it
  +MPX_TRUE_Y_INDEX_TO_Y
  jmp Multiplexor.InitialHardwareSpriteLoop

Multiplexor.InitialSpriteListFinished
  ldx #0
  stx Multiplexor.CurrentHardwareSpriteIndex
  stx Multiplexor.ReplacementSpriteIndex
  ; we need to get the first sprite in the list's Y Coordinate
;  ldy Multiplexor.Indexes     ; get the first sprites index
;  lda Multiplexor.YCoords,y   ; and the actual sprites y coord
;  clc
;  adc #VIC_HARDWARE_SPRITE_HEIGHT
;  bcc Multiplexor.InitialRequiredRaster
;Multiplexor.InitialRasterSchedule
;  lda #VIC_SPRITE_BORDER_BOTTOM
;Multiplexor.InitialRequiredRaster
  ldy Multiplexor.Indexes
  lda Multiplexor.YCoordsBottom,y
  
  
  sta VIC_RASTER
  
  lda #$7f   ; turn off raster MSB
  and VIC_CONTROL_REGISTER_1
  sta VIC_CONTROL_REGISTER_1

  +STORE_WORD Multiplexor.UpdateSpriteList,KERNAL_IRQ_SERVICE_ROUTINE

  +ACK_RASTER_IRQ  
  
  !if Multiplexor.MPX_DEBUG_BORDER {
    lda #VIC_COLOUR_BLACK
    sta VIC_BORDER_COLOUR
  }
  +POP_REGISTERS_OFF_STACK
  rti
  
  
Multiplexor.UpdateSpriteList
  +PUSH_REGISTERS_ON_STACK

  !if Multiplexor.MPX_DEBUG_BORDER {
    lda #VIC_COLOUR_GREEN
    sta VIC_BORDER_COLOUR
  }

Multiplexor.UpdateSpriteListEntry2

  ; At this point we have already got the initial sprite list on the screen
  ; we just need to replace the current hardware sprite with the current
  ; virtual sprite
  ldy Multiplexor.CurrentVirtualSpriteIndex
  +MPX_TRUE_Y_INDEX_TO_Y
  ldx Multiplexor.CurrentHardwareSpriteIndex

  lda Multiplexor.Colours,y
  sta VIC_SPRITE_COLOUR_0,x
  lda Multiplexor.Pointers,y
.StoreScreenPointerUpdate ; The address gets overwritten during the MPX_INIT macro
  sta $ffff,x

  !if Multiplexor.MPX_FLAGS_ALLOWED {
    jsr Multiplexor.HandleUpdateSpriteFlags
  }

  ; Multiply X by 2 as X/Y hardware coordinates are stored in pairs, not sequentially
  txa
  asl
  tax
  ; X/Y coordinates
  lda Multiplexor.XCoords,y
  sta VIC_SPRITE_X_0,x
  lda Multiplexor.YCoords,y
  sta VIC_SPRITE_Y_0,x


  ; move to next hardware sprite
  inc Multiplexor.CurrentHardwareSpriteIndex
  lda Multiplexor.CurrentHardwareSpriteIndex
  and #7
  sta Multiplexor.CurrentHardwareSpriteIndex
  
  ; move to the next replacement sprite
  inc Multiplexor.ReplacementSpriteIndex
  ; move to next virtual sprite
  inc Multiplexor.CurrentVirtualSpriteIndex
  lda Multiplexor.CurrentVirtualSpriteIndex
  cmp Multiplexor.VirtualSpriteCount
  beq Multiplexor.SpriteUpdateFinished
  ; We still have sprites to process - lets schedule the raster after the current replacement sprite
  ldy Multiplexor.ReplacementSpriteIndex
  +MPX_TRUE_Y_INDEX_TO_Y
  lda Multiplexor.YCoordsBottom,y

  ; compare the requested raster interrupt with the current raster
  ; problem - bottom value is same as raster - so it schedules raster as now
  ; which causes flickering
  
  sbc #Multiplexor.CLOSE_RASTER_SEPARATION
  cmp VIC_RASTER

  ; the next sprite to display is less than the current raster - so we can just try and display it
  bcc Multiplexor.NotRequiredRaster
  lda Multiplexor.YCoordsBottom,y
  jmp Multiplexor.RequiredRaster
Multiplexor.NotRequiredRaster
  ; the next required sprite raster is <= the current raster so just go back and draw the next sprite
  ;inc Multiplexor.ReplacementSpriteIndex
  inc VIC_BORDER_COLOUR
  jmp Multiplexor.UpdateSpriteListEntry2

Multiplexor.SpriteUpdateFinished
  ; we have reached the end of the sprite list
  ; lets schedule the next raster to be after the last sprite / bottom of the screen - which ever is lower
  lda #0
  sta Multiplexor.CurrentVirtualSpriteIndex

  ldy Multiplexor.VirtualSpriteCount
  dey
  +MPX_TRUE_Y_INDEX_TO_Y
  lda Multiplexor.YCoordsBottom,y
  ; store the A register as the required raster and schedule the next interrupt to be the initial list again
  sta VIC_RASTER
  +STORE_WORD Multiplexor.EntryPoint,KERNAL_IRQ_SERVICE_ROUTINE
  jmp Multiplexor.AfterRasterStored

Multiplexor.ScheduleRaster
  bcc Multiplexor.RequiredRaster
Multiplexor.ScheduleRasterAtBottom
  lda #VIC_SPRITE_BORDER_BOTTOM
  
  
Multiplexor.RequiredRaster  
  sta VIC_RASTER
  ;inc Multiplexor.ReplacementSpriteIndex

Multiplexor.AfterRasterStored  
  lda #$7f   ; turn off raster MSB
  and VIC_CONTROL_REGISTER_1
  sta VIC_CONTROL_REGISTER_1
Multiplexor.AfterRasterMSB


  +ACK_RASTER_IRQ
  
  !if Multiplexor.MPX_DEBUG_BORDER {
    lda #VIC_COLOUR_BLACK
    sta VIC_BORDER_COLOUR
  }
  +POP_REGISTERS_OFF_STACK
  rti


Multiplexor.SortIndex !byte 0

!macro MPX_INTIATE_SPRITE_INDEXES
  !for sprite= 0 to Multiplexor.MAX_VIRTUAL_SPRITES
    lda #sprite
    sta Multiplexor.Indexes+sprite
  !end
!end

Multiplexor.SortSpriteList
Multiplexor.SortLoop
  lda #1
  sta Multiplexor.SortIndex
  sta Multiplexor.SortComplete

Multiplexor.SortCompare
  ldy Multiplexor.SortIndex
  dey
  +MPX_TRUE_Y_INDEX_TO_X      ; X = Indexes,(y-1)
  
  ldy Multiplexor.SortIndex
  +MPX_TRUE_Y_INDEX_TO_Y      ; Y = Indexes,y
  
  ; at this point - X hold the 1st element index
  ; y holds the second element index
  
  lda Multiplexor.YCoordsBottom,x             ; A = Ycoord at 1st Element
  cmp Multiplexor.YCoordsBottom,y             ; Compare with YCoord at 2nd element
  beq Multiplexor.PairSorted
  bcc Multiplexor.PairSorted            ; If 1st Ycoord < 2nd YCoord then pair already sorted
  ; Swap the indexes around here
  ldy Multiplexor.SortIndex
  lda Multiplexor.Indexes,y
  pha
  lda Multiplexor.Indexes-1,y
  sta Multiplexor.Indexes,y
  pla
  sta Multiplexor.Indexes-1,y
  ; flag as not sorted
  lda #0
  sta Multiplexor.SortComplete
Multiplexor.PairSorted
  inc Multiplexor.SortIndex
  ldy Multiplexor.SortIndex
  cpy Multiplexor.VirtualSpriteCount
  bne Multiplexor.SortCompare   ;sort check the next pair
  lda Multiplexor.SortComplete
  beq Multiplexor.SortLoop
  ; sort has finished
  rts
  



Multiplexor.HandleInitialSpriteFlags
  !if Multiplexor.MPX_FLAGS_ALLOWED {
    lda #0
    !if Multiplexor.MPX_ENABLED_ALLOWED {
      sta VIC_SPRITE_ENABLE
    }
    !if Multiplexor.MPX_X_MSB_ALLOWED {
      sta VIC_SPRITE_X_MSB
    }
    !if Multiplexor.MPX_DATA_PRIORITY_ALLOWED {
      sta VIC_SPRITE_DATA_PRIORITY
    }
    !if Multiplexor.MPX_MULTICOLOUR_ALLOWED {
      sta VIC_SPRITE_MULTICOLOUR
    }
    !if Multiplexor.MPX_X_EXPANSION_ALLOWED {
      sta VIC_SPRITE_X_EXPANSION
    }
    !if Multiplexor.MPX_Y_EXPANSION_ALLOWED {
      sta VIC_SPRITE_Y_EXPANSION
    }
    ldy Multiplexor.CurrentVirtualSpriteIndex
    +MPX_TRUE_Y_INDEX_TO_Y
    ldx #0
Multiplexor.HandleSpriteFlagsHardwareLoop
    !if Multiplexor.MPX_ENABLED_ALLOWED {
      lda Multiplexor.Flags,y
      and #Multiplexor.FLAG_ENABLED
      beq Multiplexor.HandleSpriteFlagsNotEnabled
      lda VIC_SPRITE_ENABLE
      ora Multiplexor.FlagMaskValues,x
      sta VIC_SPRITE_ENABLE
    }
Multiplexor.HandleSpriteFlagsNotEnabled
    !if Multiplexor.MPX_X_MSB_ALLOWED {
      lda Multiplexor.Flags,y
      and #Multiplexor.FLAG_X_MSB
      beq Multiplexor.HandleSpriteFlagsNotXMSB
      lda VIC_SPRITE_X_MSB
      ora Multiplexor.FlagMaskValues,x
      sta VIC_SPRITE_X_MSB
    }
Multiplexor.HandleSpriteFlagsNotXMSB
    !if Multiplexor.MPX_DATA_PRIORITY_ALLOWED {
      lda Multiplexor.Flags,y
      and #Multiplexor.FLAG_PRIORITY
      beq Multiplexor.HandleSpriteFlagsNotPriority
      lda VIC_SPRITE_DATA_PRIORITY
      ora Multiplexor.FlagMaskValues,x
      sta VIC_SPRITE_DATA_PRIORITY
    }
Multiplexor.HandleSpriteFlagsNotPriority
    !if Multiplexor.MPX_MULTICOLOUR_ALLOWED {
      lda Multiplexor.Flags,y
      and #Multiplexor.FLAG_MULTICOLOUR
      beq Multiplexor.HandleSpriteFlagsNotMulticolour
      lda VIC_SPRITE_MULTICOLOUR
      ora Multiplexor.FlagMaskValues,x
      sta VIC_SPRITE_MULTICOLOUR
    }
Multiplexor.HandleSpriteFlagsNotMulticolour
    !if Multiplexor.MPX_X_EXPANSION_ALLOWED {
      lda Multiplexor.Flags,y
      and #Multiplexor.FLAG_X_EXPAND
      beq Multiplexor.HandleSpriteFlagsNotXExpand
      lda VIC_SPRITE_X_EXPANSION
      ora Multiplexor.FlagMaskValues,x
      sta VIC_SPRITE_X_EXPANSION
    }
Multiplexor.HandleSpriteFlagsNotXExpand
    !if Multiplexor.MPX_Y_EXPANSION_ALLOWED {
      lda Multiplexor.Flags,y
      and #Multiplexor.FLAG_Y_EXPAND
      beq Multiplexor.HandleSpriteFlagsNotYExpand
      lda VIC_SPRITE_Y_EXPANSION
      ora Multiplexor.FlagMaskValues,x
      sta VIC_SPRITE_Y_EXPANSION
    }
Multiplexor.HandleSpriteFlagsNotYExpand

    ; advance hardware and virtual sprite count
    inx
    cpx #VIC_HARDWARE_SPRITE_COUNT
    beq Multiplexor.HandleSpriteFlagsExit
    inc Multiplexor.CurrentVirtualSpriteIndex
    ldy Multiplexor.CurrentVirtualSpriteIndex
    cpy Multiplexor.VirtualSpriteCount
    beq Multiplexor.HandleSpriteFlagsExit
    +MPX_TRUE_Y_INDEX_TO_Y
    jmp Multiplexor.HandleSpriteFlagsHardwareLoop
Multiplexor.HandleSpriteFlagsExit

    rts
  }
  



    
Multiplexor.HandleUpdateSpriteFlags
  !if Multiplexor.MPX_FLAGS_ALLOWED {
    !if Multiplexor.MPX_Y_EXPANSION_ALLOWED {
      lda Multiplexor.Flags,y
      and #Multiplexor.FLAG_Y_EXPAND
      beq Multiplexor.HandleUpdateSpriteFlagsNot_Y_EXPANSION
      ; Flag Set
      lda Multiplexor.FlagMaskValues,x
      ora VIC_SPRITE_Y_EXPANSION
      sta VIC_SPRITE_Y_EXPANSION
      jmp Multiplexor.HandleUpdateSpriteFlagsAfter_Y_EXPANSION
    Multiplexor.HandleUpdateSpriteFlagsNot_Y_EXPANSION
      ; Flag Not Set
      lda Multiplexor.FlagNegativeMaskValues,x
      and VIC_SPRITE_Y_EXPANSION
      sta VIC_SPRITE_Y_EXPANSION
    }
    Multiplexor.HandleUpdateSpriteFlagsAfter_Y_EXPANSION
    
    !if Multiplexor.MPX_X_EXPANSION_ALLOWED {
      lda Multiplexor.Flags,y
      and #Multiplexor.FLAG_X_EXPAND
      beq Multiplexor.HandleUpdateSpriteFlagsNot_X_EXPANSION
      ; Flag Set
      lda Multiplexor.FlagMaskValues,x
      ora VIC_SPRITE_X_EXPANSION
      sta VIC_SPRITE_X_EXPANSION
      jmp Multiplexor.HandleUpdateSpriteFlagsAfter_X_EXPANSION
    Multiplexor.HandleUpdateSpriteFlagsNot_X_EXPANSION
      ; Flag Not Set
      lda Multiplexor.FlagNegativeMaskValues,x
      and VIC_SPRITE_X_EXPANSION
      sta VIC_SPRITE_X_EXPANSION
    }
    Multiplexor.HandleUpdateSpriteFlagsAfter_X_EXPANSION
    
    !if Multiplexor.MPX_MULTICOLOUR_ALLOWED {
      lda Multiplexor.Flags,y
      and #Multiplexor.FLAG_MULTICOLOUR
      beq Multiplexor.HandleUpdateSpriteFlagsNot_MULTICOLOUR
      ; Flag Set
      lda Multiplexor.FlagMaskValues,x
      ora VIC_SPRITE_MULTICOLOUR
      sta VIC_SPRITE_MULTICOLOUR
      jmp Multiplexor.HandleUpdateSpriteFlagsAfter_MULTICOLOUR
    Multiplexor.HandleUpdateSpriteFlagsNot_MULTICOLOUR
      ; Flag Not Set
      lda Multiplexor.FlagNegativeMaskValues,x
      and VIC_SPRITE_MULTICOLOUR
      sta VIC_SPRITE_MULTICOLOUR
    }
    Multiplexor.HandleUpdateSpriteFlagsAfter_MULTICOLOUR
    
    !if Multiplexor.MPX_ENABLED_ALLOWED {
      lda Multiplexor.Flags,y
      and #Multiplexor.FLAG_ENABLED
      beq Multiplexor.HandleUpdateSpriteFlagsNot_ENABLED
      ; Flag Set
      lda Multiplexor.FlagMaskValues,x
      ora VIC_SPRITE_ENABLE
      sta VIC_SPRITE_ENABLE
      jmp Multiplexor.HandleUpdateSpriteFlagsAfter_ENABLED
    Multiplexor.HandleUpdateSpriteFlagsNot_ENABLED
      ; Flag Not Set
      lda Multiplexor.FlagNegativeMaskValues,x
      and VIC_SPRITE_ENABLE
      sta VIC_SPRITE_ENABLE
    }
    Multiplexor.HandleUpdateSpriteFlagsAfter_ENABLED
    
    !if Multiplexor.MPX_DATA_PRIORITY_ALLOWED {
      lda Multiplexor.Flags,y
      and #Multiplexor.FLAG_PRIORITY
      beq Multiplexor.HandleUpdateSpriteFlagsNot_DATA_PRIORITY
      ; Flag Set
      lda Multiplexor.FlagMaskValues,x
      ora VIC_SPRITE_DATA_PRIORITY
      sta VIC_SPRITE_DATA_PRIORITY
      jmp Multiplexor.HandleUpdateSpriteFlagsAfter_DATA_PRIORITY
    Multiplexor.HandleUpdateSpriteFlagsNot_DATA_PRIORITY
      ; Flag Not Set
      lda Multiplexor.FlagNegativeMaskValues,x
      and VIC_SPRITE_DATA_PRIORITY
      sta VIC_SPRITE_DATA_PRIORITY
    }
    Multiplexor.HandleUpdateSpriteFlagsAfter_DATA_PRIORITY
    
    !if Multiplexor.MPX_X_MSB_ALLOWED {
      lda Multiplexor.Flags,y
      and #Multiplexor.FLAG_X_MSB
      beq Multiplexor.HandleUpdateSpriteFlagsNot_XMSB
      ; Flag Set
      lda Multiplexor.FlagMaskValues,x
      ora VIC_SPRITE_X_MSB
      sta VIC_SPRITE_X_MSB
      jmp Multiplexor.HandleUpdateSpriteFlagsAfter_XMSB
    Multiplexor.HandleUpdateSpriteFlagsNot_XMSB
      ; Flag Not Set
      lda Multiplexor.FlagNegativeMaskValues,x
      and VIC_SPRITE_X_MSB
      sta VIC_SPRITE_X_MSB
    }
    Multiplexor.HandleUpdateSpriteFlagsAfter_XMSB
    
    rts
  }

  

  
Multiplexor.VirtualSpriteCount           !byte Multiplexor.MAX_VIRTUAL_SPRITES

Multiplexor.CurrentVirtualSpriteIndex    !byte 0
Multiplexor.CurrentHardwareSpriteIndex   !byte 0
Multiplexor.ReplacementSpriteIndex       !byte 0

Multiplexor.Indexes
!fill  Multiplexor.MAX_VIRTUAL_SPRITES,$00

Multiplexor.XCoords
!fill  Multiplexor.MAX_VIRTUAL_SPRITES,$00

Multiplexor.YCoords
!fill  Multiplexor.MAX_VIRTUAL_SPRITES,$00

Multiplexor.Colours
!fill  Multiplexor.MAX_VIRTUAL_SPRITES,$00

Multiplexor.Pointers
!fill  Multiplexor.MAX_VIRTUAL_SPRITES,$00

Multiplexor.Flags
!fill  Multiplexor.MAX_VIRTUAL_SPRITES,$00

Multiplexor.YCoordsBottom
!fill  Multiplexor.MAX_VIRTUAL_SPRITES,$00

Multiplexor.SortComplete                !byte 0

Multiplexor.RequestedRaster             !byte 0

Multiplexor.FlagMaskValues
!byte 1
!byte 2
!byte 4
!byte 8
!byte 16
!byte 32
!byte 64
!byte 128

Multiplexor.FlagNegativeMaskValues
!byte 255 - 1
!byte 255 - 2
!byte 255 - 4
!byte 255 - 8
!byte 255 - 16
!byte 255 - 32
!byte 255 - 64
!byte 255 - 128