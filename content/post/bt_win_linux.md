---
title: "Sharing same Bluetooth device on Windows/Linux dual-boot"
date: 2023-10-14
lastmod: 2025-12-21
categories: ["Tutorial"]
tags: ["linux","windows","bluetooth"]
contentCopyright: true
hideHeaderAndFooter: false
---
This is a guide written on how to share the same Bluetooth device(s) across Windows and Linux without having to uniquely pair each.
<!--more-->

## Method 1: Extract Keys from Linux (Recommended)

This method uses `hivexsh` to read the Windows registry directly from Linux without needing to boot into Windows.

### Prerequisites

Install hivex:

```bash
# Arch Linux
sudo pacman -S hivex

# Debian/Ubuntu
sudo apt install libhivex-bin

# Fedora
sudo dnf install hivex
```

### Steps

1. Pair your Bluetooth device(s) with Linux **first**
2. Reboot into Windows, then re-pair the devices with Windows
3. Reboot back to Linux
4. Mount your Windows partition (if not already mounted):

   ```bash
   sudo mount /dev/sdXN /mnt/windows
   ```

5. Find your Bluetooth adapter MAC address and paired devices:

   ```bash
   ls /var/lib/bluetooth/
   # Example output: 24:EB:16:23:5B:94

   ls /var/lib/bluetooth/24:EB:16:23:5B:94/
   # Example output: EC:66:D1:B1:9A:33 (your device)
   ```

6. Use `hivexsh` to extract the pairing key from the Windows registry:

   ```bash
   hivexsh /mnt/windows/Windows/System32/config/SYSTEM
   ```

7. Navigate to the Bluetooth keys (MAC addresses are lowercase, no colons):

   ```text
   cd ControlSet001\Services\BTHPORT\Parameters\Keys
   ls
   cd 24eb16235b94
   lsval
   ```

   Example output:
   ```text
   "ec66d1b19a33"=hex(3):1d,68,ef,88,a8,fa,60,2e,a3,1c,69,2e,61,a4,36,4f
   ```

8. Convert the key to Linux format (remove commas, uppercase):

   ```text
   1d,68,ef,88,a8,fa,60,2e,a3,1c,69,2e,61,a4,36,4f
   → 1D68EF88A8FA602EA31C692E61A4364F
   ```

9. Update the Linux Bluetooth info file:

   ```bash
   sudo nano /var/lib/bluetooth/24:EB:16:23:5B:94/EC:66:D1:B1:9A:33/info
   ```

   Replace the `Key=` value under `[LinkKey]` with the converted key.

10. Restart the Bluetooth service:

    ```bash
    sudo systemctl restart bluetooth
    ```

---

## Method 2: Export Keys from Windows

This method requires exporting the registry keys while booted into Windows.

### Steps

1. Pair your Bluetooth device(s) with Linux **first**
2. Reboot into Windows, then re-pair the devices with Windows
3. Run `regedit` **as Administrator**
4. Navigate to:

   ```text
   HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\BTHPORT\Parameters\Keys
   ```

   If you **do not see any Keys under the tree** then you need to open `regedit` as a system-account user. One way to do this is using the PsExec by [downloading it from Microsoft Sysinternals](https://learn.microsoft.com/en-us/sysinternals/downloads/psexec). Once it is downloaded, you will need to run a command-prompt **as Administrator** and navigate to the location `PsExec` is unzipped and run `PsExec.exe -s -i regedit`. The Bluetooth keys should now be visible.

5. Right-click on `Keys` in the left-hand pane and select `Export`. During the dialog change `Save as type` to `Text files` and that the `Export range` is set to `Selected branch`. Store this somewhere **accessible by both Windows and Linux** -- if a shared drive is unavailable, use a USB drive or cloud-storage.
6. Reboot to Linux
7. In a root (e.g. `sudo su`) terminal navigate to `/var/lib/bluetooth` then to the MAC address of your host-system (_there should only be a single sub-directory under `/var/lib/bluetooth`_)
8. Find the relevant Bluetooth device(s) by MAC address to share and enter the equally named MAC address directory of the client device.
9. Open the `info` file, with root privileges, in the text editor of your choice.
10. In another tab/window, using either a text viewer or editor, open the **previously exported Windows registry text file for the device**
11. From the **Windows** file, copy the Bluetooth Key. Example:

    ```text
    00000000   31 c0 08 fa 4f 7b d2 4c - 6f e1 7d ba 32 29 a9 a7  1À.ïO{ÒLoá}ºQ)©§
    ```

    _From the above copy `31 c0 .... a9 a7`_

12. Paste the key from the previous step into the `Key=` portion of the **Linux** Bluetooth `info` file. Make sure to **remove all spaces, hyphens, and change all characters to upper-case (all-caps)**.
13. Save the `info` file with the changes to complete device sharing. Repeat for any other Bluetooth devices to share.
14. Restart the Bluetooth service:

    ```bash
    sudo systemctl restart bluetooth
    ```
