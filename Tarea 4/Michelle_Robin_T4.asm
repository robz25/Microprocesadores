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
;       DESCRIPCION:    LECTURA DE TECLADO MATRICIAL:    CODIGO QUE CONSISTE
;                       DE 3 SUBRUTINAS Y 2 SUBRUTINAS DE INTERRUPCION QUE
;                       LEEN BOTONES PRESIONADOS EN EL TECLADO MATRICIAL DEL
;                       DRAGON12 Y PONEN EN UN ARRELGO VALORES CORRESPONDIENTES
;                       A LAS TECLAS PRESIONADAS.
;
;*******************************************************************************
;                      Declaración de estructuras de datos
;*******************************************************************************

MAX_TCL:        EQU     $1000
Tecla:          EQU     $1001
Tecla_IN:       EQU     $1002
Cont_Reb:       EQU     $1003
Cont_TCL:       EQU     $1004
Patron:         EQU     $1005
Banderas:       EQU     $1006
Num_Array:      EQU     $1007
Teclas:         EQU     $100D

        ORG     MAX_TCL
        db      6
        ORG     Teclas
        db      $01,$02,$03,$04,$05,$06,$07,$08,$09,$0B,$0,$0E

;*******************************************************************************
;                             Relocalizar vectores
;*******************************************************************************

         org        $3E70  ;Debug 12
;         org        $FFF0  ;Flash
        dw RTI_ISR

         org        $3E4C  ;Debug 12
;         org        $FFCC  ;Flash
        dw PH0_ISR
        
;*******************************************************************************
;            Inicialización de varaibles y config de hardware
;*******************************************************************************

                ORG     $2000
                
	MOVB #$FF,Tecla
	MOVB #$FF,Tecla_IN
	MOVW #$FFFF,Num_Array
	MOVW #$FFFF,Num_Array+2
	MOVW #$FFFF,Num_Array+4
	CLR Cont_Reb
	CLR Cont_TCL
	CLR Patron
	CLR Banderas
	
	BSET CRGINT,$80
	MOVB #$0F,RTICTL
	
	BSET PIEH,$01
	BCLR PPSH,$01

	MOVB $F0,DDRA

        LDS #$3BFF
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
