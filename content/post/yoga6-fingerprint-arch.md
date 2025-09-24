---
title: "Fingerprint Support on Lenovo Yoga 6 with Arch Linux"
date: 2025-09-23
lastmod: 2025-09-23
categories: ["Blog"]
tags: ["linux", "archlinux", "hardware"]
---
Got a Lenovo Yoga 6 2-in-1 and frustrated that your fingerprint reader isn't working on Arch Linux? You're not alone. The standard fprintd package doesn't include the necessary firmware for this laptop's Synaptics sensor.

<!--more-->

# The Problem

The Lenovo Yoga 6 2-in-1 laptop comes with a Synaptics fingerprint sensor that requires proprietary firmware not included in the standard fprintd package. Without this firmware, fprintd can't communicate with the sensor, leaving you with a non-functional fingerprint reader.

# The Solution

The AUR package `libfprint-2-tod1-synatudor-git` provides the necessary Touch-On-Display (TOD) driver and firmware for Synaptics sensors, including the one in the Yoga 6.

## Installation Steps

1. **Install the AUR package:**
```bash
yay -S libfprint-2-tod1-synatudor-git
```
Or if you're using paru:
```bash
paru -S libfprint-2-tod1-synatudor-git
```

2. **Install fprintd (if not already installed):**
```bash
sudo pacman -S fprintd
```

3. **Enable and start the fprintd service:**
```bash
sudo systemctl enable --now fprintd.service
```

4. **Verify the fingerprint reader is detected:**
```bash
fprintd-list-devices
```

You should see output listing your Synaptics sensor.

## Setting Up Fingerprints

Once the driver is installed and working:

1. **Enroll your fingerprints:**
```bash
fprintd-enroll
```
Follow the prompts to scan your finger multiple times.

2. **Test authentication:**
```bash
fprintd-verify
```

## PAM Integration

To use fingerprint authentication for system login and authentication, add fingerprint support to the appropriate PAM configuration files:

1. **For system login**, add to `/etc/pam.d/system-local-login`:
```
auth      sufficient pam_fprintd.so
```

2. **For display managers**, the configuration may already exist:
   - SDDM: `/etc/pam.d/sddm` should have `auth sufficient pam_fprintd.so`
   - LightDM: `/etc/pam.d/lightdm` should have `auth sufficient pam_fprintd.so`

3. **For sudo authentication**, add to `/etc/pam.d/sudo`:
```
auth sufficient pam_fprintd.so
```

The `sufficient` directive means fingerprint authentication will be attempted first, falling back to password if fingerprint fails.

# Why This Works

The `libfprint-2-tod1-synatudor-git` package provides:
- The proprietary Synaptics firmware blob required by the sensor
- The TOD (Touch-On-Display) driver implementation for libfprint2
- Proper USB device ID mappings for various Synaptics sensors

Without this package, fprintd only has access to open-source drivers that don't support the proprietary communication protocol used by many modern fingerprint sensors.

# Troubleshooting

If the fingerprint reader still doesn't work:

1. **Check USB device detection:**
```bash
lsusb | grep -i synaptics
```

2. **Review fprintd logs:**
```bash
journalctl -u fprintd -b
```

3. **Ensure secure boot is disabled** - some proprietary firmware doesn't load with secure boot enabled.

4. **Reboot after installation** - the driver may need a fresh start to properly initialize.

# Final Notes

While it's unfortunate that proprietary firmware is required, this AUR package makes fingerprint authentication possible on the Yoga 6 and similar laptops with Synaptics sensors. The convenience of fingerprint login, especially on a 2-in-1 device, is worth the extra installation step.