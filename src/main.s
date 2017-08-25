; Princess Engine
; Copyright (C) 2014-2017 NovaSquirrel
;
; This program is free software: you can redistribute it and/or
; modify it under the terms of the GNU General Public License as
; published by the Free Software Foundation; either version 3 of the
; License, or (at your option) any later version.
;
; This program is distributed in the hope that it will be useful, but
; WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
; General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;

; Start the main loop off and initialize things
.proc MainLoopInit
  lda #0
  sta UploadTileAddress+1 ; Make sure tile uploading is off
  sta IsNormalDoor        ; Make sure the door entering flag is off

  ; This value is kept at $f0 for most routines, so make sure it's right
  lda #$f0
  sta EnemyRightEdge

  ; Start the music.
  ; Right now music is disabled until I get something non-annoying in there.
  lda #SOUND_BANK
  jsr _SetPRG
  jsr pently_init
;  lda LevelMusic
;  jsr pently_start_music
  jsr pently_stop_music

  inc JustTeleported ; Cause enemies to appear

  ; Render the part of the level the player starts in, if there isn't a dialog
  ; that needs to be shown at the start of the level.
  ; (this way the level isn't shown for a frame before the dialog starts)
  lda #MAINLOOP_BANK
  jsr SetPRG
  lda NeedDialog
  bne :+
  jsr RenderLevelScreens ; Render the screen the player's on
  jsr WaitVblank
  lda #BG_ON             ; Turn PPU display on
  sta PPUMASK
:

  ; Make sure NMI is on
  lda #VBLANK_NMI | NT_2000 | OBJ_8X8 | BG_0000 | OBJ_1000
  sta PPUCTRL
  jsr ClearOAM
  jmp VBlankUpdates
.endproc

.proc VBlankUpdates
  ; The VRAM is unusable outside of vertical blank because the PPU is constantly using it.
  ; Nova the Squirrel writes to queues during gameplay when it wants VRAM changes, and waits for vertical blank
  ; to actually perform the changes.
  jsr WaitVblank
  lda #2
  sta OAM_DMA
  bit PPUSTATUS

  ; if IsScrollUpdate is set, update the side of the screen with the ThirtyUpdate buffer
  lda IsScrollUpdate
  jeq NotScrollUpdate
    lda #VBLANK_NMI | NT_2000 | OBJ_8X8 | BG_0000 | OBJ_1000 | VRAM_DOWN ; write vertically
    sta PPUCTRL
    lda ThirtyUpdateAddr+0
    sta PPUADDR
    lda ThirtyUpdateAddr+1
    sta PPUADDR
    .repeat 30, I
      lda ThirtyUpdateTile+I
      sta PPUDATA
    .endrep
    ; Update attributes so the newly scrolled-in tiles have the right colors
    ; Note: Vertical writes are still on! This cuts the number of times we need to write
    ; to PPUADDR in half.
    lda IsScrollUpdate
    cmp #4
    bne Not4
      .repeat 4, I
        lda AttributeWriteA1
        sta PPUADDR
        lda AttributeWriteA2+I
        sta PPUADDR
        lda AttributeWriteD+I
        sta PPUDATA
        lda AttributeWriteD+I+4
        sta PPUDATA
      .endrep
    Not4:
  NotScrollUpdate:

  ; Horizontal writes again
  lda #VBLANK_NMI | NT_2000 | OBJ_8X8 | BG_0000 | OBJ_1000
  sta PPUCTRL

  ; Upload four tiles worth of data (64 bytes) to a PPU address if needed
  lda UploadTileAddress+1
  beq NoUploadTile
    sta PPUADDR
    lda UploadTileAddress+0
    sta PPUADDR
    jsr UploadFourTiles
  NoUploadTile:

  ; Queue for up to four single-byte changes
  .repeat 4, I ; change if the max number of tile changes per frame is changed
    lda TileUpdateA1+I
    beq :+
      sta PPUADDR
      lda TileUpdateA2+I
      sta PPUADDR
      lda TileUpdateT+I
      sta PPUDATA
      lda #0
      sta TileUpdateA1+I
    :
  .endrep

  ; Queue for up to three changes the size of a block
  .repeat 3, I
    lda BlockUpdateA1+I
    beq :+
      sta PPUADDR
      lda BlockUpdateA2+I
      sta PPUADDR
      lda BlockUpdateT1+I
      sta PPUDATA
      lda BlockUpdateT2+I
      sta PPUDATA

      lda BlockUpdateB1+I
      sta PPUADDR
      lda BlockUpdateB2+I
      sta PPUADDR
      lda BlockUpdateT3+I
      sta PPUDATA
      lda BlockUpdateT4+I
      sta PPUDATA
      lda #0
      sta BlockUpdateA1+I
    :
  .endrep

  ; The PPU address register is the same as the scroll register, so
  ; change the scroll value to be correct again
  jsr UpdateScrollRegister
.endproc
; don't put anything else here
.proc MainLoop
  ; Turn PPU display on (only if the level doesn't need to be rerendered)
  lda NeedLevelRerender
  bne :+
.ifdef CPU_METER
  lda #OBJ_ON | BG_ON | %11100000
  sta PPUMASK
.else
  lda #OBJ_ON | BG_ON
  sta PPUMASK
.endif
:
  ; A flag gets set at the start of the main loop, and if it's still
  ; set when NMI happens, a lag frame occured
  .ifdef NMI_MUSIC
    lda #1
    sta LagFrame
  .endif
  countdown IsScrollUpdate ; decrease scroll update stage
  jsr ReadJoy
  jsr ClearOAM

  ; There's a timer that only goes up every 4 frames rather than 1
  ; and delayed metatile edits use it so that they can fit a longer
  ; delay into a byte.
  lda retraces
  and #3
  bne NotSlowTimer
    inc slowtimer

    ; check the delayed metatile updates
    ldx #MaxDelayedMetaEdits-1
DelayCheck:
    lda DelayedMetaEditIndexHi,x
    beq @NotPresent
      lda DelayedMetaEditTime,x
      beq @DoDelayedEdit
      dec DelayedMetaEditTime,x ; count down the timer for the edit if it's nonzero
      jmp @NotPresent
  @DoDelayedEdit:
    ; set up the edit
    lda DelayedMetaEditIndexHi,x
    sta LevelBlockPtr+1
    lda DelayedMetaEditIndexLo,x ; ChangeBlock needs to have the Y position and column starting address
    tay                          ; separate, but the DelayedMetaEdit array combines them.
    and #$f0                     ; Separate them out.
    sta LevelBlockPtr+0
    tya                          ; Y gets the Y position.
    and #$0f
    tay
    lda DelayedMetaEditType,x
    jsr ChangeBlock              ; saves X so we don't have to do that here
    lda #0
    sta DelayedMetaEditIndexHi,x ; Don't need to clear the rest
  @NotPresent:
    dex
    bpl DelayCheck
NotSlowTimer:

  ; Run the player, objects, and most other stuff
  lda #MAINLOOP_BANK
  jsr SetPRG

  lda FallingBlockPointer+1
  beq NoFallingBlock
    ; Load the position
    ldy FallingBlockY
    lda FallingBlockPointer+0
    sta LevelBlockPtr+0
    lda FallingBlockPointer+1
    sta LevelBlockPtr+1
    lda (LevelBlockPtr),y
    cmp BackgroundMetatile
    bne NoMoreFallingBlock

    ; Erase this block and add another one below
    dey
    lda (LevelBlockPtr),y
    pha
    lda BackgroundMetatile
    jsr ChangeBlock
    iny
    pla
    jsr ChangeBlock
    inc FallingBlockY
    lda FallingBlockY
    cmp #15
    bne NoFallingBlock
  NoMoreFallingBlock:
  lda #0
  sta FallingBlockPointer+1
NoFallingBlock:

  lda PlaceBlockInLevel
  bne PlaceBlockMode
  jsr RunPlayer
  jsr AdjustCamera
  jsr DisplayPlayer
  lda #OBJECT_BANK
  jsr SetPRG
  jsr RunObjects
  jsr FlickerEnemies

  lda #SOUND_BANK
  jsr SetPRG

  lda PlayerHealth
  bne NotDie
  jsr pently_init ; Stop music and sound effects
  jsr ShowDie
NotDie:
  ; If the enemies and objects are skipped, the sound bank wasn't set
  ; so it needs to be set for pently_update
  jmp DidntSkipPlayerAndEnemies
PlaceBlockMode:
  jsr RunPlaceBlockMode
  lda #SOUND_BANK
  jsr SetPRG
DidntSkipPlayerAndEnemies:

  ; Update music+sfx, play sounds if needed
  jsr pently_update
  lda NeedSFX
  bpl :++
    cmp #SFX::BOOM1 ; boom sound has a second sound effect that plays with it
    php
    and #63
    jsr pently_start_sound
    plp
    bne :+
      lda #SFX::BOOM2
      jsr pently_start_sound
    :
    lda #0
    sta NeedSFX
  :
  countdown SoundDebounce

  ; Still need sound bank since the pause screen mutes the sound
  lda PlaceBlockInLevel
  bne NoPause
  lda keynew
  and #KEY_START
  beq NoPause
.ifdef NMI_MUSIC
    lsr LagFrame
.endif
    jsr PauseScreen
  NoPause:

  ; Render the level if needed (like when you go in a door)
  lda #MAINLOOP_BANK
  jsr SetPRG

  lda NeedLevelRerender
  beq :+
    lda #MAINLOOP_BANK
    jsr SetPRG
    jsr WaitVblank
    jsr RenderLevelScreens
    lda #0
    sta NeedLevelRerender
    jsr WaitVblank
  :

  ; Change ability if needed
  lda NeedAbilityChange
  bpl :+
    ldy #0
    sty NeedAbilityChange
    ldy NeedAbilityChangeNoSound
    bne @NoSound
    and #127
    jsr ChangePlayerAbility
    jmp :+
@NoSound:
    and #127
    jsr ChangePlayerAbilityWithoutSFX
    lda #0
    sta NeedAbilityChangeNoSound
  :

  ; Let player reset their ability
  lda keydown
  and #KEY_SELECT
  bne :+
    lda #0
    sta PlayerSelectTimer
  :
  lda keydown
  and #KEY_SELECT
  beq :+
    lda PlayerAbility
    beq :+
      lda keydown
      and #KEY_DOWN
      bne @ForceResetAbility
      inc PlayerSelectTimer
      lda PlayerSelectTimer
      cmp #30
      bne :+
@ForceResetAbility:
        lda #128
        sta NeedAbilityChange
  :

  ; Reset the whole level if that's needed too
  lda NeedLevelReload
  beq :+
    jsr WaitVblank
    lda #0
    sta NeedLevelReload
    sta PPUMASK
    lda LevelNumber
    jsr DecompressLevel
    ldx #$ff
    txs
    jmp MainLoopInit
  :

  lda NeedDialog
  beq :+
.ifdef NMI_MUSIC
    lsr LagFrame
.endif
    jsr StartCutscene ; this routine clears NeedDialog
  :

  lda MakeCheckpoint
  beq :++
    lda #0
    sta MakeCheckpoint
    lda PlayerPXH
    sta CheckpointX
    lda PlayerPYH
    sta CheckpointY
    lda LevelNumber
    sta CheckpointLevelNumber

    ; Copy the current game state into the checkpoint state
    ldy #GameStateLen-1
  : lda CurrentGameState,y
    sta CheckpointGameState,y
    dey
    bpl :-
  :

.ifdef CPU_METER
  lda #OBJ_ON | BG_ON
  sta PPUMASK
.endif
  .ifdef NMI_MUSIC
    lda #0
    sta LagFrame
  .endif
  jmp VBlankUpdates
.endproc

.proc RunPlaceBlockMode
Offset = 2
Type   = 3
PlayerDrawX = 4
PlayerDrawY = 5

; Make sure rendering is ong
  lda #OBJ_ON | BG_ON
  sta PPUMASK

; Figure out the offset
  lda ScrollX
  lsr
  lsr
  lsr
  lsr
  sta Offset

  lda keydown
  beq NoAutorepeat
  cmp keylast
  bne NoAutorepeat
  inc PlaceBlockAutorepeat
  lda PlaceBlockAutorepeat
  cmp #12
  bcc SkipNoAutorepeat

  lda retraces
  and #3
  bne :+
  lda keydown
  and #KEY_LEFT|KEY_RIGHT|KEY_UP|KEY_DOWN
  ora keynew
  sta keynew
:

  ; Keep it from going up to 255 and resetting
  dec PlaceBlockAutorepeat
  bne SkipNoAutorepeat
NoAutorepeat:
  lda #0
  sta PlaceBlockAutorepeat
SkipNoAutorepeat:

; Move the block
  lda keynew
  and #KEY_LEFT
  beq :+
    lda PlaceBlockX
    cmp #1
    beq :+
    dec PlaceBlockX
  :
  lda keynew
  and #KEY_DOWN
  beq :+
    lda PlaceBlockY
    cmp #13
    beq :+
    inc PlaceBlockY
  :
  lda keynew
  and #KEY_UP
  beq :+
    lda PlaceBlockY
    beq :+
    dec PlaceBlockY
  :
  lda keynew
  and #KEY_RIGHT
  beq :+
    lda PlaceBlockX
    cmp #15
    beq :+
    inc PlaceBlockX
  :

; Display the block
  ldy OamPtr
  lda PlaceBlockInLevel
  ora #64 ; Delay switching the sprite graphics until the OAM is actually set
  sta PlaceBlockInLevel
  and #15
  sta Type
  tax
  lda PlaceableTiles0,x
  sta OAM_TILE+(4*0),y
  lda PlaceableTiles1,x
  sta OAM_TILE+(4*1),y
  lda PlaceableTiles2,x
  sta OAM_TILE+(4*2),y
  lda PlaceableTiles3,x
  sta OAM_TILE+(4*3),y

  lda #OAM_COLOR_0
  sta OAM_ATTR+(4*0),y
  sta OAM_ATTR+(4*1),y
  sta OAM_ATTR+(4*2),y
  sta OAM_ATTR+(4*3),y
  sta OAM_ATTR+(4*4),y
  sta OAM_ATTR+(4*5),y
  sta OAM_ATTR+(4*6),y
  sta OAM_ATTR+(4*7),y
  lda PlaceBlockX
  asl
  asl
  asl
  asl
  sub Offset
  sta OAM_XPOS+(4*0),y
  sta OAM_XPOS+(4*1),y
  add #8
  sta OAM_XPOS+(4*2),y
  sta OAM_XPOS+(4*3),y

  lda PlaceBlockY
  asl
  asl
  asl
  asl
  sub #1
  sta OAM_YPOS+(4*0),y
  sta OAM_YPOS+(4*2),y
  add #8
  sta OAM_YPOS+(4*1),y
  sta OAM_YPOS+(4*3),y

  ; Draw player marker
  RealYPosToScreenPos PlayerPYL, PlayerPYH, PlayerDrawY
  RealXPosToScreenPos PlayerPXL, PlayerPXH, PlayerDrawX
  lda #$34
  sta OAM_TILE+(4*4),y
  lda #$35
  sta OAM_TILE+(4*5),y
  lda #$36
  sta OAM_TILE+(4*6),y
  lda #$37
  sta OAM_TILE+(4*7),y
  ldx PlayerDir
  lda PlayerDrawX
  add PlayerSymbolXOffset,x
  sta OAM_XPOS+(4*4),y
  sta OAM_XPOS+(4*5),y
  add #8
  sta OAM_XPOS+(4*6),y
  sta OAM_XPOS+(4*7),y
  lda PlayerDrawY
  add #7
  sta OAM_YPOS+(4*4),y
  sta OAM_YPOS+(4*6),y
  add #8
  sta OAM_YPOS+(4*5),y
  sta OAM_YPOS+(4*7),y

  tya
  add #8*4
  sta OamPtr

; Cancel the block if possible
  lda keynew
  and #KEY_B
  beq :+
    ; Can only cancel if you're actually using an inventory item
    lda PlaceBlockItemIndex
    cmp #255
    beq :+
      lda #0
      sta PlaceBlockInLevel
      jmp ClearOAM
  :

; Place down the block
  lda keynew
  and #KEY_A
  beq :+
    ; Is the block being placed a solid one?
    ldx Type
    lda PlaceableMetatiles,x
    tax
    lda MetatileFlags,x
    bpl NotSolid

    ; If solid, check for collision with the player tile
    lda OAM_XPOS+(4*0),y
    sta TouchLeftA
    lda OAM_YPOS+(4*0),y
    sta TouchTopA

    lda OAM_XPOS+(4*4),y
    sta TouchLeftB
    lda OAM_YPOS+(4*4),y
    sta TouchTopB

    lda #16
    sta TouchWidthA
    sta TouchWidthB
    sta TouchHeightA
    sta TouchHeightB
    jsr ChkTouchGeneric
    bcs :+
NotSolid:

    ldy PlaceBlockY
    lda ScrollX+1
    add PlaceBlockX
    jsr GetLevelColumnPtr
    cmp BackgroundMetatile ; Don't overwrite blocks
    bne :+
      ldx Type
      lda PlaceableMetatiles,x
      jsr ChangeBlock
      lda #SFX::PLACE_BLOCK
      jsr PlaySound

      ; Stop if it's not an actual inventory item
      ldx PlaceBlockItemIndex
      cpx #255
      beq End

      ; Subtract one item from the item count, and erase the item and stop if it's the last one
      lda InventoryAmount,x
      beq LastOne
      dec InventoryAmount,x
  :
  rts

LastOne:
  lda #0
  sta InventoryType,x
End:
  lda #0
  sta PlaceBlockInLevel
  jmp ClearOAM

PlayerSymbolXOffset:
  .byt <-8, 0

; block, spring, arrow left/down/up/right, arrow metal left/down/up/right, wood box, metal box
PlaceableTiles0:
  .byt $0c, $3f, $c0, $c4, $c8, $cc, $c0, $c4, $c8, $cc, $d4, $d4
PlaceableTiles1:
  .byt $0d, $18, $c1, $c5, $c9, $cd, $c1, $c5, $c9, $cd, $d5, $d5
PlaceableTiles2:
  .byt $0e, $3f, $c2, $c6, $ca, $ce, $c2, $c6, $ca, $ce, $d6, $d6
PlaceableTiles3:
  .byt $0f, $19, $c3, $c7, $cb, $cf, $c3, $c7, $cb, $cf, $d7, $d7
PlaceableMetatiles:
  .byt Metatiles::SOLID_BLOCK, Metatiles::SPRING
  .byt Metatiles::WOOD_ARROW_LEFT, Metatiles::WOOD_ARROW_DOWN, Metatiles::WOOD_ARROW_UP, Metatiles::WOOD_ARROW_RIGHT
  .byt Metatiles::METAL_ARROW_LEFT, Metatiles::METAL_ARROW_DOWN, Metatiles::METAL_ARROW_UP, Metatiles::METAL_ARROW_RIGHT
  .byt Metatiles::WOOD_CRATE, Metatiles::METAL_CRATE
.endproc
