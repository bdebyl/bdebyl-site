---
title: "Installing a Hardened Linux Kernel (Arch Linux)"
date: 2019-07-30
lastmod: 2019-07-30
tags: ["linux","security"]
categories: ["Blog"]
contentCopyright: true
hideHeaderAndFooter: false
---
It's generally good security practice to ensure that you're running a secure
kernel, and the best way to do so is by running a [hardened Linux
kernel](https://wiki.archlinux.org/index.php/security#Kernel_hardening).

<!--more-->

It is important to understand that this will not guarantee a fully secure and
bullet-proof kernel. However, it is more security-focused than the [vanilla
kernel](https://www.kernel.org/), and has the addition of allowing the user to
enable more hardening features. By default, the `linux-hardened` kernel on Arch
Linux has security leaning defaults.

# Laying the Ground Work
On Arch Linux, it's as simple as:
```
# pacman -S linux-hardened linux-hardened-headers
```
_Optionally (additionally) run `mkinitcpio -p linux-hardened` as root if
this wasn't already done automatically as part of the installation_

The steps to boot to the hardened kernel will change based on your boot
loader. Personally, I am using
[`systemd-boot`](https://wiki.archlinux.org/index.php/Systemd-boot) and will
therefore start with that.


## Boot Loader Configuration
### **`systemd-boot`**
Create a new loader config will need to be created on top of your existing one
in `/boot/loader/entries/`

**Example**
```apacheconf
title Arch Linux (Hardened)
linux /vmlinuz-linux-hardened
initrd /initramfs-linux-hardened.img
options ...
```
_The `options` line above will be specific to your system. This can be copied
from existing, working loader configurations or such as the one described in
[Installing Arch Linux](/post/archinstall/#set-up-linux-installation)_

Change the default **or** enable `auto-entries` to selectively boot from it in
`/boot/loader/loader.conf`

### **`grub`**
For grub, it should be as simple as running `grub-mkconfig -o
/boot/grub/grub.cfg` (_as root_)

### **`syslinux`**
Similar to `systemd-boot`, `syslinux` requires an additional entry in it's
configuration file, found at `/boot/syslinux/syslinux.conf`

**Example**
```apacheconf
PROMPT 1
TIMEOUT 50
DEFAULT archhardened

LABEL archhardened
    LINUX ../vmlinuz-linux-hardened
    APPEND root=/dev/sda2 rw
    INITRD ../initramfs-linux-hardened.img

...
```
<sub>Note that the `APPEND` may differ from the example, same with `options`
for `systemd-boot`</sub>

# Finish Line
It's that simple! There are additional system hardening steps one may opt to
take such as:

- [Restricting access to `dmesg`](https://wiki.archlinux.org/index.php/Security#Restricting_access_to_kernel_logs)
- [Restricting access to kernel pointers](https://wiki.archlinux.org/index.php/Security#Restricting_access_to_kernel_pointers_in_the_proc_filesystem)
- [Restricting module loading](https://wiki.archlinux.org/index.php/Security#Restricting_module_loading)

.. and [more](https://wiki.archlinux.org/index.php/Security#Kernel_hardening)!

On top of that, there are other tools one could leverage in addition to a
hardened kernel, though that's out-of-scope for this post. One example would be
something as simple as **disabling SSH password authentication**
(`/etc/ssh/sshd_config`):
```apacheconf
..
PasswordAuthentication no
..
```

This will force **requiring a public key** added to the `~/.ssh/authorized_keys`
file for the user you are connecting as. See `man ssh-copy-id` for an easy way
to do this prior to enabling this.
