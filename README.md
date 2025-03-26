# SnakeOS

A bare-metal snake game written in assembly supporting local multiplayer. It can run on any x86
system capable of 32-bit that has a BIOS.

<video src="https://github.com/user-attachments/assets/3baf6a9e-77a2-4b0f-817d-9006ab899889"></video>

# Running
Pre-built images are available at [Releases](https://github.com/hacrvlq/snakeos/releases).
## Real Hardware
Put the disk image `snakeos.img` on an usb stick/ssd/hdd. On unix this can be achieved using `dd`:
```
dd if=snakeos.img of=<device_file> conv=fsync
```
Then boot from this device.
## Emulation
To run SnakeOS in [QEMU](https://www.qemu.org), use the following command:
```
qemu-system-i386 -drive format=raw,file=snakeos.img
```

# Building
Requires the [nasm](https://nasm.us) assembler.
```
nasm -f bin -i src src/root.asm -o snakeos.img
```
