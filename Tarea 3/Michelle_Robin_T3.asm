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
;       DESCRIPCION:    CODIGO QUE SE ENCARGA DE LLAMAR 3 SUBRUTINAS,
;                       PARA OBTENER LA RAIZ CUADRADA DE LOS NUMEROS
;                       CON RAIZ ENTERA PRESENTES EN LA TABLA DATOS
;
;
;*******************************************************************************
;                             Estructuras de datos
;*******************************************************************************

CR:             EQU     $0D
LF:             EQU     $0A
PrintF:         EQU     $EE88
GETCHAR:        EQU     $EE84
FINMSG:         EQU     $0
CANT:           EQU     $1001
LONG:           EQU     $1000
CONT:           EQU     $1002
ENTERO:         EQU     $1010
DATOS:          EQU     $1020
CUAD:           EQU     $1030
TEMP_RAIZ:      EQU     $1122
SP_TEMP         EQU     $1124
TEMP:           EQU     $1126
TEMP2:          EQU     $1128

        ORG     $1130
MSG1    FCC "Ingrese el valor de CANT (entre 1 y 99): "
        ;db CR,CR,LF
        db FINMSG
MSG2    FCC "%d"
        ;db CR,CR,LF
        db FINMSG
MSG3    FCC "El valor: 0 no es un valor valido"
        db CR,CR,LF
        db FINMSG
MSG4    FCC "CANT ingresado es: %d"
        db CR,CR,LF
        db FINMSG
MSG5    db CR,LF
        FCC "CANTIDAD DE NUMEROS ENCONTRADOS: %d"
        db CR,LF
        db FINMSG
MSG6    db CR,CR
        FCC "ENTERO: "
        db FINMSG
MSG7    FCC "%d, "
        db FINMSG
MSG8    FCC "%d";x hex, c char, i o d int, o octal, u decimal sin signo
        db CR,LF
        db FINMSG

        ORG CANT
        db 0

        ORG CONT
        db 0

        ORG     ENTERO
        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

        ORG LONG
        db 15   ; el profe solo me da espacio para 16 numeros en DATOS
                ;ingresar CANT mayor a eso dara problemas

        ORG CUAD
        db 4, 9, 16, 25, 36, 49, 64, 81, 100, 121, 144, 169, 196, 225

        ORG     DATOS
;        db 0, 4, 30, 24, 67, 36, 69, 77, 49, 100, 255, 23, 144, 9, 225        
;        db 7, 88, 128, 133, 155, 167, 146, 29, 237, 19, 188, 224, 49, 0, 43
         db 16, 88, 128, 121, 144, 167, 146, 201, 237, 169, 196, 225, 49, 0, 43
;        db 0,0,0,0,0,0,0,0,0,0,0,0,0,16,0,0,

;*******************************************************************************


;*******************************************************************************
;                             PROGRAMA PRINCIPAL
;*******************************************************************************

                ORG     $2000
        CLR CONT
        LDS #$3BFF      ;coloca el SP en la posicion mas alta posible dentro en RAM
        JSR LEER_CANT
        JSR BUSCAR
        JSR Print_RESULT

        BRA *

                        ;*******************************************************
LEER_CANT:              ;                          SUBRUTINA
                        ;*******************************************************
                        ;Subrutina que lee un numeros de dos digitos de terminal
                        ;*******************************************************
        STS SP_TEMP
inicio_leer:
        LDX #$0         ;pone X en 0 para usarlo en direccionamiento indexado
                        ;por acumulador m�s adelante
        LDD #MSG1       ;Pone la direcci�n de memoria donde se encuentra el
                        ;arreglo constante de caracteres a usar en PrintF
        JSR [PrintF,X]  ;Jump SubRoutine salta a la direcci�n dada por 0 + $EE88

        LDX #$0
decenas:
        JSR [GETCHAR,X] ;llama a subrutina en $EE84 que lee un caracter de la terminal

        SUBB #$30       ;Resta $30 de B y guarda en B
        CMPB #9         ;Comapra B con 9, este n�mero est� en decimal
        BHI decenas 	;Salta si valor en B es mayor a 9
        CMPB #0         ;Compara B con0
        BLO decenas 	;Salta si valor en B es menor a 0
        STAB TEMP       ;guarda B en direcci�n TEMP
        PSHD    	;Hay que usar PSHD
        LDX #0
        LDD #MSG2
        JSR [PrintF,X]
        LDAB TEMP
        LDAA #$A        ;pone 10 en A
        MUL     	;multiplica contenido de A por B guarda en D, le da el valor en
                	;decenas al primer d�gito ingresado
        STAB TEMP

unidades:      		;se realiza lo mismo para otro d�gito
        LDX #0
        JSR [GETCHAR,X]
        SUBB #$30
        CMPB #9
        BHI unidades	 ;Salta si valor en B es mayor a 9
        CMPB #0
        BLO unidades 	;Salta si valor en B es menor a 0
        ADDB TEMP
        STAB TEMP
        CMPB #0
        BNE continuar   ;si el valor en B no es 0 continua, si es 0 da error y
                        ;reinicia lectura de caracteres
        LDD #MSG3
        LDX #0
        JSR [PrintF,X]
        BRA inicio_leer

continuar:              ;notifica del n�mero final ingresado por el usuario
        LDAB TEMP
        STAB CANT
        PSHD
        LDD #MSG4
        LDX #0
        JSR [PrintF,X]
        LDS SP_TEMP
        RTS             ;vuelve a ejecucci�n en programa principal


                        ;*******************************************************
BUSCAR:                 ;                          SUBRUTINA
                        ;*******************************************************
                        ;Subrutina que busca valores de un arreglo en otro
                        ;*******************************************************

        LDAB LONG       ;pongo cantidad de datos en B
        LDX #DATOS      ;pongo direccion inicial de tabla en X
        ABX             ;sumo a dir inicial cantidad de datos, X barrera DATOS
        INX
        STX TEMP        ;guardo dir final de DATOS en TEMP
        LDX #DATOS      ;pongo direccion inicial de tabla en X

recorrer:
        LDY #CUAD       ;direccion de inicial de tabla CUAD Y barrera esa tabla
        LDAB 1,X+       ;Carga el valor en la posici�n dada por X luega incrementa
                        ;direccion en X en 1
        CPX TEMP
        BEQ fin_buscar  ;si X ya llego al final de DATOS terminal subrutina
recCuad:
        CMPB 1,Y+       ;compara dato actual con valor en CUAD
        BNE continuar_buscar   ;si no son iguales va a continuar
        PSHX            ;ponga X en pila
        PSHB
        JSR RAIZ
        PULB
        LDX #ENTERO
        LDAA CONT
        INC CONT        ;aumente contador de valores encontrados en CONT
        STAB A,X        ;guarde el valor resultante de RAIZ en posicion ENTERO +
                        ;offset dado por A
        PULX            ;Recupere valor de X antes de subrutina RAIZ
        LDAB CANT
        CMPB CONT
        BEQ fin_buscar  ;si ya encontro los CANT valores existentes terminar
        BRA recorrer

continuar_buscar:
        CPY #(CUAD+14)  ;compara Y con direccion de valor final en CUAD
        BNE recCuad     ;si no ha terminado de barrer CUAD siga recorriendolo
        BRA recorrer    ;y continue con siguiente valor en DATOS

fin_buscar:
        RTS     	;regrese al programa principal

                        ;*******************************************************
RAIZ:                   ;                          SUBRUTINA
                        ;*******************************************************
                        ;Subrutina que calcula raicez de numeros enteros
                        ;*******************************************************

        INS
        INS     ;decrementa SP dos veces para llegar a dur debajo de dir de
                ;retorno en esta dir esta B
        PULB
        CLRA
        STD TEMP_RAIZ   ;el DATO estara en TEMP
        STD TEMP2       ;t sera TEMP2
        LDX TEMP2

loop_raiz:
        LDD TEMP_RAIZ
        IDIV    ;division entera: D/X, guarda resultado en X y residuo en D
        XGDX    ;ponemos el resultado en D
        ADDD TEMP2      ;sumamos el valor actuar de r al resultado
        LSRD            ;dividimos el resultado anterior entre 2, ahora D es r
        CPD TEMP2       ;se compara r con t
        BEQ fin_raiz    ;si r y t son iguales se acaba el algoritmo babilonico
        XGDX            ;si no son iguales ponemos el resultado en X
        STX TEMP2       ;guardamos X en TEMP2 (t)
        BRA loop_raiz

fin_raiz:
        PSHB            ;B contiene el resultado pues es de 8 bits
        DES
        DES             ;Para que SP se devuelva a lugar donde estaba direcci�n
                        ;de retorno y no se pierda
        RTS

                        ;*******************************************************
PRINT_RESULT:           ;                          SUBRUTINA
                        ;*******************************************************
                        ;Subrutina que imprime valores de una posici�n de
                        ;memoria y de un arreglo
                        ;*******************************************************
        STS SP_TEMP
        LDAB CONT
        LDX #0
        CLRA            ;borrar parte alta de B
        PSHD            ;argumento de impresi�n, debe ser de 16 bits, en este
                        ;caso el valor en CONT
        LDD #MSG5       ;Texto a imprimir
        JSR [PrintF,X]
        LDD #MSG6
        LDX #0
        JSR [PrintF,X]
        LDY #ENTERO     ;y contendra posicion del arreglo arrego a imprimir
        LDAA CONT       ;usaremos A como contador de valores del arreglo impresos
        CMPA #1
        BLS ultimo
        DECA

loop:
        LDAB 1,Y+       ;cargar valor de ENTERO en B, direccionamiento indexado
                        ;de offset cte post incremento
        STY TEMP
        LDX #0
        STAA TEMP2
        CLRA
        PSHD            ;pasar como argumento valor de ENTERO a imprimir
        LDD #MSG7       ;imprimir numero con coma
        JSR [PrintF,X]
        LDAA TEMP2
        LDY TEMP
        DBNE A,loop

ultimo:
        LDAB 0,Y        ;cargar ultimo numero
        CLRA
        PSHD
        LDD #MSG8
        LDX #0
        JSR [PrintF,X]  ;imprimir ultimo numero
        LDS SP_TEMP
        RTS