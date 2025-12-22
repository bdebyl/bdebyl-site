---
title: "The Case of the Bloated Boot"
date: 2025-09-22
lastmod: 2025-09-22
categories: ["Blog"]
tags: ["linux"]
---
When `sudo mkinitcpio -P` fails because your boot partition is full, you've got
a fun problem. The culprit? That massive fallback initramfs taking up precious
space on a tiny boot partition.

<!--more-->

# The Problem

Picture this: you're dual-booting Linux and running a system update when
suddenly `mkinitcpio` fails to generate the larger fallback image. Your boot
partition is completely stuffed.

```bash
$ df -h /boot
Filesystem      Size  Used Avail Use% Mounted on
/dev/nvme0n1p1  256M  256M     0 100% /boot
```

**Yikes.** Time to investigate what's eating all that space.

# Damage Assessment

A quick `du -sh` reveals the usual suspects:

```bash
$ du -sh /boot/*
157M    /boot/initramfs-linux-fallback.img
52M     /boot/initramfs-linux.img
16M     /boot/vmlinuz-linux
30M     /boot/EFI
```

The fallback initramfs is **three times larger** than the normal one. But why?

# The Autodetect Mystery

The secret lies in one simple flag in `/etc/mkinitcpio.d/linux.preset`:

```bash
fallback_options="-S autodetect"
```

That `-S autodetect` flag skips the autodetect hook, which normally shrinks your
initramfs by only including modules your hardware actually needs. Without it,
mkinitcpio includes **everything**.

## By the Numbers

Here's what that means in practice for me:

| Component          | Normal (with autodetect) | Fallback (no autodetect) |   Ratio |
| :----------------- | -----------------------: | -----------------------: | ------: |
| **Kernel modules** |              190 modules |            6,319 modules | **33x** |
| **Firmware files** |                711 files |              2,996 files |  **4x** |
| **Total size**     |                      52M |                     157M |  **3x** |

The fallback image is essentially a universal boot disk that works on _any_
hardware — your laptop, your friend's desktop, that ancient server in the
closet. It includes drivers for RAID controllers you don't have, network cards
from 2003, and GPU firmware for every generation of graphics hardware.

# The Nuclear Option

Since I never use the fallback image anyway (live USB for rescue), the
solution was just to get rid of this:

1. **Remove the fallback image** to free immediate space:
   ```bash
   sudo rm /boot/initramfs-linux-fallback.img
   ```

2. **Disable future generation** by editing `/etc/mkinitcpio.d/linux.preset`:
   ```bash
   # Change this line:
   PRESETS=('default' 'fallback')
   # To this:
   PRESETS=('default')
   ```

3. **Test it works**:
   ```bash
   sudo mkinitcpio -P
   ```

Result: boot partition goes from 100% to 39% usage, and future kernel updates
won't recreate the bloated fallback.

# Why It Matters

The autodetect hook is actually quite clever. On my system with 443MB of total
kernel modules available, it correctly identified that I only need 190 of them
— things like my specific WiFi driver, filesystem modules for ext4 and LVM, and
encryption support for LUKS.

The fallback includes _everything else too_: drivers for hardware I'll never own
(_especially since this is on a laptop_), filesystem support for formats I'll
never use, and network protocols from the dawn of time. It's the digital
equivalent of packing for a trip by bringing your entire garage of tools "just
in case"

# The Takeaway

Unless you're regularly swapping hardware or need guaranteed boot recovery from
the initramfs itself, the fallback image is dead weight. Modern autodetection
works well enough that most people never need it. I've personnally never, ever
used the fallback image and for the context of this laptop probably never will
as a bootable USB is my go-to for any and all boot issues.

For those tight boot partitions in dual-boot setups, disabling fallback
generation is it. Save the space for kernel updates that actually matter :^)

And if you _do_ need recovery? Well, that's what live USBs are for, but you're
welcome to make your own decisions.