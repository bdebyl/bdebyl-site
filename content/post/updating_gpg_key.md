---
title: "OpenPGP: Updating Key Expiration"
date: 2020-02-17
lastmod: 2020-02-17
tags: ["linux"]
categories: ["Blog"]
contentCopyright: true
hideHeaderAndFooter: false
---
It's a good idea to update your GPG key(s) before they expire. Mine is set to
expire year, from whence I last updated the expiration. Let's explore how this
is done!

<!--more-->

{{< admonition info Info >}}
If the reader is unfamiliar with OpenPGP, it's suggested to check out the prior
write-up on this blog: [**OpenPGP Best Practices (and Git)**](/post/gpg_best_practices_and_git/)
{{< /admonition >}}

# Importing Secret Keys

Personally, my secret (primary) key is not kept on any device. It's stored, and
backed up in encrypted external media devices (_USB, etc._) only to be imported
when keys require editing.

## Mounting Secure Device (LUKS)

This is done using `cryptsetup` and Linux Unified Key Setup[^1] (LUKS) for
encryption. Plugging in my USB device and mounting it requires only _one_
additional step. Instead of initially running `mount /dev/sdXN` we first must
"open" the encrypted drive via:

```bash
cryptsetup --type luks open /dev/sdXN encryptedusb
```

{{< sub >}}
The `encryptedusb` name is a user-specified friendly name that has
no relevance to accessing the drive
{{< /sub >}}

**Now** the device can be mounted to a directory, but not via the `/dev/sdXN` device
-- rather the `/dev/mapper/encryptedusb` device (_or whatever friendly name you
gave it_).

```bash
mount /dev/mapper/encryptedusb /mnt/media
```

## Backing up the Keys

Once the device has been securely mounted, it's a good idea to either export
the keys currently in the keyring **or** back-up the entire `~/.gnupg`
directory. The backup created will be stored on the previously mounted external
media device.

### GPG Key Export Backup

It's as simple as exporting the secret key, which will also contain your public
key:

```bash
gpg --armor --export-secret-key your@email.address > /mnt/media/some/dir/secretkey.gpg.bak
```

### GPG Directory Backup (optional)

This isn't entirely necessary, though it's never a bad idea to create a hard
back-up of the directory -- _just don't forget to remove it after!_

```bash
cp ~/.gnupg /mnt/media/some/backup/dir/.gnupg.bak
```

{{< sub >}}
Note: If the `~/.gnupg.bak` directory already exists, the above command will
copy it to `~/gnupg.bak/.gnupg`!
{{< /sub >}}

## Import and Update Expiration

Now that back-ups have been taken care of, the current keyring can either be
emptied, deleted, or simply worked with. That's up to the user.

### Import

In any event, the next step ultimately becomes importing the secret (primary)
key:

```bash
gpg --import /mnt/media/some/backup/dir/secretprimarykey.gpg
```

Verify the presence of the primary secret key, noting no presence of `sec#` in
the output indicating only a partially stripped secret key, via:

```bash
gpg --list-secret-keys

--------------------------------
sec  rsa4096 2017-11-21 [SC] [expires: 2021-02-16]
...
```

### Update

Updating the primary secret key and all it's sub keys is done via `gpg` in the
following manner:

```text
gpg --edit-key your@email.address

gpg> key 0
gpg> expire
...
Key is valid for? (0) 1y
Is this correct? (y/N) y

gpg> key 1
gpg> expire
Key is valid for? (0) 1y
Is this correct? (y/N) y

gpg> key 2
gpg> expire
Key is valid for? (0) 1y
Is this correct? (y/N) y

gpg> save
```

At this point, it's a good idea to send the key to the key server:

```bash
gpg --send-keys your@email.address
# or
gpg --keyserver pgp.mit.edu --send-keys your@email.address
```

## Cleanup

Now it's time to export the primary key and it's sub keys to the encrypted
external media device:

```bash
gpg --armor --export-secret-key your@email.address > /mnt/media/some/dir/secretkey.gpg
gpg --armor --export-secret-subkeys your@email.address > /mnt/media/some/dir/secretsubkey.gpg
```

Then, delete the primary secret key from your keyring and import **only** the
secret sub-key:

```bash
gpg --delete-secret-keys your@email.address
# reply 'yes' to the prompts as needed
gpg --import /mnt/media/some/dir/secretsubkey.gpg

```

### Verification

Once **only** the secret sub-key has been imported from the previous step, it
should be verified that the primary secret key is **not** in your keyring
(partial stripped key designated via `sec#` in the following):

```text
gpg --list-secret-keys

--------------------------------
sec#  rsa4096 2017-11-21 [SC] [expires: 2021-02-16]
...
```

{{< sub >}}
Note: `sec#` is what we are looking for. If it is indicated as only `sec` then
the primary secret key is **still** in the keyring! Repeat the prior steps to
attempt this again should you have to, but do so carefully.
{{< /sub >}}

## Unmounting

Lastly, remember to remove any local back-ups of the keyring or keys you stored
on the host! These should _only_ exist on the encrypted external device.

To un-mount the LUKS[^1] encrypted device, it's just one additional step to the
usual `umount`:

```bash
umount /mnt/media
cryptsetup --type luks close encryptedusb
```

That being done, it is safe to remove the external device!

# OpenKeychain Export & Import

Provided the reader is on an Android device, it can be mounted onto the local
host using `simple-mtpfs`.

## Mounting Android Device

First, plug in the Android device via a suitable USB cable to the local host and
set the USB managed option to "File Transfer" on the Android device. After this
the device should be mountable:

```bash
simple-mtpfs -l
1: Google IncNexus/Pixel (MTP)

simple-mtpfs --device 1 /mnt/android
```

## Export Secret Key

Once the device is mounted, we want to export the _partially_ stripped key (_not
the primary key_) to be imported using OpenKeychain on the Android device. The
next steps quote from the [OpenKeychain
FAQ](https://www.openkeychain.org/faq/#how-to-import-an-openkeychain-backup-with-gpg):

```bash
# generate a strong random password
gpg --armor --gen-random 1 20

# encrypt key, use password above when asked
gpg --armor --export-secret-keys YOUREMAILADDRESS | gpg --armor --symmetric --output /mnt/android/Downloads/mykey.sec.asc
```

Import it in OpenKeychain (_may require deletion in OpenKeychain first -- make
sure **not to revoke and delete!**_) and we're done!

[^1]: https://guardianproject.info/archive/luks/
