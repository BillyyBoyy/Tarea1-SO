; Tarea1-SO

; Nombre: William Gerardo Alfaro Quiros

; Carné: 2022437996

[org 0x7E00] ; Dirección de carga

[bits 16]  ; Modo de 16 bits

%define SCREEN 0xB800   ; Memoria de video

main:
    ; Inicializar pantalla
    mov ax, SCREEN
    mov es, ax         ; ES = 0xB800 a pantalla de texto
    xor di, di

    ; Ciclo principal
    .loop:
        call generar_cadena     ; Generar cadena aleatoria de 4 caracteres
        call mostrar_menu       ; Mostrar la palabra a deletrear
        call pedir_respuestas   ; Pedir y validar respuestas
        call mostrar_puntaje    ; Mostrar puntaje
        jmp .loop               ; Repetir indefinidamente

;-------------------------------------------------
; Generar cadena aleatoria de 4 caracteres (a-z, 0-9)
; Descripcion: Genera una cadena aleatoria de 4 caracteres en la dirección de memoria 'cadena'.
; Entradas: Ninguna
; Salidas: Ninguna

generar_cadena:
    mov si, cadena             ; Puntero a la cadena
    mov cx, 4
    .generar:                 ; Generar 4 caracteres
        rdtsc                   ; Semilla aleatoria basada en el temporizador
        xor dx, dx
        mov bx, 36              ; 26 letras + 10 números
        div bx
        cmp dl, 26             ; ¿Es un número?
        jl .letra
        add dl, '0' - 26        ; Números (0-9)
        jmp .guardar           ; Guardar carácter
    .letra:
        add dl, 'a'             ; Letras (a-z)
    .guardar:
        mov [si], dl           ; Guardar carácter en cadena
        inc si
        loop .generar          ; Repetir 4 veces
    mov byte [si], 0           ; Terminar cadena con null
    ret

;-------------------------------------------------
; Mostrar menú con la cadena generada
; Descripcion: Muestra el mensaje de bienvenida y la cadena a deletrear

mostrar_menu:   ; SI apunta a la cadena a mostrar (4 caracteres + null)
    mov si, mensaje_bienvenida ; Mensaje de bienvenida
    call imprimir        ; Mostrar mensaje
    mov si, cadena           ; Cargar cadena
    call imprimir           ; Mostrar cadena
    mov si, nueva_linea     ; Nueva línea
    call imprimir
    ret     ; Retornar

;-------------------------------------------------
; Pedir y validar respuestas del usuario
; Descripcion: Pide al usuario que deletree la cadena generada y valida las respuestas
pedir_respuestas:
    mov cx, 4
    mov si, cadena          ; Cargar cadena
    .preguntar:
        push cx            ; Guardar contador
        mov ah, 0x0E           ; Imprimir carácter
        mov al, [si]
        int 0x10
        mov al, ':'           ; Dos puntos
        int 0x10             ; Imprimir
        mov al, ' '
        int 0x10              ; Espacio

        ; Leer entrada del usuario
        mov di, buffer_entrada ; Puntero a buffer
        call leer_entrada     ; Leer entrada
        call comparar_fonetica ; Validar entrada
        pop cx
        inc si
        loop .preguntar      ; Repetir 4 veces
    ret

;-------------------------------------------------
; Leer entrada del usuario
; Descripcion: Lee la entrada del usuario y la guarda en el buffer de entrada
; Entradas: DI apunta al buffer de entrada
leer_entrada:
    pusha
    mov cx, 0                 ; Contador de caracteres
    .leer:
        mov ah, 0x00           ; Leer tecla
        int 0x16
        cmp al, 0x0D           ; Enter?
        je .fin
        mov [di], al           ; Guardar carácter en buffer
        inc di                ; Avanzar puntero
        inc cx
        mov ah, 0x0E           ; Imprimir carácter
        int 0x10
        jmp .leer            ; Repetir
    .fin:
    mov byte [di], 0           ; Terminar cadena con null
    popa
    ret

;-------------------------------------------------
; Comparar entrada con fonética esperada
; Descripcion: Compara la entrada del usuario con la palabra fonética esperada
; Entradas: SI apunta a la palabra fonética esperada
comparar_fonetica:
    pusha
    ; Buscar la palabra fonética del carácter en [si]
    mov al, [si]
    mov si, tabla_fonetica      ; Cargar tabla
    mov cx, 36                  ; 26 letras + 10 números

    ; Convertir AL a índice (0-35)
    cmp al, 'a'
    jl .es_numero              ; ¿Es un número?
    sub al, 'a'                 ; Índice 0-25 para letras
    jmp .buscar
.es_numero:
    sub al, '0'                 ; Índice 26-35 para números
    add al, 26                 ; Ajustar índice

.buscar:                     ; Buscar palabra fonética
    movzx bx, al
    shl bx, 1                   ; Cada entrada es 2 bytes (puntero)
    add si, bx
    mov si, [si]                ; SI ahora apunta a la palabra esperada

    ; Comparar entrada del usuario con la palabra esperada
    mov di, buffer_entrada     ; Puntero a entrada
    call comparar_cadenas      ; Comparar cadenas
    jz .correcto              ; Son iguales

    ; Incorrecto: mostrar 0 pts
    mov si, msg_error
    call imprimir
    jmp .fin

.correcto:
    ; Correcto: mostrar 1 pt
    mov si, msg_acierto
    call imprimir
    inc word [puntaje]          ; Incrementar puntaje

.fin:
    mov si, nueva_linea        ; Nueva línea
    call imprimir
    popa                       ; Restaurar registros
    ret

;-------------------------------------------------
; Comparar cadenas en SI (esperada) y DI (entrada)
; Retorna ZF=1 si son iguales
; Descripcion: Compara dos cadenas y retorna ZF=1 si son iguales, ZF=0 si no son iguales
; Entradas: SI apunta a la cadena esperada, DI apunta a la cadena de entrada
comparar_cadenas:
    pusha
.ciclo:
    lodsb                       ; Cargar carácter de SI
    mov bl, [di]                ; Cargar carácter de DI
    inc di
    cmp al, bl                 ; Comparar
    jne .no_igual
    test al, al                 ; Fin de cadena?
    jz .igual
    jmp .ciclo                ; Repetir
.no_igual:
    or al, 1                   ; ZF=0
    jmp .fin
.igual:                 ; Llegó al final de ambas cadenas
    xor al, al                 ; ZF=1
.fin: 
    popa
    ret

;-------------------------------------------------
; Mostrar puntaje
; Descripcion: Muestra el puntaje acumulado
; Entradas: AX = puntaje

mostrar_puntaje:
    pusha                      ; Guardar registros
    lea si, msg_puntaje         ; Asegurar que SI apunta a la dirección correcta
    call imprimir
    mov ax, [puntaje]         ; Cargar puntaje
    call imprimir_numero        ; Mostrar el número del puntaje
    lea si, nueva_linea
    call imprimir             ; Nueva línea
    popa
    ret

;-------------------------------------------------
; Imprimir número en AX
; Descripcion: Imprime un número en pantalla
; Entradas: AX = número a imprimir
imprimir_numero:             ; AX = número a imprimir
    pusha                     ; Guardar registros
    mov cx, 0

.convertir:                ; Convertir dígitos a ASCII
    xor dx, dx
    mov bx, 10              ; Divisor
    div bx
    add dl, '0'            ; Convertir a ASCII
    push dx
    inc cx                ; Contador de dígitos
    test ax, ax
    jnz .convertir        ; Repetir si hay más dígitos

.imprimir:
    pop ax               ; Sacar dígito de la pila
    mov ah, 0x0E          ; Imprimir carácter
    int 0x10
    loop .imprimir       ; Repetir para todos los dígitos

    popa
    ret

;-------------------------------------------------
; Función para imprimir cadenas
; Descripcion: Imprime una cadena en pantalla
; Entradas: SI apunta a la cadena a imprimir
imprimir:
    .ciclo:                ; Imprimir cadena en SI
        lodsb
        test al, al          ; ¿Fin de cadena?
        jz .fin
        mov ah, 0x0E           ; Imprimir carácter
        int 0x10
        jmp .ciclo          ; Repetir
    .fin: 
    ret

;-------------------------------------------------
; Datos
mensaje_bienvenida db 'Bienvenido a MRPV!', 0x0D, 0x0A, 'Deletrea:', 0x0D, 0x0A, 0
nueva_linea db 0x0D, 0x0A, 0
cadena times 5 db 0            ; Cadena generada (4 caracteres + null).
buffer_entrada times 16 db 0   ; Buffer para entrada del usuario
puntaje dw 0                   ; Puntaje acumulado

;-------------------------------------------------
; Tabla fonética
; Descripción: Tabla de palabras fonéticas para letras y números. 
; Cada entrada es un puntero a una cadena terminada en null
tabla_fonetica:
    ; Letras a-z
    dw fon_a, fon_b, fon_c, fon_d, fon_e, fon_f, fon_g, fon_h, fon_i
    dw fon_j, fon_k, fon_l, fon_m, fon_n, fon_o, fon_p, fon_q, fon_r
    dw fon_s, fon_t, fon_u, fon_v, fon_w, fon_x, fon_y, fon_z
    ; Números 0-9
    dw fon_0, fon_1, fon_2, fon_3, fon_4, fon_5, fon_6, fon_7, fon_8, fon_9

;-------------------------------------------------
; Palabras fonéticas
; Descripción: Palabras fonéticas para letras y números
fon_a: db "alfa",0
fon_b: db "bravo",0
fon_c: db "charlie",0
fon_d: db "delta",0
fon_e: db "echo",0
fon_f: db "foxtrot",0
fon_g: db "golf",0
fon_h: db "hotel",0
fon_i: db "india",0
fon_j: db "juliett",0
fon_k: db "kilo",0
fon_l: db "lima",0
fon_m: db "mike",0
fon_n: db "november",0
fon_o: db "oscar",0
fon_p: db "papa",0
fon_q: db "quebec",0
fon_r: db "romeo",0
fon_s: db "sierra",0
fon_t: db "tango",0
fon_u: db "uniform",0
fon_v: db "victor",0
fon_w: db "whiskey",0
fon_x: db "x-ray",0
fon_y: db "yankee",0
fon_z: db "zulu",0
fon_0: db "zero",0
fon_1: db "one",0
fon_2: db "two",0
fon_3: db "three",0
fon_4: db "four",0
fon_5: db "five",0
fon_6: db "six",0       
fon_7: db "seven",0
fon_8: db "eight",0
fon_9: db "nine",0


; Mensajes
; Cada palabra termina en null
msg_acierto: db "1 pt",0
msg_error: db "0 pts",0
msg_puntaje: db "Puntaje total: ",0

