;#incluude registers.inc

;*******************************************************************************
;       UNIVERSIDAD DE COSTA RICA       ESCUELA DE INGENIERIA ELECTRICA
;               MICROPROCESADORES IE 623  II SEMESTRE 2020
;*******************************************************************************
;                                  RUN METER623
;*******************************************************************************
;       V7
;       AUTOR: ROBIN GONZALEZ   B43011
;
;       DESCRIPCION:    Proyecto EOMal
;       contador de vueltas y velocidad para un velodromo
;       con los swithces 7 y 6 se cambia de modo
;       mensajes se desplegan en las pantallas
;       sw5 y sw2 simulan sensores que detectan al ciclista
;
;*******************************************************************************


;*******************************************************************************
;                             Estructuras de datos
;*******************************************************************************
EOM:        EQU                $00      ;End Of Message byte para indicar EOM de fcc

            org         $1000
   
BANDERAS:      ds 1 ;7=modo1, 6=modo0, 5=Calc_ticks,3=Pant_FLG,2=Array_OK,1=TCL_LEIDA,0=TCL_LISTA
NumVueltas:    ds 1 ;
ValorVueltas:  ds 1 ;???comentar que hace cada variable 
MAX_TCL:       db $02 ; Se define el valor maximo del arreglo de teclas
Tecla:         ds 1 ; Se define la variable de tipo tecla.
Tecla_IN:      ds 1 ;
Cont_Reb:      ds 1 ;
Cont_TCL:      ds 1 ;
Patron:        ds 1 ;
Num_Array:     ds 2 ;
BRILLO:        ds 1 ;
POT:           ds 1 ;
TICK_EN:       ds 2 ; 
TICK_DIS:      ds 2 ;
Veloc:         ds 1 ;
Vueltas:       ds 1 ;
VelProm:       ds 1 ;
TICK_MED:      ds 2 ;
BIN1:          ds 1 ;
BIN2:          ds 1 ;
BCD1:          ds 1 ;
BCD2:          ds 1 ;
BCD_L:         ds 1 ;
BCD_H:         ds 1 ;
TEMP:          ds 1 ;
LOW:           ds 1 ;
DISP1:         ds 1 ;
DISP2:         ds 1 ;
DISP3:         ds 1 ;
DISP4:         ds 1 ;
LEDS:          ds 1 ;
CONT_DIG:      ds 1 ;
CONT_TICKS:    ds 1 ;
DT:            ds 1 ;
CONT_7SEG:     ds 2 ;
CONT_200:      db 200 ;
Cont_Delay:    ds 1 ;
D2mS:          dB 100 ;
D260uS:        dB 14 ; ??? era 13 y  240s
D40uS:         dB 2 ;
Clear_LCD:     dB $01 ;
ADD_L1:        dB $80 ;
ADD_L2:        dB $C0 ;  
TEMP1:         ds  1    ;Otras banderas7: vueltas_es_NumVueltas,4= CambioMOD, 3: LCD_configurada ,1: Calc_flag
TEMP2:         ds  1    ;usado para contador de  200 para ATD
TEMP3:         ds  1    ;variable temeporal 3
TEMP4:         ds  1    ;variable temeporal 4
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
        MOVB $FF,Num_Array
        MOVB $FF,Num_Array+1
        MOVB #$40,Banderas      ;iniciar en modo config
        MOVB #$00,Patron 
        MOVB #$00,Cont_TCL 
        MOVB #$00,Cont_Reb 
        MOVB #$00,LEDS 
        MOVB #$00,BIN1 
        MOVB #$BB,BIN2 
        MOVB #$00,BRILLO 
        MOVB #$00,CONT_DIG 
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
        MOVB #$10, TEMP1        ;iniciar con estado final de vueltas
        MOVB #$00, TEMP2 
        MOVB #$00, TEMP3
        movw #$0000,CONT_7SEG
        MOVB #$00,Cont_Delay ;
        MOVB #200,CONT_200  ;Para contador de RTI que activa ATD para leer pot

;*******************************************************************************
;                          Configuracion de hardware
;*******************************************************************************                
        ;Configurar interrupcion key wakeups en  PTH
        MOVB #$09,PIEH ;habilitamos la interrup en el puerto H para los bits 0 y 3
        BCLR PPSH,$09 ;interrupcion se habilita por flanco creciente
        BCLR DDRH,$C0 ;PTH es entrada automaticamente, para recordar bits 6 y 7

        ;Configurar interrupcion Timer Overflow Interrupt
        ;BSET TSCR1,$80        ;Poner 1 en TEN Timer enable bit y de Timer Status Control Reg 1
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

        ;Leds y 7 segmentos
        MOVB #$FF,DDRB       ;puerto B como salida para poner digitos y valores de leds
        BSET DDRJ,$02        ;bit 1 de puerto J como salida, habilita leds
        BSET PTJ,$02         ;1 en el bit 1 del puerto J para apagar los leds
        MOVB #$0F,DDRP       ;nibble inf de P como salida para habilitar digitos de 7 seg

        ;Comunicacion LCD
        MOVB        #$FF,DDRK
        ;Teclado matricial, puerto A
        MOVB #$F0,DDRA ; Seteamos 7-4 como salidas y 3-0 como entradas
        BSET PUCR,$01 ; Se habilitan las resistencias de pullup para el puerto A

       ;Configurar ATD 0
        MOVB #$C2,ATD0CTL2      ;enciende ADC 0, al leer borra banderas, enciende INTs 
        ;pongo en 1 bit AFFC que permite borrado de bandera al leer regs de datos
        LDAA #180               ;???espero +10 ms, 10 : 160
esperar_10ms:
        DBNE A,esperar_10ms
        MOVB #$30,ATD0CTL3      ;FIFO OFF, se haran 6 conversiones
        MOVB #$B3,ATD0CTL4      ;res a 8 bits, 4 ciclos de reloj, Prescalador en 19
        MOVB #$87,ATD0CTL5      ;just a derecha, sin signo, controlada por software, sin MUX,canal 7

        ;RTI
        BSET CRGINT,$80 ; habilita interrupcion por real time
        MOVB #$17, RTICTL  ;carga valores para contar 1.024 ms segun formula

        
;_______________________________________________________________________________
;
;*******************************************************************************
;                            Programa principal
;*******************************************************************************
;_______________________________________________________________________________

             LDS         #$3BFF
        ; Permitir interrup enmascaradas
            CLI
        
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
            oraa BANDERAS
            STAA BANDERAS
            BSET TEMP1,$10
            BRA comp
sin_cambios:
            BCLR TEMP1,$10
comp:
            BRSET BANDERAS,$C0,ir_a_comp
            BRSET BANDERAS,$80,ir_a_resumen
            CLR Veloc           ;no es cmop ni resumen
            BCLR TEMP1,$80         ;borramos bandera para que active PTH
            CLR Vueltas
            MOVB #0,VelProm ;???porque sino indefine division Necesario para PROMEDIO '' cambio 1 a 0???
            BRCLR TEMP1,$10,conf
            MOVB #$03,TSCR2
            BCLR $0F,PIEH
            BCLR $0F,PIFH
            
conf:
            BRSET BANDERAS,$40,ir_a_config
            JSR MODO_LIBRE
            BRA loop_main
ir_a_config:
            JSR MODO_CONFIGURACION
            BRA loop_main
ir_a_comp:
        ;activate TOI
            MOVB #$83,TSCR2  
            JSR MODO_COMPETENCIA
            BRA loop_main
ir_a_resumen:
            JSR MODO_RESUMEN
            BRA loop_main

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
        IDIV
        XGDX
        STAB POT        ;guarda el promedio en POT
        LDAA #20
        MUL
        LDX #255
        IDIV            ;divide valor en D entre valor en X guarda cociente en X
        XGDX            ;ponemos el cociente en D, quedaría en B pues es de 8 bits
        STAB BRILLO ;guarda valor entre 1 y 20 en BRILLO
        LDAA #5
        MUL     ;A*B y guarda en D
        STAB DT ;obtenemos DT          
        RTI

                        ;*******************************************************
CALCULAR:               ;                   Subrutina PTH_ISR
                        ;*******************************************************
                        ;Subrutina que atiende interrupciones al presionar los
                        ;pulsadores SW5 en PH0 y SW2 en PH3
                        ; PH3 representa el sensor S1
                        ; PH0 representa el sensor S2
                        ;ecuacion para obtener velocidad en Km/h:
                        ;          9063/TICK_MED
                        ;donde:
                        ;9063 = 55*3600*46875/(1000*1024)
                        ;1024/46875 = 0.021845 s = tiempo de TOI
                        ;3600/1000 conversion a Km/h
                        ;ecuacion para obtener velocidad promedio:
                        ;       VelProm*(Vueltas-1)+Veloc
                        ;       _____________________________
                        ;                   Vueltas
                        ;*******************************************************
            BRSET PIFH,$01,PH0
            BRSET PIFH,$08,PH3
            BRA retorno_calc
PH0:
        ;BSET PORTB,$04
        
            BSET PIFH, $01 
        ;Si el contador de rebotes es distinto de 0 se ejecuta el Calculo
            TST CONT_REB
            BNE retorno_calc    ;despues de rebotes
            MOVB #85,CONT_REB
            BRCLR TEMP3,$80,retorno_calc    ;ignorar entrada si no entro ph3 antes
            BCLR TEMP3,$80  ;borrar bandera
            LDX TICK_MED                    
            ;BEQ RETURN`
            ;BCLR BANDERAS,$20          ;???
            LDD #9063             
            IDIV        ;velocidad en kmph en B
            XGDX        ;poner resultado en B
        
           
            CMPB #35    ;rangos de vlocidad
            BLO no_rango
            CMPB #95
            BHI no_rango
            STAB Veloc
            INC Vueltas
        ; Revisamos si existe un valor en VelProm
            ;LDAA VelProm
            ;CMPA #20    ;si es menor a 20 (si es 0 u 1) por decir algo
            TST VelProm
            BNE no_primera_vuelta
            MOVB Veloc,VelProm      ;si e primera vuelta
            BRA retorno_calc

no_primera_vuelta:
           LDAB Vueltas
           CLRA
           XGDX        ;ponemos Vueltas en X
           LDAB Vueltas
           DECB
           LDAA VelProm
           MUL
           ADDB Veloc
           IDIV
           XGDX
           STAB VelProm    ;guardar velocidad promedio en VelProm                  
           
           BRA retorno_calc

no_rango
            MOVB #$FF,Veloc     ;indicar vel invalida
            BRA retorno_calc

PH3:
            BSET PIFH,$08            
            LDAA Cont_Reb
            BNE retorno_calc
            MOVB #85,Cont_Reb
            BSET TEMP3,$80      ;poner bandera de direccion correcta
            MOVW #0,TICK_MED
            ;BSET BANDERAS,$20  ;????           
            BSET TEMP1,$02            ;indicar que habra calculo para que competencia imprima msg de calculo
retorno_calc:
            RTI

                        ;*******************************************************
RTI_ISR:                ;                   Subrutina RTI_ISR
                        ;*******************************************************
                        ;Subrutina que cuenta 1 ms y cuanta 200 ms para llamar a
                        ;ATD07
                        ;*******************************************************
        BSET CRGFLG,$80 ;borrar solicitud de interrupcion
        INC TEMP2
        LDAA #200
        CMPA TEMP2
        BNE continuar_retorno_RTI
        MOVB #0,TEMP2
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
            loc
            BSET TFLG1,$10 ;borra interrupciones
            LDAA CONT_TICKS
            LDAB DT
            CBA
            BGE apagar`
            TST CONT_TICKS
            BEQ check_digit`
checkN`
            CMPA #100
            BEQ changeDigit`
INCticks`
            INC CONT_TICKS
            LBRA part2`
;Apagar
apagar`
            MOVB #$FF,PTP
            BCLR PTJ,$02 ; enciendo
            MOVB #$0, PORTB
            BRA checkN`
changeDigit`
            MOVB #$0,CONT_TICKS
            LDAA #5
            CMPA CONT_DIG
            BNE jpart2`
            CLR CONT_DIG
jpart2`
            INC CONT_DIG
            BRA part2`
check_digit`
            LDAA CONT_DIG
            CMPA #1
            BNE dig2`
            BCLR PTP, $08
            MOVB DISP1, PORTB
            BSET PTJ, $02
            BRA INCticks`
dig2`
            CMPA #2
            BNE dig3`
            BCLR PTP, $04
            LDAA DISP2
            CMPA #$3F
            BEQ ndig2`
            MOVB DISP2, PORTB
            BSET PTJ, $02
ndig2`
            BRA INCticks`
dig3`
            CMPA #3
            BNE dig4`
            BCLR PTP, $02
            MOVB DISP3, PORTB
            BSET PTJ, $02
ndig3`
            BRA INCticks`
dig4`
            CMPA #4
            BNE digleds`
            BCLR PTP, $01
            LDAA DISP4
            CMPA #$3F
            BEQ ndig4`
            MOVB DISP4, PORTB
            BSET PTJ, $02
ndig4`
            LBRA INCticks`
digleds`
            MOVB LEDS, PORTB
            BCLR PTJ, $02
            INC CONT_TICKS

part2`
            TST CONT_DELAY
            BEQ TST7seg`
            DEC CONT_DELAY
TST7seg`
            LDX CONT_7SEG
            BEQ JBCD_7SEG`
            DEX
            STX CONT_7SEG
returnOC4
            LDD TCNT
            ADDD #60
            STD TC4
            RTI
JBCD_7SEG`
            MOVW #5000,CONT_7SEG
            JSR BCD_7SEG
            JSR CONV_BIN_BCD
            BRA returnOC4

                        ;*******************************************************
TCNT_ISR:               ;                   Subrutina TCNT_ISR
                        ;*******************************************************
                        ;Timer Overflow Interrrupt
                        ;Subrutina que cuenta el tiempo para calcular velocidad
                        ;del ciclista y ademas para desplegar info en la
                        ;pantalla LCD
                        ;Timer Overflow Interrupt cada 0.021845 s
                        ;*******************************************************
        BSET TFLG2,$FF ;borrar solicitud de interrupcion  se borra con un 1
        ;BSET TFLG2,$80 ;borrar solicitud de interrupcion  se borra con un 1                      
        LDX TICK_MED
        INX
        STX TICK_MED
        LDX TICK_EN
        LDY TICK_DIS       
        TBNE X,tick_en_no_0       ;salta si no es 0

        ;PANT_FLAG=1
        BSET BANDERAS,$08 ;poner bit 3 Pant_FLAG
        BRA continuar_tick_dis
tick_en_no_0:       
        DEX
        STX TICK_EN
continuar_tick_dis:
        TBNE Y,tick_dis_no_0    ;salta si no es 0
;
        BCLR BANDERAS,$08 ;borra bit 3
        BRA retorno_tcnt
tick_dis_no_0:        
        DEY
        STY TICK_DIS
        ;DEC TICK_DIS
retorno_tcnt:
         RTI  
     

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
MODO_CONFIGURACION:     ;            Subrutina MODO_CONFIGURACION
                        ;*******************************************************
                        ;Subrutina que lee valor de vueltas y desplega en panta-
                        ;lla siempre y cuando este en el rango [5 , 25]
                        ;Variables de entrada:
                        ;ValorVueltas : numero de vueltas ingresadas
                        ;Variables de salida:
                        ;NumVueltas: vueltas validas ingresdas
                        ;BIN1 y BIN2: valores a poner en pantalla 7 segmentos
                        ;BIN1 displays 1 y 2
                        ;BIN2 displays 3 y 4
                        ;*******************************************************            
            BRCLR TEMP1,$10,seguir_config    ;ssalta si no ha cambiado el modo
            BCLR TEMP1,$10
            MOVB #$02,LEDS
            MOVB NumVueltas,BIN1    ;mostramos numero de vueltas actuales
            MOVB #$BB,BIN2  ;apagamos segmentos izquierdos
            MOVW 0,TICK_DIS
            MOVW 0,TICK_EN           
            MOVB #0,ValorVueltas    ;vueltas ingresadas son 0
            LDX #MSGConfig_L1
            LDY #MSGConfig_L2
            JSR CARGAR_LCD
seguir_config:
            BCLR PIEH,$0F   ;interrupciones apagadas
            BRSET BANDERAS,$04,ingresar_arreglo ;si el arreglo no ha sido ingresado
            JSR TAREA_TECLADO
            BRA retorno_config
ingresar_arreglo:                        
            JSR BCD_BIN ;convertir a binario
            BCLR BANDERAS,$04
            LDAA ValorVueltas
            CMPA #25
            BHI fuera_rango ;salta si val en A > 25
            CMPA #5
            BLO fuera_rango
            MOVB ValorVueltas,NumVueltas    ;valor valido, mostrar en pantalla
            MOVB NumVueltas,BIN1
            BRA retorno_config          
fuera_rango:
            CLR NumVueltas
retorno_config:
            RTS
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
            BRSET TEMP1,$80,desactivar_pth
            BSET PIEH,$09    ;activa PTH
            BSET PIFH,$09 
seguir_comp
            BRCLR TEMP1,$10,continuar_competencia       
            BCLR TEMP1,$90  ;borra bandera de ultima vuelta al reingreso para reactivar PTH
            MOVB #$BB,BIN1  ;tambion borramos cambio de mod     
            MOVB #$BB,BIN2
            ;BCLR TEMP1,$10 ;???
            MOVB #$04,LEDS
            LDX #MSGINICIAL_L1
            LDY #MSGINICIAL_L2
            JSR CARGAR_LCD
            CLR VelProm     ;si hay que borrarlos dice profesor 
            CLR Vueltas
            CLR Veloc
continuar_competencia:
            TST VELOC
            BEQ posible_calculo
            JSR PANT_CTRL
posible_calculo:
            BRCLR TEMP1,$02,retorno_competencia ;si la bandera de calulo es 1
            BCLR PIEH,$08           ;apague Interrupciones e imprima el msj
            BCLR TEMP1,$02
            LDX #MSGCALCULANDO_L1
            LDY #MSGCALCULANDO_L2
            JSR CARGAR_LCD
retorno_competencia
            RTS
desactivar_pth:
            BCLR PIEH,$FF ;desactiva intr
            BSET PIFH,$09
            BRA seguir_comp


                        ;*******************************************************
MODO_RESUMEN:           ;                 Subrutina MODO_RESUMEN
                        ;*******************************************************
                        ;Subrutina que desplega en pantallas vueltas y velocidad
                        ;Variables de entrada: TEMP2.5
                        ;Variables de salida: LEDS, BIN1, BIN2, TEMP2.5
                        ;*******************************************************       
            BRCLR TEMP1,$10,retorno_resumen
            BCLR TEMP1,$10
            BCLR $0F,PIEH   ;apago interrupciones PTH
            BCLR $0F,PIFH
            MOVB #$08,LEDS
            LDX #MSGRESUMEN_L1
            LDY #MSGRESUMEN_L2
            JSR CARGAR_LCD
retorno_resumen:
            MOVB Vueltas,BIN2 
           ; LDAA #1 ;???
            ;CMPA VelProm
            ;BEQ vprom_es_0:
            MOVB VelProm,BIN1           
            RTS
vprom_es_0:
            MOVB #0,BIN1                   
            RTS

                        ;*******************************************************
MODO_LIBRE:             ;                  Subrutina MODO_LIBRE
                        ;*******************************************************
                        ;Subrutina que espera al cambio de otro modo
                        ;Variables de entrada: TEMP1.6 bandera de cambio de modo
                        ;Variables de salida: TEMP1.6
                        ;*******************************************************
            BRCLR TEMP1,$10,retorno_libre ;salir si no cambio el modo
            BCLR TEMP1,$10   
            LDX #MSGLIBRE_L1
            LDY #MSGLIBRE_L2
            MOVB #$01,LEDS
            JSR CARGAR_LCD
retorno_libre:
            MOVB #$BB,BIN1  ;apago 7 segmentos
            MOVB #$BB,BIN2
            RTS

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
            loc
            BCLR PIEH,$09
            BSET        PIFH,$09        ;???funcionara
            LDAA Veloc
            CMPA #$FF
            BNE valid_speed`
        ; fuera de rango 35 =< veloc =< 95
            LDAA BIN1
            CMPA #$AA
            BEQ der
            MOVB #$AA,BIN1
            MOVB #$AA,BIN2            
        ; 3 s = T_tick * 137 => TICK_DIS - TICK_EN = 137            
            MOVW #0,TICK_EN
            MOVW #138,TICK_DIS
        ; Pant_flag ON
            BSET BANDERAS,$08           ;'???? pone pant flag
            LDX #MSGALERTA_L1 
            LDY #MSGALERTA_L2
            JSR CARGAR_LCD
            BRA retorno_pc
der:
            BRCLR BANDERAS,$08,m_ini        ;revisa Pnat_flag
            BRA retorno_pc
m_ini:
            MOVB #$BB,BIN1
            MOVB #$BB,BIN2            
            LDX #MSGINICIAL_L1 
            LDY #MSGINICIAL_L2
            JSR CARGAR_LCD
            LDAA Vueltas
            CMPA NumVueltas
            BEQ salt
            BSET PIEH,$09
salt:
            BCLR BANDERAS,$20
            CLR Veloc
retorno_pc:
            LDAA Vueltas
            CMPA NumVueltas
            BNE seguir_retorno
            BSET TEMP1,$80     ;bandera de fi nalizacion
            BCLR PIEH,$09
seguir_retorno:            
            RTS
valid_speed`
            BRSET BANDERAS,$20,chk_pantflg`
            BSET BANDERAS,$20
                        BSET BANDERAS,$20
            CLRA
;            LDAB VelProm    ;calculo de ticks
            LDAB Veloc  ;???cambio valoc
            XGDX
            LDD #32959            
            IDIV
            STX TICK_EN
            CLRA
            ;LDAB VelProm       ;???cambio valoc
            LDAB Veloc
            XGDX
            LDD #49438
            IDIV
            STX TICK_DIS
            BRA retorno_pc
        ; Ecuacion de Tick_Dis
chk_pantflg`
            LDAA BIN1
            BRSET BANDERAS,$08,chk_comp_msg`
            CMPA #$BB
            BEQ retorno_pc
            LBRA m_ini
chk_comp_msg`
            CMPA #$BB
            BNE retorno_pc
            BSET PIEH,$09       ;??? habilita interrupciones
        ; 3 segundos hasta que se deshabilite
            ;MOVW #138,TICK_DIS
            ;MOVW #1,TICK_EN
            LDX #MSGCOMPETENCIA_L1 
            LDY #MSGCOMPETENCIA_L2
            JSR CARGAR_LCD
            MOVB Veloc,BIN1
            MOVB Vueltas,BIN2
            lBRA retorno_pc

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
            loc
            MOVB    #0,BCD_L
            LDAA    BIN1   ;inicio con bcd1
            CMPA    #$BB
            BEQ     chk_special1`
            CMPA    #$AA
            BEQ     chk_special1`
        ; Algoritmo para numeros, que no sea " " o "-" en d. 7 seg
            LDAB    #14
            LDX     #BCD_L    
            BRA     loop`
changeBCD`
            lsla
            rol     0,X
chk_BCD`
            MOVB    BCD_L,BCD1
            LDAA    BIN2   ;continua con bcd2
            CMPA    #$BB
            BEQ     chk_special2`
            CMPA    #$AA
            BEQ     chk_special2`
            MOVB    #0,BCD_L    
loop`
            lsla
            rol     0,X
            STAA    TEMP
            LDAA    0,X
            anda    #$0F
            CMPA    #5
            blt     continue1`
            adda    #3
continue1`
            STAA    LOW 
            LDAA    0,X
            anda    #$F0
            CMPA    #$50
            blt     continue2`
            adda    #$30
continue2`
            adda    LOW
            STAA    0,X
            LDAA    TEMP
            DECb
            cmpb    #7
            BEQ     changeBCD`
            cmpb    #0 
            BNE     loop`
            lsla
            rol     0,X
            MOVB    BCD_L,BCD2
return`                                         
            RTS
        ; Casos donde se apaga o utiliza un guion
chk_special1`
            STAA    BCD1
            STAA    BCD2
            BRA     return`
chk_special2`
            STAA    BCD2
            BRA     return`

                        ;*********************************************************
BCD_7SEG:               ;                 Subrutina BCD_7SEG
                        ;*********************************************************
                        ;Convierte a valor desplegable en pantalla de 7 segmentos
                        ;los valores en BCD en BCD1 y BCD2 se guardan en DISP[0:3]
                        ;Entadas: SEGMENT talba de valores en 7 seg, se lee con X
                        ;Salidas: 
                        ;DISIP1, DIPS2, DISP3, DISP4 valores en 7 segmentos
                        ;*********************************************************
        LDY SEGMENT
        LDY #SEGMENT
        LDAA #$F0
        ANDA BCD2
        LSRA            ;el problema era estar usano ASRA
        LSRA            ; asra no debe usarse porque mantiene el bit de signo
        LSRA
        LSRA
cont_1:
        MOVB A,Y,DISP4
dg2:
        LDAA #$0F
        ANDA BCD2
        MOVB A,Y,DISP3
        LDAA #$F0
        ANDA BCD1
        LSRA
        LSRA
        LSRA
        LSRA
cont_2:
        MOVB A,Y,DISP2
dig4:
        LDAA #$0F
        ANDA BCD1
        MOVB A,Y,DISP1
        RTS

                        ;*******************************************************
BCD_BIN:                ;                Subrutina BIN_BCD
                        ;*******************************************************
                        ;Subrutina que toma el valor en Num_Array y lo convierete
                        ;a binario guardando en ValorVueltas
                        ;*******************************************************
            LDX #NUM_ARRAY
            LDAA    1,X
            CMPA    #$FF
        ;Revisar $FF
            BEQ invalido
            LDAA    #0
loop
            CMPA    #0
            BEQ mul10
            addb    A,X    
            BRA sumA
mul10
            LDAB    A,X
            LSLB
            LSLB
        ;mult x 8
            LSLB        
            addb    A,X
        ;mult x 10
            addb    A,X    
sumA
            MOVB    #$FF,A,X
            INCA
            CMPA    MAX_TCL
            BNE loop
            STAB    ValorVueltas
            BRA return
invalido
            LDAA    MAX_TCL
loop1
            MOVB    #$FF,A,X
            dBNE    A,loop1
            CLR ValorVueltas
return
            RTS


;*******************************************************************************
;                         Subrutinas de pantalla LCD
;*******************************************************************************

                        ;*******************************************************
Cargar_LCD:             ;                 Subrutina Cargar_LCD
                        ;*******************************************************
                        ;Controlador de la pantalla LCD, se encarga de enviar
                        ;comandos y datos segun el protocolo de la pantalla
                        ;recibe en X direccion del mensaje de la linea 1 y en Y 
                        ;la del mensaje de la linea 2
                        ;*******************************************************
            BRSET TEMP1,$08,continuar_cargar
            BSET TEMP1,$08  ;poner bandera de LCD configurada
            PSHX
            LDX #initDisp
            LDAB    #4
loopINITLCD:
            LDAA    1,X+
            
            JSR SendCommand
            MOVB    D40uS,Cont_Delay
            JSR Delay
            dBNE    B,loopINITLCD

            LDAA    Clear_LCD
            JSR SendCommand
            MOVB    D2mS,Cont_Delay
            JSR Delay
            PULX
continuar_cargar:            
            LDAA    Clear_LCD
            JSR SendCommand
            MOVB    D2mS,Cont_Delay
            JSR Delay

            LDAA ADD_L1
            JSR SendCommand
            MOVB D40uS,Cont_Delay
            JSR Delay
linea_1_Cargar_LCD:
            LDAA 1,X+
            CMPA #EOM
            BEQ salir_linea_1_Cargar_LCD
            JSR SendData
            MOVB D40uS,Cont_Delay
            JSR Delay
            BRA linea_1_Cargar_LCD
salir_linea_1_Cargar_LCD:
            LDAA ADD_L2
            JSR SendCommand
            MOVB D40uS,Cont_Delay
            JSR Delay
linea_2_Cargar_LCD:
            LDAA 1,Y+
            CMPA #EOM
            BEQ retornar_Cargar_LCD
            JSR SendData
            MOVB D40uS,Cont_Delay
            JSR Delay
            BRA linea_2_Cargar_LCD
retornar_Cargar_LCD:
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
                        ;Genera retardo para enviar informaciÃ³n a la pantalla 
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
        TST Cont_Reb    ;Prueba si valor en memoria (contador de rebotes) es 0
        BNE final_Tarea_Teclado ;si no es cero vuelva a main
        JSR MUX_TECLADO ;si es 0 vaya a subrutina

        BRSET Tecla,$FF,tecla_lista        ;Salta si valor en Tecla es FF
        BRCLR Banderas,$02,tecla_no_procesada        ;salta si bit 1 es 0
        LDAB Tecla_IN
        CMPB Tecla      ;compara el valor de Tecla_IN con Tecla
        BEQ tecla_procesada        ;salta si son iguales
        MOVB #$FF,Tecla         ;si son diferentes tomamos lectura como error
        MOVB #$FF,Tecla_IN      ;borramos ambos valores
        BCLR Banderas,$03       ;borramos banderas

final_Tarea_Teclado:
        RTS     ;Return Subroutine

tecla_procesada:
        BSET Banderas,$01       ;tecla lista en 1
        BRA final_Tarea_Teclado

tecla_no_procesada:
        BSET Banderas,$02       ;marcar tecla como ahora procesada
        MOVB Tecla,Tecla_IN
        MOVB #10,Cont_Reb       ;poner el valor inmediato decimal 10 en Cont_Reb
        BRA final_Tarea_Teclado

tecla_lista:
        BRCLR Banderas,$01,final_Tarea_Teclado  ;Salta si bit 0 (TCL_Lista) es 0
        BCLR Banderas,$03       ;Borra dos ultimos bits de mem, 2 ultimas banderas
        JSR FORMAR_ARRAY
        BRA final_Tarea_Teclado 
         
                        ;*******************************************************
MUX_TECLADO:            ;                  Subrutina MUX_TECLADO
                        ;*******************************************************
                        ;Lee teclado matricial barriendo filas con 0 y viendo 
                        ;que bit del nibbble bajo de PORTA se hace 0
                        ;*******************************************************
 
        CLRB        ;borra B
        LDAA #12        ;pone el numero decimal 12 en A se usara como contador
        MOVB #$EF,Patron        ;pone $EF en dir dada por Patron

barrido_teclas:
        MOVB Patron,PORTA       ;pone Patron en Puerto A
        BRCLR PORTA,$02,presionada      ;Branch if Cleared, salta si bit 1 de
                                        ;PORTA es 0
        INCB
        NOP
        NOP
        NOP
        NOP                             ;No Operation para retener CPU un ciclo
                                     ;esperando que se descargue capacitancia
                                     ;en lineas de botones para leer mejor

        BRCLR PORTA,$04,presionada
        INCB
        NOP
        NOP
        NOP
        NOP
        BRCLR PORTA,$08,presionada      ;salta si bit 3 es 0
        INCB
        NOP
        NOP
        NOP

        NOP
        LSL Patron      ;logical shift left Patron
        BSET Patron,$0F ;pone en 1 nibble inferior
;        MOVB Patron,PORTA

        CBA     ;Compara contenido de A con B
        BNE barrido_teclas      ;salta si no se ha llegado a 12
        MOVB #$FF,Tecla  ;borrar tecla pues no se presiono o ya se libero
        BRA final_MUX_TECLADO

presionada:
        LDX #Teclas     ;pone en X el valor inmediato Teclas
        LDAA B,X        ;poner en A el valor dado por el contenido de la direccion
                        ;en X mas el valor de B Indexado por acumulador
        STAA Tecla

final_MUX_TECLADO:
        RTS     ;Return Subroutine

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
      
        LDAB Cont_TCL
        CMPB MAX_TCL
        BEQ array_lleno ;salte si ya se leyeron todas las teclas posibles
        TST Cont_TCL
        BNE ni_primera_ni_ultima        ;salte si no es la primera tecla
        ;Es la primera tecla:
        LDAB #$0B             ;compara la tecla con Borrar o enter
        CMPB Tecla_IN         ;si son esas no hace nada y retorna
        BEQ final_FORMAR_ARRAY
        LDAB #$0E
        CMPB Tecla_IN
        BEQ final_FORMAR_ARRAY
        ;si es primera tecla pero no borrar ni enter:
        MOVB Tecla_IN,Num_Array        ;mueve la tecla al arreglo
        INC Cont_TCL    ;Incrementa contador de teclas guardadas

final_FORMAR_ARRAY:
        BSET Tecla_IN,$FF
        RTS     ;Return Subroutine

array_lleno:         ;si es borrar borra ultimo valor, si es enter termina
        LDAB #$0B
        CMPB Tecla_IN
        BEQ tecla_borrar
        LDAB #$0E
        CMPB Tecla_IN
        BEQ tecla_enter
        BRA final_FORMAR_ARRAY

tecla_enter:
        CLR Cont_TCL        ;importante: borramos cuenta para rellenar al volver a entrar
        BSET Banderas,$04       ;pone bit Array_OK
        BRA final_FORMAR_ARRAY

tecla_borrar:                   ;borra ultimo valor
        LDX #Num_Array
        DEC Cont_TCL
        LDAB Cont_TCL
        MOVB #$FF,B,X    ;guarda $FF en posicion dada por val en X + A, off acc
        BRA final_FORMAR_ARRAY

ni_primera_ni_ultima:
        LDAB #$0B
        CMPB Tecla_IN
        BEQ tecla_borrar
        LDAB #$0E
        CMPB Tecla_IN
        BEQ tecla_enter
        LDAB Cont_TCL
        LDX #Num_Array
        MOVB Tecla_IN,B,X       ;mueve valor en Tecla_IN a pos dada por val en X + B
        INC Cont_TCL    ;Incrementa contador de teclas guardadas
        BRA final_FORMAR_ARRAY      