# Intel igc driver backport for CentOS 7.9 (kernel v3.10.0-1160)

This repository contains the Intel IGC driver backported for CentOS 7.9 (kernel 3.10). It is based on the `synology-igc` driver which was originally targeted for kernel 4.4.180.

## Prerequisites

Before building, ensure you have the necessary development tools and kernel headers installed for your running kernel.

```bash
sudo yum update
sudo yum groupinstall 'Development Tools'
sudo yum install kernel-devel-$(uname -r)
```

## Build and Install

A helper script `build.sh` is provided to automate the build, installation, and reloading process.

1.  **Make the script executable:**
    ```bash
    chmod +x build.sh
    ```

2.  **Run the build script:**
    ```bash
    ./build.sh
    ```

This script will:
*   Compile the `igc.ko` module against your current kernel.
*   Compress the module to `igc.ko.xz` (matching CentOS 7 standards).
*   Install it to `/lib/modules/$(uname -r)/updates/drivers/net/ethernet/intel/igc/`.
*   Update module dependencies (`depmod -a`).
*   Unload the old driver and load the new one.

## Persistence after Reboot

To ensure the new driver is loaded automatically at boot time, you must rebuild the initial ramdisk (initramfs). This is because the network driver is often needed early in the boot process.

Run the following command after a successful build and install:

```bash
sudo dracut -f
```

## Troubleshooting & Notes

The following information summarizes common issues encountered during the backporting process.

### 1. "Unknown symbol ptp_..." Errors
The IGC driver depends on the PTP (Precision Time Protocol) subsystem.
*   **Symptom:** `modprobe` fails with "Unknown symbol" errors related to `ptp_clock_index`, `ptp_clock_register`, etc.
*   **Solution:** This is usually caused by forgetting to update the module dependency database after installation. Run `sudo depmod -a` before loading the module.
    The driver has been updated with `MODULE_SOFTDEP("pre: ptp")` to automatically request the `ptp` module. If it still fails, ensure the `ptp` module is available and loaded:
    ```bash
    sudo modprobe ptp
    ```

### 2. Driver Loaded but network is not working
*   **Symptom:** `lsmod | grep igc` shows the module is loaded, but network is not working, and `lspci -nnk | grep -i ethernet -A3` does not show "Kernel driver in use: igc".
*   **Cause:** The driver failed to bind to the hardware during the "probe" phase.
*   **Diagnosis:** Check kernel logs for specific error codes:
    ```bash
    dmesg | grep -i igc
    ```

### 3. Probe Failed with Error -2 (ENOENT)
*   **Symptom:** `dmesg` shows `igc: probe of 0000:xx:00.0 failed with error -2`.
*   **Context:** In the context of driver initialization, this often indicates a missing kernel resource, subsystem initialization failure, or API mismatch in the backport (e.g., LED setup or PHY initialization failures).  I saw this error when loading the driver modified from https://github.com/systems-nuts/igc_driver
*   **Diagnosis:** It may require code modifications to handle 3.10 kernel API differences.

### 4. Kernel Taint Warning
*   **Message:** `igc: loading out-of-tree module taints kernel.`
*   **Status:** Safe to ignore. This simply indicates that the module was compiled outside of the official CentOS kernel source tree.

### 5. Refreshing Network Interfaces
After loading the driver, you may need to restart the network interface to make it active.
```bash
# Identify your interface name (e.g., eno1)
nmcli device status

# Restart the interface
sudo nmcli device down <interface_name>
sudo nmcli device up <interface_name>
```
