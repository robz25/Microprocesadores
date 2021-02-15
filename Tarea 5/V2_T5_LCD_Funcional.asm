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
SEGMENT:         db      $3F,$06,$5b,$4f,$66,$6D,$7D,$07,$7F,$6F,0,0,0,0,0,0
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
        MOVB #0,CUENTA
        MOVB #0,AcmPQ
        MOVB #0,CantPQ
        MOVB #0,LEDS
        MOVB #50,BRILLO
        MOVB #1,CONT_DIG        ;para que funcione bien OC4
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
        MOVB #0,CONT_7SEG + 1     ; estaba en 50
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
        BSET TSCR1,$90  ;encendemos Timer, TFFCLA
        BSET TSCR2,$04  ;poner prescalador en 16
        BSET TIOS,$10
        BSET TIE,$10  ;habilitar interrupcion por canal 4
        LDD #30
        ADDD TCNT
        STD TC4

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
        ;BRSET Banderas,$04,main ;salta a main si el bits 2 (%0000 0100) es 1 en Banderas
        BSET Banderas,$10 ; Bandera 4 (CambMod en 1)
Loop_main:
        TST CantPQ
        Beq Antes_Rama_CONFIG
        Ldaa #$80
        Anda PTH
        Ldab #08
        Andb Banderas
        LSRA    ;corre a derecha un bit sin meter carry
        LSRA
        LSRA
        LSRA
        CBA ; ModSel = ModActual
        Beq Revisar_ModSel
        BSET Banderas,$10    ; Banderas.4 (Camb_Mod) en 1
        TSTA
        BEQ quitar_modo_actual  ;si ModSEL esta en 0
        BSET Banderas,$08
Revisar_ModSel:
        TSTA
        BNE Rama_CONFIG ;si ModSEL no es 0 esta en 1, entonces ir a inicio Config
        BRCLR Banderas,$10,Ir_a_Modo_RUN
        BCLR Banderas,$10
        MOVB #1,LEDS
        MOVB #$0F,PIEH
        Ldx #Msg2_L1
        Ldy #Msg2_L2
        Jsr Cargar_LCD
Ir_a_Modo_RUN:
        Jsr MODO_RUN
        Bra Loop_main
quitar_modo_actual:
        BCLR Banderas,$08
        Bra Revisar_ModSel
Antes_Rama_CONFIG:
        BSET Banderas,$08
Rama_CONFIG:
        BRCLR Banderas,$10,Ir_a_Modo_CONFIG
        BCLR Banderas,$10
        CLR BIN2 ;borrar DISP1 y DISP2
        CLR CUENTA ;borrar cuenta para cuando empiece Run otra vez
        CLR AcmPQ ;borrar para cuando empiece Run de nuevo
        BCLR PORTE,$04 ;apagar relé
        MOVB #2,LEDS ;poner leds de CONFIG
        MOVB #$0C,PIEH
        Ldx #Msg1_L1
        Ldy #Msg1_L2
        Jsr Cargar_LCD
Ir_a_Modo_CONFIG:
        ;MOVB #$40,PORTB ;led 6
        Jsr MODO_CONFIG
        LBra Loop_main
        ; Cambiar CamMod se usa $10
        ; Cambiar ModActual se usa $08

       ;BRA *

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

MODO_CONFIG:
        BRCLR Banderas,$04,llamar_Tarea_Teclado   ; Se moidifica Array_Ok con m?scara $04
        BCLR Banderas,$04   ;no hay forma de validar si se ingresaron 2 numeros en TT
        Jsr BCD_BIN
        Ldaa CantPQ
        Cmpa #25
        Blo no_valido
        Cmpa #85
        Bhi no_valido      ;si es mayor a 85 es invalida
        Movb CantPQ,BIN1
;        CLR Cont_TCL
        MOVB #$FF,Num_Array
        MOVB #$FF,Num_Array+1
        Rts
        
no_valido:
        Clr CantPQ
        RTS

llamar_Tarea_Teclado:
        Jsr Tarea_Teclado
        Rts


MODO_RUN:               ;                 Subrutina MODO_RUN
                        ;*******************************************************
                        ; Subrutina que lleva la cuenta de tornillos
                        ;*******************************************************
        TST TIMER_CUENTA
        BNE retorno_MODO_RUN
        MOVB #VMAX,TIMER_CUENTA
        INC CUENTA
        LDAA CUENTA
        CMPA CantPQ
        BNE retorno_MODO_RUN
        BCLR CRGINT,$80 ;apagar RTI
        INC AcmPQ
        BSET PORTE,$04
        LDAA #100
        CMPA AcmPQ
        BNE retorno_MODO_RUN
        CLR AcmPQ

retorno_MODO_RUN:
        MOVB CUENTA,BIN1
        MOVB AcmPQ,BIN2
        RTS




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
         Decb
         Tstb
         Bne Loop1
         Lsla
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
        BRSET Banderas,$08,retorno_RTI  ;estamos en config y por lo tanto no hay que descontar TIMER_CUENTA
        BRCLR TIMER_CUENTA,$FF,retorno_RTI  ;salta si la pos Cont_reb es 0
        DEC TIMER_CUENTA
retorno_RTI:
        RTI

PTH_ISR:                ;                Subrutina PTH_ISR
                        ;*******************************************************
                        ;Subrutina que lee botones conectados al puerto H
                        ;*******************************************************
        brset PIFH,$01,reiniciar_CUENTA
        brset PIFH,$02,reiniciar_AcmPQ
        brset PIFH,$04,disminuir_brillo
        brset PIFH,$08,aumentar_brillo
retorno_PTH_ISR:
        Rti
reiniciar_CUENTA:
        bset PIFH,$01 ; Borramos la bandera de solicitud de interrupcion
        clr CUENTA
        bclr PORTE,$04 ; Desactivamos el rele
        bset CRGINT,$80 ; Activamos la INterrupcion RTI
        bra retorno_PTH_ISR
reiniciar_AcmPQ:
        bset PIFH,$02 ; Borramos la bandera de solicitud de interrupcion
        clr AcmPQ
        bra retorno_PTH_ISR
aumentar_brillo:
        bset PIFH,$08
        ldaa BRILLO
        cmpa #5
        beq retorno_PTH_ISR
        suba #5 ;
        staa BRILLO
        bra retorno_PTH_ISR
disminuir_brillo:
        bset PIFH,$04
        ldaa BRILLO
        cmpa #95
        beq retorno_PTH_ISR
        adda #5 ;
        staa BRILLO
        bra retorno_PTH_ISR


OC4_ISR:
;        BSET TFLG2,$80  ;borrar int estamos usando TFFCA
                        ;                Subrutina OC4_ISR
                        ;*******************************************************
                        ;Subrutina que genera interrupciones cada 50 KHz
                        ;*******************************************************
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
        Cmpa CONT_TICKS ;lo que est? en a es DT (se acaba de guardar)
        Bhs  apagar_LEDS
        BRSET CONT_DIG,$01,CONT_DIG_es_1
        BRSET CONT_DIG,$02,CONT_DIG_es_2
        BRSET CONT_DIG,$04,CONT_DIG_es_4
        BRSET CONT_DIG,$08,CONT_DIG_es_8
        Movb DISP1,PORTB ;CONT_DIG = $16
        LDAA #$0E
        MOVB #$0E,PTP   ;que hay en el nibble superior de P?
        Bset PTJ,$2
        
Antes_de_retornar:
        Ldd TCNT
        Addd #30
        Std TC4
        RTI

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

apagar_LEDS:
        Movb #$0F,PTP
        BSET PTJ,$02
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