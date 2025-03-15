; Tarea1-SO

; Nombre: William Gerardo Alfaro Quiros

; Carné: 2022437996




[org 0x7C00]
[bits 16]

start:
    ; Configurar segmentos
    xor ax, ax         ; Segmento de datos
    mov ds, ax        ; DS = 0
    mov es, ax       ; ES = 0

    ; Cargar MRPV desde el segundo sector (sector 2)
    mov ah, 0x02        ; Función de lectura de disco
    mov al, 1           ; Número de sectores a leer
    mov ch, 0           ; Cilindro 0
    mov cl, 2           ; Sector 2
    mov dh, 0           ; Cabeza 0
    mov bx, 0x7E00      ; Dirección de carga (después del bootloader)
    int 0x13            ; Interrupción de disco

    jmp 0x7E00          ; Saltar a MRPV

times 510-($-$$) db 0   ; Rellenar con ceros
dw 0xAA55               ; Firma del bootloader
