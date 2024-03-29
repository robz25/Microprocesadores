#include registers.inc

;*******************************************************************************
;       UNIVERSIDAD DE COSTA RICA       ESCUELA DE INGENIERIA ELECTRICA
;               MICROPROCESADORES IE 623  III CICLO 2020
;*******************************************************************************
;                                  RUN METER623
;*******************************************************************************
;       V8
;       AUTORES:
;                ROBIN GONZALEZ RICZ  B43011
;               MICHELLE GUTIERREZ MU?OZ B43195
;
;       DESCRIPCION:    Proyecto Final
;       Contador de vueltas y velocidad para un velodromo
;       con los swithces 7 y 6 se cambia de modo
;       mensajes se desplegan en las pantallas
;       sw5 y sw2 simulan sensores que detectan al ciclista
;       se ingresa el valor de vueltas en el modo configuracion
;       mediante el teclado matricial
;
;*******************************************************************************


;*******************************************************************************
;                             Estructuras de datos
;*******************************************************************************
EOM:        EQU        $FF      ;End Of Message byte para indicar EOM de fcc

            org         $1000

BANDERAS:      ds 1 ;7=modo1, 6=modo0, 5=Calc_ticks,4=CambMod,3=Pant_FLG,2=Array_OK,1=TCL_LEIDA,0=TCL_LISTA
NumVueltas:    ds 1 ;cantidad de vueltas a contar
ValorVueltas:  ds 1 ;vueltas ingresadas en configuracion
MAX_TCL:       db $02 ; Se define el valor maximo del arreglo de teclas
Tecla:         ds 1 ; Se define la variable de tipo tecla
Tecla_IN:      ds 1 ; Tecla que se ingreso en la iteracion anterior
Cont_Reb:      ds 1 ;contador para rebotes al leer botones
Cont_TCL:      ds 1 ;contador de teclas ingresadas
Patron:        ds 1 ;Patron para revisar el teclado matricial
Num_Array:     ds 2 ;Arreglo de teclas ingresadas
BRILLO:        ds 1 ;Variable para controlar brillo de leds y 7 segmentos
POT:           ds 1 ;variable de lectura del potenciometro
TICK_EN:       ds 2 ;contador word para poner PantFLG
TICK_DIS:      ds 2 ;contador word para borrar PantFLG
Veloc:         ds 1 ;Byte para guardar velocidad actual
Vueltas:       ds 1 ;Variable para guardar cantidad de vueltas dadas
VelProm:       ds 1 ;Guarda promedio de velocidad
TICK_MED:      ds 2 ;Word para contar tiempo entre presion de ph3 y ph0
BIN1:          ds 1 ;numero para poner en derecha de pantalla en binario
BIN2:          ds 1 ;numero para poner en izquierda de pantalla en binario
BCD1:          ds 1 ;numero para poner en derecha de pantalla en bcd
BCD2:          ds 1 ;numero para poner en izquierda de pantalla en bcd
BCD_L:         ds 1 ;Byte utilizado para guardar conversion de binario a bcd
BCD_H:         ds 1 ;diay esto no lo usamos pero igual hay que ponerlo
TEMP:          ds 1 ;varaible temporal para calculo a bcd
LOW:           ds 1 ;usado en bin bcd como variable temporal
DISP1:         ds 1 ;valor en 7 seg a poner en disp1
DISP2:         ds 1 ;valor en 7 seg a poner en disp2
DISP3:         ds 1 ;valor en 7 seg a poner en disp3
DISP4:         ds 1 ;valor en 7 seg a poner en disp4
LEDS:          ds 1 ;valor a poner en las 8 leds
CONT_DIG:      ds 1 ;contador de digitos/leds que enciende oc4
CONT_TICKS:    ds 1 ;contador de 100 mS en OC4
DT:            ds 1 ;variable innecesaria para brillo
CONT_7SEG:     ds 2 ;contador de 5000 para cambiar valores en pantalla
CONT_200:      db 200 ;cantidad de entradas en RTI para activad ADT0
Cont_Delay:    ds 1 ;contador delays en oc4
D2mS:          dB 100 ;cantidad de entradas en oc4 para esperar 2 ms
D260uS:        dB 13 ;cantidad de entradas en oc4 para esperar 260 us
D40uS:         dB 2 ;cantidad de entradas en oc4 para esperar 40 us
Clear_LCD:     dB $01 ;comando para borrar pantalla LCD
ADD_L1:        dB $80 ;comando para direccionar LCD a linea 1 en memoria
ADD_L2:        dB $C0 ;comando para direccionar LCD a linea 1 en memoria
;adicionales
YULS:          ds  1 ;7: apagarBIN2, 5=velocidadValida, 4=Direccion, 3:PantFLG, 2:habraCalculo
CURIE:         ds  1 ;variable word para guardar primer parte de calculo de prom
CURIE2:        ds  1
HZD:           ds  1 ;usado para contador de  200 para ATD
                        org $1040
Teclas:        dB $01,$02,$03,$04,$05,$06,$07,$08,$09,$0B,$00,$0E ; Tabla con los valores de Tecla
                        org $1050
SEGMENT:       dB $3F,$06,$5B,$4F,$66,$6D,$7D,$07,$7F,$6F,$40,$00 ; Valores en 7 seg para cada numero, ordenado por indice, pos 10 = - , pos 11 = apagado
                        org $1060
initDisp:      dB $28,$28,$06,$0C ; Comandos para inicializacion de la LCD

            org     $1070

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


;_______________________________________________________________________________
;
;*******************************************************************************
;                           Rutina de inicialización
;*******************************************************************************
;_______________________________________________________________________________


;*******************************************************************************
;                     Declaracion de vectores de interrupcion
;*******************************************************************************

        org            $3E5E  ;DEBUG12
                dw TCNT_ISR

        org            $3E70
                dw RTI_ISR

        org            $3E4C
                dw CALCULAR

        org            $3E66
                dw OC4_ISR

        org            $3E52
                dw ATD_ISR

;*******************************************************************************
;                        Inicializacion de variables
;*******************************************************************************
                org     $2000

        MOVB #$FF,Tecla
        MOVB #$FF,Tecla_IN
        MOVB #$00,NumVueltas
        MOVB #$00,Vueltas
        MOVB #$00,ValorVueltas
        MOVB #$FF,Num_Array
        MOVB #$FF,Num_Array+1
        MOVB #$00,Banderas      ;iniciar en 0
        MOVB #$00,Patron
        MOVB #$00,Cont_TCL
        MOVB #$00,Cont_Reb
        MOVB #$00,LEDS
        MOVB #$00,BIN1
        MOVB #$BB,BIN2  ;para que apague digitos de la izquierda se apaguen
        MOVB #$00,BRILLO
        MOVB #1,CONT_DIG        ;para que empiece con el primer digito
        MOVB #$00,CONT_TICKS
        MOVW #0,TICK_EN
        MOVW #0,TICK_DIS
        MOVW #0,TICK_MED
        MOVB #$00,BCD1
        MOVB #$00,BCD2
        MOVB #$00,DISP1
        MOVB #$00,DISP2
        MOVB #$00,DISP3
        MOVB #$00,DISP4
        MOVB #$00, Vueltas
        MOVB #$00, NumVueltas
        MOVB #$00, Veloc
        MOVB #$00, VelProm
        MOVB #$00, YULS        ;2do reg de banderas
        MOVB #$00, CURIE       ;primera fraccion de calculo de promedio (word)
        MOVB #$00, CURIE2
        MOVB #$00, HZD  ;contador de 200 para llamada de ATD0 en RTI
        movw #$0000,CONT_7SEG
        MOVB #$00,Cont_Delay ;
;        MOVB #200,CONT_200  ;Para contador de RTI que activa ATD para leer pot

;*******************************************************************************
;                          Configuracion de hardware
;*******************************************************************************
        ;Configurar interrupcion key wakeups en  PTH
        MOVB #$09,PIEH ;habilitamos la interrup en el puerto H para los bits 0 y 3
        BCLR PPSH,$09 ;interrupcion se habilita por flanco creciente
        BCLR DDRH,$C0 ;PTH es entrada automaticamente, para recordar bits 6 y 7

        ;Configurar interrupcion Timer Overflow Interrupt
        MOVB #$80,TSCR1        ;Poner 1 en TEN Timer enable bit y de Timer Status Control Reg 1, sin ffca
        BSET TSCR2,$83        ;Poner 1 en TOI Timer Overflow Interrupt (habilita)
                              ;y 2 en Prescalador = 8 de Timer Status Control Reg 2

        ;Configurar interrupcion OC4 Output Compare en canal 4
        BSET TIOS,$10   ;habilitar el canal 4 como salida
        BSET TIE,$10  ;habilitar interrupcion por canal 4
        LDD #60      ;60 en D, para que cuente 20 mS
        ADDD TCNT       ;60 + contador en D
        STD TC4         ;60 + contador en TC4

        ;Leds
        MOVB #$FF,DDRB       ;puerto B como salida para poner digitos y valores de leds
        BSET DDRJ,$02        ;bit 1 de puerto J como salida, habilita leds
        BSET PTJ,$02         ;1 en el bit 1 del puerto J para apagar los leds
        ;Pantalla 7 segmentos
        BSET DDRP,$0F       ;nibble inf de P como salida para habilitar digitos de 7 seg

        ;Comunicacion LCD
        MOVB #$FF,DDRK

        ;Teclado matricial, puerto A
        MOVB #$F0,DDRA ; Seteamos 7-4 como salidas y 3-0 como entradas
        BSET PUCR,$01 ; Se habilitan las resistencias de pullup para el puerto A

       ;Configurar ATD 0
        MOVB #$C2,ATD0CTL2      ;enciende ADC 0, al leer borra banderas, enciende INTs
        ;pongo en 1 bit AFFC que permite borrado de bandera al leer regs de datos
        LDAA #180               ;espero +10 ms, 10 : 160
esperar_10ms:
        DBNE A,esperar_10ms
        MOVB #$30,ATD0CTL3      ;FIFO OFF, se haran 6 conversiones
        MOVB #$B3,ATD0CTL4      ;res a 8 bits, 4 ciclos de reloj, Prescalador en 19
        MOVB #$87,ATD0CTL5      ;just a derecha, sin signo, controlada por software, sin MUX,canal 7

        ;RTI
        BSET CRGINT,$80 ; habilita interrupcion por real time
        MOVB #$17, RTICTL  ;carga valores para contar 1.024 ms segun formula


        LDS         #$3BFF
        CLI        ;Permitir interrup enmascaradas

        ;configuracion inical de la LCD
        CLRB
        LDX #initDisp
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
        
;_______________________________________________________________________________
;
;*******************************************************************************
;                            Programa principal
;*******************************************************************************
;_______________________________________________________________________________

        LDX #MSGConfig_L1
        LDY #MSGConfig_L2
        JSR CARGAR_LCD

config_loop:
        JSR MODO_CONFIGURACION
        TST NumVueltas
        BEQ config_loop
loop_main:
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
        CLR Veloc ;borrar Veloc pues salimos del modo competencia
        CLR Vueltas
        MOVB #0,VelProm ;borrar promedio

conf:
        BRSET BANDERAS,$40,trampolin_config
        BRCLR BANDERAS,$10,seguir_libre ;salir si no cambio el modo
        BCLR PIEH,$09   ;apago interrupciones PTH
        BCLR CRGINT,$80 ;apagamos RTI
        BCLR TSCR2,$80 ;apagamos TCNT
        BCLR BANDERAS,$10
        MOVW #0,TICK_DIS
        MOVW #0,TICK_EN
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
        BCLR PIEH,$09   ;apago interrupciones PTH
        BCLR CRGINT,$80 ;apagamos RTI
        BCLR TSCR2,$80   ;apago interrupcion TCNT
        MOVW #0,TICK_DIS
        MOVW #0,TICK_EN
        MOVB #$08,LEDS
        LDX #MSGRESUMEN_L1
        LDY #MSGRESUMEN_L2
        JSR CARGAR_LCD
seguir_resumen:
        JSR MODO_RESUMEN
        LBRA loop_main

trampolin_config:
        BRA ir_a_config
        
ir_a_comp:
        BRCLR BANDERAS,$10,seguir_comp    ;ssalta si no ha cambiado el modo
        Bset PIEH,$09 ; Habilitar de nuevo las interrupciones PTH
        BSET TSCR2,$80 ;Habilitar interrupciones TCNT
        BSET CRGINT,$80 ;Habilitar interrupcion RTI
        MOVW #$BBBB,BIN1 ;poner $BB en BIN2 y BIN2
        Movw #0,Veloc ; Borrar Veloc y Vueltas
        Clr VelProm
        Bclr YULS,$3C ; Borrar Veloc V?lida, Direcci?n, PantFlag y Habr? c?lculo
        Bclr Banderas,$38 ;Borrar CalcTicks, CambModo y PantFlag
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
        BCLR PIEH,$09   ;apago interrupciones PTH
        BCLR TSCR2,$80 ;apagamos TCNT
        Bset CRGINT,$80 ;encendemos RTI
        MOVB #$02,LEDS
        MOVB NumVueltas,BIN1    ;mostramos numero de vueltas actuales
        MOVB #$BB,BIN2  ;apagamos segmentos izquierdos
        MOVW #0,TICK_DIS
        MOVW #0,TICK_EN
        LDX #MSGConfig_L1
        LDY #MSGConfig_L2
        JSR CARGAR_LCD
seguir_config:
        JSR MODO_CONFIGURACION
        LBRA loop_main

;_______________________________________________________________________________
;
;*******************************************************************************
;                        Subrutinas de interrupcion
;*******************************************************************************
;_______________________________________________________________________________

                        ;*******************************************************
ATD_ISR:                ;                   Subrutina ATD_ISR
                        ;*******************************************************
                        ;Subrutina que promedia 6 lecturas del canal 7
                        ;aunque son valores de 8 bits los guardo en D, pues los
                        ;justifique a la derecha porque sumados podrian sobrepasar
                        ;los 8 bits
                        ;*******************************************************
        LDD ADR00H      ;leer regs de datos borra bandera de int pues active AFFC
        ADDD ADR01H     ;lee las 6 lecturas y las suma en el acumulador D
        ADDD ADR02H
        ADDD ADR03H
        ADDD ADR04H
        ADDD ADR05H
        lDX #6
        IDIV            ;obtenemos el promedio de 6 lecturas
        XGDX
        STAB POT        ;guarda el promedio en POT
        LDAA #20
        MUL
        LDX #255
        IDIV            ;divide valor en D entre valor en X guarda cociente en X
        XGDX            ;ponemos el cociente en D, quedara en B pues es de 8 bits
        LDAA #5         ;En B tenemos un valor entre 1 y 20 y lo multiplicamos
        MUL     ;A*B y guarda en D un numero entre 0 y 100
        CMPB #5
        BHI ver_si_es_mayor_95
        LDAB #5
ver_si_es_mayor_95:
        CMPB #95
        BLO seguir_atd
        LDAB #95
seguir_atd:
        STAB BRILLO ;obtenemos el BRILLO como un valor entre 5 y 95
        RTI




                        ;*******************************************************
RTI_ISR:                ;                   Subrutina RTI_ISR
                        ;*******************************************************
                        ;Subrutina que cuenta 1 ms y cuanta 200 ms para llamar a
                        ;ATD07
                        ;*******************************************************
        BSET CRGFLG,$80 ;borrar solicitud de interrupcion
        INC HZD
        LDAA HZD
        CMPA CONT_200
        BNE continuar_retorno_RTI
        MOVB #0,HZD
        MOVB #$87,ATD0CTL5      ;just a derecha, sin signo, controlada por software, sin MUX, inicia lectura en canal 7
continuar_retorno_RTI:
        TST Cont_Reb
        BEQ retorno_RTI ;si el contador es cero salta
        DEC Cont_Reb
retorno_RTI:
        RTI

                        ;*******************************************************
OC4_ISR:                ;                   Subrutina OC4_ISR
                        ;*******************************************************
                        ;Subrutina que cuenta tiempos para control de pantallas
                        ;LCD y de 7 segmentos
                        ;borrado de banderas manual para que no se borre TOI
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
        Addd #60        ;para que cuenta 20 ms
        Std TC4
        RTI

CONT_DIG_es_8:
        Movb DISP2,PORTB
        MOVB #$0D,PTP
        Bset PTJ,$2
        Bra Antes_de_retornar

CONT_DIG_es_4:
        Movb DISP3,PORTB
        MOVB #$0B,PTP
        Bset PTJ,$2
        Bra Antes_de_retornar

CONT_DIG_es_2:
        Movb DISP4,PORTB
        MOVB #$07,PTP
        Bset PTJ,$2
        Bra Antes_de_retornar

CONT_DIG_es_1:
        Movb LEDS,PORTB
        MOVB #$0F,PTP
        BClr PTJ,$2
        Bra Antes_de_retornar

apagar_LEDS:
        Movb #$0F,PTP
        BSET PTJ,$02
        Bra Antes_de_retornar

                        ;*******************************************************
TCNT_ISR:               ;                   Subrutina TCNT_ISR
                        ;*******************************************************
                        ;Timer Overflow Interrrupt
                        ;Subrutina que cuenta el tiempo para calcular velocidad
                        ;del ciclista y ademas para desplegar info en la
                        ;pantalla LCD
                        ;Timer Overflow Interrupt cada 0.021845 s
                        ;*******************************************************
        BSET TFLG2,$80 ;borrar solicitud de interrupcion  se borra con un 1
        LDX TICK_MED
        INX
        STX TICK_MED
        LDX TICK_EN
        LDY TICK_DIS
        TBEQ X,tick_en_es_0       ;salta si TICK_EN = 0
        DEX
        STX TICK_EN
        BRA revisar_tick_dis
tick_en_es_0:
        BSET BANDERAS,$08 ;poner bit 3 Pant_FLAG
revisar_tick_dis:
        TBEQ Y,tick_dis_es_0       ;salta si TICK_DIS = 0
        DEY
        STY TICK_DIS
        BRA retorno_tcnt

tick_dis_es_0:
        BCLR BANDERAS,$08 ;borra bit 3 Pant_FLAG

retorno_tcnt:
        RTI

                        ;*******************************************************
CALCULAR:               ;                   Subrutina CALCULAR/PTH_ISR
                        ;*******************************************************
                        ;Subrutina que atiende interrupciones al presionar los
                        ;pulsadores SW5 en PH0 y SW2 en PH3
                        ; PH3 representa el sensor S1
                        ; PH0 representa el sensor S2
                        ;ecuacion para obtener velocidad en Km/h:
                        ;          9063/TICK_MED
                        ;1024/46875 = 0.021845 s = tiempo de TOI
                        ;3600/1000 conversion a Km/h
                        ;ecuacion para obtener velocidad promedio:
                        ;       VelProm*(Vueltas-1)+Veloc
                        ;       _____________________________
                        ;                   Vueltas
                        ;*******************************************************
        TST Cont_Reb
        BNE retorno_calcular
        Movb #80,Cont_Reb

        BRSET PIFH,$08,PH3
        BRSET PIFH,$01,PHO
        Bra retorno_calcular
PHO:
        BRCLR YULS,$10,retorno_calcular ;salta si es el primer sensor activado
        BCLR YULS,$10 ;borrar bandera de direccion
        BCLR YULS,$04 ;borrar bandera de calculo
        LDX TICK_MED
        LDD #9063
        IDIV
        XGDX
        STAB Veloc
        CMPB #35
        BLO veloc_fuera_de_rango
        CMPB #95
        BHI veloc_fuera_de_rango

        BSET YULS,$20 ;poner bandera de velocidad valida
        CLRA
        LDAB Vueltas
        XGDX
        LDAA VelProm
        LDAB Vueltas
        DECB
        MUL
        IDIV
        STX CURIE

        CLRA
        LDAB Vueltas
        XGDX
        CLRA
        LDAB Veloc
        IDIV
        XGDX
        ADDD CURIE
        STAB VelProm
        BCLR Banderas,$20
        BCLR PIEH,$09   ;apagar interrupciones key wakeups en ph0 y ph3

retorno_calcular:
        LDAA #$FF
        ANDA PIFH
        STAA PIFH
        RTI

veloc_fuera_de_rango:
        BCLR YULS,$20 ;quitar bit de velocidad valida
        DEC Vueltas
        BRA retorno_calcular

PH3:
        BRSET YULS,$10,retorno_calcular
        MOVW #0,TICK_MED
        INC Vueltas
        BSET YULS,$10 ;indicar que ya paso por sensor 1 (direccion)
        BSET YULS,$04 ;poner bandera de calculo para poner mensaje en pant_ctrl
        Bra retorno_calcular

;_______________________________________________________________________________
;
;*******************************************************************************
;                         Subrutinas de generales
;*******************************************************************************
;_______________________________________________________________________________


;*******************************************************************************
;                     Subrutinas nuevas para RunMeter 623
;*******************************************************************************

                        ;*******************************************************
PANT_CRTL:              ;                  Subrutina PANT_CTRL
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
        Brclr Banderas,$20,Calcular_Ticks
        Ldaa #$08
        Ldab #$08
        Anda Banderas
        Andb YULS
        Cba
        Beq Retorno_PANT_CRTL
        Ldaa #$08
        Eora YULS
        Staa YULS
        Brclr YULS,$08,Mensaje_esperando
        Brclr YULS,$20,Activar_Alerta
        Ldx #MSGCOMPETENCIA_L1
        Ldy #MSGCOMPETENCIA_L2
        Movb Veloc,BIN1
        Movb Vueltas,BIN2
        Jsr CARGAR_LCD
        Bra Retorno_PANT_CRTL

Retorno_PANT_CRTL:
        Rts

Calcular_Ticks:
        Brclr YULS,$20,Veloc_No_Valida
        Clra
        Ldab VelProm
        XGDX
        Ldd #49438
        Idiv
        Stx TICK_DIS

        Clra
        Ldab VelProm
        XGDX
        Ldd #32959
        Idiv
        Stx TICK_EN
        Bset Banderas,$20
        Bra Retorno_PANT_CRTL

Veloc_No_Valida:
        Movw #1,TICK_EN
        Movw #138,TICK_DIS
        Bset Banderas,$20
        Bra Retorno_PANT_CRTL

Activar_Alerta:
        Ldx #MSGALERTA_L1
        Ldy #MSGALERTA_L2
        Movb #$AA,BIN1
        Movb #$AA,BIN2
        Jsr CARGAR_LCD
        Bra Retorno_PANT_CRTL

Mensaje_esperando:
        Ldx #MSGINICIAL_L1
        Ldy #MSGINICIAL_L2
        Jsr CARGAR_LCD
        Movb #$BB,BIN1
        Movb #$BB,BIN2
        Ldaa NumVueltas
        Clr Veloc
        Cmpa Vueltas
        LBeq Retorno_PANT_CRTL ;final de todas las vueltas

        Bset PIEH,$09
        Bclr Banderas,$20
        LBra Retorno_PANT_CRTL ;retorno usual


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
        Brset YULS,$04,Ir_a_mensaje_calculo
        TST Veloc
        BEQ retorno_competencia
        JSR PANT_CRTL
retorno_competencia:
        Rts
Ir_a_mensaje_calculo:
        Ldx #MSGCALCULANDO_L1
        Ldy #MSGCALCULANDO_L2
        Bclr YULS,$04
        Movb #$BB,BIN1
        Movb #$BB,BIN2
        Jsr CARGAR_LCD
        Bra retorno_competencia


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
MODO_RESUMEN:           ;                 Subrutina MODO_RESUMEN
                        ;*******************************************************
                        ;Subrutina que desplega en pantallas vueltas y velocidad
                        ;Variables de entrada: TEMP2.5
                        ;Variables de salida: LEDS, BIN1, BIN2, TEMP2.5
                        ;*******************************************************
        Movb VelProm,BIN1
        Movb Vueltas,BIN2
        Rts

                        ;*******************************************************
MODO_LIBRE:             ;                  Subrutina MODO_LIBRE
                        ;*******************************************************
                        ;Subrutina que espera al cambio de otro modo
                        ;Variables de entrada: TEMP1.6 bandera de cambio de modo
                        ;Variables de salida: TEMP1.6
                        ;*******************************************************
        Movb #$AA,BIN1
        Movb #$AA,BIN2
        Rts
;*******************************************************************************
;               Subrutinas de binario y BCD y display de 7 segmentos
;*******************************************************************************

                        ;*******************************************************
CONV_BIN_BCD:           ;                Subrutina CONV_BIN_BCD
                        ;*******************************************************
                        ;Subrutina que se encarga de llamar a BIN_BCD para
                        ;conveRTIr de binario a BCD los valores ingresados al
                        ;teclado presentes en las variables BIN1 y BIN2, los
                        ;guarda en BCD1 y BCD2
                        ;*******************************************************
        LDAB BIN2
        CMPB #$BB
        BEQ poner_bcd2_apagado
        BCLR YULS,$80   ;quitar bandera de bcd2 apagado
continuar_conv_bin_bcd:
        Ldaa BIN1
        CMPA #$AA
        BNE revisar_bb
        MOVW #$AAAA,BCD1  ;poner ambos valores de BCD en AA para poner rayas
        bra retorno_conv_bin_bcd
revisar_bb:
        CMPA #$BB
        BNE seguir_conv_bin_bcd
        MOVW #$BBBB,BCD1  ;poner ambos valores de BCD en AA para poner rayas
        bra retorno_conv_bin_bcd
poner_bcd2_apagado:
        BSET YULS,$80   ;poner bandera de bcd2 apagado
        BRA continuar_conv_bin_bcd

seguir_conv_bin_bcd:
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
        bra retorno_conv_bin_bcd
BCD1_es_menor_a_10:
        Ldaa #$B0
        Eora BCD1
        Staa BCD1
        Bra revisar_BCD2
BCD2_es_menor_a_10:
        Ldaa #$B0
        Eora BCD2
        Staa BCD2
        bra retorno_conv_bin_bcd
es_cero:
        Movb #$B0,BCD1  ;poner 0
        Bra revisar_BCD2
BCD2_es_cero:
        Movb #$B0,BCD2  ;poner 0
        bra retorno_conv_bin_bcd

retorno_conv_bin_bcd:
        BRCLR YULS,$80,mantener_bcd2_igual
        MOVB #$BB,BCD2
mantener_bcd2_igual:
        RTS

                        ;*******************************************************
BCD_7SEG:               ;                 Subrutina BCD_7SEG
                        ;*******************************************************
                        ;Convierte a valor desplegable en pantalla de 7 segmentos
                        ;los valores en BCD en BCD1 y BCD2 se guardan en DISP[0:3]
                        ;Entadas: SEGMENT talba de valores en 7 seg, se lee con X
                        ;Salidas:
                        ;DISIP1, DIPS2, DISP3, DISP4 valores en 7 segmentos
                        ;*******************************************************
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

                        ;*******************************************************
BCD_BIN:                ;                Subrutina BCD_BIN
                        ;*******************************************************
                        ;Subrutina que toma el valor en Num_Array y lo convierete
                        ;a binario guardando en ValorVueltas
                        ;*******************************************************
	BRSET Num_Array+1,$FF,un_solo_digito
        Ldx #Num_Array
        Ldab #$A
        Ldaa 1,X+
        Mul
        Ldaa 0,X
        Aba
        Staa ValorVueltas
        Rts
un_solo_digito:
        MOVB Num_Array,ValorVueltas
	RTS

                        ;*******************************************************
BIN_BCD:                ;                Subrutina BIN_BCD
                        ;*******************************************************
                        ;Subrutina que convierte de binario a BCD
                        ;Entadas: se recibe BIN en R1
                        ;Salidas: BCD_L
                        ;*******************************************************
        Ldab #7
        Movb #0,BCD_L
Loop1:  Lsla
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

;*******************************************************************************
;                         Subrutinas de pantalla LCD
;*******************************************************************************

                        ;*******************************************************
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
        CMPA #EOM;NUMERAL-> Hay que poner numeral si uso un valor definido con EQU
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
        CMPA #EOM
        BEQ retorno_cargar_LCD
        JSR SendData
        MOVB D40uS,Cont_Delay
        JSR Delay
        BRA loop_L2

retorno_cargar_LCD:
        RTS
                        ;*******************************************************
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


;*******************************************************************************
;                         Subrutinas de manejo del teclado
;*******************************************************************************

                        ;*******************************************************
Tarea_Teclado:          ;           Subrutina Tarea_Teclado
                        ;*******************************************************
                        ;Verifica que se presiono una tecla, se encarga de la
                        ;lectura del teclado y formacion del arreglo de teclas
                        ;leidas
                        ;*******************************************************
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
MUX_TECLADO:            ;                  Subrutina MUX_TECLADO
                        ;*******************************************************
                        ;Lee teclado matricial barriendo filas con 0 y viendo
                        ;que bit del nibbble bajo de PORTA se hace 0
                        ;*******************************************************
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
        MOVB #$FF,Tecla
        RTS

tecla_presionada:
        MOVB A,X,Tecla
        RTS

                        ;*******************************************************
FORMAR_ARRAY:           ;            Subrutina FORMAR_ARRAY
                        ;*******************************************************
                        ;Llena arreglo Num_Array con teclas leidas
                        ;Entradas:
                        ;Tecla_IN tecla presionada
                        ;MAX_TCL: maixmo de teclas en arreglo
                        ;Salidas:
                        ;NumArray: arreglo de 2 teclas
                        ;COnt_TCL: cantidad de teclas ingresadas
                        ;*******************************************************
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