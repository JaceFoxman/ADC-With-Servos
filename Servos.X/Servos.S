; SERVOS
; JASON PERMANN
; RCET 3375
; 5th Semester
; Fall
; Program/Project
; https:// 
    
;Device Setup
;-------------------------------------------------------------------------------

; Configuration
; PIC16F883 Configuration Bit Settings

; Assembly source line config statements

; CONFIG1
  CONFIG  FOSC = XT	   
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

    
; Include Statements

; Code Section
;-------------------------------------------------------------------------------
    
; Register/Variable Setup
    SOMEVALUE EQU 0x5f				   
 ;Asign A Value To A Variable
 
; Start Of Program
    PSECT resetVect,class=CODE,delta=2	;Reset Vector Adress
    GOTO Start 

    PSECT isrVect,class=CODE,delta=2
    GOTO INTERUPT_HANDLER
    
    
; Setup Code That Runs Once At Power Up/Reset
    PSECT code,class=CODE,delta=2
Start:
    ;BANK 3
    BSF	    STATUS,5    ;Set RP0 to 1
    BSF	    STATUS,6    ;Set RP1 to 1
    MOVLW   0x01	;Move (0000|0001) to w
    CLRF    ANSEL	;Enable Analog Input for AN0 
    CLRF    ANSELH	;Disables Analog inputs for Higer level bits
    MOVLW   0x80	;move (1000|0000) to w
    MOVWF   OPTION_REG  ;Disable pull ups/ set timer 0 to WDT 1:1

   ;----------------
   ;BANK 2
    BSF	    STATUS,6    ;Set RP0 to 1
    BCF	    STATUS,5    ;Set RP1 to 0
    CLRF    CM2CON1     ;Disabels Comparator C2 Control Register 1
    CLRF    CM2CON0	;Disables Comparator C2 Control Register 0
    CLRF    CM1CON0	;Disables Comparator C1 Control Register 0
    ;---------------
    ;BANK 1
    BSF	    STATUS,5    ;Set RP0 to 1
    BCF	    STATUS,6    ;Set RP1 to 0
    MOVLW   0x00	;move (0000|0000) to w
    MOVWF   IOCB	;Disable Interrupt on change PORTB
    CLRF    PSTRCON     ;Disable Pulse Sterring Control Register
    CLRF    PCON	;Disable BOR/Power-on-Reset/Brown-out reset
    CLRF    ADCON1	;Left justify ADC result, use VSS and VDD as reference voltages
    MOVLW   0x00        ;Move (0000|0000) to w
    MOVWF   WPUB        ;Disable Pull-Ups
    MOVLW   0x01	;Move (0000|0001) to w
    MOVWF   TRISA	;Bit 0 set to input for AN0 to function
    MOVLW   0x00        ;Move (0000|0000) to w
    MOVWF   TRISB       ;Enable Outputs
    MOVLW   0x00	;Move (0000|0000) to w
    MOVWF   TRISC       ;Enable Outputs
    
    MOVLW   0x02	;move (0000|0010) to w
    MOVWF   PIE1	;Enable TMR2 interupt flag
    MOVLW   0xFF	;move (1111|1111) to w
    MOVWF   PR2		;Set count so that TMR2 compares itself too at max, 0xFF
    ;---------------
    ;BANK 0
    BCF	    STATUS,5    ;Set RP0 to 0
    BCF	    STATUS,6    ;Set RP1 to 0
    CLRF    RCSTA       ;Disables the recieve bits potential point of failure
    CLRF    SSPCON      ;Disables I^2C  bits and stuff
    CLRF    T1CON       ;Timer control disabled
    CLRF    CCP1CON     ;PWM1 control disabled
    CLRF    CCP2CON     ;PWM2 control disabled
    MOVLW   0x41	;Move (0100|0001) to w
    CLRF    ADCON0	;Set Fosc/8, Analog channel to AN0, and Enable ADC
    MOVLW   0x00	;Move (0000|0000) to w
    MOVWF   PORTA	;Set PORTA to all 0 at start up
    MOVLW   0x00	;Move (0000|0000)
    MOVWF   PORTB	;Set PORTB to all 0 at start up
    MOVLW   0x00	;Move (0000|0000) to w
    MOVWF   PORTC       ;Set PORTC to all 0 at start up
    
    MOVLW   0x00	;move (0000|0000) to w
    MOVWF   PIR1	;Set TMR2 flag to 0 at set up
    
    MOVLW   0x00	;move (0000|0000) to w
    MOVWF   TMR2	;Start TMR2 at 0x00 at startup
    
    MOVLW   0x00	;move (0000|0000) to w
    MOVWF   T2CON	;Keep TMR2 off until ready
    
    MOVLW   0xC0	;move (1010|0000) to w
    MOVWF   INTCON	;Eable Global and Pereperial interupts
    
    W_SAVE   EQU    0x20    ;General Purpouse register for saving values during interrupt
    STAT_SAVE EQU   0x21    ;General Purpouse register for saving values during interrupt
    COMP_SAVE EQU    0x22   ;General purpouse register for 

;-------------------------------------------------------------------------------
    MAIN:
    BSF	    ADCON0,0
    BSF	    ADCON0,1	;Start ADC
    MOVF    ADRESH,0
    MOVWF   PORTC
    GOTO    MAIN
;-------------------------------------------------------------------------------
    INTERUPT_HANDLER:
    MOVWF   W_SAVE	;Move w to w_Save
    MOVF    STATUS,0	;Move Status to w
    MOVWF   STAT_SAVE	;Move w to Stat_Save
    
    MOVF    STAT_SAVE,0	;Move STAT_SAVE to w
    MOVWF   STATUS	;Move w to STATUS
    MOVF    W_SAVE,0	;Move w_SAVE to w
    
    RETFIE		;Return from interupt, renable Global interrupts
;-------------------------------------------------------------------------------    

   
END			;End OF Code. This Is Required