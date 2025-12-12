#!/bin/bash
set -e

echo "===================================================="
echo "Setting up build environment..."
echo "===================================================="

# 1. Fix CentOS 7 EOL repositories if we are on CentOS 7
echo "Detected CentOS 7. Applying EOL repository fixes..."

# Only apply if we haven't already (simple check)
if ! grep -q "sslverify=0" /etc/yum.conf; then
    echo "sslverify=0" >> /etc/yum.conf
fi

rm -f /etc/yum.repos.d/CentOS-Base.repo

if [ -f /etc/yum.repos.d/CentOS-Vault.repo ]; then
    # Reset repo file if needed or just apply sed
    sed -i 's/7.8.2003/7.9.2009/g' /etc/yum.repos.d/CentOS-Vault.repo
    sed -i '/# C7.9.2009/,$ s/enabled=0/enabled=1/g' /etc/yum.repos.d/CentOS-Vault.repo
    sed -i 's/baseurl=http\:/baseurl=https\:/g' /etc/yum.repos.d/CentOS-Vault.repo
fi

yum clean all
# yum makecache # Optional, update will do it

# 2. Install Dependencies
if [ -z "$SKIP_DEPS" ]; then
    echo "Installing build dependencies..."
    yum -y update
    # remove again since it might be reinstalled by 'yum -y update'
    rm -f /etc/yum.repos.d/CentOS-Base.repo
    yum -y install gcc make perl elfutils-libelf-devel kmod sudo ncurses-devel bc bison flex
    yum -y install kernel kernel-devel

    # Try to install kernel-devel for the current kernel, fallback to generic
    if ! yum -y install "kernel-devel-$(uname -r)"; then
        echo "Warning: Could not install kernel-devel-$(uname -r). Falling back to latest kernel-devel..."
        yum -y install kernel-devel || echo "Warning: Failed to install any kernel-devel."
    fi
else
    echo "Skipping dependency installation (SKIP_DEPS is set)."
fi

# 3. Install Local RPMs (e.g. for specific kernels)
# We look for rpm_pkg relative to this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
RPM_DIR="$SCRIPT_DIR/rpm_pkg"

if [ -d "$RPM_DIR" ] && ls "$RPM_DIR"/*.rpm >/dev/null 2>&1; then
    echo "Installing local RPMs from $RPM_DIR..."
    yum localinstall -y "$RPM_DIR"/*.rpm || echo "Warning: Failed to install some RPMs, continuing..."
else
    echo "No local RPMs found in $RPM_DIR to install."
fi

echo "Environment setup complete."
