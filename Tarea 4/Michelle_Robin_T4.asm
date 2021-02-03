#include registers.inc

;*******************************************************************************
;       UNIVERSIDAD DE COSTA RICA       ESCUELA DE INGENIERIA ELECTRICA
;               MICROPROCESADORES IE 623  III CICLO 2020
;*******************************************************************************
;                                 TAREA 4
;*******************************************************************************
;       V1
;       AUTORES: ROBIN GONZALEZ   B43011
;                MICHELLE GUTIERREZ     B43195
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

MAX_TCL:        EQU     $1000   ;X:X:X:X:X:Array_OK : TCL_LEIDA : TCL_LISTA
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

main:
        BRSET Banderas,$04,main ;salta a main si el bits 2 (%0000 0100) es 1 en Banderas
        JSR Tarea_Teclado       ;ir a subrutina Tarea_Teclado
        BRA main        ;salta siempre a main


;*******************************************************************************
;                                     SUBRUTINAS
;*******************************************************************************


                        ;*******************************************************
Tarea_Teclado:          ;                      SUBRUTINA
                        ;*******************************************************
                        ;Verifica estado de teclas ingresadas
                           ;y llama a las otras subrutinas
                        ;*******************************************************
        TST Cont_Reb
        BNE Retorno_Tarea_Teclado
        JSR Mux_Teclado
        BRSET Tecla,$FF,revisar_TCL_LISTA

        BRCLR Banderas,$02,revisar_teclas
        MOVB Tecla,Tecla_IN
        BSET Banderas,$02
        MOVB #10,Cont_Reb
        BRA Retorno_Tarea_Teclado

revisar_teclas:
        LDAA Tecla
        CMPA Tecla_IN
        BNE error_al_leer
        BSET Banderas,$01
        BRA Retorno_Tarea_Teclado
        
error_al_leer:
        MOVW #$FFFF,Tecla ;Pone FF en las posiciones Tecla y Tecla_IN;
        BCLR Banderas,$03
        BRA Retorno_Tarea_Teclado

revisar_TCL_LISTA:
        BRCLR Banderas,$01,Retorno_Tarea_Teclado
        BCLR Banderas,$03
        JSR Formar_Array

Retorno_Tarea_Teclado:
        RTS

                        ;*******************************************************
MUX_TECLADO:            ;                      SUBRUTINA
                        ;*******************************************************
                        ;Lee teclado matricial
                        ;*******************************************************
        LDX Teclas
        CLRA
        MOVB #$EF,Patron
loop_mux:
        MOVB Patron,PORTA
        BRCLR PORTA,$02,tecla_presionada
        INCA
        BRCLR PORTA,$04,tecla_presionada
        INCA
        BRCLR PORTA,$08,tecla_presionada
        INCA
        LSLA
        BRCLR Patron,$0F,nada_presionado
        BRA loop_mux
        
nada_presionado:
        MOVB #$FF,Tecla
        RTS
        
tecla_presionada:
        MOVB A,X,Tecla
        RTS
        
                        ;*******************************************************
FORMAR_ARRAY:           ;                      SUBRUTINA
                        ;*******************************************************
                        ;Llena arreglo Num_Array con teclas leidas
                        ;*******************************************************
        Ldx Num_Array   ; Cargar dirección de Num_Array en el índice Y
        Ldaa #$0B
        Ldab #$0E
        Inc Cont_TCL
        Cmpb MAX_TCL
        Beq full_array
        TST Cont_TCL
        Beq primer_input
        Cmpa Tecla_IN
        Beq reducir_contador
        Cmpb Tecla_IN
        Beq poner_array_ok
        Ldab Cont_TCL
        Movb Tecla_IN,b,x ; No sabemos si está bien
        Inc Cont_TCL
        Bra Nodo_Final
        
poner_array_ok:
        Bset Banderas,$04 ;Poner en 1 el bit 3 (Array_Ok)
        Bra Nodo_Final
        
reducir_contador:
        Dec Cont_TCL
        Bra Nodo_Final
        
primer_input:
        Cmpa Tecla_IN
        Beq Nodo_Final
        Cmpb Tecla_IN
        Beq Nodo_Final
        Ldab Cont_TCL
        Movb Tecla_IN,b,x
        Inc Cont_TCL
        Bra Nodo_Final
        
full_array:
        Cmpa Tecla_IN
        beq reducir_contador
        Cmpb Tecla_IN
        Beq poner_array_ok
        Bra Nodo_Final
        
Nodo_Final:
        Movb #$FF,Tecla_IN
        RTS
        
;*******************************************************************************
;                         SUBRUTINAS DE INTERRUPCION
;*******************************************************************************

RTI_ISR:                ;                Subrutina RTI_ISR
                        ;*******************************************************
                        ;Subrutina que cuenta 10 ms
                        ;*******************************************************
        BSET CRGFLG,$80         ;borrar bandera de interrupcion
        BRCLR Cont_Reb,$FF,retorno_RTI  ;salta si la pos Cont_reb es 0
        DEC Cont_Reb    ;decrementar Cont_Reb
        
retorno_RTI:
        RTI

        
PH0_ISR:                ;                Subrutina PH0_ISR
                        ;*******************************************************
                        ;Subrutina que borrar Num_Array y Array_Ok al detectar
                        ;un flanco decreciente en PH0
                        ;*******************************************************
        BSET PIFH,$01   ;borramos la bandear de interrupcion
        
        BCLR Banderas,$04       ;borramos el bit 2
        MOVW #$FFFF,Num_Array
        MOVW #$FFFF,Num_Array+2
        MOVW #$FFFF,Num_Array+4

retorno_PH0:
        RTI