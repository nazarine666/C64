!source "..\Macros\Macros.asm",once
!source "..\CHIPLabels\VICLabels.asm",once


!zone Multiplexor


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Parameters
;; Specify these in the calling routine to influence behaviour
;;
; Multiplexor.MPX_X_MSB_ALLOWED         =1
; Multiplexor.MPX_X_EXPANSION_ALLOWED   =1
; Multiplexor.MPX_Y_EXPANSION_ALLOWED   =1
; Multiplexor.MPX_MULTICOLOUR_ALLOWED   =1
; Multiplexor.MPX_DATA_PRIORITY_ALLOWED =1
; Multiplexor.MPX_ENABLED_ALLOWED       =1
; Multiplexor.MPX_DEBUG_BORDER          =1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Constants - Configurable
;;
; The maximum possible virtual sprites
Multiplexor.MAX_VIRTUAL_SPRITES           = 32
Multiplexor.MAX_RASTER_HOOKS              = 5

; How many raster lines it takes to process an update. If difference between next required raster and current raster is <= this then don't initiate a new interrupt - just run the code again
Multiplexor.CLOSE_RASTER_SEPARATION                =3


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Macros
;;
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
  ;sta Multiplexor.StoreScreenPointerInitial+1
  lda #>(screen_address+VIC_SPRITE_MEMORY_POINTER_OFFSET)
  ;sta Multiplexor.StoreScreenPointerInitial+2

  lda #<(screen_address+VIC_SPRITE_MEMORY_POINTER_OFFSET)
  ;sta Multiplexor.StoreScreenPointerUpdate+1
  lda #>(screen_address+VIC_SPRITE_MEMORY_POINTER_OFFSET)
  ;sta Multiplexor.StoreScreenPointerUpdate+2
  
  +MPX_INITIATE_SPRITE_INDEXES
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
  +MPX_SET_SAFE_DELETE_RASTER sprite
!end

!Macro MPX_SET_SAFE_DELETE_RASTER sprite
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
  sta Multiplexor.SafeToDelete+sprite
!end

!Macro MPX_SET_ALL_SAFE_DELETE_RASTERS
  !For sprite=0 to Multiplexor.MAX_VIRTUAL_SPRITES
    +MPX_SET_SAFE_DELETE_RASTER sprite
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

!macro MPX_INITIATE_SPRITE_INDEXES
  !for sprite= 0 to Multiplexor.MAX_VIRTUAL_SPRITES
    lda #sprite
    sta Multiplexor.SpriteIndexes+sprite
  !end
!end

!macro MPX_SET_RASTER_HOOK_COUNT rasterCount
  lda #rasterCount
  sta Multiplexor.RasterHookCount
!end

!macro MPX_SET_RASTER_HOOK rasterIndex,rasterLine,hookAddress
  lda #rasterLine
  sta Multiplexor.RasterHookWhen+rasterIndex
  lda #<hookAddress
  sta Multiplexor.RasterHooAddressLSB+rasterIndex
  lda #>hookAddress
  sta Multiplexor.RasterHooAddressMSB+rasterIndex
!end


; Given a virtual sprite index in Y, return the true sprite data offset in the y register
!macro MPX_TRUE_Y_INDEX_TO_Y
  lda Multiplexor.SpriteIndexes,y
  tay
!end

; Given a virtual sprite index in Y, return the true sprite data offset in the x register
!macro MPX_TRUE_Y_INDEX_TO_X
  lda Multiplexor.SpriteIndexes,y
  tax
!end


; SpriteTable
;             Y Coordinate    Expand    SafeToDelete
; VS 00       100             N         121
; VS 01       110             N         131
; VS 02       120             N         141
; VS 03       130             N         151
; VS 04       140             N         161
; VS 05       150             N         171
; VS 06       160             Y         202
; VS 07       170             N         191
; VS 08       180             N         201
; VS 09       190             N         211
; VS 10       200             N         221
; VS 11       210             N         231

; Custom      DrawRaster
; CR 00       135
; CR 01       165
; CR 02       185

; SortedSpriteTable
;; Sorted By Safe Deletion
; Index       Virtusl Sprite  Hardware Sprite   DrawingSprite
; 00          VS 00           0                 VS06    (08)
; 01          VS 01           1                 VS09    (09)
; 02          VS 02           2                 VS10    (10)
; 03          VS 03           3                 VS11    (11)
; 04          VS 04           4                 VS00    (00)
; 05          VS 05           5                 VS01    (01)
; 06          VS 07           6                 VS02    (02)
; 07          VS 08           7                 VS03    (03)
; 08          VS 06           0                 VS04    (04)
; 09          VS 09           1                 VS05    (05)
; 10          VS 10           2                 VS07    (06)
; 11          VS 11           3                 VS08    (07)


; Drawing Table   What      When        Hardware Sprite
; 00              VS06      121         0
; 01              VS09      131         1
; 03              CR80      135
; 04              VS10      141         2
; 05              VS11      151         3
; 06              VS00      161         4
; 07              CR81      165
; 08              VS01      171         5
; 09              CR82      185
; 10              VS02      191         6
; 11              VS03      201         7
; 12              VS04      202         0
; 13              VS05      211         1
; 14              VS07      221         2
; 15              VS08      231         3


; Calculate SafeDeletion during sprite addition
; assume custom rasters are already sorted
; Sort Rasters by SafeDeletion to produce index table
; Create drawing table by
; custom index =0
; sprite index =0
; hardware index = 0
; set draw index = 0
;
; DrawingSetupLoop
; ----------------
; if customindex = customcount then CheckSprites
; if DrawRaster(CustomIndex) <= SafeDeletion(SpriteIndex)
;   set DrawingTable.What(draw index) = custom index or #$80
;   set DrawingTable.When(draw index) = Custom table(CustomIndex).DrawRaster
;   increment custom index
;   jump EndDrawingLoop
; CheckSprites
; ------------
; else
;   Set DrawingTable.What(draw index) = sprite index
;   set DrawingTable.When(draw index) = SpriteTable(SortedSpriteTable(SpriteIndex).DrawingSprite).SafeDeletion
;   increment sprite index
;
; EndDrawingLoop
; --------------
; if customindex <> customcount goto DrawingSetupLoop
; if spriteindex <> spritecount goto DrawingSetupLoop
; if here - the drawing table has been created
; we set the drawing index to be 0
; we set the raster to be drawingtable(drawingindex).when
; we set hardware sprite index to be 0
; trigger raster

; RasterRoutine
; if drawingTable.What(drawingIndex) is sprite
;     draw sprite
;     increment hardware sprite index
; if drawingTable.what(drawingIndex) is custom
;     draw custom
; increment drawing index
; if drawindex = drawing count
;    set drawing index to be 0
;    set raster request to drawingtable(0).When
;    RTI
; if drawingTable.When(drawingIndex) < current raster
;   goto RasterRoutineEntry
; set raster request to drawingTable(drawingIndex).when
; RTI




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Constants - Fixed
;;

; The overall boolean to indicate if Sprite flag processing is required
Multiplexor.MPX_FLAGS_ALLOWED = Multiplexor.MPX_X_MSB_ALLOWED + Multiplexor.MPX_X_EXPANSION_ALLOWED + Multiplexor.MPX_Y_EXPANSION_ALLOWED + Multiplexor.MPX_MULTICOLOUR_ALLOWED + Multiplexor.MPX_DATA_PRIORITY_ALLOWED + Multiplexor.MPX_ENABLED_ALLOWED
; Sprite X MSB flag can be set
Multiplexor.FLAG_X_MSB                    =1
; Sprite X Double width flag
Multiplexor.FLAG_X_EXPAND                 =2
; Sprite Y Double width flag
Multiplexor.FLAG_Y_EXPAND                 =4
; Sprite Multicolour flag
Multiplexor.FLAG_MULTICOLOUR              =8
; Sprite Priority flag
Multiplexor.FLAG_PRIORITY                 =16
; Sprite Enabled flag
Multiplexor.FLAG_ENABLED                  =32
; Multiplexor hook, not a sprite
Multiplexor.FLAG_HOOK                     =128

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Main Variables (Sprites)
;;
; The number of virtual sprites
Multiplexor.VirtualSpriteCount           !byte Multiplexor.MAX_VIRTUAL_SPRITES

; The next virtual sprite to try and display
Multiplexor.CurrentVirtualSpriteIndex    !byte 0

; The index into the actual sprite data
Multiplexor.SpriteIndexes
!fill  Multiplexor.MAX_VIRTUAL_SPRITES,$00

; The X Coordinates of the virtual sprites
Multiplexor.XCoords
!fill  Multiplexor.MAX_VIRTUAL_SPRITES,$00

; The Y Coordinates of the virtual sprites
Multiplexor.YCoords
!fill  Multiplexor.MAX_VIRTUAL_SPRITES,$00

; The Y Coordinates when this virtual sprite is safe to delete
Multiplexor.SafeToDelete
!fill  Multiplexor.MAX_VIRTUAL_SPRITES,$00

; The Colours of the virtual sprites
Multiplexor.Colours
!fill  Multiplexor.MAX_VIRTUAL_SPRITES,$00

; The Sprite frame pointer of the virtual sprites
Multiplexor.Pointers
!fill  Multiplexor.MAX_VIRTUAL_SPRITES,$00

; The flags of the virtual sprites
Multiplexor.Flags
!fill  Multiplexor.MAX_VIRTUAL_SPRITES,$00


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Main Variables (Hooks)
;;

; The number of raster hooks
Multiplexor.RasterHookCount           !byte 0
Multiplexor.CurrentRasterHookIndex    !byte 0

; Which raster line to trigger the hook
Multiplexor.RasterHookWhen
!fill Multiplexor.MAX_RASTER_HOOKS,$00
; The LSB of the hook address
Multiplexor.RasterHooAddressLSB
!fill Multiplexor.MAX_RASTER_HOOKS,$00
Multiplexor.RasterHooAddressMSB
!fill Multiplexor.MAX_RASTER_HOOKS,$00

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Main Variables (Both)
;;
Multiplexor.CurrentDrawIndex          !byte 0
Multiplexor.CurrentDrawCount          !byte 0
Multiplexor.DrawTableWhat
!fill Multiplexor.MAX_VIRTUAL_SPRITES+Multiplexor.MAX_RASTER_HOOKS,$0


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Main IRQ Entry Point
;;
Multiplexor.EntryPoint
  rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Sort Sprite List
;;
Multiplexor.SortIndex     !byte 0
Multiplexor.SortComplete  !byte 0

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
  
;  lda Multiplexor.SafeToDelete,x             ; A = Ycoord at 1st Element
;  cmp Multiplexor.SafeToDelete,y             ; Compare with YCoord at 2nd element
;  beq Multiplexor.PairSorted
;  bcc Multiplexor.PairSorted            ; If 1st Ycoord < 2nd YCoord then pair already sorted
  lda Multiplexor.SafeToDelete,y
  cmp Multiplexor.SafeToDelete,x
  bcs Multiplexor.PairSorted
  
  ; Swap the indexes around here
  ldy Multiplexor.SortIndex
  lda Multiplexor.SpriteIndexes,y
  pha
  lda Multiplexor.SpriteIndexes-1,y
  sta Multiplexor.SpriteIndexes,y
  pla
  sta Multiplexor.SpriteIndexes-1,y
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
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Construct Draw List
;;
Multiplexor.ConstructDrawList
  lda #0
  sta Multiplexor.CurrentRasterHookIndex      ; x
  sta Multiplexor.CurrentVirtualSpriteIndex   ; y
  sta Multiplexor.CurrentDrawIndex
  tax
  tay
  
Multiplexor.DrawingSetupRepeat
  cpx Multiplexor.RasterHookCount
  beq Multiplexor.HooksLoadedIntoDrawTable
  
  ldy Multiplexor.CurrentVirtualSpriteIndex
  cpy Multiplexor.VirtualSpriteCount
  beq Multiplexor.SpritesLoadedIntoDrawTable

  ; if here there are still sprites (y) and still hooks (x) to add to the draw table
  +MPX_TRUE_Y_INDEX_TO_Y
  ; CMP (a - memory) (carry set if memory <= a register)
  ; if hook <= sprite
  lda Multiplexor.SafeToDelete,y
  cmp Multiplexor.RasterHookWhen,x
  bcc Multiplexor.AddSpriteToDrawTable

  ; add the hook to the draw table and increment the hook
Multiplexor.AddHookToDrawTable
  ldy Multiplexor.CurrentDrawIndex
  txa
  ora #$80
  sta Multiplexor.DrawTableWhat,y
  inc Multiplexor.CurrentDrawIndex
  inx   ; move to next hook
  jmp Multiplexor.DrawingSetupRepeat

Multiplexor.AddSpriteToDrawTable
  ; add sprite to the draw table and increment the sprite
  lda Multiplexor.CurrentVirtualSpriteIndex
  ldy Multiplexor.CurrentDrawIndex
  sta Multiplexor.DrawTableWhat,y
  inc Multiplexor.CurrentVirtualSpriteIndex
  inc Multiplexor.CurrentDrawIndex
  jmp Multiplexor.DrawingSetupRepeat
  
Multiplexor.SpritesLoadedIntoDrawTable
  ; if here all the sprites have been dealt with and we just need to load
  ; any remaining hooks to the draw table
  cpx Multiplexor.RasterHookCount
  beq Multiplexor.DrawTableConstructed
  jmp Multiplexor.AddHookToDrawTable
  
Multiplexor.HooksLoadedIntoDrawTable
  ; if here all hooks have been dealt with and we just need to load the sprites
  ldy Multiplexor.CurrentVirtualSpriteIndex
  cpy Multiplexor.VirtualSpriteCount
  beq Multiplexor.DrawTableConstructed
  jmp Multiplexor.AddSpriteToDrawTable
  
Multiplexor.DrawTableConstructed
    rts