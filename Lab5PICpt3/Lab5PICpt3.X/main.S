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
    MOVF PORTB,W	    ;
    MOVWF PB_NEW	    ;
    XORWF PB_OLD,W	    ;
    
    MOVWF PB_CHANGED	    ;
    MOVF PB_NEW,W
    MOVWF PB_OLD
    
    PB_OLD
    PB_NEW
    PB_CHANGED
    BCF INTCON,0
    goto LeaveHandler
    
LeaveHandler:
    SWAPF STATUS_TEMP,0	    ;Swap STATUS_TEMP register into W
			    ;(sets bank to original state)
    MOVWF STATUS	    ;Move W into STATUS register
    SWAPF W_TEMP,1	    ;Swap W_TEMP
    SWAPF W_TEMP,0	    ;Swap W_TEMP into W
    RETFIE		    ;Return from interupt at point of interruption+1
End