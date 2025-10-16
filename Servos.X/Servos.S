; SERVOS
; JASON PERMANN
; RCET 3375
; 5th Semester
; Fall
; Program/Project
; https://github.com/JaceFoxman/ADC-With-Servos.git
    
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
    MOVWF   ANSEL	;Enable Analog Input for AN0 
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
    
    W_SAVE  EQU    0x20 ;General Purpouse register for saving values during interrupt
    STAT_SAVE EQU  0x21 ;General Purpouse register for saving values during interrupt
    ADC_SAVE EQU   0x22 ;General purpouse register for adding to Program Counter
    TIME EQU	   0x23	;General Purpouse register for Pulse Width Delay
 
;-------------------------------------------------------------------------------
   TIMER2_SETUP:
    MOVLW   0x00	;move (0000|0000) to w
    MOVWF   PIR1	;Set TMR2 flag to 0 at set up
    
    MOVLW   0x00	;move (0000|0000) to w
    MOVWF   TMR2	;Start TMR2 at 0x00 at startup
    
    MOVLW   0x00	;move (0000|0000) to w
    MOVWF   T2CON	;Keep TMR2 off until ready
    
    BSF	    STATUS,5    ;Set RP0 to 1
    BCF	    STATUS,6    ;Set RP1 to 0
    
    MOVLW   0x02	;move (0000|0010) to w
    MOVWF   PIE1	;Enable TMR2 interupt flag
    
    MOVLW   0xFF	;move (1111|1111) to w
    MOVWF   PR2		;Set count so that TMR2 compares itself too at max, 0xFF
    
    MOVLW   0xC0	;move (1010|0000) to w
    MOVWF   INTCON	;Eable Global and Pereperial interupts
    
    BCF	    STATUS,5    ;Set RP0 to 0
    BCF	    STATUS,6    ;Set RP1 to 0
    
    MOVLW   0x26	;move (0010|0110) to w
    MOVWF   T2CON	;Set Prescaler to 1:16, Postscaler to 1:5, Turn on TRM2
;------------------------------------------------------------------------------- 
    MAIN:
    BSF	    ADCON0,0	;Enable ADC
    BSF	    ADCON0,1	;Start Conversion 
    MOVF    ADRESH,0	;Take ADC value and move to w
    MOVWF   PORTC	;Display w to PORTC
    GOTO    MAIN	;GOTO line 142
;-------------------------------------------------------------------------------
    INTERUPT_HANDLER:  
    MOVWF   W_SAVE	;Move w to w_Save
    MOVF    STATUS,0	;Move Status to w
    MOVWF   STAT_SAVE	;Move w to Stat_Save
    
    BCF	    PIR1,1	;Clear TMR2 flag (20ms)
    
    BTFSC   ADRESH,3	;Check if ADRESH bit 3 is 1 or 0
    CALL    BIT_3	;GOTO line 185
    
    BTFSC   ADRESH,4	;Check if ADRESH bit 3 is 1 or 0
    CALL    BIT_4	;GOTO line 190
	
    BTFSC   ADRESH,5	;Check if ADRESH bit 3 is 1 or 0
    CALL    BIT_5	;GOTO line 195
    
    BTFSC   ADRESH,6	;Check if ADRESH bit 3 is 1 or 0
    CALL    BIT_6	;GOTO line 200
	
    BTFSC   ADRESH,7	;Check if ADRESH bit 3 is 1 or 0
    CALL    BIT_7	;GOTO line 205
    
    MOVF    ADC_SAVE,0	;Move the value of ADRESH bits checked to w
    GOTO    POSITION	;GOTO line
    
    INT_END:
    BCF	    PORTB,0	;Clear flag to give servo Pulse space for rest of 20ms period
    MOVLW   0x00	;Move (0000|0000) to w
    MOVWF   ADC_SAVE	;Clear ADC_SAVE for next check
    
    MOVF    STAT_SAVE,0	;Move STAT_SAVE to w
    MOVWF   STATUS	;Move w to STATUS
    MOVF    W_SAVE,0	;Move w_SAVE to w
    
    RETFIE		;Return from interupt, renable Global interrupts
;-------------------------------------------------------------------------------   
    BIT_3:
    MOVLW   0x01	;Decimal 1
    ADDWF   ADC_SAVE	;ADD w to ADC_SAVE
    RETURN		;Return to line 157
    
    BIT_4:
    MOVLW   0x02	;Decimal 2
    ADDWF   ADC_SAVE	;ADD w to ADC_SAVE
    RETURN		;Return to line 160
    
    BIT_5:
    MOVLW   0x04	;Decimal 4
    ADDWF   ADC_SAVE	;ADD w to ADC_SAVE
    RETURN		;Return to line 163
    
    BIT_6:
    MOVLW   0x08	;Decimal 8
    ADDWF   ADC_SAVE	;ADD w to ADC_SAVE
    RETURN		;Return to line 166
    
    BIT_7:
    MOVLW   0x10	;Decimal 16
    ADDWF   ADC_SAVE	;ADD w to ADC_SAVE
    RETURN		;Return to line 169
    
    POSITION:
    ADDWF   PCL,1   ;ADD working register to program counter  
    GOTO    P1	;0
    GOTO    P2	;1
    GOTO    P2	;2
    GOTO    P3	;3
    GOTO    P4	;4
    GOTO    P4	;5
    GOTO    P5	;6
    GOTO    P6	;7
    GOTO    P6	;8
    GOTO    P7	;9
    GOTO    P8	;10
    GOTO    P8	;11
    GOTO    P9	;12
    GOTO    P10	;13
    GOTO    P10	;14
    GOTO    P11	;15
    GOTO    P12	;16
    GOTO    P12	;17
    GOTO    P13	;18
    GOTO    P14	;19
    GOTO    P14	;20
    GOTO    P15	;21
    GOTO    P16	;22
    GOTO    P16	;23
    GOTO    P17	;24
    GOTO    P18	;25
    GOTO    P18	;26
    GOTO    P19	;27
    GOTO    P20	;28
    GOTO    P20	;29
    GOTO    P21	;30
    GOTO    P21	;31
   
    P1:
    MOVLW   0x32    ;Decimal 50
    MOVWF   TIME    ;Set Delay value for desired Pulse Width
    BSF	    PORTB,0 ;Set bit high for Servo's Pulse Width
    GOTO    DELAY   ;GOTO line 371
    
    P2:
    MOVLW   0x3C    ;Decimal 60
    MOVWF   TIME    ;Set Delay value for desired Pulse Width
    BSF	    PORTB,0 ;Set bit high for Servo's Pulse Width
    GOTO    DELAY   ;GOTO line 371
    
    P3:
    MOVLW   0x46    ;Decimal 70
    MOVWF   TIME    ;Set Delay value for desired Pulse Width
    BSF	    PORTB,0 ;Set bit high for Servo's Pulse Width
    GOTO    DELAY   ;GOTO line 371
    
    P4:
    MOVLW   0x50    ;Decimal 80
    MOVWF   TIME    ;Set Delay value for desired Pulse Width
    BSF	    PORTB,0 ;Set bit high for Servo's Pulse Width
    GOTO    DELAY   ;GOTO line 371
    
    P5:
    MOVLW   0x5A    ;Decimal 90
    MOVWF   TIME    ;Set Delay value for desired Pulse Width
    BSF	    PORTB,0 ;Set bit high for Servo's Pulse Width
    GOTO    DELAY   ;GOTO line 371
    
    P6:
    MOVLW   0x64    ;Decimal 100
    MOVWF   TIME    ;Set Delay value for desired Pulse Width
    BSF	    PORTB,0 ;Set bit high for Servo's Pulse Width
    GOTO    DELAY   ;GOTO line 371
    
    P7:
    MOVLW   0x6E    ;Decimal 110
    MOVWF   TIME    ;Set Delay value for desired Pulse Width
    BSF	    PORTB,0 ;Set bit high for Servo's Pulse Width
    GOTO    DELAY   ;GOTO line 371
    
    P8:
    MOVLW   0x78    ;Decimal 120
    MOVWF   TIME    ;Set Delay value for desired Pulse Width
    BSF	    PORTB,0 ;Set bit high for Servo's Pulse Width
    GOTO    DELAY   ;GOTO line 371
    
    P9:
    MOVLW   0x82    ;Decimal 130
    MOVWF   TIME    ;Set Delay value for desired Pulse Width
    BSF	    PORTB,0 ;Set bit high for Servo's Pulse Width
    GOTO    DELAY   ;GOTO line 371
	
    P10:
    MOVLW   0x8C    ;Decimal 140
    MOVWF   TIME    ;Set Delay value for desired Pulse Width
    BSF	    PORTB,0 ;Set bit high for Servo's Pulse Width
    GOTO    DELAY   ;GOTO line 371
    
    P11:
    MOVLW   0x96    ;Decimal 150
    MOVWF   TIME    ;Set Delay value for desired Pulse Width
    BSF	    PORTB,0 ;Set bit high for Servo's Pulse Width
    GOTO    DELAY   ;GOTO line 371
    
    P12:
    MOVLW   0xA0    ;Decimal 160
    MOVWF   TIME    ;Set Delay value for desired Pulse Width
    BSF	    PORTB,0 ;Set bit high for Servo's Pulse Width
    GOTO    DELAY   ;GOTO line 371
    
    P13:
    MOVLW   0xAA    ;Decimal 170
    MOVWF   TIME    ;Set Delay value for desired Pulse Width
    BSF	    PORTB,0 ;Set bit high for Servo's Pulse Width
    GOTO    DELAY   ;GOTO line 371
    
    P14:
    MOVLW   0xB4    ;Decimal 180
    MOVWF   TIME    ;Set Delay value for desired Pulse Width
    BSF	    PORTB,0 ;Set bit high for Servo's Pulse Width
    GOTO    DELAY   ;GOTO line 371
    
    P15:
    MOVLW   0xBE    ;Decmial 190
    MOVWF   TIME    ;Set Delay value for desired Pulse Width
    BSF	    PORTB,0 ;Set bit high for Servo's Pulse Width
    GOTO    DELAY   ;GOTO line 371
    
    P16:
    MOVLW   0xC8    ;Decmial 200
    MOVWF   TIME    ;Set Delay value for desired Pulse Width
    BSF	    PORTB,0 ;Set bit high for Servo's Pulse Width
    GOTO    DELAY   ;GOTO line 371
    
    P17:
    MOVLW   0xD2    ;Decimal 210
    MOVWF   TIME    ;Set Delay value for desired Pulse Width
    BSF	    PORTB,0 ;Set bit high for Servo's Pulse Width
    GOTO    DELAY   ;GOTO line 371
    
    P18:
    MOVLW   0xDC    ;Decimal 220
    MOVWF   TIME    ;Set Delay value for desired Pulse Width
    BSF	    PORTB,0 ;Set bit high for Servo's Pulse Width
    GOTO    DELAY   ;GOTO line 371
    
    P19:
    MOVLW   0xE6    ;Decimal 230
    MOVWF   TIME    ;Set Delay value for desired Pulse Width
    BSF	    PORTB,0 ;Set bit high for Servo's Pulse Width
    GOTO    DELAY   ;GOTO line 371
    
    P20:
    MOVLW   0xF2    ;Decimal 242
    MOVWF   TIME    ;Set Delay value for desired Pulse Width
    BSF	    PORTB,0 ;Set bit high for Servo's Pulse Width
    GOTO    DELAY   ;GOTO line 371
    
    P21:
    MOVLW   0xFF    ;Decimal 255
    MOVWF   TIME    ;Set Delay value for desired Pulse Width
    BSF	    PORTB,0 ;Set bit high for Servo's Pulse Width
    GOTO    DELAY   ;GOTO line 371
    
    DELAY:
    NOP		    ;No Operation
    NOP		    ;No Operation
    NOP		    ;No Operation
    NOP		    ;No Operation
    NOP		    ;No Operation
    NOP		    ;No Operation
    NOP		    ;No Operation
    DECFSZ  TIME    ;Decrement "Time" register skip if 0
    GOTO    DELAY   ;GOTO line 371
    GOTO    INT_END ;GOTO line 174
    
END		    ;End OF Code. This Is Required