; Using this to test that Mode 3 works.

ORG 0

	; Put the controller in Mode 3
	LOADI 3
	OUT MMode
	
	; Full send the approach speed
	; LOADI &H00F0
	; OUT M3ApproachSpeed

MainLoop:
	
	; yeet the switches into the velocity register
	IN Switches
	SHIFT -9
	JZERO SetDrive
SetReverseDrive:
	IN Switches
	AND LowByte
	XOR Ones
	ADDI 1
	JUMP SetDriveDone
SetDrive:
	IN Switches
	AND LowByte
SetDriveDone:
	OUT M3Velocity
	
	; Show drive on Hex1
	IN M3Velocity
	OUT Hex1
	
	; display current motor position
	IN MPos
	OUT Hex0
	
	; jump back to loop
	JUMP MainLoop

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
