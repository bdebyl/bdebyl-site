---
title: "Password Checking Script"
date: 2019-04-13
lastmod: 2019-04-13
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
The full **source code** for this script can be found in my public scripts
repository:
[scripts/bash/pass-check.sh](https://gitlab.com/bdebyl/scripts/blob/master/bash/pass-check.sh)

It's worth nothing that I use [`passwordstore`](https://www.passwordstore.org/)
to generate, and manage my passwords. On mobile, this is done using the official
[OpenKeychain](https://www.openkeychain.org/), and
[Password Store](https://github.com/zeapo/Android-Password-Store). Passwords are
shared across my devices using Git[^2]

# Pump Your Brakes
Instead of jumping right into checking all my passwords, in plain-text, against
the `pwnedpasswords` API, it would be best to figure out how to safely transform
them to SHA-1[^3]. The API supports sending the first 5 characters of a SHA-1
hash, returning a list of all SHA-1s of exposed passwords (_with the exposed
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
being piped into `sha1sum`. I discovered incorrect `sha1sum` outputs **without**
`FNR==1` resulting in a useless password check!

{{< admonition note Note >}}
`IFS=` would not have fixed the above newline issue, as the problem stems
from the output of `pass "$p"` and **not** the filenames.
{{< /admonition >}}

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

# Passwortstärke
The simplest method of password strength checking, with indications as to _why_
it's weak (_i.e. "Exists in attack dictionary", "Too short", etc._) was to use
[`cracklib`](https://github.com/cracklib/cracklib). Sadly, it's not the most
well-documented or fully-fledged application to fully determine password
strength though for my purposes it will be good enough (_I don't care to write
my own version of this, yet.._).
{{< admonition note Note >}}
I made this part of the script **optional**, as not every user would want to
install `cracklib` on their system.
{{< /admonition >}}

This addition was made in the following order:

1. First, we need to find the executable **and** create _yet another_ useful
   associative array for us to store the outputs (_a.k.a. messages_):
   ```bash
   CRACKLIB=$(command -v cracklib-check)
   declare -A pwscracklib
   ```

1. Then a convenient function to iterate over all found passwords, safely
   "expose" them, and run the check storing all **relevant** "outputs":
   ```bash
   # Run through the global pws associative array and check for suggestions
   checkcracklib()
   {
       for i in "${!pws[@]}"; do
           msg=$(pass "$i" | awk 'FNR==1 {printf "%s", $0}' | $CRACKLIB | sed s/^.*:[\ \\t]*//)
           if [[ ! "$msg" =~ "OK" ]]; then
               pwscracklib["$i"]="$msg"
           fi
       done
    }
   ```

Done! It's _that_ easy.

# Have you been Pwned
The last, but **most important**, step was to add the actual check against the
`pwnedpass` API check! This gets a bit fun as we use
[Shell Parameter Expansion](https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html)
to trim the first five, and everything _after_ the first five, characters of the
full SHA-1 string.

We need to get the full SHA-1 hash of each password, to then query the API using
**only the first 5 characters** of the SHA-1 hash! We will get a list of each
exposed (_"pwned"_) password's SHA-1 hash, and the amount of times they have
been leaked as a response. The prefix of the first 5 characters is dropped in
this list, thus we check for a match of our password using everything after the
first 5 characters of the SHA-1 hash and we're done!
```bash
# Check passwords against the HIBP password API (requires internet)
checkpwnapi()
{
    for i in "${!pws[@]}"; do
        # Check the pwnedpasswords API via hashing
        pwsha="${pws[$i]}"
        url="https://api.pwnedpasswords.com/range/${pwsha:0:5}"
        res=$(curl -s "$url" | grep "${pwsha:5}")
        if [ "$res" ]; then
            pwunsafe["$i"]=$(printf "%s" "$res" | awk -F ':' '{printf "%d", $2}')
        fi
    done
}
```

That's it! The left was to add some fun, colorful `printf`s as part of the final
output report. Feel free to look at the source code mentioned in the **Preface**
to see more details on this as it wasn't worth including in the write-up.

[^1]: [Have I Been Pwned](https://haveibeenpwned.com/Passwords)
[^2]: [`pass` Extended Git Example](https://git.zx2c4.com/password-store/about/#EXTENDED%20GIT%20EXAMPLE)
[^3]: [SHA-1 (Secure Hashing Algorithm)](https://en.wikipedia.org/wiki/SHA-1)
[^4]: [Arrays (Bash Reference Manual)](https://www.gnu.org/software/bash/manual/html_node/Arrays.html)
[^5]: [`man read`](https://linux.die.net/man/2/read)
