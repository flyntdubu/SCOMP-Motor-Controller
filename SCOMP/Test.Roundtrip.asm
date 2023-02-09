; Test 1:1 roundtripping through IO registers
; This program will sweep through an entire 16-bit integer,
; stopping if it finds a value that doesn't roundtrip properly.

; Status indicators (on hex1)
;   01 : Initializing
;   02 : Scanning
;   03 : Done scanning
;   0F : Found a problem



ORG 0
	LOADI 1 ; State 1: initializing
	OUT Hex1

	; Put the controller in Mode 2
	LOADI 2
	OUT MMode	
	
	; Start at position 0
	LOADI 0
	OUT M2TargetPos
	
	; full send it to the target position
	LOADI &H00FF
	OUT M2ApproachSpeed
	
	; State 2: scanning test values
	LOADI 2
	Out Hex1

MainLoop:

	; Display current value
	; LOAD Value
	; OUT Hex0
	
	; Roundtrip the value
	LOAD Value
	OUT M2TargetPos
	IN M2TargetPos
	STORE GotValue
	
	; Test if the roundtrip was correct
	LOAD GotValue
	SUB Value
	JNEG Broken
	JPOS Broken
	
	; Increment value by 1
	LOAD Value
	OUT Hex0
	ADDI 1
	STORE Value

	
	; If we have overflown the value, finish.
	JZERO Done
	
	; Wait a little before repeating	
	CALL Pause
	
	JUMP MainLoop

Broken:
	LOADI &H000F
	Out Hex1
	JUMP Halt

Done:
	LOADI 3
	OUT Hex1
	JUMP Halt

Pause:
	OUT Timer
PauseWait:
	IN Timer
	JZERO PauseWait
	RETURN
	
Halt: JUMP Halt

Value: DW &HFF00
GotValue: DW 0

; Motor Controller IO
MPos:            EQU &H0F0 ; Shaft position
MDrive:          EQU &H0F1 ; PWM drive strength
MMode:           EQU &H0F2 ; Mode register
M1Drive:         EQU &H0F3 ; Mode 1: drive strength. Signed.
M2TargetPos:     EQU &H0F4 ; Mode 2: target position
M2ApproachSpeed: EQU &H0F5 ; Mode 2: approach speed

; IO address constants
Switches:    EQU &H000
LEDs:        EQU &H001
Timer:       EQU &H002
Hex0:        EQU &H004
Hex1:        EQU &H005
But:         EQU &H006
