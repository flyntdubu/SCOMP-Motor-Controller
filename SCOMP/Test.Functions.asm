; Testing Functions

ORG 0
	
MainLoop:
	IN But
	JPOS WaitForStby
	LOADI 360
	CALL DPSToTick
	CALL DriveAtVelocity
	CALL GetVelocity
	OUT Hex0
	JUMP MainLoop
	
WaitForStby:
	IN But
	JZERO Standby
	JUMP WaitForStby

Standby:
	IN But
	JPOS WaitForMain
	CALL HaltMotor
	JUMP Standby

WaitForMain:
	IN But
	JZERO MainLoop
	JUMP WaitForMain

;******************************************************************************
; HaltMotor: Halts the motor at the current position
; Sets motor to Mode 0. AC will not be affected
;******************************************************************************

HaltMotor:
	LOADI 0				; Loads 0 into AC
	OUT MMode			; Sets motor Mode to 0 (Standby Mode)
	RETURN	

;******************************************************************************
; DPSToTick: Converts a given value in degrees per second to tick velocity
; Returns AC converted to an encoder tick velocity (AC * 2 / 3)
; Keeps original unconverted value in DPSTT_Orig until next function call.
;******************************************************************************

DPSToTick:
	STORE DPSTT_Orig  	; Store the original value
	SHIFT -1        	; AC / 2
	SUB	  DPSTT_Orig  	; AC - OriginalValue
	RETURN
DPSTT_Orig:	DW 0    	; Stores the original value of the AC for multiplication

;******************************************************************************
; DriveAtVelocity: Moves the motor at the velocity specified in the AC  (Mode 3)
; Input AC is a given velocity represented by fractional encoder ticks per cycle
; Defaults to full approach strength, can be changed by modifying DAV_AppStr
;******************************************************************************

DriveAtVelocity:
	OUT M3Velocity	  ; Store position to M3Vel
	LOAD DAV_AppStr	  ;
	OUT M3ApproachSpeed ; Set approach speed to DAV_AppSpeed
	LOADI 3				  ; 
	OUT MMode			  ; Set motor to Mode 3
	RETURN
DAV_AppStr:	    DW &H00F0 ; Defaults to default approach speed

;******************************************************************************
; GetPos: Gets the motor's current position 
; Returns current position in encoder ticks to AC
;******************************************************************************

GetVelocity:
	IN M3Velocity
	RETURN

; Motor Controller IO
MPos:            EQU &H0F0 ; Shaft position
MDrive:          EQU &H0F1 ; PWM drive strength
MMode:           EQU &H0F2 ; Mode register
M1Drive:         EQU &H0F3 ; Mode 1: drive strength. Signed.
M2TargetPos:     EQU &H0F4 ; Mode 2: target position
M2ApproachSpeed: EQU &H0F5 ; Mode 2: approach speed
M3Velocity:      EQU &H0F6 ; Mode 3: target velocity
M3ApproachSpeed: EQU &H0F7 ; Mode 3: approach speed

But:         	 EQU &H006
Hex0:            EQU &H004