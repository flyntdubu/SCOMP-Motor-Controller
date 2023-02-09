; Using this to test that bang bang works : Michael

ORG 0

	; Put the controller in Mode 2
	LOADI 2
	OUT MMode	
	
	; mode 2 target
	LOADI &H0F00
	OUT M2TargetPos

MainLoop:
	
	; display quad position
	IN MPos
	OUT Hex0
	
	; yoink switches into target pos
	IN Switches
	OUT M2TargetPos
	
	; display the pos, as stored in io reg
	IN M2TargetPos
	OUT Hex1
	
	; jump back to loop
	JUMP MainLoop

; Motor Controller IO
MPos:            EQU &H0F0 ; Shaft position
MDrive:          EQU &H0F1 ; PWM drive strength
MMode:           EQU &H0F2 ; Mode register
M1Drive:         EQU &H0F3 ; Mode 1: drive strength. Signed.
M2TargetPos:     EQU &H0F4 ; Mode 2: target position
M2ApproachSpeed: EQU &H0F5 ; Mode 2: approach speed

; Useful values
Zero:      DW 0
NegOne:    DW -1
Six:       DW 6
Nine:      DW 9
Ones:      DW &B1111111111111111
EightOnes: DW &B0000000011111111
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
