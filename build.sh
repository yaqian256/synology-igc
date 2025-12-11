#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Get current kernel version
KVER=$(uname -r)
BUILD_DIR="/lib/modules/$KVER/build"
# Use 'updates' directory which takes precedence over 'kernel'
INSTALL_DIR="/lib/modules/$KVER/updates/drivers/net/ethernet/intel/igc"

echo "----------------------------------------------------"
echo "Building IGC driver for kernel: $KVER"
echo "----------------------------------------------------"

# Check if kernel headers are installed
if [ ! -d "$BUILD_DIR" ]; then
    echo "Error: Kernel headers not found at $BUILD_DIR"
    echo "Please run: sudo yum install kernel-devel-$KVER"
    exit 1
fi

# Clean previous build
make -C "$BUILD_DIR" M="$PWD" clean

# Build the module
make -C "$BUILD_DIR" M="$PWD" modules

# Check if igc.ko was created
if [ ! -f "igc.ko" ]; then
    echo "Error: Build failed, igc.ko not found."
    exit 1
fi

echo "----------------------------------------------------"
echo "Compressing module..."
echo "----------------------------------------------------"
if command -v xz >/dev/null 2>&1; then
    xz -f igc.ko
    MODULE_FILE="igc.ko.xz"
else
    echo "Warning: 'xz' command not found. Installing uncompressed module."
    MODULE_FILE="igc.ko"
fi

echo "----------------------------------------------------"
echo "Installing $MODULE_FILE..."
echo "----------------------------------------------------"

# Create destination directory if it doesn't exist
sudo mkdir -p "$INSTALL_DIR"

# Function to backup a file
backup_file() {
    local file_path="$1"
    if [ -f "$file_path" ] && [ ! -L "$file_path" ]; then
        local timestamp=$(date +%Y%m%d_%H%M%S)
        echo "Backing up existing module to ${file_path}.bak.${timestamp}"
        sudo mv "$file_path" "${file_path}.bak.${timestamp}"
    fi
}

# Backup potential conflicts in updates location
backup_file "$INSTALL_DIR/igc.ko"
backup_file "$INSTALL_DIR/igc.ko.xz"

# Copy the new module
sudo cp "$MODULE_FILE" "$INSTALL_DIR/"
echo "Installed to $INSTALL_DIR"

echo "----------------------------------------------------"
echo "Updating module dependencies..."
echo "----------------------------------------------------"
sudo depmod -a

echo "----------------------------------------------------"
echo "Reloading driver..."
echo "----------------------------------------------------"

# Unload existing driver
if lsmod | grep -q "^igc"; then
    echo "Unloading igc..."
    sudo modprobe -r igc
fi

# Load the new driver
echo "Loading igc..."
if sudo modprobe igc; then
    echo "Success: igc module loaded."
else
    echo "Error: Failed to load igc module. Check 'dmesg' for details."
    exit 1
fi

echo "----------------------------------------------------"
echo "Verification:"
echo "----------------------------------------------------"
modinfo igc | grep filename
lsmod | grep igc

echo ""
echo "----------------------------------------------------"
echo "Build and installation complete."
echo "NOTE: To ensure the driver loads on boot, you should rebuild the initramfs:"
echo "      sudo dracut -f"
echo "----------------------------------------------------"
