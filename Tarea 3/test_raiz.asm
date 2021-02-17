;*******************************************************************************
;       UNIVERSIDAD DE COSTA RICA       ESCUELA DE INGENIERIA ELECTRICA
;               MICROPROCESADORES IE 623  III CICLO 2020
;*******************************************************************************
;                                 TAREA 3
;*******************************************************************************
;       V1
;       AUTORES: ROBIN GONZALEZ   B43011
;                MICHELLE GUTIERREZ B43195
;
;       DESCRIPCION:    BLABLA
;
;*******************************************************************************
;                             Estructuras de datos
;*******************************************************************************

EOM             EQU     $FF
CR:             EQU     $0A
LF:             EQU     $0D
GETCHAR:        EQU     $EE84
FINMSG:         EQU     $0
SUB:            EQU     $1A     ;Borrado pantalla

                ORG $1000
Long:           dB 4
                ORG $1001
CANT:           dB 3 ;Pasar a ds
                ORG $1002
CONT:           ds 10
                ORG $1010
ENTERO:         ds 15
                ORG $1020
DATOS:          dB 2, 4, 5, 9, 36
                ORG $1030
CUAD:           dB 4, 9, 36
                ORG $1040
; Temporales para subrutina RAIZ
                ORG $1050
TempX:          ds 2
                ORG $1060
TempT:          ds 2
; Contadores para subrutina BUSCAR
                ORG $1070
Cont1:          ds 5
                ORG $1080
Cont2:          ds 5
                ORG $1090
Cont3:          ds 5


;*******************************************************************************
;                             PROGRAMA PRINCIPAL
;*******************************************************************************
                ORG $2000
                lds #$4000
                jsr BUSCAR
                ldab #36
                PSHX            ;ponga X en pila
	        PSHB
	        JSR RAIZ
	        PULB
                bra *


;*******************************************************************************
;                                     SUBRUTINAS
;*******************************************************************************
BUSCAR:         Ldaa #0
                Staa Cont1    ;Se inician los contadores en 0
                Staa Cont2
                Staa Cont3
s_buscando:     Ldaa Cont1
                Ldy #DATOS
                Ldaa a,Y ; Recorrer DATOS
                Ldab Cont2
                Ldy #CUAD
                Cmpa b,Y  ;Compara valor de DATOS con los valores de CUAD
                Lbne  no_valido
                Inc  CONT      ;Incrementar contadores
                Inc  Cont1
                Clr  Cont2
                Psha         ; Apilar dato a sacar raíz
                jsr  RAIZ     ; Llamar subrutina RAIZ
                Pula         ; Desapilar resultado
                Ldab Cont3
                Ldy  #ENTERO
                Staa b,Y ;Guardar resultado de raiz en ENTERO
                Inc  Cont3
no_valido:      Inc  Cont2
                Ldaa #3
                Cmpa Cont2
                Bne seguir
                Inc Cont1
                Clr Cont2
seguir:         Ldab Cont1
                Cmpb LONG      ;Comparar para ver si se cumple condición de parada
                Beq  terminar
                Ldab CANT
                Cmpb CONT      ;Comparar para ver si se cumple condición de parada
                Bne  s_buscando
terminar:       Rts





RAIZ:           Puly          ;Desapilar dirección de SP en Y
                Pulb          ;Desapilar dirección del valor a sacar la raíz en B (parte baja de D)
                Stab TempX    ;Guardar el valor a sacar raíz en TempX
                Ldaa #0       ;Carda 0 en A
                Staa TempT    ;Inicia en 0 TempT
Ciclo:          Cmpb TempT    ;Compara valor de r y TempT
                Bne  diferentes ;Si no son iguales salta a etiqueta
                Pshb           ;Apilo el resultado de la raíz
                Pshy           ;Apilo dirección de SP
                Rts            ; Retornar a programa principal
diferentes:     Stab TempT     ;Nuevo valor para TempT
                XGDX           ;Intercambia contenido de D(A:B) con X (R en X)
                Ldab TempX     ;Carga en B el contenido de TempX
                Idiv           ;Divide D/X, resultado en X
                XGDX           ;Resultado ahora vuelve a D (en la parte de B)
                Addb TempT     ;Suma resultado con TempT
                Asrb           ;Divide entre dos
                Bra  Ciclo

