[BITS 16]          ; Especificamos que el código es de 16 bits
[ORG 0x7C00]       ; El código se carga en la dirección 0x7C00 (MBR)

start:
    xor ax, ax     ; Limpiamos el registro AX
    mov ds, ax     ; Configuramos DS (Data Segment) a 0
    mov es, ax     ; Configuramos ES (Extra Segment) a 0

    ; Configuramos la pantalla en modo texto 80x25
    mov ah, 0x00   ; Función de BIOS para establecer modo de video
    mov al, 0x03   ; Modo de texto 80x25
    int 0x10       ; Llamada a la interrupción de BIOS

    ; Mensaje de bienvenida
    mov si, welcome_msg
    call print_string

    ; Iniciar el programa fonético
    call phonetic_program

    ; Bucle infinito para evitar que el programa termine
    jmp $

; Función para imprimir una cadena en pantalla
print_string:
    mov ah, 0x0E   ; Función de BIOS para imprimir un carácter
.print_char:
    lodsb          ; Cargamos el siguiente byte de la cadena en AL
    cmp al, 0      ; Comparamos con 0 (fin de la cadena)
    je .done       ; Si es 0, terminamos
    int 0x10       ; Llamada a la interrupción de BIOS para imprimir el carácter
    jmp .print_char ; Repetimos para el siguiente carácter
.done:
    ret            ; Retornamos de la función

; Función principal del programa fonético
phonetic_program:
    ; Generar una cadena aleatoria (en este caso, fija para simplificar)
    mov si, random_string
    call print_string

    ; Salto de línea
    call print_newline

    ; Pedir al usuario que ingrese la respuesta fonética
    mov si, prompt_msg
    call print_string

    ; Leer la entrada del usuario
    call read_input

    ; Evaluar la respuesta fonética
    call evaluate_response

    ; Mostrar la nota
    call print_newline
    mov si, score_msg
    call print_string

    ; Convertir el puntaje a una cadena de caracteres
    mov al, [score]
    call print_score

    ret

; Función para leer la entrada del usuario
read_input:
    mov di, user_input
.read_loop:
    mov ah, 0x00   ; Función de BIOS para leer un carácter
    int 0x16       ; Llamada a la interrupción de BIOS
    cmp al, 0x0D   ; Verificar si es Enter (fin de la entrada)
    je .done
    stosb          ; Almacenar el carácter en user_input
    mov ah, 0x0E   ; Imprimir el carácter ingresado
    int 0x10
    jmp .read_loop
.done:
    mov al, 0      ; Terminar la cadena con un byte nulo
    stosb
    ret

; Función para evaluar la respuesta fonética del usuario
evaluate_response:
    mov si, phonetic_responseA  ; Respuesta fonética correcta
    mov di, user_input         ; Entrada del usuario
.compare_loop:
    lodsb                     ; Cargar un carácter de la respuesta correcta
    scasb                     ; Comparar con la entrada del usuario
    jne .incorrect            ; Si no coincide, respuesta incorrecta
    cmp al, 0                 ; Fin de la cadena
    jne .compare_loop         ; Repetir hasta el final
.correct:
    add byte [score], 10      ; Puntaje perfecto
    ret
.incorrect:
    mov byte [score], 0       ; Puntaje 0
    ret

; Función para imprimir un salto de línea
print_newline:
    mov ah, 0x0E
    mov al, 0x0D   ; Retorno de carro
    int 0x10
    mov al, 0x0A   ; Salto de línea
    int 0x10
    ret

; Función para imprimir el puntaje como una cadena de caracteres
print_score:
    cmp al, 10
    je .print_10
    add al, '0'    ; Convertir el número a ASCII
    mov ah, 0x0E
    int 0x10
    ret
.print_10:
    mov al, '1'    ; Imprimir '1'
    mov ah, 0x0E
    int 0x10
    mov al, '0'    ; Imprimir '0'
    mov ah, 0x0E
    int 0x10
    ret

; Mensajes
welcome_msg db 'Bienvenido al programa MRPV!', 0x0D, 0x0A, 0
random_string db 'Cadena a deletrear: A', 0x0D, 0x0A, 0
prompt_msg db 'Deletrea la cadena foneticamente (ejemplo: Alfa Bravo Charlie):', 0x0D, 0x0A, 0
score_msg db 'Tu puntaje es: ', 0

; Respuesta fonética correcta
phonetic_responseA db 'Alfa', 0
phonetic_responseB db 'Beta', 0

; Variables
user_input times 20 db 0  ; Almacenar la entrada del usuario
score db 0                ; Almacenar el puntaje

; Rellenamos el resto del sector con ceros
times 510-($-$$) db 0

; Firmware del MBR (0xAA55)
dw 0xAA55