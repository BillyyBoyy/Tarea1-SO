[org 0x7E00]
[bits 16]

%define SCREEN 0xB800   ; Memoria de video

main:
    ; Inicializar pantalla
    mov ax, SCREEN
    mov es, ax
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
generar_cadena:
    mov si, cadena
    mov cx, 4
    .generar:
        rdtsc                   ; Semilla aleatoria basada en el temporizador
        xor dx, dx
        mov bx, 36              ; 26 letras + 10 números
        div bx
        cmp dl, 26
        jl .letra
        add dl, '0' - 26        ; Números (0-9)
        jmp .guardar
    .letra:
        add dl, 'a'             ; Letras (a-z)
    .guardar:
        mov [si], dl
        inc si
        loop .generar
    mov byte [si], 0           ; Terminar cadena con null
    ret

;-------------------------------------------------
; Mostrar menú con la cadena generada
mostrar_menu:
    mov si, mensaje_bienvenida
    call imprimir
    mov si, cadena
    call imprimir
    mov si, nueva_linea
    call imprimir
    ret

;-------------------------------------------------
; Pedir y validar respuestas del usuario
pedir_respuestas:
    mov cx, 4
    mov si, cadena
    mov byte [bandera_correcto], 1  ; Inicializar bandera como "correcto"
    .preguntar:
        push cx
        mov ah, 0x0E           ; Imprimir carácter
        mov al, [si]
        int 0x10
        mov al, ':'
        int 0x10
        mov al, ' '
        int 0x10

        ; Leer entrada del usuario
        mov di, buffer_entrada
        call leer_entrada
        call comparar_fonetica ; Validar entrada
        jz .respuesta_correcta
        mov byte [bandera_correcto], 0  ; Marcar como incorrecto si alguna respuesta falla
    .respuesta_correcta:
        pop cx
        inc si
        loop .preguntar

    ; Verificar si todas las respuestas fueron correctas
    cmp byte [bandera_correcto], 1
    jne .fin
    inc word [puntaje]          ; Incrementar puntaje solo si todas fueron correctas
.fin:
    ret

;-------------------------------------------------
; Leer entrada del usuario
leer_entrada:
    pusha
    mov cx, 0
    .leer:
        mov ah, 0x00           ; Leer tecla
        int 0x16
        cmp al, 0x0D           ; Enter?
        je .fin
        mov [di], al           ; Guardar carácter en buffer
        inc di
        inc cx
        mov ah, 0x0E           ; Imprimir carácter
        int 0x10
        jmp .leer
    .fin:
    mov byte [di], 0           ; Terminar cadena con null
    popa
    ret

;-------------------------------------------------
; Comparar entrada con fonética esperada
comparar_fonetica:
    pusha
    ; Buscar la palabra fonética del carácter en [si]
    mov al, [si]
    mov si, tabla_fonetica      ; Cargar tabla
    mov cx, 36                  ; 26 letras + 10 números

    ; Convertir AL a índice (0-35)
    cmp al, 'a'
    jl .es_numero
    sub al, 'a'                 ; Índice 0-25 para letras
    jmp .buscar
.es_numero:
    sub al, '0'                 ; Índice 26-35 para números
    add al, 26

.buscar:
    movzx bx, al
    shl bx, 1                   ; Cada entrada es 2 bytes (puntero)
    add si, bx
    mov si, [si]                ; SI ahora apunta a la palabra esperada

    ; Comparar entrada del usuario con la palabra esperada
    mov di, buffer_entrada
    call comparar_cadenas
    pushf                       ; Guardar estado de las banderas (ZF)
    
    jz .correcto

    ; Incorrecto
    mov si, msg_error
    call imprimir
    jmp .fin_impresion

.correcto:
    ; Correcto
    mov si, msg_acierto
    call imprimir

.fin_impresion:
    mov si, nueva_linea
    call imprimir
    popf                        ; Restaurar banderas (ZF)
    popa
    ret

;-------------------------------------------------
; Comparar cadenas en SI (esperada) y DI (entrada)
; Retorna ZF=1 si son iguales
comparar_cadenas:
    pusha
.ciclo:
    lodsb                       ; Cargar carácter de SI
    mov bl, [di]                ; Cargar carácter de DI
    inc di
    cmp al, bl
    jne .no_igual
    test al, al                 ; Fin de cadena?
    jz .igual
    jmp .ciclo
.no_igual:
    or al, 1                   ; ZF=0
    jmp .fin
.igual:
    xor al, al                 ; ZF=1
.fin:
    popa
    ret

;-------------------------------------------------
; Mostrar puntaje
mostrar_puntaje:
    pusha
    lea si, msg_puntaje         ; Asegurar que SI apunta a la dirección correcta
    call imprimir
    mov ax, [puntaje]
    call imprimir_numero        ; Mostrar el número del puntaje
    lea si, nueva_linea
    call imprimir
    popa
    ret

;-------------------------------------------------
; Imprimir número en AX
imprimir_numero:
    pusha
    mov cx, 0

.convertir:
    xor dx, dx
    mov bx, 10
    div bx
    add dl, '0'
    push dx
    inc cx
    test ax, ax
    jnz .convertir

.imprimir:
    pop ax
    mov ah, 0x0E
    int 0x10
    loop .imprimir

    popa
    ret

;-------------------------------------------------
; Función para imprimir cadenas
imprimir:
    .ciclo:
        lodsb
        test al, al
        jz .fin
        mov ah, 0x0E           ; Imprimir carácter
        int 0x10
        jmp .ciclo
    .fin:
    ret

;-------------------------------------------------
; Datos
mensaje_bienvenida db 'Bienvenido a MRPV!', 0x0D, 0x0A, 'Deletrea:', 0x0D, 0x0A, 0
nueva_linea db 0x0D, 0x0A, 0
cadena times 5 db 0            ; Cadena generada (4 caracteres + null)
buffer_entrada times 16 db 0   ; Buffer para entrada del usuario
puntaje dw 0                   ; Puntaje acumulado
bandera_correcto db 0          ; Bandera para rastrear si todas las respuestas son correctas

;-------------------------------------------------
; Tabla fonética
tabla_fonetica:
    ; Letras a-z
    dw fon_a, fon_b, fon_c, fon_d, fon_e, fon_f, fon_g, fon_h, fon_i
    dw fon_j, fon_k, fon_l, fon_m, fon_n, fon_o, fon_p, fon_q, fon_r
    dw fon_s, fon_t, fon_u, fon_v, fon_w, fon_x, fon_y, fon_z
    ; Números 0-9
    dw fon_0, fon_1, fon_2, fon_3, fon_4, fon_5, fon_6, fon_7, fon_8, fon_9

;-------------------------------------------------
; Palabras fonéticas
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
msg_acierto: db "1 pt",0
msg_error: db "0 pts",0
msg_puntaje: db "Puntaje total: ",0