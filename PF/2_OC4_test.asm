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
NumVueltas:          ds      1
ValorVueltas:   ds      1
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
SEGMENT:         db      $3F,$06,$5b,$4f,$66,$6D,$7D,$07,$7F,$6F,$40,0,0,0,0,0
iniDsp:          db      $28,$28,$06,$0F
D5mS:            db      250
                org $1060

MSGConfig_L1:                 fcc     "  MODO CONFIG"
                db EOM
MSGConfig_L2:                 fcc     "  NUM VUELTAS"
                db EOM
MSGINICIAL_L1:                fcc     "  RunMeter 623"
                db EOM
MSGINICIAL_L2:                fcc     "  ESPERANDO..."
                db EOM
MSGCOMPETENCIA_L1:            fcc     " M. COMPETENCIA"
                db EOM
MSGCOMPETENCIA_L2:            fcc     " VUELTA   VELOC"
                db EOM
MSGCALCULANDO_L1:             fcc     "  RunMeter 623"
                db EOM
MSGCALCULANDO_L2:             fcc     "  CALCULANDO..."
                db EOM
MSGALERTA_L1:                 fcc     "**  VELOCIDAD **"
                db EOM
MSGALERTA_L2:                 fcc     "*FUERA DE RANGO*"
                db EOM
MSGRESUMEN_L1:                fcc     "  MODO RESUMEN"
                db EOM
MSGRESUMEN_L2:                fcc     "VUELTAS    VELOC"
                db EOM
MSGLIBRE_L1:                  fcc     "  RunMeter 623"
                db EOM
MSGLIBRE_L2:                  fcc     "   MODO LIBRE"
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
        MOVB #1,CantPQ
        MOVB #0,LEDS
        MOVB #50,BRILLO
        MOVB #1,CONT_DIG        ;para que funcione bien OC4
        MOVB #0,DT
        MOVB #0,BIN1
        MOVB #0,BIN2
        MOVB #0,NumVueltas
        MOVB #0,ValorVueltas
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
        BCLR PPSH,$0F   ;interrupcion en flanco decreciente

        ;OC4
        MOVB #$80,TSCR1        ;Poner 1 en TEN Timer enable bit y de Timer Status Control Reg 1, sin ffca
        MOVB #$03,TSCR2
        ;BSET TSCR2,$83        ;Poner 1 en TOO Timer Overflow Interrupt (habilita)
                              ;y 2 en Prescalador = 8 de Timer Status Control Reg 2
        ;Configurar interrupcion Output Compare en canal 4
        MOVB #$10,TIOS         ;Vamos a usar canal 4
        MOVB #$10,TIE          ;habilitamos interrupcion de canal 4
        LDD #60      ;60 en D, para que cuente 20 mS
        ADDD TCNT       ;60 + contador en D
        STD TC4         ;60 + contador en TC4
        
        
        ;BSET TSCR1,$90  ;encendemos Timer, TFFCLA
       ; BSET TSCR2,$04  ;poner prescalador en 16
       ; BSET TIOS,$10
       ; BSET TIE,$10  ;habilitar interrupcion por canal 4
       ; LDD #30
       ; ADDD TCNT
       ; STD TC4




        LDS #$3BFF
        CLI

        JSR LCD_INIT



;*******************************************************************************
;                             PROGRAMA PRINCIPAL
;*******************************************************************************
            movB #0,bin2
            LDX #MSGConfig_L1
            LDY #MSGConfig_L2
            JSR CARGAR_LCD
;            Movb #$00,DISP1
;            Movb #$5B,DISP2
;            Movb #$4F,DISP3
;            Movb #$66,DISP4
config_loop:
            JSR MODO_CONFIGURACION
            TST NumVueltas
            BEQ config_loop
loop_main:
            ;Movb #$00,DISP1
            ;Movb #$5B,DISP2
            ;Movb #$4F,DISP3
            ;Movb #$66,DISP4
            LDAA PTIH
            anda #$C0
            LDAB BANDERAS
            ANDB #$C0
            CBA
            BEQ sin_cambios
            BCLR BANDERAS,$C0
            Oraa BANDERAS
            STAA BANDERAS
            BSET BANDERAS,$10
            BRA comp
sin_cambios:
            BCLR BANDERAS,$10
comp:
            BRSET BANDERAS,$C0,ir_a_comp
            BRSET BANDERAS,$80,ir_a_resumen
;            CLR Veloc           ;no es cmop ni resumen
;            BCLR TEMP1,$80         ;borramos bandera para que active PTH
;            CLR Vueltas
;            MOVB #0,VelProm ;???porque sino indefine division Necesario para PROMEDIO '' cambio 1 a 0???
            ;BRCLR BANDERAS,$40,conf
            ;MOVB #$03,TSCR2
            ;BCLR $0F,PIEH
            ;BCLR $0F,PIFH

conf:
            BRSET BANDERAS,$40,ir_a_config
            BRCLR BANDERAS,$10,seguir_libre ;salir si no cambio el modo
	        BSET CRGINT,$80 ; Habilitar RTI
;        Movb NumVueltas,BIN1
            BCLR BANDERAS,$10
            LDX #MSGLIBRE_L1
            LDY #MSGLIBRE_L2
            MOVB #$01,LEDS
            JSR CARGAR_LCD
seguir_libre:
            JSR MODO_LIBRE
            LBRA loop_main

ir_a_resumen:
            BRCLR BANDERAS,$10,seguir_resumen
            BCLR BANDERAS,$10
            ;BCLR $0F,PIEH   ;apago interrupciones PTH
            ;BCLR $0F,PIFH
            MOVB #$08,LEDS
            LDX #MSGRESUMEN_L1
            LDY #MSGRESUMEN_L2
            JSR CARGAR_LCD
seguir_resumen:
            JSR MODO_RESUMEN
            LBRA loop_main
ir_a_comp:
        ;activate TOI
            ;MOVB #$83,TSCR2
            BRCLR BANDERAS,$10,seguir_comp    ;ssalta si no ha cambiado el modo
            BCLR BANDERAS,$10
            MOVB #$04,LEDS
            LDX #MSGINICIAL_L1
            LDY #MSGINICIAL_L2
            JSR CARGAR_LCD
seguir_comp:
            JSR MODO_COMPETENCIA
            LBRA loop_main

ir_a_config:
            BRCLR BANDERAS,$10,seguir_config    ;ssalta si no ha cambiado el modo
            BCLR BANDERAS,$10
            MOVB #$02,LEDS
            MOVB NumVueltas,BIN1    ;mostramos numero de vueltas actuales
            MOVB #$BB,BIN2  ;apagamos segmentos izquierdos
	    BSET CRGINT,$80 ; Habilitar RTI
            ;MOVW 0,TICK_DIS
            ;MOVW 0,TICK_EN
            ;MOVB #0,ValorVueltas    ;vueltas ingresadas son 0
            LDX #MSGConfig_L1
            LDY #MSGConfig_L2
            JSR CARGAR_LCD
seguir_config:
            JSR MODO_CONFIGURACION
            LBRA loop_main



; main viejo
        MOVB #0,LEDS
        MOVB #74,BIN1
        MOVB #74,BIN2
;        MOVB #$3F,DISP1
;        MOVB #$3F,DISP2
;        MOVB #$06,DISP3
;        MOVB #$5B,DISP4

        LDAA #255
main:        MOVB D5mS,Cont_Delay
          JSR Delay
        DBNE A,main

        MOVB #$1,LEDS
        MOVB #77,BIN1
        MOVB #77,BIN2
;        MOVB #$06,DISP1
;        MOVB #$5B,DISP2
;        MOVB #$4F,DISP3
;        MOVB #$66,DISP4

        LDAA #255
main_1:        MOVB D5mS,Cont_Delay
        JSR Delay
        DBNE A,main_1

        MOVB #$2,LEDS
        MOVB #66,BIN1
        MOVB #66,BIN2
;;        MOVB #$5B,DISP1
;;        MOVB #$66,DISP2
;        MOVB #$6D,DISP3
;        MOVB #$7D,DISP4

        LDAA #255
main_2:        MOVB D5mS,Cont_Delay
        JSR Delay
        DBNE A,main_2

        MOVB #$4,LEDS
        MOVB #82,BIN1
        MOVB #82,BIN2
;        MOVB #$4F,DISP1
;        MOVB #$7D,DISP2
;        MOVB #$07,DISP3
;        MOVB #$7F,DISP4

        LDAA #255
main_3:        MOVB D5mS,Cont_Delay
        JSR Delay
        DBNE A,main_3

        MOVB #$8,LEDS
        MOVB #83,BIN1
        MOVB #83,BIN2
 ;       MOVB #$66,DISP1
 ;       MOVB #$6F,DISP2
 ;       MOVB #$3F,DISP3
 ;       MOVB #$06,DISP4

        LDAA #255
main_4:        MOVB D5mS,Cont_Delay
        JSR Delay
        DBNE A,main_4

        MOVB #$10,LEDS
        MOVB #84,BIN1
        MOVB #84,BIN2
    ;    MOVB #$6D,DISP1
  ;      MOVB #$3F,DISP2
   ;     MOVB #$6D,DISP3
   ;     MOVB #$6D,DISP4

        LDAA #255
main_5:        MOVB D5mS,Cont_Delay
        JSR Delay
        DBNE A,main_5

        MOVB #$20,LEDS
        MOVB #85,BIN1
        MOVB #85,BIN2
     ;   MOVB #$7D,DISP1
      ;  MOVB #$7D,DISP2
       ; MOVB #$3F,DISP3
       ; MOVB #$7D,DISP4

        LDAA #255
main_6:        MOVB D5mS,Cont_Delay
        JSR Delay
        DBNE A,main_6

        MOVB #$40,LEDS
        MOVB #86,BIN1
        MOVB #86,BIN2
;        MOVB #$7F,DISP1
;        MOVB #$7F,DISP2
;        MOVB #$7F,DISP3
;        MOVB #$3F,DISP4

        LDAA #255
main_7:        MOVB D5mS,Cont_Delay
        JSR Delay
        DBNE A,main_7

        MOVB #$80,LEDS
        MOVB #87,BIN1
        MOVB #87,BIN2
;        MOVB #$6F,DISP1
;        MOVB #$3F,DISP2
;        MOVB #$6F,DISP3
;        MOVB #$6F,DISP4

        LDAA #255
main_8:        MOVB D5mS,Cont_Delay
        JSR Delay
        DBNE A,main_8

        MOVB #0,LEDS
        MOVB #88,BIN1
        MOVB #88,BIN2
;        MOVB #$40,DISP1
;        MOVB #$40,DISP2
;        MOVB #$3F,DISP3
;        MOVB #$40,DISP4

        LDAA #255
main_9:        MOVB D5mS,Cont_Delay
        JSR Delay
        DBNE A,main_9

        BRA *






;*******************************************************************************
;                                     SUBRUTINAS
;*******************************************************************************

LCD_INIT:
        ;configuracion inical de la LCD
        CLRB
        LDX #iniDsp
loopIniDsp:
        LDAA B,X
        JSR SendCommand
        MOVB D40uS,Cont_Delay
        JSR Delay
        INCB
        CMPB #4
        BNE loopIniDsp
        LDAA Clear_LCD
        JSR SendCommand
        MOVB D2mS,Cont_Delay
        JSR Delay
        RTS

                        ;*******************************************************
MODO_CONFIGURACION:     ;            Subrutina MODO_CONFIGURACION
                        ;*******************************************************
                        ;Subrutina que lee valor de vueltas y desplega en panta-
                        ;lla siempre y cuando este en el rango [3 , 23]
                        ;Variables de entrada:
                        ;ValorVueltas : numero de vueltas ingresadas
                        ;Variables de salida:
                        ;NumVueltas: vueltas validas ingresdas
                        ;BIN1 y BIN2: valores a poner en pantalla 7 segmentos
                        ;BIN1 displays 1 y 2
                        ;BIN2 displays 3 y 4
                        ;*******************************************************
        Brclr Banderas,$04,llamar_Tarea_Teclado   ; Se moidifica Array_Ok con m?scara $04
        Bclr Banderas,$04   ;no hay forma de validar si se ingresaron 2 numeros en TT
        Jsr BCD_BIN
        Ldaa ValorVueltas
        Cmpa #3
        Blo no_valido
        Cmpa #23
        Bhi no_valido      ;si es mayor a 85 es invalida
        Movb ValorVueltas,NumVueltas
        Movb NumVueltas,BIN1
;        CLR Cont_TCL
        MOVB #$FF,Num_Array
        MOVB #$FF,Num_Array+1
        Rts

no_valido:
        Clr NumVueltas
        RTS

llamar_Tarea_Teclado:
        Jsr Tarea_Teclado
        Rts


                        ;*******************************************************
MODO_COMPETENCIA:       ;                Subrutina MODO_COMPETENCIA
                        ;*******************************************************
                        ;Subrutina que envia msg inical a LCD
                        ;y se queda esperando a detectar ciclista en S1
                        ;Variables de entrada:
                        ;TEMP1
                        ;Variables de salida: Vueltas
                        ;VelProm
                        ;Veloc
                        ;TEMP1
                        ;*******************************************************
        MOVB #25,BIN1
        MOVB #16,BIN2
	rts
                        ;*******************************************************
MODO_RESUMEN:           ;                 Subrutina MODO_RESUMEN
                        ;*******************************************************
                        ;Subrutina que desplega en pantallas vueltas y velocidad
                        ;Variables de entrada: TEMP2.5
                        ;Variables de salida: LEDS, BIN1, BIN2, TEMP2.5
                        ;*******************************************************
        MOVB #36,BIN1
        MOVB #27,BIN2
	rts

                        ;*******************************************************
MODO_LIBRE:             ;                  Subrutina MODO_LIBRE
                        ;*******************************************************
                        ;Subrutina que espera al cambio de otro modo
                        ;Variables de entrada: TEMP1.6 bandera de cambio de modo
                        ;Variables de salida: TEMP1.6
                        ;*******************************************************
        MOVB #58 BIN1
        MOVB #49,BIN2
	rts


                        ;*******************************************************
PANT_CTRL:              ;                  Subrutina PANT_CTRL
                        ;*******************************************************
                        ;Subrutina que modifica el valor de las pantallas
                        ;segun el modo seleccionado y la activacionde de los
                        ;sensores y la velocidad determinada
                        ;velocidad fuera de rango: alerta
                        ;velocidad en rango: muestra valor y vueltas
                        ;ecuaciones:
                        ;   TICKS_EN = 32959/VelProm
                        ;   TICKS_DIS = 49438/VelProm
                        ;Variables de entrada:
                        ;Veloc: velocidad de ciclistas
                        ;Vueltas: vueltas completas
                        ;Variables de salida:
                        ;BIN1 y BIN2: mensajes para pantalla
                        ;*******************************************************

        rts
        



Cargar_LCD:             ;                 Subrutina Cargar_LCD
                        ;*******************************************************
                        ;Envia datos a al pantalla LCD
                        ;recibe direcciones de datos en X linea 1 y en Y linea 2
                        ;llama a SendCommand y SendData
                        ;*******************************************************
        LDAA Clear_LCD  ;para borrar info anterior en pantalla LCD
        JSR SendCommand
        MOVB D2mS,Cont_Delay
        JSR Delay

        LDAA ADD_L1
        JSR SendCommand
        MOVB D40uS,Cont_Delay
        JSR Delay
loop_L1:
        LDAA 1,X+
        CMPA #EOM          ; NUMERAL NUMERAL NUMERAL -> Hay que poner numeral si uso un valor definido con EQU
        BEQ inicio_L2
        JSR SendData
        MOVB D40uS,Cont_Delay
        JSR Delay
        BRA loop_L1

inicio_L2:
        LDAA ADD_L2
        JSR SendCommand
        MOVB D40uS,Cont_Delay
        JSR Delay
loop_L2:
        LDAA 1,Y+
        CMPA #EOM          ; NUMERAL NUMERAL NUMERAL -> Hay que poner numeral si uso un valor definido con EQU
        BEQ retorno_cargar_LCD
        JSR SendData
        MOVB D40uS,Cont_Delay
        JSR Delay
        BRA loop_L2

retorno_cargar_LCD:
        RTS

SendCommand:            ;                 Subrutina SendCommand
                        ;*******************************************************
                        ;Envia comandos a la memoria de la pantalla LCD
                        ;recibe el comando en A
                        ;*******************************************************
        PSHA
        ANDA #$F0
        LSRA
        LSRA
        STAA PORTK
        BCLR PORTK,$01
        BSET PORTK,$02
        MOVB D260uS,Cont_Delay
        JSR Delay
        BCLR PORTK,$02
        PULA
        ANDA #$0F
        LSLA
        LSLA
        STAA PORTK
        BCLR PORTK,$01
        BSET PORTK,$02
        MOVB D260uS,Cont_Delay
        JSR Delay
        BCLR PORTK,$02
        RTS

                        ;*******************************************************
SendData:               ;                 Subrutina SendData
                        ;*******************************************************
                        ;Envia datos a la memoria de la pantalla LCD, recibe
                        ;comando en A
                        ;*******************************************************
        PSHA
        ANDA #$F0
        LSRA
        LSRA
        STAA PORTK
        BSET PORTK,$01       ;dato
        BSET PORTK,$02
        MOVB D260uS,Cont_Delay
        JSR Delay
        BCLR PORTK,$02
        PULA
        ANDA #$0F
        LSLA
        LSLA
        STAA PORTK
        BSET PORTK,$01  ;dato
        BSET PORTK,$02
        MOVB D260uS,Cont_Delay
        JSR Delay
        BCLR PORTK,$02
        RTS

                        ;*******************************************************
Delay:                  ;                 Subrutina Delay
                        ;*******************************************************
                        ;Genera retardo para enviar informaci?n a la pantalla
                        ;LCD, se queda en un loop hasta que la variable ha sido
                        ;DECrementada a 0 por OC4
                        ;*******************************************************
        TST Cont_Delay
        BNE Delay
        RTS


                         ;******************************************************
BCD_BIN:                 ;          Subrutina BCD_BIN
                         ;******************************************************
                         ;  Se encarga de convertir un numero de BCD a Binario
                         ;******************************************************
        BRSET Num_Array+1,$FF,arreglo_invalido
        Ldx #Num_Array
        Ldab #$A
        Ldaa 1,X+
        Mul
        Ldaa 0,X
        Aba
        Staa CantPQ
        Rts
arreglo_invalido:
        MOVB #0,CantPQ
        RTS

BIN_BCD:                 ;          Subrutina BIN_BCD
                         ;**********************************************************
                         ;Subrutina que pasa un n?mero de binario (BIN) a BCD (BCD_l)
                         ;**********************************************************
         ;Ldaa BIN1   ;  Tengo que meter el n?mero binario en el acumulador A antes
         Ldab #7
         Movb #0,BCD_L
Loop1:   Lsla
         Rol BCD_L
         Staa TEMP
         Ldaa #$0F
         Anda BCD_L
         Cmpa #5
         Blo no_mayor_a_5
         Adda #3
no_mayor_a_5:
         Staa LOW
         Ldaa #$F0
         Anda BCD_L
         Cmpa #$50
         Blo no_mayor_a_50
         Adda #$30
no_mayor_a_50:
         Adda LOW
         Staa BCD_L
         Ldaa TEMP
;         Decb
;         Tstb
         DBne B,Loop1
         Lsla  ; No quitar, entender later xD
         Rol BCD_L
         Rts

BCD_7SEG:                ;          Subrutina BCD_7SEG
                         ;**********************************************************
                         ;  Carga los valores correspondientes a ser desplegados
                         ; en la pantalla de 7 segmentos
                         ;**********************************************************
         Ldx #SEGMENT
         Ldaa #$0F
         Anda BCD2
         Movb A,X,DISP2
         Ldaa #$F0
         Anda BCD2
         Lsra
         Lsra
         Lsra
         Lsra
         Movb A,X,DISP1
         Ldaa #$0F
         Anda BCD1
         Movb A,X,DISP4
         Ldaa #$F0
         Anda BCD1
         Lsra
         Lsra
         Lsra
         Lsra
         Movb A,X,DISP3
         Rts


CONV_BIN_BCD:            ;          Subrutina CONV_BIN_BCD
                         ;******************************************************
                         ;  Se encarga de poner BIN1 y BIN2 en el acumulador dos
                         ;  para llamar a BIN_BCD y guardar los resultados
                         ; seg?n corresponda, adem?s devuelve $B si un LED
                         ; debe estar apagado
                         ;******************************************************
         Ldaa BIN1
         Jsr BIN_BCD
         Movb BCD_L,BCD1
         Ldaa BIN2
         Jsr BIN_BCD
         Movb BCD_L,BCD2
         Tst BCD1
         Beq es_cero
         Ldaa BCD1
         Cmpa #9
         Bls BCD1_es_menor_a_10
revisar_BCD2:
         Tst BCD2
         Beq BCD2_es_cero
         Ldaa BCD2
         Cmpa #9
         Bls BCD2_es_menor_a_10
         Rts
BCD1_es_menor_a_10:
         Ldaa #$B0
         Eora BCD1
         Staa BCD1
         Bra revisar_BCD2
BCD2_es_menor_a_10:
         Ldaa #$B0
         Eora BCD2
         Staa BCD2
         Rts
es_cero:
         Movb #$BB,BCD1
         Bra revisar_BCD2
BCD2_es_cero:
         Movb #$BB,BCD2
         Rts



;*******************************************************************************
;                        SUBRUTINAS DE INTERRUPCION
;*******************************************************************************

RTI_ISR:                ;                Subrutina RTI_ISR
                        ;*******************************************************
                        ;Subrutina que cuenta 1 ms
                        ;*******************************************************
        BSET CRGFLG,$80         ;borrar bandera de interrupcion
        BRCLR Cont_Reb,$FF,seguir_RTI  ;salta si la pos Cont_reb es 0
        DEC Cont_Reb    ;decrementar Cont_Reb
seguir_RTI:
        BRCLR TIMER_CUENTA,$FF,retorno_RTI  ;salta si la pos Cont_reb es 0
        DEC TIMER_CUENTA
retorno_RTI:
        RTI




PTH_ISR:                ;                Subrutina PTH_ISR
                        ;*******************************************************
                        ;Subrutina que lee botones conectados al puerto H
                        ;*******************************************************

retorno_PTH:
        BRSET Banderas,$08,saltar_pth0  ;revisa Mod_Actual   config si es 1
        BRCLR PIFH,$01,saltar_pth0
        BSET PIFH,$01
        CLR CUENTA
        BCLR PORTE,$04  ;apagar Rel?
        BSET CRGINT,$80  ;encender RTI
        BRA retorno_PTH_ISR

saltar_pth0:
        TST Cont_Reb
        BNE retorno_PTH_ISR
        BRClr Tecla,$80,segundo_ingreso ; Si Tecla.7 = 1 es el primer ingreso
        MOVB PIFH,Tecla
        LDAA #$0F
        ANDA PIFH
        STAA PIFH
        MOVB #5,Cont_Reb
        ;BCLR Tecla,$80  ;indicar que ya entro por primera vez
        BRA retorno_PTH_ISR

segundo_ingreso:
        LDAB PIFH
        CMPB Tecla      ;revisar si valores anteriores de PIFH son iguales ahora
        BEQ lectura_correcta
        MOVB #$FF,Tecla

retorno_PTH_ISR:
        RTI

lectura_correcta:
        BSET Tecla,$80
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

OC4_ISR:
;        BSET TFLG2,$80  ;borrar int estamos usando TFFCA
                        ;                Subrutina OC4_ISR
                        ;*******************************************************
                        ;Subrutina que genera interrupciones cada 50 KHz
                        ;*******************************************************
        BSET TFLG1,$10 ;borra interrupciones
        Tst Cont_Delay
        BEQ aumentar_CONT_TICKS
        Dec Cont_Delay
aumentar_CONT_TICKS:
        Inc CONT_TICKS
        Ldaa #100
        Cmpa CONT_TICKS
        Bne aumentar_CONT_7SEG
        Clr CONT_TICKS
        Lsl CONT_DIG
        Ldaa #$20
        Cmpa CONT_DIG
        BNE aumentar_CONT_7SEG
        MOVB #1,CONT_DIG
aumentar_CONT_7SEG:    ;aumentar cont7_seg
        Ldd CONT_7SEG
        Addd #1
        Std CONT_7SEG
;        Ldd #5000
        Cpd #5000
        BNE Antes_de_revisar_CONT_DIG
        Movw #$0,CONT_7SEG ;Si uso move word se pone 0 cont7seg +1 ?
        Jsr CONV_BIN_BCD
        Jsr BCD_7SEG

Antes_de_revisar_CONT_DIG:
        Ldaa #100
        Suba BRILLO
        Tab
        Ldaa #100
        Sba
        Staa DT
        Cmpa CONT_TICKS ; lo que est? en a es DT (se acaba de guardar)
        Bhs  Portb_cero
        Ldaa #1
        Cmpa CONT_DIG
        Beq CONT_DIG_es_1
        Ldaa #2
        Cmpa CONT_DIG
        Beq CONT_DIG_es_2
        Ldaa #4
        Cmpa CONT_DIG
        Beq CONT_DIG_es_4
        Ldaa #8
        Cmpa CONT_DIG
        Beq CONT_DIG_es_8
        Movb DISP1,PORTB
        LDAA #$0E
        MOVB #$0E,PTP   ;que hay en el nibble superior de P?
;        Bset PTP,$0E     ;PTP.[3:0] <- $E
        Bset PTJ,$2
Antes_de_retornar:
        Ldd TCNT
        Addd #60
        Std TC4
        Rti

CONT_DIG_es_8:
        Movb DISP2,PORTB
        MOVB #$0D,PTP
;        Bset PTP,$0D   ;PTP.[3:0] <- $D
        Bset PTJ,$2
        Bra Antes_de_retornar

CONT_DIG_es_4:
        Movb DISP3,PORTB
        MOVB #$0B,PTP
;        Bset PTP,$0B ;PTP.[3:0] <- $B
        Bset PTJ,$2
        Bra Antes_de_retornar

CONT_DIG_es_2:
        Movb DISP4,PORTB
        MOVB #$07,PTP
;        Bset PTP,$07 ;PTP.[2:0] <- 7
        Bset PTJ,$2
        Bra Antes_de_retornar

CONT_DIG_es_1:
        Movb LEDS,PORTB
        MOVB #$0F,PTP
;        Bset PTP,$F
        BClr PTJ,$2
        Bra Antes_de_retornar

Portb_cero:
        Movb #$0,PORTB
        Bra Antes_de_retornar


;*******************************************************************************
;                           SUBRUTINAS DE TAREA 4
;*******************************************************************************

                        ;*******************************************************
Tarea_Teclado:          ;                      SUBRUTINA
                        ;*******************************************************
                        ;Verifica estado de teclas ingresadas
                           ;y llama a las otras subrutinas
                        ;*******************************************************
;        MOVB #$01,PORTB  ;debugging
;        INC Print+1
        TST Cont_Reb
        BNE Retorno_Tarea_Teclado
        JSR Mux_Teclado
        BRSET Tecla,$FF,revisar_TCL_LISTA

        BRSET Banderas,$02,revisar_teclas
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
Mux_Teclado:            ;                      SUBRUTINA
                        ;*******************************************************
                        ;Lee teclado matricial
                        ;*******************************************************
;        MOVB #$02,PORTB  ;debugging
;        INC Print+2
        LDX #Teclas
        CLRA
        MOVB #$EF,Patron
loop_mux:
        MOVB Patron,PORTA
        BRCLR PORTA,$02,tecla_presionada
        INCA
        NOP
        NOP
        NOP
        NOP
        NOP
        BRCLR PORTA,$04,tecla_presionada
        INCA
        NOP
        NOP
        NOP
        NOP
        NOP
        BRCLR PORTA,$08,tecla_presionada
        INCA
        NOP
        NOP
        NOP
        NOP
        NOP
        LSL Patron
        BRCLR Patron,$F0,nada_presionado
        BRA loop_mux

nada_presionado:
;        Inc Print+6
        MOVB #$FF,Tecla
        RTS

tecla_presionada:
        MOVB A,X,Tecla
;        Inc Print+7
        RTS

                        ;*******************************************************
Formar_Array:           ;                      SUBRUTINA
                        ;*******************************************************
                        ;Llena arreglo Num_Array con teclas leidas
                        ;*******************************************************
;        MOVB #$04,PORTB  ;debugging
;        INC Print+3
        Ldx #Num_Array   ; Cargar direcci?n de Num_Array en el ?ndice Y
        Ldaa #$0B
        Ldab Cont_TCL
        ;Incb
        Cmpb MAX_TCL
        Beq full_array
        Ldab #$0E
        TST Cont_TCL
        Beq primer_input
        Cmpa Tecla_IN
        Beq reducir_contador
        Cmpb Tecla_IN
        Beq poner_array_ok
        Ldab Cont_TCL
        Movb Tecla_IN,b,x ; No sabemos si est? bien
        Inc Cont_TCL
        Bra Nodo_Final

poner_array_ok:
        Bset Banderas,$04 ;Poner en 1 el bit 3 (Array_Ok)
        Clr Cont_TCL
        Bra Nodo_Final

reducir_contador:
        Dec Cont_TCL
        Ldab Cont_TCL
        Movb #$FF,b,x
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
        Ldab #$0E
        Cmpa Tecla_IN
        beq reducir_contador
        Cmpb Tecla_IN
        Beq poner_array_ok
        Bra Nodo_Final

Nodo_Final:
        Movb #$FF,Tecla_IN
        RTS