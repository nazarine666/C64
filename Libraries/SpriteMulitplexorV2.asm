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
;Multiplexor.MPX_USE_STAGING_AREA      =0

Multiplexor.CLOSE_RASTER_SEPARATION                =5

Multiplexor.MPX_FLAGS_ALLOWED = Multiplexor.MPX_X_MSB_ALLOWED + Multiplexor.MPX_X_EXPANSION_ALLOWED + Multiplexor.MPX_Y_EXPANSION_ALLOWED + Multiplexor.MPX_MULTICOLOUR_ALLOWED + Multiplexor.MPX_DATA_PRIORITY_ALLOWED + Multiplexor.MPX_ENABLED_ALLOWED

Multiplexor.FLAG_X_MSB          =1
Multiplexor.FLAG_X_EXPAND       =2
Multiplexor.FLAG_Y_EXPAND       =4
Multiplexor.FLAG_MULTICOLOUR    =8
Multiplexor.FLAG_PRIORITY       =16
Multiplexor.FLAG_ENABLED        =128



  


!macro MPX_SET_NUMBER_OF_SPRITES spriteCount
  lda #spriteCount
  sta Multiplexor.VirtualSpriteCount
  lda #0
  sta Multiplexor.CurrentVirtualSpriteIndex

!end

!macro MPX_SET_FLAGS sprite,mask    
  lda #mask
  !if Multiplexor.MPX_USE_STAGING_AREA {
    sta Multiplexor.StagingFlags+sprite
  } else  {
    sta Multiplexor.Flags+sprite
  }
!end

!macro MPX_SET_FLAG sprite,flag
  !if Multiplexor.MPX_USE_STAGING_AREA {
    lda Multiplexor.StagingFlags+sprite
    ora #flag
    sta Multiplexor.StagingFlags+sprite
  } else  {
    lda Multiplexor.Flags+sprite
    ora #flag
    sta Multiplexor.Flags+sprite
  }
!end

!macro MPX_CLEAR_FLAG sprite,flag
  !if Multiplexor.MPX_USE_STAGING_AREA {
    lda Multiplexor.StagingFlags+sprite
    and #(255-flag)
    sta Multiplexor.StagingFlags+sprite
  } else  {
    lda Multiplexor.Flags+sprite
    and #(255-flag)
    sta Multiplexor.Flags+sprite
  }
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
  !if Multiplexor.MPX_USE_STAGING_AREA {
    sta Multiplexor.StagingXCoords+sprite
  } else {
    sta Multiplexor.XCoords+sprite
  }
  
  !if xcoord<256 {
    ; +MPX_CLEAR_FLAG sprite,Multiplexor.FLAG_X_MSB
    !if Multiplexor.MPX_USE_STAGING_AREA {
      lda Multiplexor.StagingFlags+sprite
      and #(255-Multiplexor.FLAG_X_MSB)
      sta Multiplexor.StagingFlags+sprite
    } else {
      lda Multiplexor.Flags+sprite
      and #(255-Multiplexor.FLAG_X_MSB)
      sta Multiplexor.Flags+sprite
    }
  }
  !if xcoord >255 {
    ;+MPX_SET_FLAG sprite,Multiplexor.FLAG_X_MSB
    !if Multiplexor.MPX_USE_STAGING_AREA {
      lda Multiplexor.StagingFlags+sprite
      ora #Multiplexor.FLAG_X_MSB
      sta Multiplexor.StagingFlags+sprite
    } else {
      lda Multiplexor.Flags+sprite
      ora #Multiplexor.FLAG_X_MSB
      sta Multiplexor.Flags+sprite
    }
  }
!end

!Macro MPX_SET_YCOORD sprite,ycoord
  lda #ycoord
  !if Multiplexor.MPX_USE_STAGING_AREA {
    sta Multiplexor.StagingYCoords+sprite
  } else {
    sta Multiplexor.YCoords+sprite
  }
!end

!macro MPX_SET_MEMORY_POINTER  sprite,pointer
  lda #pointer
  !if Multiplexor.MPX_USE_STAGING_AREA {
    sta Multiplexor.StagingPointers+sprite
  } else {
    sta Multiplexor.Pointers+sprite
  }
!end

!Macro MPX_SET_COLOUR sprite,colour
  lda #colour
  !if Multiplexor.MPX_USE_STAGING_AREA {
    sta Multiplexor.StagingColours+sprite
  } else {
    sta Multiplexor.Colours+sprite
  }
!end

!macro MPX_ENABLE_SPRITE sprite
  ;+MPX_SET_FLAG sprite,Multiplexor.FLAG_ENABLED
  !if Multiplexor.MPX_USE_STAGING_AREA {
    lda Multiplexor.StagingFlags+sprite
    ora #Multiplexor.FLAG_ENABLED
    sta Multiplexor.StagingFlags+sprite
  } else {
    lda Multiplexor.Flags+sprite
    ora #Multiplexor.FLAG_ENABLED
    sta Multiplexor.Flags+sprite
  }
!end

!macro MPX_DISABLE_SPRITE sprite
  ;+MPX_CLEAR_FLAG sprite,Multiplexor.FLAG_ENABLED
  !if Multiplexor.MPX_USE_STAGING_AREA {
    lda Multiplexor.StagingFlags+sprite
    and #(255-Multiplexor.FLAG_ENABLED)
    sta Multiplexor.StagingFlags+sprite
  } else {
    lda Multiplexor.Flags+sprite
    and #(255-Multiplexor.FLAG_ENABLED)
    sta Multiplexor.Flags+sprite
  }
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

Multiplexor.CopyStagingAreaToActive
  ldx #0
Multiplexor.CopyStagingAreaToActiveLoop
  lda Multiplexor.StagingXCoords,x
  sta Multiplexor.XCoords,x
  
  lda Multiplexor.StagingColours,x
  sta Multiplexor.Colours,x
  
  lda Multiplexor.StagingPointers,x
  sta Multiplexor.Pointers,x
  
  lda Multiplexor.StagingFlags,x
  sta Multiplexor.Flags,x
  
  lda Multiplexor.StagingYCoords,x
  sta Multiplexor.YCoords,x

  inx
  cpx Multiplexor.VirtualSpriteCount
  bne Multiplexor.CopyStagingAreaToActiveLoop
  rts


Multiplexor.EntryPoint
  +PUSH_REGISTERS_ON_STACK

  !if Multiplexor.MPX_DEBUG_BORDER {
    lda #VIC_COLOUR_RED
    sta VIC_BORDER_COLOUR
  }

  ; we are creating the initial sprite list here
  !if Multiplexor.MPX_USE_STAGING_AREA {
    jsr Multiplexor.CopyStagingAreaToActive
  }
  lda #VIC_COLOUR_LIGHT_BLUE
  sta VIC_BORDER_COLOUR

  jsr Multiplexor.SortSpriteList
  inc VIC_BORDER_COLOUR
  ; initial sprite flags
  !if Multiplexor.MPX_FLAGS_ALLOWED {
    jsr Multiplexor.HandleInitialSpriteFlags
  }
  
  ldx #0
  ldy #0
  sty Multiplexor.ReplacementSpriteIndex

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
  iny
  cpy Multiplexor.VirtualSpriteCount
  bne Multiplexor.CheckHardwareIndex
  ldy #0;  Virtual Sprite Index has wrapped around to 0
  ldx #0;
  jmp Multiplexor.InitialSpriteListFinished  
Multiplexor.CheckHardwareIndex
  cpx #8
  bne Multiplexor.InitialHardwareSpriteLoop
  ldx #0

Multiplexor.InitialSpriteListFinished
  sty Multiplexor.CurrentVirtualSpriteIndex
  stx Multiplexor.CurrentHardwareSpriteIndex
  lda #0
  sta Multiplexor.ReplacementSpriteIndex
  lda Multiplexor.YCoords
  clc
  adc # VIC_HARDWARE_SPRITE_HEIGHT
  bcc Multiplexor.InitialRequiredRaster
Multiplexor.InitialRasterSchedule
  lda #VIC_SPRITE_BORDER_BOTTOM
Multiplexor.InitialRequiredRaster
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
  
  ; move to next virtual sprite
  inc Multiplexor.CurrentVirtualSpriteIndex
  lda Multiplexor.CurrentVirtualSpriteIndex
  cmp Multiplexor.VirtualSpriteCount
  beq Multiplexor.SpriteUpdateFinished
  ; We still have sprites to process - lets schedule the raster after the current replacement sprite
  inc Multiplexor.ReplacementSpriteIndex
  ldy Multiplexor.ReplacementSpriteIndex
  lda Multiplexor.YCoords,y
  clc
  adc #VIC_HARDWARE_SPRITE_HEIGHT
  bcs Multiplexor.ScheduleRasterAtBottom
  adc #Multiplexor.CLOSE_RASTER_SEPARATION
  bcs Multiplexor.ScheduleRasterAtBottom
  ;sta .RequestedRaster
  cmp VIC_RASTER

  ; the next sprite to display is less than the current raster - so we can just try and display it
  bcs Multiplexor.RequiredRaster
  
  ; the next required sprite raster is <= the current raster so just go back and draw the next sprite
  lda #VIC_COLOUR_CYAN
  sta VIC_BORDER_COLOUR
  jmp Multiplexor.UpdateSpriteListEntry2
  ;
Multiplexor.SpriteUpdateFinished
  ; we have reached the end of the sprite list
  ; lets schedule the next raster to be bottom of the screen
  lda #0
  sta Multiplexor.CurrentVirtualSpriteIndex
  +STORE_WORD Multiplexor.EntryPoint,KERNAL_IRQ_SERVICE_ROUTINE

  
  jmp Multiplexor.ScheduleRasterAtBottom

Multiplexor.ScheduleRaster
  bcc Multiplexor.RequiredRaster
Multiplexor.ScheduleRasterAtBottom
  lda #VIC_SPRITE_BORDER_BOTTOM
Multiplexor.RequiredRaster  
  sta VIC_RASTER
  
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

!macro MPX_TRUE_Y_INDEX_TO_Y
  lda Multiplexor.Indexes,y
  tay
!end
!macro MPX_TRUE_Y_INDEX_TO_X
  lda Multiplexor.Indexes,y
  tax
!end

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
  
  lda Multiplexor.YCoords,x             ; A = Ycoord at 1st Element
  cmp Multiplexor.YCoords,y             ; Compare with YCoord at 2nd element
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
  

;Multiplexor.SortSpriteList
;  ; Bubble Sort
;Multiplexor.SortLoop
;  lda #1
;  sta Multiplexor.SortComplete
;  ldy #1
;Multiplexor.SortComparePair
;  lda Multiplexor.YCoords,y
;  cmp Multiplexor.YCoords-1,y
;  bcs Multiplexor.PairSorted
;  ; swap pair
;  jsr Multiplexor.SwapPair

;  ; flag as not sorted
;  lda #0
;  sta Multiplexor.SortComplete
;Multiplexor.PairSorted
;  iny
;  cpy Multiplexor.VirtualSpriteCount
;  bne Multiplexor.SortComparePair
;  lda Multiplexor.SortComplete
;  beq Multiplexor.SortLoop
;  rts


Multiplexor.SwapPair  
  lda Multiplexor.YCoords-1,y
  pha
  lda Multiplexor.YCoords,y
  sta Multiplexor.YCoords-1,y
  pla
  sta Multiplexor.YCoords,y
  
  lda Multiplexor.XCoords-1,y
  pha
  lda Multiplexor.XCoords,y
  sta Multiplexor.XCoords-1,y
  pla
  sta Multiplexor.XCoords,y

  lda Multiplexor.Colours-1,y
  pha
  lda Multiplexor.Colours,y
  sta Multiplexor.Colours-1,y
  pla
  sta Multiplexor.Colours,y

  lda Multiplexor.Pointers-1,y
  pha
  lda Multiplexor.Pointers,y
  sta Multiplexor.Pointers-1,y
  pla
  sta Multiplexor.Pointers,y
  
  lda Multiplexor.Flags-1,y
  pha
  lda Multiplexor.Flags,y
  sta Multiplexor.Flags-1,y
  pla
  sta Multiplexor.Flags,y

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
    iny
    cpy Multiplexor.VirtualSpriteCount
    beq Multiplexor.HandleSpriteFlagsExit
    
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


Multiplexor.StagingXCoords
!fill  Multiplexor.MAX_VIRTUAL_SPRITES,$00

Multiplexor.StagingYCoords
!fill  Multiplexor.MAX_VIRTUAL_SPRITES,$00

Multiplexor.StagingColours
!fill  Multiplexor.MAX_VIRTUAL_SPRITES,$00

Multiplexor.StagingPointers
!fill  Multiplexor.MAX_VIRTUAL_SPRITES,$00

Multiplexor.StagingFlags
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