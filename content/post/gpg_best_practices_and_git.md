---
title: "OpenPGP Best Practices (and Git)"
date: 2019-02-17
lastmod: 2019-02-22
categories: ["Blog"]
tags: ["linux"]
---
I decided to start signing my Git commits for personal, and work Git
repositories. Currently, most third-party Git repository hosts only support
signed commits and **do not** support signed pushes.
<!--more-->

That being said, I have added my public key to my
[GitLab](https://gitlab.com/bdebyl), and set the global config to use my signing
key, and sign all of my commits.

```bash
git config --global user.signingKey 875953A2
git config --global commit.gpgSign true
```

For reference, I am directly referencing the subkey ID I use for **signing only**
denoted by `[S]`:
```
pub   rsa4096/ADAA54FC 2017-11-21 [SC] [expires: 2020-02-23]
uid                    Bastian de Byl <bastiandebyl@gmail.com>
sub   rsa4096/A72FC2F1 2017-11-21 [E] [expires: 2020-02-23]
sub   rsa4096/875953A2 2019-02-23 [S] [expires: 2020-02-23]
```
<sub>Note: _I am using git version `2.20.1` in the above example._</sub>


# Getting Started with OpenPGP
It is recommended to read through the
[Getting Started](https://www.gnupg.org/gph/en/manual/c14.html) page  on the
official GnuPG website. It is also **strongly** recommend to use the
`--full-gen-key` option in place of `--gen-key`. This will allow you to specify
additional details about your key, such as using a 4096-bit RSA key. Lastly,
create a separate subkey for **signing only** -- read more about that
[here](https://wiki.debian.org/Subkeys).

# OpenPGP Keyserver Pool
As of GnuPG version
[2.1.11](https://github.com/riseupnet/riseup_help/issues/294#issuecomment-192913705),
the `hpks.pool.sks-keyservers.net` CA certificate is installed and made use by
default meaning there is nothing to do.

However, if you are using older versions then obtain the CA and verify the
signature. Instructions can be found on the
[HKPS Pool Verification](https://sks-keyservers.net/verify_tls.php) page or by
reading further below.

## Verification
To verify and retrieve the necessary keys to do so (automatically, if possible):
```bash
gpg --auto-key-retrieve --verify sks-keyservers.netCA.pem.asc sks-keyservers.netCA.pem
```

The expected output:
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
`/usr/share/ca-certificates` to update the list of trusted CA certificates. Do
this via:

+ **ArchLinux:** `sudo update-ca-trust`
+ **Debian/Ubuntu, RHEL:** `sudo update-ca-certificates`


{{% admonition tip "CA Path" %}}
On my system the full path to the CA certs is:

- `/etc/ca-certificates/extracted/cadir/sks-keyservers.net_CA.pem`
{{% /admonition %}}

Two following parameters should be added to your `~/.gnupg` configuration files:

### GnuPG Versions >2.1


{{% admonition note "gpg.conf" %}}
```
keyserver hkps://hkps.pool.sks-keyservers.net
```
{{% /admonition %}}


{{% admonition note "dirmngr.conf" %}}
```
hkp-cacert /etc/ca-certificates/path/to/CA.pem
```
{{% /admonition %}}

### GnuPG Versions <2.1
{{% admonition note "gpg.conf" %}}
```
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
The
[OpenPGP Best Practices](https://riseup.net/en/security/message-security/openpgp/best-practices)
page is a good resource for finding out more on best practices. A few points
worth exploring, that I personally recommend:

- Keep an encrypted backup of your secret key
- Keep your primary key entirely offline
- Have a separate subkey for signing
