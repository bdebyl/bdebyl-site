---
title: "GPG Best Practices (and Git)"
date: 2019-02-17
lastmod: 2019-02-18
categories: ["Blog"]
tags: ["linux"]
---
I decided to start signing my Git commits for personal, and work Git
repositories. Currently, most third-party Git repository hosts only support
signing commits, but **do not** support signing pushes.
<!--more-->

That being said, I've added my public key to my
[GitLab](https://gitlab.com/bdebyl), and set the global config to use my key,
and sign all of my commits:
```bash
git config --global user.signingKey ADAA54FC
git config --global commit.gpgSign true
```
_Note: I am using git version `2.20.1` in the above example._

# Getting Started with OpenPGP
It is recommended to read through the
[Getting Started](https://www.gnupg.org/gph/en/manual/c14.html) page  on the
official GnuPG website. However, I would **strongly** recommend using the
`--full-gen-key` option in place of the `--gen-key`. This will allow you to
specify additional details about your key, such as using a 4096-bit RSA key.

# OpenPGP Keyserver Pool
In addition to that, there came the addition of using the
[SKS Keyserver Pool](https://sks-keyservers.net/overview-of-pools.php) for
sending and receiving keys for OpenPGP. This can be done by obtaining the CA and
verifying the signature on the
[HKPS Pool Verification](https://sks-keyservers.net/verify_tls.php) page.

## Verification
```
gpg --auto-key-retrieve --verify sks-keyservers.netCA.pem.asc sks-keyservers.netCA.pem
```

The output received was as follows:
```
gpg: Signature made Wed 30 Mar 2016 11:06:29 AM EDT
gpg:                using RSA key 250B7AFED6379D85
gpg: key 0B7F8B60E3EDFAE3: 1214 signatures not checked due to missing keys
gpg: key 0B7F8B60E3EDFAE3: public key "Kristian Fiskerstrand <kristian.fiskerstrand@sumptuouscapital.com>" imported
gpg: marginals needed: 3  completes needed: 1  trust model: pgp
    gpg: depth: 0  valid:   2  signed:   0  trust: 0-, 0q, 0n, 0m, 0f, 2u
gpg: Total number processed: 1
gpg:               imported: 1
gpg: Good signature from "Kristian Fiskerstrand <kristian.fiskerstrand@sumptuouscapital.com>" [unknown]
gpg:                 aka "Kristian Fiskerstrand <kf@gnupg.net>" [unknown]
gpg:                 aka "Kristian Fiskerstrand <k_f@gentoo.org>" [unknown]
gpg:                 aka "Kristian Fiskerstrand <kf@sumptuouscapital.com>" [unknown]
gpg: Note: This key has expired!
Primary key fingerprint: 94CB AFDD 3034 5109 5618  35AA 0B7F 8B60 E3ED FAE3
     Subkey fingerprint: B4EA D120 C7F8 9A4A EA47  2707 250B 7AFE D637 9D85
```

## Adding the HKPS Pool CA
Once the signature has been verified, the CA can be moved over to
`/usr/share/ca-certificates` to add to your CA certificates via `sudo
update-ca-trust` (_Arch_) or `sudo update-ca-certificates` (_Debian/Ubuntu_).

{{% admonition tip "CA Path" %}}
On my system the full path to the CA certs is:

- `/etc/ca-certificates/extracted/cadir/sks-keyservers.net_CA.pem`
{{% /admonition %}}

Two following parameters should be added to your `~/.gnupg` configuration files:

### GnuPG Versions >2.1
{{% admonition note "gpg.conf" %}}
```apacheconf
keyserver hkps://hkps.pool.sks-keyservers.net
```
{{% /admonition %}}

{{% admonition note "dirmngr.conf" %}}
```apacheconf
hkp-cacert /etc/ca-certificates/path/to/CA.pem
```
{{% /admonition %}}

### GnuPG Versions <2.1
{{% admonition note "gpg.conf" %}}
```apacheconf
keyserver hkps://hkps.pool.sks-keyservers.net
keyserver-options ca-cert-file=/path/to/CA/sks-keyservers.netCA.pem
```
{{% /admonition %}}

## *Optional* - Ensure keys refreshed through keyserver
To ensure no keys are pulled from insecure sources, or that an attacked would
not be able to designate a keyserver they control, it is recommended to add the
following additional parameter to the above `gpg.conf` file:
```
keyserver-options no-honor-keyserver-url
```

---

# More Information
There is a whole load of information on
[OpenPGP Best Practices](https://riseup.net/en/security/message-security/openpgp/best-practices).
A few noteworthy points worth exploring:

- **Keep an encrypted backup of your secret key**
- Have a separate subkey for signing
- Keep your primary key entirely offline
