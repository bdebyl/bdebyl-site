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

# Encryption
1. Format the Linux LVM partition:
   ```
   # cryptsetup luksFormat /dev/sdaN
   Enter passphrase:
   ```
   **Note:** _Remember your passphrase! You will need this every time you boot
   your computer_
1. Create a mapping for your Linux LVM (LUKS):
   ```
   # cryptsetup open --type luks /dev/sdaN <map_name>
   ```
   _Use whatever name you want. Ex. `lvm`, `volume`, etc._
1. Create the physical volume, volume group, and logical volumes for
   `<map_name>` specified in the previous step:
   ```
   # pvcreate /dev/mapper/<map_name>
   # vgcreate <volume_name> /dev/mapper/<map_name>
   ```
   _Use whatever volume name you want. Ex. `volume`, `main`, `linux`, etc._
   ```
   # lvcreate -L2G <volume_name> -n swap
   ```
   _Select size for swap, if desired. Here we use `2G` for 2Gb._
   ```
   # lvcreate -L16G <volume_name> -n root
   # lvcreate -l 100%FREE <volume_name> -n home
   ```
1. Specify and write the desired filesystems:
   ```
   # mkfs.ext4 /dev/mapper/<volume_name>-root
   # mkfs.ext4 /dev/mapper/<volume_name>-home
   # mkswap /dev/mapper/<volume_name>-swap
   ```

# Install Linux
1. Mount the boot partition and logical volumes for installation:
   ```
   # mount /dev/mapper/<volume_name>-root /mnt
   # mkdir /mnt/home
   # mkdir /mnt/boot
   # mount /dev/mapper/<volume_name>-home /mnt/home
   # mount /dev/sdaN /mnt/boot
   # swapon /dev/mapper/<volume_name>-swap
   ```

1. Install the base system (_Assuming you have internet connectivity. Use
   `wifi-menu`, or other, to connect to the internet at this point._):
   ```
   # pacstrap /mnt base base-devel
   ```

# Set-up Linux Installation
1. Generate the `fstab`:
   ```
   # genfstab -p /mnt >> /mnt/etc/fstab
   ```

1. Move into the installation:
   ```
   # arch-chroot /mnt
   ```

1. Configure `initramfs`:
   1. Edit `HOOKS` in `/etc/mkinitcpio.conf` using text editor of your choice
      (e.g. `vi`, `nano`, etc.). Move the `keyboard` hook before `filesystems`,
      and add `encrypt` and `lvm2` hooks **before** `filesystems`:
      ```
      # egrep '^HOOKS' /etc/mkinitcpio.conf
      HOOKS=(base udev autodetect modconf block keyboard encrypt lvm2 filesystems fsck)
      ```
      _Read the comment documentation on `HOOKS` in the document to find out
      more._

   1. Generate `initramfs`:
      ```
      # mkinitcpio -p linux
      ```

1. Install a bootloader (e.g. `systemd-boot`, `grub`, `syslinux`, etc.):
   1. I will be using `systemd-boot`
      ```
      # bootctl --path=/boot/ install
      ```

   1. Edit the loader configuration using a text editor of your choice:
      ```apacheconf
      # cat /boot/loader/loader.conf
      default arch
      timeout 3
      editor 0
      ```

   1. Create the loader entry for the default `arch` entry specified above (_You
      can edit this name if desired._). Use `blkid /dev/sdaN` to find the UUID
      of your crypt device, and recall the volume name you gave your device
      above (_`main` in example below_):
      ```apacheconf
      # cat /boot/loader/entries/arch.conf
      title Arch Linux
      linux /vmlinuz-linux.img
      initrd /initramfs-linux.img
      options cryptdevice=UUID=9f1fc119-b1dc-49d8-9a5a-686ad9e2fd2e:volume root=/dev/mapper/main-root quiet rw
      ```

1. Create a root password using `passwd`.
1. Set a hostname:
   ```
   # echo "<your_hostname>" > /etc/hostname
   ```

1. Set up the time:
   ```
   # ln -fs /usr/share/zoneinfo/<continent>/<city/place> /etc/localtime
   # hwclock --systohc --utc
   ```

1. Set the locale to `en_US`:
   ```
   # sed -i 's/^\#en_US/en_US/' /etc/locale.gen
   # locale-gen
   # locale > /etc/locale.conf
   ```

1. Done!
   ```
   # exit
   # unmount -R /mnt
   # reboot
   ```
