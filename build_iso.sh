#!/usr/bin/env bash
set -euo pipefail

echo "=== Building Interaktiv OS ISO ==="

BUILD_DIR="/tmp/interaktiv_os_build"
ISO_DIR="$BUILD_DIR/iso"
INITRD_DIR="$BUILD_DIR/initrd"
OUTPUT_ISO="interactive-os.iso"

rm -rf "$BUILD_DIR"
mkdir -p "$ISO_DIR/isolinux"
mkdir -p "$INITRD_DIR"/{bin,sbin,etc,proc,sys,dev,mnt,tmp,usr/bin,usr/sbin,lib,lib64}

# 1. Install BusyBox in initrd
echo "Installing BusyBox..."
BUSYBOX_BIN=$(which busybox || echo "/usr/bin/busybox")
cp "$BUSYBOX_BIN" "$INITRD_DIR/bin/busybox"
chmod +x "$INITRD_DIR/bin/busybox"
for applet in $("$INITRD_DIR/bin/busybox" --list); do
    ln -s /bin/busybox "$INITRD_DIR/bin/$applet" 2>/dev/null || true
done

# 2. Copy Python and essential dynamic libraries to initrd
echo "Copying Python and dependencies..."
cp /usr/bin/python3 "$INITRD_DIR/bin/python3"
ln -s python3 "$INITRD_DIR/bin/python"

# Function to copy shared library dependencies
copy_deps() {
    local bin="$1"
    for lib in $(ldd "$bin" | grep -o '/lib[^ ]*'); do
        if [ -f "$lib" ]; then
            local dir
            dir=$(dirname "$lib")
            mkdir -p "$INITRD_DIR$dir"
            cp -L "$lib" "$INITRD_DIR$lib" 2>/dev/null || true
        fi
    done
}

copy_deps /usr/bin/python3
copy_deps "$BUSYBOX_BIN"

# Copy python stdlib modules
PY_VER=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
PY_LIB_DIR="/usr/lib/python${PY_VER}"
PY_DEST_DIR="$INITRD_DIR/usr/lib/python${PY_VER}"
mkdir -p "$PY_DEST_DIR"

# Copy complete python stdlib directory
if [ -d "$PY_LIB_DIR" ]; then
    cp -r "$PY_LIB_DIR"/* "$PY_DEST_DIR/"
fi

# Copy python binary extension modules (.so) dependencies
if [ -d "$PY_DEST_DIR/lib-dynload" ]; then
    for so in "$PY_DEST_DIR/lib-dynload"/*.so; do
        if [ -f "$so" ]; then copy_deps "$so"; fi
    done
fi

# Copy dynamic linker
cp -L /lib64/ld-linux-x86-64.so.2 "$INITRD_DIR/lib64/" 2>/dev/null || true

# 3. Create Interaktiv OS Desktop Python Application inside initrd
cat << 'EOF' > "$INITRD_DIR/bin/interactive_os_desktop.py"
#!/usr/bin/env python3
import sys
import os
import time

def clear_screen():
    print("\033[H\033[J", end="")

def print_header():
    print("==========================================================================")
    print("                      INTERAKTIV OS (Interactive OS)                      ")
    print("           Site: https://schmiedleander.wixsite.com/interactive-os        ")
    print("==========================================================================")
    print(" Welcome to the Interactive OS Desktop Simulator local environment!")
    print(" JS/JSX Engine | Modular Architecture | Real-Time OS Simulation")
    print("--------------------------------------------------------------------------")

def process_manager():
    clear_screen()
    print_header()
    print("[ PROZESSVERWALTUNG / PROCESS MANAGER ]")
    print("PID   NAME              STATUS      CPU %   MEM (MB)")
    print("--------------------------------------------------")
    print("1     kernel_core       RUNNING     0.1%    12.4 MB")
    print("2     js_jsx_engine     ACTIVE      1.2%    45.8 MB")
    print("3     desktop_ui        RUNNING     0.5%    28.1 MB")
    print("4     sim_env_01        IDLE        0.0%     8.2 MB")
    print("--------------------------------------------------")
    input("\nPress ENTER to return to Main Menu...")

def system_resources():
    clear_screen()
    print_header()
    print("[ SYSTEMRESSOURCEN / SYSTEM RESOURCES ]")
    print("CPU Architecture : 64-Bit Multi-Core Simulator Engine")
    print("RAM Memory       : 8192 MB Allocated [Used: 94.5 MB / 8192 MB]")
    print("Storage          : 20 GB Virtual NVMe / SSD Space")
    print("Graphics         : Interactive JS/JSX Canvas Engine (1080p compatible)")
    print("OS Core          : Interaktiv OS Live v1.0.0")
    print("--------------------------------------------------")
    input("\nPress ENTER to return to Main Menu...")

def file_manager():
    clear_screen()
    print_header()
    print("[ DATEIMANAGEMENT / FILE MANAGER ]")
    print("Directory: /")
    print("├── bin/")
    print("├── system/")
    print("│   ├── core_tech.js")
    print("│   └── jsx_simulator.js")
    print("├── user/")
    print("│   └── desktop_config.json")
    print("└── README.txt")
    print("--------------------------------------------------")
    input("\nPress ENTER to return to Main Menu...")

def system_settings():
    clear_screen()
    print_header()
    print("[ SYSTEMEINSTELLUNGEN / SYSTEM SETTINGS ]")
    print("1. Display Theme    : Futuristic Dark Mode (Default)")
    print("2. Language         : Deutsch / English")
    print("3. Simulation Speed : Real-Time (1.0x)")
    print("4. Network Status   : Sandbox Local Loopback (Online)")
    print("--------------------------------------------------")
    input("\nPress ENTER to return to Main Menu...")

def shell():
    clear_screen()
    print_header()
    print("[ INTERAKTIV OS SHELL / CLI SIMULATOR ]")
    print("Type 'help', 'info', or 'exit' to return to menu.\n")
    while True:
        try:
            cmd = input("interaktiv-os@desktop:~$ ").strip()
        except (EOFError, KeyboardInterrupt):
            break
        if cmd in ["exit", "quit"]:
            break
        elif cmd == "help":
            print("Available commands: help, info, clear, status, sim, exit")
        elif cmd == "info":
            print("Interaktiv OS Simulator v1.0 - JS/JSX Powered Desktop Environment")
        elif cmd == "clear":
            clear_screen()
            print_header()
        elif cmd == "status":
            print("Status: All Core Tech modules running normally.")
        elif cmd == "sim":
            print("Starting SIM_ENV_01 real-time simulation... OK!")
        elif cmd:
            print(f"Command execution simulated for: {cmd}")

def main():
    while True:
        clear_screen()
        print_header()
        print(" [1] Dateimanagement (File Manager)")
        print(" [2] Systemeinstellungen (System Settings)")
        print(" [3] Prozessverwaltung (Process Manager)")
        print(" [4] Systemressourcen (System Resources)")
        print(" [5] Interaktiv OS Shell / Simulator Terminal")
        print(" [6] Neustart / Reboot")
        print(" [7] Beenden / Shutdown")
        print("--------------------------------------------------------------------------")
        choice = input(" Select option [1-7]: ").strip()

        if choice == "1":
            file_manager()
        elif choice == "2":
            system_settings()
        elif choice == "3":
            process_manager()
        elif choice == "4":
            system_resources()
        elif choice == "5":
            shell()
        elif choice == "6":
            print("\nRebooting Interaktiv OS...")
            time.sleep(1)
            os.system("reboot -f")
            sys.exit(0)
        elif choice == "7":
            print("\nPowering off Interaktiv OS...")
            time.sleep(1)
            os.system("poweroff -f")
            sys.exit(0)

if __name__ == "__main__":
    main()
EOF
chmod +x "$INITRD_DIR/bin/interactive_os_desktop.py"

# 4. Create Init script inside initrd
cat << 'EOF' > "$INITRD_DIR/init"
#!/bin/busybox sh

# Mount essential file systems
/bin/mount -t proc proc /proc
/bin/mount -t sysfs sysfs /sys
/bin/mount -t devtmpfs devtmpfs /dev

# Set up terminal and environment variables
export PATH=/bin:/sbin:/usr/bin:/usr/sbin
export HOME=/root
export TERM=linux

clear
echo "========================================================="
echo "   Booting Interaktiv OS (https://schmiedleander.wixsite.com/interactive-os)..."
echo "========================================================="
sleep 1

# Launch Interaktiv OS Desktop UI
while true; do
    if [ -f /bin/python3 ]; then
        echo "Starting Python desktop application..."
        /bin/python3 /bin/interactive_os_desktop.py 2>&1
    else
        echo "Launching fallback shell..."
        /bin/sh
    fi
    echo "Restarting Interaktiv OS Desktop UI..."
    sleep 2
done
EOF
chmod +x "$INITRD_DIR/init"

# 5. Pack Initramfs
echo "Packing initramfs..."
(cd "$INITRD_DIR" && find . -print0 | cpio --null --create --format=newc | gzip -9) > "$ISO_DIR/initrd.img"

# 6. Copy Linux Kernel dynamically
echo "Copying Kernel..."
KERNEL_IMAGE=""
if [ -f "/boot/vmlinuz-$(uname -r)" ]; then
    KERNEL_IMAGE="/boot/vmlinuz-$(uname -r)"
elif [ -f "/boot/vmlinuz" ]; then
    KERNEL_IMAGE="/boot/vmlinuz"
else
    KERNEL_IMAGE=$(ls -1 /boot/vmlinuz* 2>/dev/null | head -n 1)
fi

if [ -z "$KERNEL_IMAGE" ] || [ ! -f "$KERNEL_IMAGE" ]; then
    echo "Error: Kernel image not found in /boot" >&2
    exit 1
fi

echo "Using kernel image: $KERNEL_IMAGE"
cp "$KERNEL_IMAGE" "$ISO_DIR/vmlinuz"

# 7. Configure ISOLINUX Bootloader
echo "Configuring ISOLINUX..."
cp /usr/lib/ISOLINUX/isolinux.bin "$ISO_DIR/isolinux/"
cp /usr/lib/syslinux/modules/bios/ldlinux.c32 "$ISO_DIR/isolinux/" 2>/dev/null || true
cp /usr/lib/syslinux/modules/bios/libcom32.c32 "$ISO_DIR/isolinux/" 2>/dev/null || true
cp /usr/lib/syslinux/modules/bios/libutil.c32 "$ISO_DIR/isolinux/" 2>/dev/null || true
cp /usr/lib/syslinux/modules/bios/vesamenu.c32 "$ISO_DIR/isolinux/" 2>/dev/null || true

cat << 'EOF' > "$ISO_DIR/isolinux/isolinux.cfg"
DEFAULT interaktiv
PROMPT 0
TIMEOUT 1

LABEL interaktiv
    MENU LABEL Start Interaktiv OS Live Desktop
    KERNEL /vmlinuz
    INITRD /initrd.img
    APPEND init=/init console=tty0 console=ttyS0,115200n8 quiet
EOF

# 8. Generate ISO Image using genisoimage/xorriso & isohybrid
echo "Generating ISO Image..."
genisoimage -o "$OUTPUT_ISO" \
    -b isolinux/isolinux.bin \
    -c isolinux/boot.cat \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -J -R -V "INTERAKTIV_OS" \
    "$ISO_DIR"

isohybrid "$OUTPUT_ISO"

echo "ISO successfully built at: $OUTPUT_ISO"
ls -lh "$OUTPUT_ISO"
