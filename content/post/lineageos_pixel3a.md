---
title: "Installing LineageOS Unofficial on Pixel 3a"
date: 2020-07-13
lastmod: 2020-07-13
draft: false
tags: ["android", "security", "hacking"]
categories: ["Tutorial"]
contentCopyright: true
hideHeaderAndFooter: false
preview: "/static/img/lineageos-pixel3a/lineage-settings.png"
---
In this post I aim to highlight my findings in deciding to go through  the
process of installing LineageOS on my Pixel 3a. Currently, LineageOS does not
officially support the Pixel 3a. However, InvisibleK (Dan Pasanen) does host
updated versions of his unofficial LineageOS build for the Pixel 3a complete
with a custom recovery to utilize for this purpose!

{{< thumbgallery >}}
    {{< thumb src="/static/img/lineageos-pixel3a/lineage-settings.png"
        alt="Screenshot showing the LineageOS version and other LineageOS settings on the Pixel 3a" >}}
    {{< thumb src="/static/img/lineageos-pixel3a/lineage-trust.png"
        alt="Screenshot showing the LineageOS Trust feature" >}}
{{< /thumbgallery >}}


<!--more-->
# Thank You
Before going on any further, I'd like to take a moment to give my sincere thanks
to InvisibleK (Dan Pasanen). Having to set up the entire custom build for Pixel
3a of LineageOS myself would add far more overhead in the overall simple task in
trying to get LineageOS to work on a Pixel 3a!

# Preface
There are plenty of guides out there on how to install and set up ADB and
Fastboot on your host machine. For me, on Arch Linux, this was as simple as
running `pacman -S android-tools`. However, should you be on MacOS or Windows
you may have to find resources on how to go about this. I do not intend to go
over this here -- _sorry_

Additionally, this _guide_ also assumes the reader has some familiarity with ADB
and/or Fastboot.

# Source Files
If you, the reader, know what you're doing and simply just require the files
for your Pixel 3a they can be found here:
- https://updater.invisiblek.org/sargo

# Installation
{{< admonition warning "Warning!" >}}
If it isn't abundantly clear by now, be aware that you **will be destroying all
the data currently on your Pixel 3a** in the process of installing LineageOS on
your device! Stop now and back up any files, 2FA codes, or other prior to
proceeding.
{{< /admonition >}}

## Note about TWRP
As of writing this, TWRP[^1] (_a custom recovery commonly used in custom OS
installation_) does not support Android 10. This would have been the preferred
for a custom recovery, though not strictly required. Since we will be installing
LineageOS 17.1 for Android 10 we cannot use TWRP.

## Flash to Stock
Google is kind enough to provide a variety of versions of the stock images for
the Pixel devices. In my process of installing LineageOS, as it will be on
Android 10, I made sure to flash to the latest stock version of Pixel 3a Android
10. Do note that the versions are listed in reverse order, with the latest being
found in the bottom-most row.
- https://developers.google.com/android/images

Additionally, Google provides a helper script `flash-all` that I highly
recommend running as-is to flash your Pixel 3a to stock. This will take some

## Flash Custom Recovery
Using InvisibleK's build page, you'll find the required custom recovery image
for flashing found at the bottom of the list of zip files marked with a lone
"download" link.

{{< admonition info "Info" >}}
The `$` prepended in the code blocks below imply a terminal session (_or
command prompt_)
{{< /admonition >}}

Download, then flash it via the following steps:
1. Reboot to recovery
   ```bash
   $ adb reboot bootloader
   ```
1. Flash the custom recovery (_make sure to replace `N` with the version you
   downloaded, mine was '4'_)
   ```bash
   $ fastboot flash boot sargo-recovery-eng-N.img
   ```
1. Boot the custom recovery either by re-entering recovery mode or fastboot --
   make sure to wait for it to enter Android Recovery after
   ```bash
   $ fastboot boot sargo-recovery-eng-N.img
   ```

## Install LineageOS
Now that the custom recovery is set up and booted into, we're ready to install LineageOS!
1. **Important!** Once in recovery, ensure to `Wipe data/factory reset` prior to
   proceeding.
1. Select `Apply update from ADB`
1. ADB Sideload the version, if not latest, of LineageOS you want for your Pixel
   3a
   ```bash
   $ adb sideload lineage-17.1-2020517-UNOFFICIAL-sargo.zip
   ```
1. Wait for installation to complete then select 'Reboot system now' from the
   recovery menu
1. **Enjoy LineageOS!**

## Verification
Once in LineageOS, you can browse the settings to verify the installation and
set up Trust the preferred way. Personally, I chose to leave the defaults.

# Bugs / Issues
I plan to keep this list of bugs and issues I discover up to date, but this is
what I have encountered so far:
- WiFi calling does not seem to work

[^1]: [Team Win Recovery Project](https://twrp.me/)
