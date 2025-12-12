#!/bin/bash
set -e

# Usage: ./compile.sh [KERNEL_VERSION] [OUTPUT_DIR]

KVER="${1:-$(uname -r)}"
OUTPUT_DIR="${2:-}"

# Determine paths
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Locate source directory
if [ -f "$ROOT_DIR/igc_main.c" ]; then
    SRC_DIR="$ROOT_DIR"
elif [ -f "$SCRIPT_DIR/igc_main.c" ]; then
    SRC_DIR="$SCRIPT_DIR"
elif [ -f "./igc_main.c" ]; then
    SRC_DIR="."
else
    echo "Error: Could not locate source files (igc_main.c)."
    exit 1
fi

# Determine Kernel Build Directory
BUILD_DIR="/lib/modules/$KVER/build"
if [ ! -d "$BUILD_DIR" ] && [ -d "/usr/src/kernels/$KVER" ]; then
    BUILD_DIR="/usr/src/kernels/$KVER"
fi

if [ ! -d "$BUILD_DIR" ]; then
    echo "Error: Kernel headers not found for $KVER at $BUILD_DIR"
    echo "Please ensure kernel-devel-$KVER is installed."
    exit 1
fi

echo "===================================================="
echo "Building IGC driver for kernel: $KVER"
echo "Source: $SRC_DIR"
echo "Headers: $BUILD_DIR"
echo "===================================================="

# Create a temporary build directory
# This ensures a clean build environment for every kernel version
WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT
echo "Work directory: $WORK_DIR"

# Copy source files to WORK_DIR
# We use cp -a to preserve attributes. We copy the content of SRC_DIR.
cp -a "$SRC_DIR/." "$WORK_DIR/"

# Build the module in the temporary directory
make -C "$BUILD_DIR" M="$WORK_DIR" modules

# Verify build
if [ ! -f "$WORK_DIR/igc.ko" ]; then
    echo "Error: Build failed, igc.ko not found."
    exit 1
fi

# Compress
echo "Compressing module..."
MODULE_NAME="igc-${KVER}.ko"
cp "$WORK_DIR/igc.ko" "$WORK_DIR/$MODULE_NAME"

if command -v xz >/dev/null 2>&1; then
    xz -f "$WORK_DIR/$MODULE_NAME"
    MODULE_NAME="${MODULE_NAME}.xz"
else
    echo "Warning: 'xz' command not found. Skipping compression."
fi

# Handle Output
if [ -n "$OUTPUT_DIR" ]; then
    mkdir -p "$OUTPUT_DIR"
    cp "$WORK_DIR/$MODULE_NAME" "$OUTPUT_DIR/"
    echo "Build artifact copied to: $OUTPUT_DIR/$MODULE_NAME"
else
    # If no output dir specified, copy back to source dir
    cp "$WORK_DIR/$MODULE_NAME" "$SRC_DIR/"
    echo "Build artifact available at: $SRC_DIR/$MODULE_NAME"
fi
