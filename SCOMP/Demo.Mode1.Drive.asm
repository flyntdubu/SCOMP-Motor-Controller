; Using this to test that the motor controler works : Flynt

ORG 0

	; Put the controller in Mode 1
	LOADI 1
	OUT MMode

MainLoop:
	
	; yeet the switches into the strength register
	IN Switches
	SHIFT -9
	JZERO SetDrive
SetReverseDrive:
	IN Switches
	XOR Ones
	ADDI 1
	JUMP SetDriveDone
SetDrive:
	IN Switches
SetDriveDone:
	OUT M1Drive
	
	; Show drive on Hex1
	IN M1Drive
	OUT Hex1
	
	; display current motor position
	IN MPos
	OUT Hex0
	
	; jump back to loop
	JUMP MainLoop

; Motor Controller IO
MPos:       EQU &H0F0 ; Shaft position
MDrive:     EQU &H0F1 ; PWM drive strength
MMode:      EQU &H0F2 ; Mode register
M1Drive:    EQU &H0F3 ; Mode 1: drive strength. Signed.

; Useful values
Zero:      DW 0
NegOne:    DW -1
Six:       DW 6
Nine:      DW 9
Ones:      DW &B1111111111111111
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
