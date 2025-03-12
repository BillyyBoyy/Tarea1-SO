bits 16
org 0x7E00

start:
    mov ax, 0x03    ; Modo texto 80x25
    int 0x10

    ; Inicializar generador aleatorio con semilla
    mov ax, [0x046C] ; Semilla del timer del BIOS
    mov [rand_seed], ax

game_loop:
    ; Mostrar mensaje de bienvenida
    mov si, bienvenida
    call imprimir

    ; Generar cadena aleatoria de 4 caracteres
    mov di, cadena
    call generar_cadena

    ; Mostrar cadena a deletrear
    mov si, cadena
    call imprimir_cadena

    ; Leer y verificar respuestas
    call verificar_respuestas

    ; Repetir indefinidamente
    jmp game_loop

; --- Funciones auxiliares ---
imprimir:
    lodsb
    or al, al
    jz .fin
    mov ah, 0x0E
    int 0x10
    jmp imprimir
.fin:
    ret

generar_cadena:
    pusha
    mov cx, 4
.generar:
    call rand
    mov [di], al
    inc di
    loop .generar
    mov byte [di], 0
    popa
    ret

verificar_respuestas:
    pusha
    mov cx, 4                ; 4 caracteres a verificar
    mov si, cadena            ; Cadena generada
    xor di, di               ; Contador de aciertos

.check_loop:
    lodsb                    ; Cargar caracter actual (AL)
    mov [char_actual], al    ; Guardar caracter para mostrar
    
    ; Mostrar "X: " donde X es el caracter
    mov ah, 0x0E
    mov al, [char_actual]
    int 0x10
    mov al, ':'
    int 0x10
    mov al, ' '
    int 0x10

    ; Leer entrada del usuario
    call leer_entrada        ; Resultado en entrada_usuario
    
    ; Buscar palabra correcta en tabla fonética
    call buscar_palabra      ; Resultado en si
    
    ; Comparar entrada con la palabra correcta
    call comparar_cadenas
    jne .incorrecto
    
    inc di                  ; Incrementar aciertos
    jmp .continuar
    
.incorrecto:
    ; Mostrar palabra correcta
    mov si, palabra_correcta
    call imprimir
    mov si, newline
    call imprimir
    jmp .continuar
    
.continuar:
    loop .check_loop
    
    ; Verificar si todos fueron correctos
    cmp di, 4
    je .todas_correctas
    
    ; Mensaje de error
    mov si, mensaje_error
    call imprimir
    jmp .fin

.todas_correctas:
    mov si, mensaje_acierto
    call imprimir

.fin:
    popa
    ret

leer_entrada:
    pusha
    mov di, entrada_usuario
    mov cx, 0
    
.read_char:
    mov ah, 0x00
    int 0x16                ; Esperar tecla
    
    cmp al, 0x0D            ; Verificar Enter
    je .fin_lectura
    
    mov [di], al            ; Guardar caracter
    inc di
    inc cx
    
    ; Echo a pantalla
    mov ah, 0x0E
    int 0x10
    
    jmp .read_char

.fin_lectura:
    mov byte [di], 0        ; Terminar cadena
    popa
    ret

buscar_palabra:
    push ax
    mov si, fonetico
    
.buscar_loop:
    cmp byte [si], 0        ; Fin de tabla
    je .no_encontrado
    
    mov al, [char_actual]
    cmp [si], al
    je .encontrado
    
    ; Saltar a siguiente entrada
    inc si
    jmp .saltar_palabra
    
.saltar_palabra:
    cmp byte [si], 0
    jne .saltar_palabra
    inc si
    jmp .buscar_loop

.encontrado:
    inc si                 ; Apuntar al inicio de la palabra
    mov [palabra_correcta], si
    pop ax
    ret

.no_encontrado:
    ; Manejar error (nunca debería ocurrir)
    pop ax
    ret

comparar_cadenas:
    pusha
    mov si, [palabra_correcta]
    mov di, entrada_usuario
    
.compare_loop:
    cmpsb
    jne .diferente
    
    cmp byte [si-1], 0
    jne .compare_loop
    
    ; Cadenas iguales
    popa
    xor ax, ax            ; Set ZF=1
    ret

.diferente:
    popa
    or ax, 1              ; Clear ZF
    ret

imprimir_cadena:
    ; Imprime la cadena generada con espacios
    pusha
    mov cx, 4
    mov si, cadena
.loop:
    lodsb
    mov ah, 0x0E
    int 0x10
    mov al, ' '
    int 0x10
    loop .loop
    mov si, newline
    call imprimir
    popa
    ret

rand:
    ; Genera caracteres a-z (97-122) o 0-9 (48-57)
    mov ax, [rand_seed]
    mov dx, 0x4ECF
    mul dx
    inc ax
    mov [rand_seed], ax

    ; Mapear a 36 caracteres (26 letras + 10 números)
    xor dx, dx
    mov bx, 36
    div bx          ; DX = 0-35

    cmp dx, 26
    jl .letra
    add dl, 22      ; 48-57 (0-9)
    jmp .fin
.letra:
    add dl, 97      ; a-z
.fin:
    mov al, dl
    ret

; --- Datos ---
bienvenida db "Bienvenido a MRPV!", 0x0D, 0x0A, "Deletrea:", 0x0D, 0x0A, 0
cadena times 5 db 0
entrada_usuario times 20 db 0
char_actual db 0
palabra_correcta dw 0
rand_seed dw 0
mensaje_acierto db "¡Has acertado todas!", 0x0D, 0x0A, 0
mensaje_error db "¡Te has equivocado!", 0x0D, 0x0A, 0
newline db 0x0D, 0x0A, 0

; Tabla fonética completa (a-z, 0-9)
fonetico:
    db 'a', "alfa", 0
    db 'b', "bravo", 0
    db 'c', "charlie", 0
    db 'd', "delta", 0
    db 'e', "echo", 0
    db 'f', "foxtrot", 0
    db 'g', "golf", 0
    db 'h', "hotel", 0
    db 'i', "india", 0
    db 'j', "juliett", 0
    db 'k', "kilo", 0
    db 'l', "lima", 0
    db 'm', "mike", 0
    db 'n', "november", 0
    db 'o', "oscar", 0
    db 'p', "papa", 0
    db 'q', "quebec", 0
    db 'r', "romeo", 0
    db 's', "sierra", 0
    db 't', "tango", 0
    db 'u', "uniform", 0
    db 'v', "victor", 0
    db 'w', "whiskey", 0
    db 'x', "x-ray", 0
    db 'y', "yankee", 0
    db 'z', "zulu", 0
    db '0', "zero", 0
    db '1', "one", 0
    db '2', "two", 0
    db '3', "tree", 0
    db '4', "fower", 0
    db '5', "fife", 0
    db '6', "six", 0
    db '7', "seven", 0
    db '8', "eight", 0
    db '9', "niner", 0
    db 0  ; Fin de tabla