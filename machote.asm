#include registers.inc

;*******************************************************************************
;       UNIVERSIDAD DE COSTA RICA       ESCUELA DE INGENIERIA ELECTRICA
;               MICROPROCESADORES IE 623  III CICLO 2020
;*******************************************************************************
;                                 TAREA 4
;*******************************************************************************
;       V1
;       AUTORES: ROBIN GONZALEZ   B43011
;                MICHELLE GUTIERREZ     B4
;
;       DESCRIPCION:    BLABLA
;
;*******************************************************************************
;                             Estructuras de datos
;*******************************************************************************

EOM     EQU     $FF
CR:     EQU     $0A
LF:     EQU     $0D
SUB:    EQU     $1A     ;Borrado pantalla

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
        


        LDS #$4000 ;SIN DEBUG12
        CLI
        
;*******************************************************************************
;                             PROGRAMA PRINCIPAL
;*******************************************************************************



;*******************************************************************************
;                                     SUBRUTINAS
;*******************************************************************************

CALCULO:

        RTS


;*******************************************************************************
;                         SUBRUTINAS DE INTERRUPCION
;*******************************************************************************

RTI_ISR:                ;                Subrutina RTI_ISR
                        ;*******************************************************
                        ;Subrutina que cuenta 10 ms
                        ;*******************************************************

retorno_RTI:
        RTI
