---
title: "Sharing Same Bluetooth device on Windows/Linux dual-boot"
date: 2023-10-14
lastmod: 2023-10-14
categories: ["Tutorial"]
tags: ["linux","windows","bluetooth"]
contentCopyright: true
hideHeaderAndFooter: false
---
This is a guide written on how to share the same Bluetooth device(s) across Windows and Linux without having to uniquely pair each.
<!--more-->
## Steps

1. Pair your Bluetooth device(s) with Linux **first**
2. Reboot into Windows, then re-pair the devices with Windows
3. Run `regedit` **as Administrator**
4. Navigate to: 
   ```
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
    ```
    00000000   31 c0 08 fa 4f 7b d2 4c - 6f e1 7d ba 32 29 a9 a7  1À.ïO{ÒLoá}ºQ)©§
    ```
    _From the above copy `31 c0 .... a9 a7`_
    
12. Paste the key from the previous step into the `Key=` portion of the **Linux** Bluetooth `info` file. Make sure to **remove all spaces, hyphens, and change all characters to upper-case (all-caps)**.
13. Save the `info` file with the changes to complete device sharing. Repeat for any other Bluetooth devices to share.