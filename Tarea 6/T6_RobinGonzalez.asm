#include registers.inc

;*******************************************************************************
;       UNIVERSIDAD DE COSTA RICA       ESCUELA DE INGENIERIA ELECTRICA
;               MICROPROCESADORES IE 623  III CICLO 2020
;*******************************************************************************
;                                 Tarea 6
;*******************************************************************************
;       V2
;       AUTORES: ROBIN GONZALEZ   B43011
;                MICHELLE GUTIERREZ B43195
;
;       DESCRIPCION:    Imprimir nivel de tanque de 15 m leido con ADT0
;
;*******************************************************************************
;                             Estructuras de datos
;*******************************************************************************

EOM     EQU        $FF ;no se  puede usar 0 porque en primera interrupcion programa carga A con 0 y lo haya cierto
                    ;entonces deshabilita interrupciones y termina;
CR:     EQU     $0A
LF:     EQU     $0D
SUB:    EQU     $1A     ;Borrado pantalla
P15:    EQU     14
P30:    EQU     31
P90:    EQU     98
P100:   EQU     106

                ORG $1000
estado  ds 1

                ORG $1010
Nivel_PROM      ds 2
NIVEL   ds      1
VOLUMEN ds      1
CONTADOR_DELAY  ds 1
Puntero ds 2
encabezado
        db SUB
        FCC "                                Universidad de Costa Rica"
        db CR,LF
        FCC "                             Escuela de Ingenieria Electrica"
        db CR,LF
        FCC "                                       Microprocesadores"
        db CR,LF
        FCC "                                            IE0623"
        db CR,LF
        FCC ""
        db CR,LF
        FCC "                             Volumen Calculado: "
Volumen_ascii:
        db 82,71,82,CR,LF
        FCC " "
        db CR,LF
        FCC " "
        db CR,LF
        db EOM

Vaciado FCC " Tanque vaciando, bomba apagada"
        db CR,LF
        db EOM
        
Alarma  FCC " Alarma: el nivel esta bajo"
        db CR,LF
        db EOM

COMPLETADO:     ds 1
;*******************************************************************************
;                             Relocalizar vectores
;*******************************************************************************

         org        $FFD2  ;Flash
        dw ATD0_ISR
        
         org        $FFD4  ;Flash
        dw SCI_ISR

         org        $FFF0  ;Flash
        dw RTI_ISR
;*******************************************************************************
;                             Config de hardware
;*******************************************************************************

                ORG     $2000
        
        ;definicion de variables
        MOVW #0,Nivel_PROM
        MOVB #0,NIVEL
        MOVB #0,VOLUMEN
        MOVB #0,CONTADOR_DELAY
        MOVB #0,COMPLETADO
        MOVB #1,estado  ;empezamos con vaciado,2:alarma,8:llenado

        ;Configurar ATD 0
        MOVB #$C2,ATD0CTL2      ;enciende ADC 0, al leer borra banderas, enciende INTs
        LDAA #160               ;espero 10 ms
esperar_10ms:
        DBNE A,esperar_10ms:
        MOVB #$30,ATD0CTL3      ;FIFO OFF, se haran 6 conversiones
        MOVB #$01,ATD0CTL4      ;res a 10 bits, 2 ciclos de reloj, Prescalador en 17
        MOVB #$80,ATD0CTL5      ;just a derecha, sin signo, controlada por software, sin MUX

        ;Configurar interrupcion RTI
        BSET CRGINT,$80         ;pone en 1 bit mas significativo
        MOVB #$49, RTICTL       ;carga valores para contar 10.24 ms segun formula
        
        ;leds
        BSET DDRB,$01
        BSET DDRJ,$02
        BCLR PTJ,$02
        
        ;config SCI 1
        LDX #encabezado
        STX Puntero
        MOVW #39,SC1BDH
        MOVB #0,SC1CR1
        MOVB #$88,SC1CR2;habilitar interrupcion

        LDS #$4000 ;SIN DEBUG12
        CLI
        
;*******************************************************************************
;                             PROGRAMA PRINCIPAL
;*******************************************************************************

        WAI  ; no avanzar hasta que suceda alguna interrupcion (ADT o RTI) ADT deber�a suceder primero
main:
        LDX #encabezado
        STX Puntero
        MOVB #$88,SC1CR2;encender SCI, con TCIE y TIE
esperar_m1:
        TST COMPLETADO ;mientras sea 0 no se ha enviado msg completo
        BEQ esperar_m1
        MOVB #0,COMPLETADO
        BRSET estado,$01,e_vaciado
        BRSET estado,$02,e_alarma
        BRSET estado,$08,e_llenado
        
continuar_main:
        MOVB #100,CONTADOR_DELAY
l1:
        TST CONTADOR_DELAY
        BEQ main
        bra l1

e_vaciado:
        LDAA #P15
        CMPA VOLUMEN
        BLO seguir_vaciado
        MOVB #$2,estado ;pasar a estado alarma
        BRA e_alarma
seguir_vaciado:
        LDX #Vaciado
        STX Puntero
        MOVB #$88,SC1CR2;encender SCI
esperar_m3:
        TST COMPLETADO ;mientras sea 0 no se ha enviado msg completo
        BEQ esperar_m3
        MOVB #0,COMPLETADO
        BRA continuar_main

e_alarma:
        LDAA #P30
        CMPA VOLUMEN
        BHI seguir_alarma
        MOVB #$8,estado
        BRA e_llenado
seguir_alarma:
        LDX #Alarma
        STX Puntero
        MOVB #$C8,SC1CR2 ;encender SCI
esperar_m2:
        TST COMPLETADO ;mientras sea 0 no se ha enviado msg completo
        BEQ esperar_m2
        MOVB #0,COMPLETADO
        BRA continuar_main
        
e_llenado:
        LDAA #P90
        CMPA VOLUMEN
        BHI seguir_llenado
        MOVB #$1,estado
        BRA e_vaciado
seguir_llenado:
        BRA continuar_main

;*******************************************************************************
;                                     SUBRUTINAS
;*******************************************************************************

CALCULO:
        lDD Nivel_PROM
        LDY #20
        EMUL
        LDX #1023
        IDIV
        XGDX
        STAB NIVEL
        LDAA #7
        MUL
        STAB VOLUMEN
        CMPB #P100
        BLO cambiar_estado_bomba
        MOVB #106,VOLUMEN
cambiar_estado_bomba:
        CMPB #P90
        BLO verificar_si_bajo
        BCLR PORTB,$01     ;apagar leds
verificar_si_bajo:
        CMPB #P15
        BHI retorno_calculo
        BSET PORTB,$01
retorno_calculo:
        RTS


CONV_ASCII:
        CLRA
        LDAB VOLUMEN
        LDX #10
        IDIV
        ADDB $30 ;sumamos 48 a unidades y tenemos valor en ascii
        STAB Volumen_ascii+2 ;hay que imprimir primero centenas, guarnda undidades
        XGDX
        LDX #10
        IDIV
        ADDB $30 ;sumamos 48 a decenas y queda en ascii
        STAB Volumen_ascii+1 ;guarda decenas
        XGDX
        ADDB $30
        STAB Volumen_ascii ;guarda centenas
        RTS

;*******************************************************************************
;                         SUBRUTINAS DE INTERRUPCION
;*******************************************************************************

RTI_ISR:                ;                Subrutina RTI_ISR
                        ;*******************************************************
                        ;Subrutina que cuenta 10 ms
                        ;*******************************************************
                        
        BSET CRGFLG,$80 ;borrar solicitud de interrupcion
        TST CONTADOR_DELAY
        BEQ retorno_RTI
        DEC CONTADOR_DELAY
retorno_RTI:
        RTI


SCI_ISR:                ;                    Subrutina SCI_ISR
                        ;*******************************************************
                        ;Subrutina que envia mensajes por SCI1
                        ;*******************************************************
                        
        LDAA SC1SR1 ;1er paso para borrar banderas de INT
        LDX Puntero
        LDAA 1,X+
        CMPA #EOM
        BEQ apagar
        STAA SC1DRL ;2do paso para borrar banderas de INT
        STX Puntero
        BRA regresar
apagar:
        MOVB #$08,SC1CR2;apago SCI1, no lo apago, borro hab de Int  de reg de TX vacio, queda en IDLE
        MOVB #1,COMPLETADO;mensaje completado
regresar:
        RTI

ATD0_ISR:               ;                    Subrutina ADT0_ISR
                        ;*******************************************************
                        ;Subrutina para leer canal 0 6 veces y promediar
                        ;*******************************************************
        LDD ADR00H      ;aunque son valores de 8 bits los guardo en D, pues los
        ADDD ADR01H     ;justifique a la derecha porque sumados podrian sobrepasar
        ADDD ADR02H     ;los 8 bits
        ADDD ADR03H
        ADDD ADR04H
        ADDD ADR05H
        lDX #6
        IDIV
        STX Nivel_PROM
        MOVB #$80,ATD0CTL5      ;recarga para reiniciar lectura por software
        JSR CALCULO
        JSR CONV_ASCII
        RTI