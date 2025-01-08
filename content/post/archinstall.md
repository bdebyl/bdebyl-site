---
title: "Installing Arch Linux with Full Disk Encryption (LUKS)"
date: 2018-12-19
lastmod: 2019-01-29
categories: ["Tutorial"]
tags: ["linux"]
---
This is a guide written on how to install Arch Linux using LUKS for disk
encryption, and Systemd-boot as the bootloader.
<!--more-->
It is assumed that the reader has basic linux knowledge and understands that
examples are given via output commands. The reader may always consult manpages,
the [Arch Wiki](https://wiki.archlinux.org/), or other documentation to build a
better understanding of the tools and methods used.

---

# Partitioning

1. Create a partition scheme using partitioner of choice (e.g. `gdisk`, `fdisk`,
   `cgdisk`).
   - First partition should be EFI/boot partition at around 256MB+ (type:
     `ef00`)
   - Second partition should be Linux LVM partition using rest of disk space
     (type: `8e00`)
1. Make the the EFI/boot partition FAT32 via `mkfs.fat -F32`

## Partitioning with `fdisk`

This operation will destroy any data on the device, please ensure to back up
any data desired prior to this operation!

Replace instances of `/dev/sdN` with your actual device name (e.g. `/dev/sda`).
References specific to partitions will be stated as such (e.g. `/dev/sdN1`,
`/dev/sdN2`)

1. Remove any existing partitions on the drive:

   ```bash
   $ dd if=/dev/zero of=/def/sdN bs=4M count=1
   1+0 records in
   1+0 records out
   4194304 bytes (4.2 MB, 4.0 MiB) copied, 0.499143 s, 8.4 MB/s
   ```

1. Create a new `gpt` partition table with `fdisk`:

   ```bash
   $ sudo fdisk /dev/sdN

   Command (m for help): g
   Created a new GPT disklabel (GUID: 07D99608-7AE7-1144-8BCA-BDF9833DAFD0).

   Command (m for help): p

   Command (m for help): n
   Partition number (1-128, default 1):
   First sector (2048-15155166, default 2048):
   Last sector, +/-sectors or +/-size{K,M,G,T,P} (2048-15155166, default
   15155166): +512M

   Created a new partition 1 of type 'Linux filesystem' and of size 512 MiB.

   Command (m for help): t
   Selected partition 1
   Partition type or alias (type L to list all): 1
   Changed type of partition 'Linux LVM' to 'EFI System'.

   Command (m for help): n
   Partition number (2-128, default 2):
   First sector (1050624-15155166, default 1050624):
   Last sector, +/-sectors or +/-size{K,M,G,T,P} (1050624-15155166, default
   15155166):

   Created a new partition 2 of type 'Linux filesystem' and of size 6.7 GiB.

   Command (m for help): t
   Partition number (1,2, default 2):
   Partition type or alias (type L to list all): 30

   Changed type of partition 'Linux filesystem' to 'Linux LVM'.

   Command (m for help): w
   The partition table has been altered.
   Calling ioctl() to re-read partition table.
   Syncing disks.

   $ fdisk -l /dev/sdN
   ...
   Disklabel type: gpt

   Device       Start      End  Sectors  Size Type
   /dev/sdN1     2048  1050623  1048576  512M EFI System
   /dev/sdN2  1050624 15155166 14104543  6.7G Linux LVM
   ```

   {{< sub >}}
   The above example `fdisk` run was done on an 8G USB drive and is provided
   for reference purposes. Ignore the sizes listed above when comparing to your
   installation.
   {{< /sub >}}

# Encryption

1. Format the Linux LVM partition:

   ```bash
   cryptsetup luksFormat /dev/sdN2
   Enter passphrase:
   ```

   {{< sub >}}
   Remember your passphrase! You will need this every time you boot
   your computer
   {{< /sub >}}

1. Create a mapping for your Linux LVM (LUKS):

   ```bash
   cryptsetup open --type luks /dev/sdN2 <map_name>
   ```

   {{< sub >}}
   Use whatever name you want. Ex. `lvm`, `volume`, etc.
   {{< /sub >}}

1. Create the physical volume, volume group, and logical volumes for
   `<map_name>` specified in the previous step:

   ```bash
   pvcreate /dev/mapper/<map_name>
   vgcreate <volume_name> /dev/mapper/<map_name>
   ```

   {{< sub >}}
   Use whatever volume name you want. Ex. `volume`, `main`, `linux`, etc.
   {{< /sub >}}

   ```bash
   lvcreate -L2G <volume_name> -n swap
   ```

   {{< sub >}}
   Select size for swap, if desired. Here we use `2G` for 2Gb.
   {{< /sub >}}

   ```bash
   lvcreate -L16G <volume_name> -n root
   lvcreate -l 100%FREE <volume_name> -n home
   ```

   {{< sub >}}
   Set your `root` partition size and `home` size if using separate `/home`
   partition. Otherwise, simply create your `-l 100%FREE` volume.
   {{< /sub >}}

1. Specify and write the desired filesystems:

   ```bash
   mkfs.ext4 /dev/mapper/<volume_name>-root
   mkfs.ext4 /dev/mapper/<volume_name>-home
   mkswap /dev/mapper/<volume_name>-swap
   ```

# Install Linux

1. Mount the boot partition and logical volumes for installation:

   ```bash
   mount /dev/mapper/<volume_name>-root /mnt
   mkdir /mnt/home
   mkdir /mnt/boot
   mount /dev/mapper/<volume_name>-home /mnt/home
   mount /dev/sdN1 /mnt/boot
   swapon /dev/mapper/<volume_name>-swap
   ```

1. Install the base system (_Assuming you have internet connectivity. Use
   `wifi-menu`, or other, to connect to the internet at this point._):

   ```bash
   pacstrap /mnt base base-devel linux linux-firmware lvm2 dhclient
   ```

   {{< sub >}}
   Here we are using `linux` kernel as an example, though you may want to use
   `linux-hardened`
   {{< /sub >}}

# Set-up Linux Installation

## Generate `fstab`

1. Generate the `fstab`:

   ```bash
   genfstab -p /mnt >> /mnt/etc/fstab
   ```

1. Move into the installation:

   ```bash
   arch-chroot /mnt
   ```

## Configure `initramfs`

1. Edit `HOOKS` in `/etc/mkinitcpio.conf` using text editor of your choice
   (e.g. `vi`, `nano`, etc.). Move the `keyboard` hook before `filesystems`,
   and add `encrypt` and `lvm2` hooks **before** `filesystems`:

   ```bash
   $ egrep '^HOOKS' /etc/mkinitcpio.conf
   HOOKS=(base udev autodetect modconf block keyboard encrypt lvm2 filesystems fsck)
   ```

   {{< sub >}}
   Read the comment on `HOOKS` in the `mkinitcpio.conf` file to find out more.
   {{< /sub >}}

1. Generate `initramfs`:

   ```bash
   mkinitcpio -p linux
   ```

## Configure bootloader

Install a bootloader (e.g. `systemd-boot`, `grub`, `syslinux`, etc.) and
configure it as per it's documentation/installation steps.

### Bootloader Example: `systemd-boot`

1. I will be using `systemd-boot`

   ```bash
   bootctl --path=/boot/ install
   ```

1. Edit the loader configuration using a text editor of your choice:

   ```bash
   $ cat /boot/loader/loader.conf
   default arch
   timeout 3
   editor 0
   ```

1. Create the loader entry for the default `arch` entry specified above (_You
   can edit this name if desired._). Use `blkid /dev/sdNx` to find the UUID
   of your crypt device, and recall the volume name you gave your device
   above (_`main` in example below_):

   ```bash
   $ cat /boot/loader/entries/arch.conf
   title Arch Linux
   linux /vmlinuz-linux.img
   initrd /initramfs-linux.img
   options cryptdevice=UUID=9f1fc119-b1dc-49d8-9a5a-686ad9e2fd2e:volume root=/dev/mapper/main-root quiet rw
   ```

## Configure finishing touches

1. Create a root password using `passwd`

1. Set a hostname:

   ```bash
   echo "<your_hostname>" > /etc/hostname
   ```

1. Set up the time:

   ```bash
   ln -fs /usr/share/zoneinfo/<continent>/<city/place> /etc/localtime
   hwclock --systohc --utc
   ```

1. Set the locale (_example for `en_US`_):

   ```bash
   sed -i 's/^\#en_US/en_US/' /etc/locale.gen
   locale-gen
   locale > /etc/locale.conf
   ```

1. Exit and reboot:

   ```bash
   exit
   unmount -R /mnt
   reboot
   ```
