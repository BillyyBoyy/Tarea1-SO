[org 0x7C00]
[bits 16]

start:
    ; Configurar segmentos
    xor ax, ax
    mov ds, ax
    mov es, ax

    ; Cargar MRPV desde el segundo sector (sector 2)
    mov ah, 0x02        ; Función de lectura de disco
    mov al, 1           ; Número de sectores a leer
    mov ch, 0           ; Cilindro 0
    mov cl, 2           ; Sector 2
    mov dh, 0           ; Cabeza 0
    mov bx, 0x7E00      ; Dirección de carga (después del bootloader)
    int 0x13            ; Interrupción de disco

    ; Verificar si la lectura fue exitosa
    jc disk_error       ; Si hay error, saltar a disk_error

    jmp 0x7E00          ; Saltar a MRPV

disk_error:
    ; Mostrar mensaje de error
    mov si, msg_disk_error
    call imprimir
    hlt                 ; Detener la ejecución

imprimir:
    .ciclo:
        lodsb           ; Cargar carácter desde SI
        test al, al     ; ¿Fin de cadena?
        jz .fin
        mov ah, 0x0E    ; Función de BIOS para imprimir carácter
        int 0x10
        jmp .ciclo
    .fin:
    ret

; Mensajes
msg_disk_error db "Error al leer el disco.", 0

times 510-($-$$) db 0   ; Rellenar con ceros
dw 0xAA55               ; Firma del bootloader