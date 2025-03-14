# Tarea1-SO

**Repositorio de William Alfaro**  
**Carné: 2022437996**

Este repositorio contiene el código fuente y los archivos necesarios para la Tarea 1 del curso de **Principios de Sistemas Operativos**. El objetivo es desarrollar un programa en ensamblador x86 que permita comprender el proceso de arranque de un sistema operativo y enseñar el alfabeto fonético de radiotelefonía.

---

## Comandos para Compilar y Ejecutar

### 1. Compilar el código

Para compilar los archivos de ensamblador (`boot.asm` y `mrpv.asm`), utiliza los siguientes comandos:

```bash
nasm -f bin boot.asm -o boot.bin
nasm -f bin mrpv.asm -o mrpv.bin
```

### 2. Crear la imagen de disco

Para crear una imagen de disco y copiar los binarios generados, utiliza:

```bash
dd if=/dev/zero of=disk.img bs=512 count=2880
dd if=boot.bin of=disk.img conv=notrunc
dd if=mrpv.bin of=disk.img bs=512 seek=1 conv=notrunc
```

**Descripción:**
- `dd if=/dev/zero of=disk.img bs=512 count=2880`: Crea una imagen de disco vacía de 1.44 MB (tamaño de un disquete).
  - `if=/dev/zero`: Fuente de ceros para llenar la imagen.
  - `of=disk.img`: Archivo de salida.
  - `bs=512`: Tamaño de bloque (512 bytes).
  - `count=2880`: Número total de bloques (1.44 MB).

- `dd if=boot.bin of=disk.img conv=notrunc`: Copia el bootloader al primer sector.
  - `conv=notrunc`: No trunca la imagen existente.

- `dd if=mrpv.bin of=disk.img bs=512 seek=1 conv=notrunc`: Copia el programa MRPV al segundo sector.
  - `seek=1`: Salta al segundo sector.

### 3. Ejecutar en QEMU

Para ejecutar la imagen de disco en QEMU, ejecuta:

```bash
qemu-system-x86_64 -drive format=raw,file=disk.img
```

**Descripción:**
- `qemu-system-x86_64`: Inicia el emulador QEMU para arquitectura x86_64.
- `-drive format=raw,file=disk.img`: Indica la imagen de disco como unidad de arranque.
  - `format=raw`: Formato binario crudo.
  - `file=disk.img`: Archivo de imagen de disco.

---

## Estructura del Repositorio

```
Tarea1-SO/
│
├── .git/                # Control de versiones
├── README.md            # Instrucciones del proyecto
└── MRPV/                
    ├── boot.asm         # Código fuente del bootloader
    ├── boot.bin         # Binario del bootloader
    ├── mrpv.asm         # Código fuente del programa MRPV
    ├── mrpv.bin         # Binario del programa MRPV
    └── disk.img         # Imagen de disco

```

