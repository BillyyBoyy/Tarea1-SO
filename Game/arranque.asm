; arranque.asm - Sector de arranque MBR
bits 16
org 0x7C00

start:
    ; Inicializar registros de segmento y pila
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00      ; Pila debajo del sector de arranque

    ; Cargar segundo sector (logica.bin) en 0x7E00
    mov ah, 0x02        ; Función de lectura de disco
    mov al, 1           ; Número de sectores a leer
    mov ch, 0           ; Cilindro 0
    mov dh, 0           ; Cabeza 0
    mov cl, 2           ; Sector 2 (primer sector es el MBR)
    mov bx, 0x7E00      ; Dirección de carga
    int 0x13            ; Interrupción del disco

    jmp 0x7E00          ; Saltar al programa principal

    ; Rellenar el sector hasta 512 bytes
    times 510-($-$$) db 0
    dw 0xAA55           ; Firma de sector de arranque