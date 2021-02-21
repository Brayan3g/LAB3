; Archivo:	Laboratorio 3 -> Contador Binario y Hexadecimal con Alarma
; Dispositivo:	PIC16F887
; Autor:	Brayan Gabriel Giron Garcia
; Compilador:	pic-as (v2.30), MPLABX V5.40
;                
; Programa:	Contador Binario y Hexadecimal con Alarma
; Hardware:	LEDs en el puerto B, push en pueto A Y diplay en pueto D
;                       
; Creado: 16 feb, 2021
; Última modificación: 19 feb, 2021
 
 PROCESSOR 16F887
 #include <xc.inc>
 
 ;configuration word 1
  CONFIG FOSC=INTRC_NOCLKOUT	// Oscillador Interno sin salidas
  CONFIG WDTE=OFF   // WDT disabled (reinicio repetitivo del pic)
  CONFIG PWRTE=ON   // PWRT enabled  (espera de 72ms al iniciar)
  CONFIG MCLRE=OFF  // El pin de MCLR se utiliza como I/O
  CONFIG CP=OFF	    // Sin protección de código
  CONFIG CPD=OFF    // Sin protección de datos
  
  CONFIG BOREN=OFF  // Sin reinicio cuándo el voltaje de alimentación baja de 4V
  CONFIG IESO=OFF   // Reinicio sin cambio de reloj de interno a externo
  CONFIG FCMEN=OFF  // Cambio de reloj externo a interno en caso de fallo
  CONFIG LVP=ON     // programación en bajo voltaje permitida
 
 ;configuration word 2
  CONFIG WRT=OFF    // Protección de autoescritura por el programa desactivada
  CONFIG BOR4V=BOR40V // Reinicio abajo de 4V, (BOR21V=2.1V)

 PSECT udata_bank0 ;common memory
    count:	DS  2 ;1 byte
    old_portA:	DS  1
    ;cont_big:	DS  1
    
 PSECT resVect, class=CODE, abs, delta=2
 ;--------------vector reset------------------
 ORG 00h	;posición 0000h para el reset
 resetVec:
     PAGESEL main
     goto main
     
 PSECT code, delta=2, abs
 ORG 100h	; posición para el código
 
  ;------------------ TABLA -----------------------
  
 Tabla:
    clrf  PCLATH      ; Limpiar bits de la tabla 
    bsf   PCLATH,0    ; Set bit0 de PCLATH
    andlw 0x0F	      ; RESTRINGE LA CANTIDAD DE VALORES DE LA TABLA A 15
    addwf PCL	      ; SE LE AGREGA EL VALOR DE W AL PCL
    retlw 00111111B   ; 0  Asignacion de los numero para los valores de salida del display 
    retlw 00000110B   ; 1
    retlw 01011011B   ; 2
    retlw 01001111B   ; 3
    retlw 01100110B   ; 4
    retlw 01101101B   ; 5
    retlw 01111101B   ; 6
    retlw 00000111B   ; 7
    retlw 01111111B   ; 8
    retlw 01101111B   ; 9
    retlw 01110111B   ; A
    retlw 01111100B   ; b
    retlw 00111001B   ; C
    retlw 01011110B   ; d
    retlw 01111001B   ; E
    retlw 01110001B   ; F
    
 ;----------------------------------------------------------------------------- 
 ;-------------------------------- MAIN ---------------------------------------
 main:
    call    Config_TMR0 ; COMFIGURAMOS EL TMR0
    call    Clock       ; ASIGNAMOS LA FRECUENCIA DEL RELOJ INTERNO
    
    banksel ANSEL
    clrf    ANSEL	; pines digitales
    clrf    ANSELH
    
    banksel TRISA
    movlw   11110111B
    movwf   TRISA	; ASIGNACION DE ENTRADAS Y SALIDAS EN EL PUERTO A
    movlw   11110000B
    movwf   TRISB	; ASIGNACION DE ENTRADAS Y SALIDAS EN EL PUERTO B
    clrf    TRISD       ; ASIGNACION COMO SALIDAS TODO EL PUERTO D
    clrf    TRISC       ; ASIGNACION COMO SALIDAS TODO EL PUERTO C
    
    banksel PORTA
    clrf    PORTA
    clrf    PORTB
    clrf    PORTC
    clrf    PORTD
    
 ;------------------------------------------------------------------------------   
 ;------------------------------Loop--------------------------------------------        
 Loop:
    call   Valor_Display ; LLAMA A LA SUBRUTINA VALOR_DISPLAY PARA ASIGNARLE EL VALOR AL DISPLAY
    movf   PORTA, W      ; MOVEMOS EL VALOR DEL PORTA A W
    movwf  old_portA     ; GUARDAMOS EL VALOR DE W EN LA VARIABLE old_PORTA
    call   Delay         ; LLAMAMOS AL DELAY PARA DARLE TIEMPO DE CAMBIAR AL VALOR DEL PUETO 
		 
    btfsc  old_portA, 0  ; REVISA EL BOTON DE INCREMENTAR
    call   inc_porta
		 
    btfsc  old_portA, 1  ; REVISA EL BOTON DE DECREMENTAR  
    call   dec_porta
    
    btfss   T0IF         ; VERIFICA SI EL TMR0 SE A DESBORDADO
    goto    Loop        
    call    Rein_TMR0    ; LLAMA AL REINICIO DEL TAIMER SI LA BANDERA DEL TMR0 ESTA LEVANTADA
    incf    PORTB        ; INCREMENTA EL PORTB, QUE TINE ASIGNADO EL CONTADOR BINARIO
    
    incf  PORTD,w        ; MOVER EL VALOR DEL PUERTO D A "W"
    subwf PORTB,w        ; RESTAR EL VALOR DE W AL VALOR DEL PORTB
    
    btfsc STATUS,2       ; VERIFICA SI EL RESULTADO DE LA RESTA ES "0"
    call  ALARMA          ; SI EL RESULTADO DE LA RESTA ES 0 SE ENCIENDE EL LED
    btfss STATUS,2       ; VERIFICA SI EL RESULTADO DE LA RESTA ES DIFENTE DE"0"
    bcf   PORTA,3        ; SI EL RESULTADO DE LA RESTA NO ES 0 SE ENCIENDE EL LED
    
    goto   Loop          ; RETORNO DEL Loop 
    
    
 ;-----------------------------sub rutinas--------------------------------------
inc_porta:
    btfss   PORTA, 0     ; VERIFICAMOS SI YA SE SOLTO EL BOTON DE INCREMENTAR
    incf    PORTD        ; INCREMENTAMOS EL PUERTO D
    return         

dec_porta:
    btfss   PORTA, 1     ; VERIFICAMOS SI YA SE SOLTO EL BOTON DE INCREMENTAR
    decf    PORTD        ; INCREMENTAMOS EL PUERTO D
    return
    
    
 Delay:
    movlw   250		 ; valor inicial del contador
    movwf   count	    
    decfsz  count, 1     ; decrementar el contador
    goto    $-1		 ; ejecutar línea anterior
    return
    
Valor_Display:
    movf    PORTD,w     ; MUEVE EL VALOR DEL PORTD A "W"
    call    Tabla       ; LLAMA A LA TABLA CON LOS VALORES DEL DISPLAY
    movwf   PORTC       ; MUEVE EL VALOR DEVUELTO POR LA TABLA AL PORTC
    return
    
    
Config_TMR0:
    
    banksel OPTION_REG  
    bcf	    T0CS         ; Activar el tipo de reloj para el TMR0
    bcf	    PSA	         ; Ponderacion para el reloj
    bsf	    PS2
    bsf	    PS1
    bsf	    PS0	         ; PRESCALAR -> 256
    call    Rein_TMR0
    return
    
    
Rein_TMR0: 
    
    banksel TMR0
    movlw   240          ; ASIGNAMOS EL VALOR AL TMR0 
    movwf   TMR0
    bcf	    T0IF         ; LIMPIAMOS LA BANDERA DE DESBORDAMIENTO DEL TMR0      
    return
    
    
Clock:
    banksel OSCCON	 ; Banco OSCCON 
    bcf	    IRCF2	 ; ASIGNAMOS LA FRECUENCIA DE RELOJ INTERNO -> 31KHz
    bcf	    IRCF1	
    bcf	    IRCF0	
    bsf	    SCS		
    return
    
ALARMA: 
    bsf   PORTA,3        ; ENCIENDE EL LED DE ALARMA
    clrf  PORTB          ; LIMPIA EL PORTB PARA REINICIAR EL CONTADOR BINARIO
    return

end

