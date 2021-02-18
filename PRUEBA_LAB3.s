; Archvo:	Lab3 
; Dispositivo:	PIC16F887
; Autor:	Brayan Girón 
; Carnet:	15807
; Compilador:	pic-as (v2.30), MPLABX v5.40
;    
; Programa:	contador en el puerto B,
; Hardware:	LEDs en el puerto b, DISPLAY en puerto C
;
; Creado:15 feb, 2021
; Ultima modificación: 16 feb, 2021
;-------------------------------------------------------------------------------
PROCESSOR 16F887
#include <xc.inc>

; configuración word1
 CONFIG FOSC=INTRC_NOCLKOUT //Oscilador interno sin salidas
 CONFIG WDTE=OFF	    //WDT disabled (reinicio repetitivo del pic)
 CONFIG PWRTE=ON
 CONFIG MCLRE=OFF
 CONFIG CP=OFF
 CONFIG CPD=OFF
 
 CONFIG BOREN=OFF
 CONFIG IESO=OFF
 CONFIG FCMEN=OFF
 CONFIG LVP=ON
 
;configuración word2
  CONFIG WRT=OFF	//Protección de autoescritura 
  CONFIG BOR4V=BOR40V	//Reinicio abajo de 4V 

;------------------------------
  PSECT udata_bank0 ;common memory
    cont:	DS  2 ;1 byte apartado
    ;cont_big:	DS  1;1 byte apartado
  
  PSECT resVect, class=CODE, abs, delta=2
  ;----------------------vector reset------------------------
  ORG 00h	;posición 000h para el reset
  resetVec:
    PAGESEL main
    goto main
  
  PSECT code, delta=2, abs
  ORG 100h	;Posición para el código
  ;------------------ TABLA -----------------------
  
  Tabla:
    clrf  PCLATH
    bsf   PCLATH,0
    andlw 0x0F
    addwf PCL
    retlw 00111111B          ; 0
    retlw 00000110B          ; 1
    retlw 01011011B          ; 2
    retlw 01001111B          ; 3
    retlw 01100110B          ; 4
    retlw 01101101B          ; 5
    retlw 01111101B          ; 6
    retlw 00000111B          ; 7
    retlw 01111111B          ; 8
    retlw 01101111B          ; 9
    retlw 01110111B          ; A
    retlw 01111100B          ; b
    retlw 00111001B          ; C
    retlw 01011110B          ; d
    retlw 01111001B          ; E
    retlw 01110001B          ; F
 
  ;---------------------------- configuración ----------------------------------
  main: 
    
    call    Clock         
    call    Config_TMR0
    
    bsf	    STATUS, 5   ;banco  11
    bsf	    STATUS, 6	;Banksel ANSEL
    clrf    ANSEL	;pines digitales
    clrf    ANSELH      
    
    banksel TRISB       
    movlw   11110000B   
    movwf   TRISB	; declara los priros 4 pines del port b como salidas
    clrf    TRISC	; declara port C como salida
    movlw   11110111B   
    movwf   TRISA       
    movlw   11110000B 
    movwf   TRISD
   ;clrf    TRISB
   
    banksel PORTB	;
    clrf    PORTB	; Limpiar PortB
    clrf    PORTC	; Limpiar PortC
    clrf    PORTD       ; Limpiar PortD
    clrf    PORTA       ; Limpiar PortA 
    
  
    
;---------------------------------- Loop ---------------------------------------
 Loop: 

    btfsc   PORTA, 0	; Verifica si el boton esta presionado
    call    Inc_D       ; Llama a la sub-rutina Inc_A
    btfsc   PORTA, 1	; Revisar si no esta presionado 
    call    Dec_D       ; Llama a la sub-rutina Dec_A
        
    movf    PORTD,w     ; MUEVE EL VALOR DEL PORTD A "W"
    call    Tabla       ; LLAMA A LA TABLA CON LOS VALORES DEL DISPLAY
    movwf   PORTC       ; MUEVE EL VALOR DEVUELTO POR LA TABLA AL PORTC
    
    btfss   T0IF        ; VERIFICA SI EL TMR0 SE A DESBORDADO
    goto    Loop        
    ;goto    $-1
    call    Rein_TMR0
    incf    PORTB
    
    movf PORTB,w         ; MOVER EL VALOR DEL PUERTO B A "W"
    subwf PORTD,w        ; RESTAR EL VALOR DE W AL VALOR DEL PORTD
    
    btfsc STATUS,2       ; VERIFICA SI EL RESULTADO DE LA RESTA ES "0"
    call mijin           ; SI EL RESULTADO DE LA RESTA ES 0 SE ENCIENDE EL LED
    
    btfss STATUS,2       ; VERIFICA SI EL RESULTADO DE LA RESTA ES DIFENTE DE"0"
    bcf   PORTA,3        ; SI EL RESULTADO DE LA RESTA NO ES 0 SE ENCIENDE EL LED
    
    goto    Loop    
  
;------------------------------- Sub Rutinas -----------------------------------
 
 mijin: 
    ;incf  PORTB
    bsf   PORTA,3        ; ENCIENDE EL LED DE ALARMA
    clrf  PORTB          ; LIMPIA EL PORTB PARA REINICIAR EL CONTADOR BINARIO
    ;call  Rein_TMR0
    return
    
    
 Config_TMR0:
    
    banksel OPTION_REG  
    bcf	    T0CS         ; reloj interno clock selection
    bcf	    PSA	         ;Prescaler 
    bsf	    PS2
    bsf	    PS1
    bsf	    PS0	         ;PRESCALAR -> 256
    
    banksel TMR0
    call    Rein_TMR0
    return
    
    
 Rein_TMR0: 
    movlw   240
    movwf   TMR0
    bcf	    T0IF
    return
    
    
 Clock:
    banksel OSCCON	 ;Banco OSCCON 
    bcf	    IRCF2	 ;frecuencia de reloj interno -> 31KHz
    bcf	    IRCF1	
    bcf	    IRCF0	
    bsf	    SCS		
    return
   
    
    
 Inc_D:
    ;call    Delay	 ;Llamamos a la sub-rutina Delay ->  
    btfsc   PORTA, 0	 ;Revisa de nuevo si no esta presionado
    goto    $-1		 ;ejecuta una linea atrás	        
    incf    PORTD
    return
    
 Dec_D:
    ;call    Delay
    btfsc   PORTA, 1	 ;Revisa de nuevo si no esta presionado
    goto    $-1		 ;ejecuta una linea atrás	        
    decf    PORTD
    return    
    
;ALARMA: 
    
   ; return 
 ;--------------------------------- Delay --------------------------------------
 ; Esta sirve para evitar el ruido al momento de presionar los botones.   
 
 ;Delay:
    ;movlw	150		;valor incial
    ;movwf	cont
    ;decfsz	cont, 1	        ;decrementar
    ;goto	$-1		;ejecutar línea anterior
    ;return    
    
end


    
    

    