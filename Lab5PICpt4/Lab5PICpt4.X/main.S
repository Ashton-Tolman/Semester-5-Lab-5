// Ashton Tolman
// RCET3373
// Lab5PICpt2
// https://github.com/Ashton-Tolman/Semester-5-Lab-5.git
// linker code:-Wl,-presetVect=0000h,-pisrVect=0004h,-pcode=0008h

; PIC16F883 Configuration Bit Settings

; Assembly source line config statements

; CONFIG1
  CONFIG  FOSC = XT             ; Oscillator Selection bits (XT oscillator: Crystal/resonator on RA6/OSC2/CLKOUT and RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = OFF           ; Power-up Timer Enable bit (PWRT disabled)
  CONFIG  MCLRE = ON            ; RE3/MCLR pin function select bit (RE3/MCLR pin function is MCLR)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = OFF             ; Low Voltage Programming Enable bit (RB3 pin has digital I/O, HV on MCLR must be used for programming)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)

// config statements should precede project file includes.
#include <xc.inc>

W_TEMP_A EQU 0x70	; Temporary W register in global GR A
STATUS_TEMP_A EQU 0x71	; Temporary Status register in global GR A
 
W_TEMP_B EQU 0x72	; Temporary W register in global GR B
STATUS_TEMP_B EQU 0x73	; Temporary Status register in global GR B

INTDetected EQU 0x74	; Global GR to detect 6 or 1
OldDisplay EQU	0x75	; Old display things for 7
 
outCount6 EQU 0x76	; Count for outer delay loop
inCount6 EQU 0x77	; Count for inner delay loop
mainCount6 EQU 0x78	; Count for main delay loop
outCount7 EQU 0x79	; Count for outer delay loop
inCount7 EQU 0x7A	; Count for inner delay loop
mainCount7 EQU 0x7B	; Count for main delay loop
 
; Reset Vector at 000h. Execution starts here after reset 
PSECT resetVect,class=CODE,delta=2
ResetVector:
    goto Setup
    
    
; Interrupt Vector at 0004h. Execution starts here after an interrupt.
PSECT isrVect,class=CODE,delta=2
InterruptVector:
    goto ISRHandler
    
; Main code section starts at 0008h. User code goes here
PSECT code,class=CODE,delta=2

Setup:
    ; add device setup here
    BSF  0x03, 06	;
    BSF  0x03, 05	; Set bank 3 active
    CLRF 0x189		; ANSELH analog/digital select portB pins as digital
    CLRF 0x188		; ANSEL analog/digital select portA pins as digital
    
    BSF  0x03, 06	;
    BCF  0x03, 5	; Set bank 2 active
    
    BCF  0x03, 06	;
    BSF  0x03, 05	; Set bank 1 active 
    CLRF 0x85		; TrisA sets all portA pins as outputs
    CLRF 0x87		; TrisC sets all portC pins as outputs
    BCF 0x81, 6		; Make interrupts trigger on falling edges
    BSF 0x96,1		; Enable IOC on bit 1

    BCF  0x03, 06	;
    BCF  0x03, 05	; Set bank 0 active
    CLRF 0x05		; Clear port A
    CLRF 0x07		; Clear port C
		     
    ;Interrupt setup
    CLRF 0x0B		; Clear INTCON to disable all interrupts by default
    BCF INTDetected,0	; Clear the 6 or 1 indicator
    BSF 0x8B,3		; Enable PortB interrupt on change
    BSF 0x8B,4		; Enable External interrupts
    BSF 0x8B,7		; Enable Global interrups
    
    BCF  0x03, 06	;
    BCF  0x03, 05	; Set bank 0 active
    goto Main
    

Main:
    MOVLW 0x31		; Put display code for "1" in W
    MOVWF 0x07		; Display 1 on PortC
    MOVLW 0x01
    XORWF 0x05
    goto Main
    
ISRHandler:
    BTFSC INTCON,0	    ;IOC flag test
    goto Context7	    ;Save context for a 7 interrupt
			    ;If not 7 save context for 6 interrupt
    
    Context6:
    MOVWF W_TEMP_A	    ;Copy W to TEMP register
    SWAPF STATUS,0	    ;Swap status to be saved into W
			    ;Swaps are used because they dont change the status bits
    MOVWF STATUS_TEMP_A	    ;Save status to bank zero STATUS_TEMP register
    goto INTExternalService ;if the flag is up go to service  
    
    Context7:
    MOVWF W_TEMP_B	    ;Copy W to TEMP register
    SWAPF STATUS,0	    ;Swap status to be saved into W
			    ;Swaps are used because they dont change the status bits
    MOVWF STATUS_TEMP_B	    ;Save status to bank zero STATUS_TEMP register
    goto IOCPORTBService    ;if the flag is up go to service
    
INTExternalService:
    BCF INTCON,1
    BCF INTCON,4
    BSF INTCON,7


    MOVLW 0x36
    MOVWF 0x07
    
    CALL Delay_2Sec6
    BSF INTDetected,0	    ;If it was a 6 INT, set GR bit to indicate

    goto LeaveHandler
    
IOCPORTBService:
    BCF INTCON,7
    MOVF PORTB,W
    MOVF PORTC,W
    MOVWF OldDisplay
    
    MOVLW 0x37
    MOVWF 0x07
    
    CALL Delay_2Sec7
    
    MOVF OldDisplay,W
    MOVWF PORTC
    
    
    BCF INTCON,0
    goto LeaveHandler
    
LeaveHandler:
    BTFSS INTDetected,0	    ;IOC flag test
    goto LeaveHandler7	    ;Load context for a 7 interrupt
			    ;If not 7 Load context for 6 interrupt
    
    
    LeaveHandler6:
    BCF INTDetected,0
    BSF INTCON,4
    SWAPF STATUS_TEMP_A,0	    ;Swap STATUS_TEMP register into W
			    ;(sets bank to original state)
    MOVWF STATUS	    ;Move W into STATUS register
    SWAPF W_TEMP_A,1	    ;Swap W_TEMP
    SWAPF W_TEMP_A,0	    ;Swap W_TEMP into W
    RETFIE		    ;Return from interupt at point of interruption+1
    
    LeaveHandler7:
    SWAPF STATUS_TEMP_B,0	    ;Swap STATUS_TEMP register into W
			    ;(sets bank to original state)
    MOVWF STATUS	    ;Move W into STATUS register
    SWAPF W_TEMP_B,1	    ;Swap W_TEMP
    SWAPF W_TEMP_B,0	    ;Swap W_TEMP into W
    RETFIE		    ;Return from interupt at point of interruption+1
    
Delay_2Sec6:
	MOVLW 0x1F		;1 TCY delay overhead
	MOVWF mainCount6	;1 TCY delay overhead
    MainDelay6:
	MOVLW 0x90		;1 TCY delay overhead
	MOVWF outCount6	;1 TCY delay overhead
    
    OutDelay6:
	MOVLW 0x94		;1 TCY delay overhead
	MOVWF inCount6	;1 TCY delay overhead
    
    InDelay6:    
	DECFSZ inCount6,1	;1(2) 1 TCY if not zero, 2 TCY if zero
	goto InDelay6	;2 TCY
    
	DECFSZ outCount6,1	;1(2) 1TCY if not zero, 2 TCY if zero
	goto OutDelay6	;2 TCY
	
	DECFSZ mainCount6,1	;1(2) 1TCY if not zero, 2 TCY if zero
	goto MainDelay6	;2 TCY
    
	RETURN
Delay_2Sec7:
	MOVLW 0x1E		;1 TCY delay overhead
	MOVWF mainCount7	;1 TCY delay overhead
    MainDelay7:
	MOVLW 0x90		;1 TCY delay overhead
	MOVWF outCount7	;1 TCY delay overhead
    
    OutDelay7:
	MOVLW 0x94		;1 TCY delay overhead
	MOVWF inCount7	;1 TCY delay overhead
    
    InDelay7:    
	DECFSZ inCount7,1	;1(2) 1 TCY if not zero, 2 TCY if zero
	goto InDelay7	;2 TCY
    
	DECFSZ outCount7,1	;1(2) 1TCY if not zero, 2 TCY if zero
	goto OutDelay7	;2 TCY
	
	DECFSZ mainCount7,1	;1(2) 1TCY if not zero, 2 TCY if zero
	goto MainDelay7	;2 TCY
    
	RETURN
End