#!/bin/bash
set -e

# Usage: ./install.sh [MODULE_FILE]

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
CURRENT_KVER=$(uname -r)

# Find module file
if [ -n "$1" ]; then
    MODULE_FILE="$1"
elif [ -f "$ROOT_DIR/output/igc-${CURRENT_KVER}.ko.xz" ]; then
    MODULE_FILE="$ROOT_DIR/igc-${CURRENT_KVER}.ko.xz"
elif [ -f "$ROOT_DIR/output/igc-${CURRENT_KVER}.ko" ]; then
    MODULE_FILE="$ROOT_DIR/igc-${CURRENT_KVER}.ko"
elif [ -f "$ROOT_DIR/igc.ko.xz" ]; then
    MODULE_FILE="$ROOT_DIR/igc.ko.xz"
elif [ -f "$ROOT_DIR/igc.ko" ]; then
    MODULE_FILE="$ROOT_DIR/igc.ko"
else
    echo "Error: No module file specified or found in root."
    echo "Usage: ./install.sh [path/to/igc.ko.xz]"
    exit 1
fi

if [ ! -f "$MODULE_FILE" ]; then
    echo "Error: File $MODULE_FILE not found."
    exit 1
fi

KVER=$(uname -r)
INSTALL_DIR="/lib/modules/$KVER/updates/drivers/net/ethernet/intel/igc"

echo "===================================================="
echo "Installing $(basename "$MODULE_FILE") for kernel $KVER"
echo "===================================================="

# Create destination directory
sudo mkdir -p "$INSTALL_DIR"

# Backup existing
backup_file() {
    local file_path="$1"
    if [ -f "$file_path" ] && [ ! -L "$file_path" ]; then
        local timestamp=$(date +%Y%m%d_%H%M%S)
        echo "Backing up existing module to ${file_path}.bak.${timestamp}"
        sudo mv "$file_path" "${file_path}.bak.${timestamp}"
    fi
}

backup_file "$INSTALL_DIR/igc.ko"
backup_file "$INSTALL_DIR/igc.ko.xz"

# Install
if [[ "$MODULE_FILE" == *.xz ]]; then
    TARGET_NAME="igc.ko.xz"
else
    TARGET_NAME="igc.ko"
fi

sudo cp "$MODULE_FILE" "$INSTALL_DIR/$TARGET_NAME"
echo "Installed to $INSTALL_DIR/$TARGET_NAME"

# Update deps
echo "Updating module dependencies..."
sudo depmod -a

# Reload
echo "Reloading driver..."
if lsmod | grep -q "^igc"; then
    sudo modprobe -r igc
fi

if sudo modprobe igc; then
    echo "Success: igc module loaded."
else
    echo "Error: Failed to load igc module. Check 'dmesg'."
    exit 1
fi

# Verify
modinfo igc | grep filename
lsmod | grep igc

echo "===================================================="
echo "Installation complete."
echo "Run 'sudo dracut -f' to persist changes in initramfs."
echo "===================================================="
