// Ashton Tolman
// RCET3373
// Lab5PICpt3
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

W_TEMP EQU 0x70		; Temporary W register in global GR
STATUS_TEMP EQU 0x71	; Temporary Status register in global GR
PB_OLD EQU 0x72		; Save the Pre-Interrupt state of PortB
PB_NEW EQU 0x73		; Save the Post-Interrupt state of PortB
PB_CHANGED EQU 0x074	; Save the PortB pin that changed
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
    BSF  0x03, 06    ;
    BSF  0x03, 05    ; Set bank 3 active
    CLRF 0x189	    ; ANSELH analog/digital select portB pins as digital
    CLRF 0x188	    ; ANSEL analog/digital select portA pins as digital
    
    BSF  0x03, 06    ;
    BCF  0x03, 5    ; Set bank 2 active
    
    BCF  0x03, 06    ;
    BSF  0x03, 05    ; Set bank 1 active 
    CLRF 0x85	    ; TrisA sets all portA pins as outputs
    CLRF 0x87	    ; TrisC sets all portC pins as outputs
    MOVLW 0xFF	    ; Put all highs in W
    MOVWF 0x96	    ; Enable IOC on all pins

    BCF  0x03, 06    ;
    BCF  0x03, 05    ; Set bank 0 active
    CLRF 0x05	    ; Clear port A
    CLRF 0x07	    ; Clear port C
		     
    ;Interrupt setup
    CLRF 0x0B	    ; Clear INTCON to disable all interrupts by default
    BSF 0x8B,3	    ; Enable PortB interrupt on change
    BSF 0x8B,7	    ; Enable Global interrups
    
    BCF  0x03, 06    ;
    BCF  0x03, 05    ; Set bank 0 active
    goto Main
    

Main:
    MOVLW 0x80		; Put bit 7 high in W
    XORWF 0x05		; Toggle bit 7 in PortA
    goto Main
    
ISRHandler:
    MOVWF W_TEMP	    ;Copy W to TEMP register
    SWAPF STATUS,0	    ;Swap status to be saved into W
			    ;Swaps are used because they dont change the status bits
    MOVWF STATUS_TEMP	    ;Save status to bank zero STATUS_TEMP register
    
    BTFSC INTCON,0	    ;Test the IOCPortB flag
    goto IOCPORTBService    ;if the flag is up go to service
    goto LeaveHandler
    
IOCPORTBService:
    MOVF PORTB,W	    ; Put the New portB state into W
    MOVWF PB_NEW	    ; Put new portB state into general register
    XORWF PB_OLD,W	    ; Detect changed bit against old portB state
    
    MOVWF PB_CHANGED	    ; Put changed pin into general register
    MOVF PB_NEW,W	    ; Put new portB state into W
    MOVWF PB_OLD	    ; Update Old general register with new state
    
    Call TestingTable	    ; Testing table is a testing lookup table function
    
    SetPin:
    MOVWF PORTA		    ; Set PortA three LED output based on W
    goto FinalService	    
    
    TestingTable:
    BTFSC PB_CHANGED,0	    ; Test RB0 for high, return if high
    RETLW 0x00		    ; Return with 0 in W
    BTFSC PB_CHANGED,1	    ; Test RB1 for high, return if high
    RETLW 0x01		    ; Return with 1 in W
    BTFSC PB_CHANGED,2	    ; Test RB2 for high, return if high
    RETLW 0x02		    ; Return with 2 in W
    BTFSC PB_CHANGED,3	    ; Test RB3 for high, return if high
    RETLW 0x03		    ; Return with 3 in W
    BTFSC PB_CHANGED,4	    ; Test RB4 for high, return if high
    RETLW 0x04		    ; Return with 4 in W
    BTFSC PB_CHANGED,5	    ; Test RB5 for high, return if high
    RETLW 0x05		    ; Return with 5 in W
    BTFSC PB_CHANGED,6	    ; Test RB6 for high, return if high
    RETLW 0x06		    ; Return with 6 in W
    BTFSC PB_CHANGED,7	    ; Test RB7 for high, return if high
    RETLW 0x07		    ; Return with 7 in W
    
    FinalService:
    BCF INTCON,0	    ; Clear PortBIOC flag
    goto LeaveHandler	    ; 
    
LeaveHandler:
    SWAPF STATUS_TEMP,0	    ;Swap STATUS_TEMP register into W
			    ;(sets bank to original state)
    MOVWF STATUS	    ;Move W into STATUS register
    SWAPF W_TEMP,1	    ;Swap W_TEMP
    SWAPF W_TEMP,0	    ;Swap W_TEMP into W
    RETFIE		    ;Return from interupt at point of interruption+1
End