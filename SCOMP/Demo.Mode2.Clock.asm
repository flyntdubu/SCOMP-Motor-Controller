; Demonstration of Mode 2 control: ticking clock

ORG 0

	; Store clock tick rotation to 30 degrees
	LOADI 30
	CALL DegToQuad
	STORE ClockTick

	; Put the controller in Mode 2
	LOADI 2
	OUT MMode	
	
	; Start at position 0
	LOAD Position
	OUT M2TargetPos

Tick:
	; Reset the timer
	LOADI 0
	OUT Timer
	
	; Tick the motor
	LOAD Position
	ADD ClockTick ; tick the clock a bit
	OUT M2TargetPos
	STORE Position

MainLoop:

	; Set the motor recovery
	IN Switches
	AND LowByte
	OUT M2ApproachSpeed
	
	; display quad position
	IN MPos
	OUT Hex0
	
	; display the error, as stored in io reg
	IN MPos
	SUB Position
	CALL Abs
	OUT Hex1
	
	; Check if two seconds have elapsed
	IN Timer
	SUB TickTime
	JPOS Tick
	
	; jump back to loop
	JUMP MainLoop

;|*************************************|
;|	        DEGTOQUAD(DEG)   		   |    
;|	Returns quad pos representation of |
;|  angle in AC					       |
;|*************************************|

DegToQuad:
	STORE OriginalDeg
	SHIFT 1
	ADD   OriginalDeg
	SHIFT -1
	RETURN
OriginalDeg:  DW 0

;******************************************************************************
; Abs: 2's complement absolute value
; Returns abs(AC) in AC
; Negate: 2's complement negation
; Returns -AC in AC
;******************************************************************************
Abs:
	JPOS   Abs_r        ; If already positive, return
Negate:
	XOR    NegOne       ; Flip all bits
	ADDI   1            ; Add one
Abs_r:
	RETURN


; Clock configuration
Position:  DW &H0000 ; should track position
ClockTick: DW 0
TickTime:  DW 10

; Motor Controller IO
MPos:            EQU &H0F0 ; Shaft position
MDrive:          EQU &H0F1 ; PWM drive strength
MMode:           EQU &H0F2 ; Mode register
M1Drive:         EQU &H0F3 ; Mode 1: drive strength. Signed.
M2TargetPos:     EQU &H0F4 ; Mode 2: target position
M2ApproachSpeed: EQU &H0F5 ; Mode 2: approach speed
M3Velocity:      EQU &H0F6 ; Mode 3: target velocity
M3ApproachSpeed: EQU &H0F7 ; Mode 3: approach speed

; Useful values
Zero:      DW 0
NegOne:    DW -1
Six:       DW 6
Nine:      DW 9
Ones:      DW &B1111111111111111
LowByte:   DW &B0000000011111111
Bit0:      DW &B0000000001
Bit1:      DW &B0000000010
Bit2:      DW &B0000000100
Bit3:      DW &B0000001000
Bit4:      DW &B0000010000
Bit5:      DW &B0000100000
Bit6:      DW &B0001000000
Bit7:      DW &B0010000000
Bit8:      DW &B0100000000
Bit9:      DW &B1000000000
LoByte:    DW &H00FF
HiByte:    DW &HFF00
StopSpeed: DW &B1111


; IO address constants
Switches:    EQU &H000
LEDs:        EQU &H001
Timer:       EQU &H002
Hex0:        EQU &H004
Hex1:        EQU &H005
But:         EQU &H006
