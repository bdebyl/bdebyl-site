---
title: "Auto-complete for libopencm3 in Emacs"
date: 2019-10-18
lastmod: 2019-10-18
tags: ["emacs", "linux"]
categories: ["Tutorial"]
contentCopyright: true
hideHeaderAndFooter: false
---
With some minor dependencies, it's fairly straightforward in setting up your
Emacs workflow to include IntelliSense-like auto-completion!

{{< img src="/static/img/emacs-clang-libopencm3/header-completion.png"
    sub="Header Completion" >}}

<!--more-->

# Dependencies

## System
Assuming you're running Linux, you'll need to have the following packages
installed:

- `cmake`
- `libclang`

## Emacs

### ELPA
If you already have ELPA/MELPA, feel free to skip this first part

To be able to easily fetch the packages, it's highly recommended you use the
**Emacs Lisp Package Archive** (ELPA). To do this, all that's required is to
simply add the following to your `init.el`/`.emacs`[^1] file:
```lisp
(require 'package)
(add-to-list 'package-archives
             '("melpa" . "https://melpa.org/packages/"))
(package-initialize)
```
<sub>Emacs will need to be restarted or reloaded to load the package
repository.</sub>

### Packages
Install the following packages in Emacs (`M-x package-install`):

- `irony`
- `company`
- `company-irony`
- `company-irony-c-headers` <sub>(_Required if you want header auto-completion_)</sub>


# Configuration

## Company
Company ([company-mode](http://company-mode.github.io/)) needs to be required,
added to the `after-init-hook` (_or similar / manually called_), and the back ends
to be added to it's list of usable back ends. This is done in the initialization
file[^1]:
```lisp
(require 'company)
(add-hook 'after-init-hook 'global-company-mode)
(add-to-list 'company-backends '(company-irony-c-headers company-irony))
```

## Irony
Initial setup of `irony` **requires** `M-x irony-install-server` to be run. If
errors are encountered, please ensure that you have the necessary [system
dependencies](https://github.com/Sarcasm/irony-mode#dependencies) installed.

Irony's `irony-mode` should be added to the relevant C/C++ mode hooks:
```lisp
(add-hook 'c++-mode-hook 'irony-mode)
(add-hook 'c-mode-hook 'irony-mode)
(add-hook 'objc-mode-hook 'irony-mode)
```

Additionally, it's a good idea to add the compile options auto setup helper
command to the `irony-mode` hook:
```
(add-hook 'irony-mode-hook 'irony-cdb-autosetup-compile-options)
```

# Usage
There are several ways to make `irony-mode` aware of what it should look for in
it's completion. My preferred method, though not the only one, is to simply add
my compile flags in the special `.clang_complete` file as part of the working
directory of the project.

For an STM32F0 project, the context of the `.clang_complete` file would be:
```
-I./libopencm3/include
-DSTM32F0
```
<sub>The above assumes that `libopencm3` is also places within the project
directory</sub>

{{< admonition warning Note >}}
There is a strange issue that is encountered with non-working completion for new
header include statements. The workaround for this includes running `M-x irony-server-kill`after new header
additions to your current working file. Irony's server is clever enough to
restart itself after a completion request is triggered via `TAB` so this is a
fairly uninvolved workaround.
{{< /admonition >}}

## Example
{{< img src="/static/img/emacs-clang-libopencm3/completion.png"
    sub="Completion" >}}

[^1]: [Emacs Initialization File]
    (https://www.gnu.org/software/emacs/manual/html_node/emacs/Init-File.html)
