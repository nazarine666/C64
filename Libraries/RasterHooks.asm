!source "..\Macros\Macros.asm",once

!zone RasterHooks

RasterHooks.MAX_RASTER_HOOKS                = 10

!macro RHK_SET_RASTER_HOOK hookIndex,rasterLine,hookFunction
  ldy #hookIndex
  lda #rasterLine
  sta RasterHooks.RasterHookLine,y
  lda #<hookFunction
  sta RasterHooks.RasterHookAddressLSB,y
  lda #>hookFunction
  sta RasterHooks.RasterHookAddressMSB,y
!end
  
!macro RHK_SET_RASTER_HOOK_COUNT hookCount
  lda #hookCount
  sta RasterHooks.RasterHookCount
!end

!macro RHK_JUST_USE_HOOKS
  lda #2
  sta RasterHooks.RasterHookFinishOff
  lda #<RasterHooks.RasterHookIRQRoutine
  sta RasterHooks.RasterHookOriginalIRQLSB
  lda #>RasterHooks.RasterHookIRQRoutine
  sta RasterHooks.RasterHookOriginalIRQMSB
!end

!macro RHK_INITIATE_IRQ
  +STORE_WORD RasterHooks.RasterHookIRQRoutine,KERNAL_IRQ_SERVICE_ROUTINE
  lda #1
  sta VIC_IRQ_CONTROL
  ; lda Multiplexor.DrawTableWhen
  lda #255
  sta VIC_RASTER
  lda #$7f
  and VIC_CONTROL_REGISTER_1
  sta VIC_CONTROL_REGISTER_1
!end


RasterHooks.RasterHookIRQRoutine
  +PUSH_REGISTERS_ON_STACK
  
  ldx RasterHooks.CurrentRasterHook
  inc RasterHooks.CurrentRasterHook
  
  lda RasterHooks.RasterHookAddressLSB,x
  sta RasterHooks.HookCallout+1
  lda RasterHooks.RasterHookAddressMSB,x
  sta RasterHooks.HookCallout+2
  
RasterHooks.HookCallout
  jsr $ffff
  
  lda RasterHooks.RasterHookFinishOff
  beq RasterHooks.RasterHookNormalLink
  ; If here then we know there are no more actual
  ; sprite rasters to schedule (from multiplexor) - so finish off any
  ; remaining raster hook routines
  inx
  cpx RasterHooks.RasterHookCount
  beq RasterHooks.NoMoreRasterHooks
  lda RasterHooks.RasterHookLine,x
  jmp RasterHooks.RasterHookScheduledRaster
  
RasterHooks.RasterHookNormalLink
  ; if the next hook raster is <= the original raster - we need to just schedule again the next hook
  ldx RasterHooks.CurrentRasterHook
  cpx RasterHooks.RasterHookCount
  beq RasterHooks.NoMoreRasterHooks
  ; there are raster hooks available. If the next raster hook line <= the original requested line
  ; we just need to schedule a raster hook again
  lda RasterHooks.RasterHookOriginalLine
  cmp RasterHooks.RasterHookLine,x
  bcc RasterHooks.NoMoreRasterHooks
  lda RasterHooks.RasterHookLine,x
  jmp RasterHooks.RasterHookScheduledRaster
  
RasterHooks.NoMoreRasterHooks
  ; Restore the original raster requested
  ; if we were in "finish off" mode
  ; we don't want to schedule the next raster - we just need
  ; to call the original routine after ensuring
  ; we have popped anything off the stack we need to
  ; the original routine will handle the necessary RTI
  
  lda RasterHooks.RasterHookFinishOff
  beq RasterHooks.NoMoreRasterHooksNotFinishingOff 
  cmp #2; this means we need to wrap around the raster hook
  beq RasterHooks.RasterHooksOnlyNoMoreHooks
  ; here we have finished all the hooks - and we were in finishing mode
  ; finishing mode - so we need to call the 
  lda RasterHooks.RasterHookOriginalIRQLSB
  sta RasterHooks.NoMoreRasterHooksJMP+1
  lda RasterHooks.RasterHookOriginalIRQMSB
  sta RasterHooks.NoMoreRasterHooksJMP+2
  +POP_REGISTERS_OFF_STACK
RasterHooks.NoMoreRasterHooksJMP
  jmp $ffff
RasterHooks.RasterHooksOnlyNoMoreHooks
  lda #0
  sta RasterHooks.CurrentRasterHook
  lda RasterHooks.RasterHookLine
  jmp RasterHooks.RasterHookScheduledRaster
  

RasterHooks.NoMoreRasterHooksNotFinishingOff  
  lda #0
  sta RasterHooks.RasterHookFinishOff
  lda RasterHooks.RasterHookOriginalIRQLSB
  sta KERNAL_IRQ_SERVICE_ROUTINE+0
  lda RasterHooks.RasterHookOriginalIRQMSB
  sta KERNAL_IRQ_SERVICE_ROUTINE+1
  
  lda RasterHooks.RasterHookOriginalLine
  
RasterHooks.RasterHookScheduledRaster
  sta VIC_RASTER
  
  lda #$7f   ; turn off raster MSB
  and VIC_CONTROL_REGISTER_1
  sta VIC_CONTROL_REGISTER_1


  +ACK_RASTER_IRQ
  
  +POP_REGISTERS_OFF_STACK
  rti


RasterHooks.CheckForPendingHooks
;; COMPARISON LOGIC
;; c = true if A >= M
;; c = false if a < m

;; A = 100      M = 200               CC
;; A = 100      M = 100               CS
;; A = 200      M = 100               CS

  ldx RasterHooks.CurrentRasterHook
  cpx RasterHooks.RasterHookCount
  beq RasterHooks.NoMoreHookProcessing
; CHECK HOOK AGAINST RASTER
RasterHooks.CheckHookAgainstRaster
  ; if Hook <= Raster (Raster >= Hook)
  lda VIC_RASTER
  cmp RasterHooks.RasterHookLine,x
  bcc RasterHooks.NoMoreHookProcessing   ;NO MORE HOOK PROCESSING
  lda RasterHooks.RasterHookAddressLSB,x
  sta RasterHooks.UpdateSpriteListHookCallout + 1
  lda RasterHooks.RasterHookAddressMSB,x
  sta RasterHooks.UpdateSpriteListHookCallout + 2
RasterHooks.UpdateSpriteListHookCallout
  jsr $ffff
  inx
  stx RasterHooks.CurrentRasterHook
  cpx RasterHooks.RasterHookCount
  bne RasterHooks.CheckHookAgainstRaster   ; CHECK HOOK AGAINST RASTER
RasterHooks.NoMoreHookProcessing
  rts


RasterHooks.RasterHookCount           !byte 0
RasterHooks.CurrentRasterHook         !byte 0
RasterHooks.RasterHookOriginalLine    !byte 0
RasterHooks.RasterHookOriginalIRQLSB  !byte 0
RasterHooks.RasterHookOriginalIRQMSB  !byte 0
RasterHooks.RasterHookFinishOff       !byte 0


RasterHooks.RasterHookLine
!fill  RasterHooks.MAX_RASTER_HOOKS,$00

RasterHooks.RasterHookAddressLSB
!fill  RasterHooks.MAX_RASTER_HOOKS,$00
RasterHooks.RasterHookAddressMSB
!fill  RasterHooks.MAX_RASTER_HOOKS,$00


