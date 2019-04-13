---
title: "Password Checking Script"
date: 2019-04-13
lastmod: 2019-04-13
draft: true
tags: ["linux","code"]
categories: ["Blog"]
contentCopyright: false
hideHeaderAndFooter: false
---
Having been inspired by the HIBP[^1] password checker, I set out to write a
script with the following goals:

1. Check for duplicate/re-used passwords
1. Check the strength of each password
1. Check passwords against the `pwnedpass` API

<!--more-->
# Preface
It's worth nothing that I use [`passwordstore`](https://www.passwordstore.org/)
to generate, and manage my passwords. On mobile, this is done using the official
[OpenKeychain](https://www.openkeychain.org/), and
[Password Store](https://github.com/zeapo/Android-Password-Store). Passwords are
shared across my devices using Git[^2]

# Pump Your Brakes
Instead of jumping right into checking all my passwords, in plain-text, against
the `pwnedpasswords` API, it would be best to figure out how to safely transform
them to `sha1sum`[^3]. The API supports sending the first 5 characters of a `sha1sum`,
returning a list of all `sha1sum`s of exposed passwords (_with the exposed
count_) for the user to verify them on their end.

# Gathering Passwords
The easiest way to get a comprehensive list (_associative array_[^4]) of
passwords and their `pass` path was to use `find` to look for `*.gpg` files in
my `.password-store` directory:
```bash
# Fetches all passwords in $PASSDIR and checks for duplicates (base check)
getpws()
{
    # Loop over the find (newline-in-filename safe)
    while read -r -d '' p; do
        # Remove the root directory, and file extension
        p=$(printf "%s" "$p" | sed "s|^$PASSDIR/||" | sed "s/.gpg//")

        # Collect the trimmed, sha1 passwords
        pwsha=$(pass "$p" | awk 'FNR==1 {printf "%s", $0}' | sha1sum | awk '{printf "%s", toupper($1)}')
        pws["$p"]="$pwsha"
    done < <(find "$PASSDIR" -name "*.gpg" -type f -print0)
}
```
To note, `find` with `-print0` is used to avoid printing newline characters
(_unlikely, but good practice_), so that we can utilize the null terminator `''`
within `read -d ''`. Also, `read -r` simply prevents backslashes from being
treated in a special way (_also good practice!_)[^5]

It may be worth mentioning, to folks less familiar with `awk`, that the
`FNR==1`, in this context, simply helps to get rid of any newline oddities from
being piped into `sha1sum`. I discovered incorrect `sha1sum` values **without**
`FNR==1` resulting in a useless password check!

{{% admonition note Note %}}
`IFS=` would not have fixed the above newline issue, as the problem stems
from the output of `pass "$p"` and **not** the filenames.
{{% /admonition %}}

That takes care of gathering our passwords, but we'll revisit this again in the
next part.

# Sharing is not Caring
The most efficient way of checking for duplicates was simply to iterate over the
array of passwords gathered, and check against the current one found in the
`getpws()` function's loop. The names of the duplicate passwords are stored in
_another_ associative array for printing later as part of the "report".
```bash
# Checks for duplicate sha1sums of passwords in the associative array
checkdupes()
{
    for i in "${!pws[@]}"; do
        if [[ "$2" == "${pws[$i]}" ]]; then
            pwdupes["$1"]="$i"
        fi
    done
}
```

That being done, we just incorporate it into the above `getpws()` loop!
```bash
getpws()
{
    while read -r -d '' p; do
        ...
        checkdupes "$p" "$pwsha"
    done < <(find "$PASSDIR" -name "*.gpg" -type f -print0)
}
```

This accomplishes our *first goal* of checking duplicate passwords --
**hooray!**

Next up: _Passwortstärke_

# TODO

[^1]: [Have I Been Pwned](https://haveibeenpwned.com/Passwords)
[^2]: [`pass` Extended Git Example](https://git.zx2c4.com/password-store/about/#EXTENDED%20GIT%20EXAMPLE)
[^3]: [SHA-1 (Secure Hashing Algorithm)](https://en.wikipedia.org/wiki/SHA-1)
[^4]: [Arrays (Bash Reference Manual)](https://www.gnu.org/software/bash/manual/html_node/Arrays.html)
[^5]: [`man read`](https://linux.die.net/man/2/read)
