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

EOM:     EQU     $FF
VMAX:    EQU     $FF

                ORG $1000
Banderas:        ds      1 ;x:x:x:CambMod:ModActual:ARRAY_OK:TCL_LEIDA:TCL_LISTA
MAX_TCL:         db      2      ;segun enunciado
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
D2mS:            db      100
D260uS:          db      13
D40uS:           db      2
Clear_LCD:       db      $01 ;comando borrar pantalla
ADD_L1:          db      $80 ;dir de inicio de linea 1 en DDRAM de pantalla
ADD_L2:          db      $C0 ;dir de inicio de linea 2 en DDRAM de pantalla
Teclas:          db      $01,$02,$03,$04,$05,$06,$07,$08,$09,$0B,$0,$0E,0,0,0,0
SEGMENT:         ds      $3F,$06,$5B,$4F,$66,$6D,$7D,$07,$7F,$6F,0,0,0,0,0,0
iniDsp:          db      $28,$28,$06,$0F
                org $1060
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
        MOVB #99,CUENTA
        MOVB #99,AcmPQ
        MOVB #0,CantPQ
        MOVB #0,LEDS
        MOVB #50,BRILLO
        MOVB #1,CONT_DIG ; Empezamos a contar en 1 con los LEDS
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
        MOVB #VMAX,TIMER_CUENTA

        ;Inicializacion de hardware

        ;Rele:
        BSET DDRE,$04   ;activar pin 2 de puerto E Rele como salida

        ;Pantalla LCD
        BSET DDRK,$FF  ;nibble inferior como salida
        BClR PORTK,$01

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

            LDS #$3BFF
        CLI

        JSR LCD_INIT
 ;        LDX #Msg1_L1
 ;        LDY #Msg1_L2
 ;        JSR Cargar_LCD


;*******************************************************************************
;                             PROGRAMA PRINCIPAL
;*******************************************************************************

main:
        JSR MODO_RUN
	BRA main
	

;*******************************************************************************
;                                     SUBRUTINAS
;*******************************************************************************


MODO_RUN:               ;                 Subrutina MODO_RUN
                        ;*******************************************************
                        ; Subrutina que lleva la cuenta de tornillos
                        ;*******************************************************
        MOVB #1,LEDS
        TST TIMER_CUENTA
        BNE retorno_MODO_RUN
        MOVB #VMAX,TIMER_CUENTA
        INC CUENTA
        LDAA CUENTA
        CMPA CantPQ
        BNE retorno_MODO_RUN

        INC AcmPQ

        LDAA #100
        CMPA AcmPQ
        BNE retorno_MODO_RUN
        CLR AcmPQ

retorno_MODO_RUN:

        RTS


                        ;*******************************************************
Delay:                  ;                 Subrutina Delay
                        ;*******************************************************
                        ;Genera retardo para enviar informaciÃ³n a la pantalla
                        ;LCD, se queda en un loop hasta que la variable ha sido
                        ;DECrementada a 0 por OC4
                        ;*******************************************************
        TST Cont_Delay
        BNE Delay
        RTS



;*******************************************************************************
;                        SUBRUTINAS DE INTERRUPCION
;*******************************************************************************

RTI_ISR:                ;                Subrutina RTI_ISR
                        ;*******************************************************
                        ;Subrutina que cuenta 1 ms
                        ;*******************************************************
        BSET CRGFLG,$80         ;borrar bandera de interrupcion
        BRCLR Cont_Reb,$FF,retorno_RTI  ;salta si la pos Cont_reb es 0
        DEC Cont_Reb    ;decrementar Cont_Reb
        BRCLR TIMER_CUENTA,$FF,retorno_RTI  ;salta si la pos Cont_reb es 0
        DEC TIMER_CUENTA ;decrementar Cont_Reb
retorno_RTI:
        RTI

PTH_ISR:                ;                Subrutina PTH_ISR
                        ;*******************************************************
                        ;Subrutina que lee botones conectados al puerto H
                        ;*******************************************************

retorno_PTH:
        BRSET Banderas,$08,saltar_pth0  ;revisa Mod_Actual   config si es 1
        BRSET PIFH,$01,saltar_pth0
        BSET PIFH,$01
        CLR CUENTA
        BCLR PORTE,$04  ;apagar Relé
        BSET CRGINT,$80  ;encender RTI
        BRA retorno_PTH_ISR
        
saltar_pth0:
        TST Cont_Reb
        BNE retorno_PTH_ISR
        BRSET Tecla,$80,segundo_ingreso
        MOVB PIFH,Tecla
        LDAA #$0F
        ANDA PIFH
        STAA PIFH
        MOVB #10,Cont_Reb
        BSET Tecla,$80  ;indicar que ya entro por primera vez
        BRA retorno_PTH_ISR

segundo_ingreso:
        BCLR Tecla,$80
        LDAB PIFH
        CMPB Tecla      ;revisar si valores anteriores de PIFH son iguales ahora
	BEQ lectura_correcta
	MOVB #$FF,Tecla

retorno_PTH_ISR:
        RTI
        
lectura_correcta:
        LDAA BRILLO
        BRSET PIFH,$04,disminuir_brillo
        BRSET PIFH,$08,aumentar_brillo
        BRSET Banderas,$08,retorno_PTH_ISR      ;Mod_actual es 1 : config
        BRSET PIFH,$02,AcmCLEAR
	BRA retorno_PTH_ISR

AcmCLEAR:
        BSET PIFH,$02
        CLR AcmPQ
	BRA retorno_PTH_ISR
	
aumentar_brillo:
        BSET PIFH,$08
        CMPA #95
        BHS retorno_PTH_ISR     ;salta si A mayor o igual a 95
        ADDA #5
        STAA BRILLO
	BRA retorno_PTH_ISR
	
disminuir_brillo:
        BSET PIFH,$04
	CMPA #5
	BLS retorno_PTH_ISR     ;salta si A es menor o igual a 5
	SUBA #5
	STAA BRILLO
	BRA retorno_PTH_ISR
	
	
	
OC4_ISR:                ;                Subrutina OC4_ISR
                        ;*******************************************************
                        ;Subrutina que genera interrupciones cada 50 KHz
                        ;*******************************************************

        BSET TFLG2,$80  ;borrar int
        TST Cont_Delay
        BEQ retorno_OC4
        DEC Cont_Delay

retorno_OC4:
        LDD #30      ;cada 30 son 20uS
        ADDD TCNT       ;30 + contador en D
        STD TC4         ;30 + contador en TC4
        RTI



