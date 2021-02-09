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
SEGMENT:         ds      16
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
       ; BSET PIEH,$0F
       ; BSET PPSH,$0F   ;interrupcion en flanco creciente
        
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
        ;JSR Tarea_Teclado       ;ir a subrutina Tarea_Teclado
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
        Staa TEMP
        CBA ; ModSel = ModActual
        Beq Revisar_ModSel
        BSET Banderas,$10    ; Banderas.4 (Camb_Mod) en 1
        BRCLR TEMP,$08,quitar_modo_actual
        BSET Banderas,$08
Revisar_ModSel:
        BRSET TEMP,$08,Rama_CONFIG
        BRCLR Banderas,$10,Ir_a_Modo_RUN
        BCLR Banderas,$10
        MOVB #$08,PORTB ;led 3
        ;Ldaa Clear_LCD
        ;Jsr SendCommand
        ;MOVB D2mS,Cont_Delay
        ;Jsr Delay
        ;JSR LCD_INIT
        Ldx #Msg2_L1
        Ldy #Msg2_L2
        Jsr Cargar_LCD
Ir_a_Modo_RUN:
        MOVB #$04,PORTB   ;led 2
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
        MOVB #$80,PORTB ;led 7
        ;Ldaa Clear_LCD
        ;Jsr SendCommand
        ;MOVB D2mS,Cont_Delay
        ;Jsr Delay
        ;JSR LCD_INIT
        Ldx #Msg1_L1
        Ldy #Msg1_L2
        Jsr Cargar_LCD
Ir_a_Modo_CONFIG:
         MOVB #$40,PORTB ;led 6
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
      MOVB #2,LEDS
      INC CantPQ
      RTS
      
MODO_RUN:
      MOVB #1,LEDS
      RTS
      


Cargar_LCD:             ;                 Subrutina Cargar_LCD
                        ;*******************************************************
                        ;Envia datos a al pantalla LCD
                        ;recibe direcciones de datos en X linea 1 y en Y linea 2
                        ;llama a SendCommand y SendData
                        ;*******************************************************
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
                        ;Subrutina que descuenta valroes cada 1 ms
                        ;*******************************************************
        BSET CRGFLG,$80         ;borrar bandera de interrupcion
        BRCLR Cont_Reb,$FF,seguir_RTI  ;salta si la pos Cont_reb es 0
        DEC Cont_Reb    ;decrementar Cont_Reb
seguir_RTI:
        BRCLR TIMER_CUENTA,$FF,retorno_RTI  ;salta si la pos TIMER_CUENTA es 0
        DEC TIMER_CUENTA    ;decrementar TIMER_CUENTA
retorno_RTI:
        RTI
        
PTH_ISR:                ;                Subrutina PTH_ISR
                        ;*******************************************************
                        ;Subrutina que lee botones conectados al puerto H
                        ;*******************************************************

retorno_PTH:
        BSET PIFH,$0F
        RTI
        
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
        Ldx #Num_Array   ; Cargar dirección de Num_Array en el índice Y
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
        Movb Tecla_IN,b,x ; No sabemos si está bien
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