#include registers.inc

;*******************************************************************************
;       UNIVERSIDAD DE COSTA RICA       ESCUELA DE INGENIERIA ELECTRICA
;               MICROPROCESADORES IE 623  III CICLO 2020
;*******************************************************************************
;                                 TAREA 5
;*******************************************************************************
;       V1
;       AUTORES: ROBIN GONZALEZ   B43011
;                MICHELLE GUTIERREZ     B43195
;
;       DESCRIPCION:    Contador de tornillos
;
;*******************************************************************************
;                             Estructuras de datos
;*******************************************************************************

EOM     EQU     $FF

                ORG $1000
Banderas:        ds      1 ;x:x:x:CambMod:ModActual:ARRAY_OK:TCL_LEIDA:TCL_LISTA
MAX_TCL:         ds      1
Tecla:           ds      1
Tecla_IN:        ds      1
Cont_Reb:        ds      1
Cont_TCL:        ds      1
Patron:          ds      1
Num_Array:       ds      2
CUENTA:          ds      1
AcmPQ:           ds      1
CantPQ:          ds      1
TIMER_CUENTA:    ds      1
LEDS:            ds      1
BRILLO:          ds      1
CONT_DIG:        ds      1
CONT_TICKS:      ds      1
DT:              ds      1
BIN1:            ds      1
BIN2:            ds      1
BCD_L:           ds      1
LOW:             ds      1
TEMP:            ds      1
BCD1:            ds      1
BCD2:            ds      1
DISP1:           ds      1
DISP2:           ds      1
DISP3:           ds      1
DISP4:           ds      1
CONT_7SEG:       dw      1
Cont_Delay:      ds      1
D2mS:            ds      1
D260uS:          ds      1
D40uS:           ds      1
Clear_LCD:       ds      1
ADD_L1:          ds      1
ADD_L2:          ds      1
Teclas:          ds      16
SEGMENT:         ds      16
iniDsp:          ds      16
Msg1_L1:                 fcc     "  MODO CONFIG"
                db EOM
Msg1_L2:                 fcc     "Ingrese CantPQ"
                db EOM
Msg2_L1:                 fcc     "    MODO RUN"
                db EOM
Msg2_L2:                 fcc     "  AcmPQ  CUENTA"
                db EOM


;*******************************************************************************
;                             Relocalizar vectores
;*******************************************************************************

         org        $3E4C       ;debug12
        dw PTH_ISR
        
         org        $3E70       ;debug12
        dw RTI_ISR
        
         org        $3E66       ;debug12
        dw OC4_ISR
        
;*******************************************************************************
;          Inicializacion de estructuras de datos y config de hardware
;*******************************************************************************

                ORG     $2000

        MOVB #0,Banderas
        MOVB #$FF,Tecla
        MOVB #$FF,Tecla_IN
        MOVB #0,Cont_Reb
        MOVB #0,Cont_TCL
        MOVB #0,Patron
        MOVB #$FF,Num_Array
        MOVB #$FF,Num_Array+1
        MOVB #$FF,Num_Array+2
        MOVB #$FF,Num_Array+3
        MOVB #$FF,Num_Array+4
        MOVB #$FF,Num_Array+5
        MOVB #0,CUENTA
        MOVB #0,AcmPQ
        MOVB #0,CantPQ
        MOVB #250,TIMER_CUENTA
        MOVB #0,LEDS
        MOVB #50,BRILLO
        MOVB #15,CONT_DIG
        MOVB #0,DT
        MOVB #0,BIN1
        MOVB #0,BIN2
        MOVB #0,BCD_L
        MOVB #0,LOW
        MOVB #0,TEMP
        MOVB #0,BCD1
        MOVB #0,BCD2
        MOVB #0,DISP1
        MOVB #0,DISP2
        MOVB #0,DISP3
        MOVB #0,DISP4
        MOVB #0,CONT_7SEG
        MOVB #50,CONT_7SEG + 1
        MOVB #0,Cont_Delay
        
        ;Inicializacion de hardware
        
	;Rele:
        BSET DDRE,$04   ;activar pin 2 de puerto E Rele como salida

        ;Pantalla LCD
        MOVB DDRK,$1F  ;nibble inferior como salida
        
        ;Pantalla 7 segmentos
        BSET DDRP,$0F  ;poner pads de salida,apagar 7 segmentos
        
        ;LEDS
        MOVB #$FF,DDRB
        BSET DDRJ,$02   ;bit 2 como salida
        BCLR PTJ,$02    ;bit 2 en 0, catodo comun
                
        ;Teclado matricial
        MOVB #$F0,DDRA
        BSET PUCR,$01
        
        ;RTI
        BSET CRGINT,$80
        MOVB #$17,RTICTL
        
        ;PTH
        CLR DDRH
        BSET PIEH,$0F
        BSET PPSH,$0F   ;interrupcion en flanco creciente
        
        ;OC4
        BSET TSCR1,$80  ;encendemos Timer, NO TFFCLA
        BSET TSCR2,$04  ;poner prescalador en 16
        BSET TIE,$10  ;poner prescalador en 16
        LDD TCNT
        ADDD #30
        STD TC4
        
        

        
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
                        ;Subrutina que cuenta 1 ms
                        ;*******************************************************

retorno_RTI:
        RTI
        
PTH_ISR:                ;                Subrutina PTH_ISR
                        ;*******************************************************
                        ;Subrutina que lee botones conectados al puerto H
                        ;*******************************************************

retorno_PTH:
        RTI
        
OC4_ISR:                ;                Subrutina OC4_ISR
                        ;*******************************************************
                        ;Subrutina que genera interrupciones cada 50 KHz
                        ;*******************************************************

retorno_OC4:
        RTI
