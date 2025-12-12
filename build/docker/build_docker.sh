#!/bin/bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Ensure environment is set up (idempotent)
# We skip dependencies since they are baked into the image, but we want to install local RPMs
export SKIP_DEPS=1
bash "$SCRIPT_DIR/../setup_env.sh"

# Find kernels
if [ -d /usr/src/kernels ]; then
    KERNELS=$(ls /usr/src/kernels/ | grep -v debug)
else
    echo "Error: /usr/src/kernels not found."
    exit 1
fi

for KVER in $KERNELS; do
    echo "Building for kernel: $KVER"
    bash "$SCRIPT_DIR/../compile.sh" "$KVER" "$SCRIPT_DIR/../../output"
done

echo "All builds complete. Artifacts in output/"
ls -l "$SCRIPT_DIR/../../output"
