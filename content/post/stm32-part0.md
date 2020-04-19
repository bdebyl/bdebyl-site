---
title: "STM32F0 with libopencm3 - Part 0: Simple GPIO"
date: 2019-12-11
lastmod: 2019-12-11
tags: ["libopencm3", "stm32", "tutorial"]
categories: ["Tutorial"]
contentCopyright: true
hideHeaderAndFooter: false
---
One of the simplest projects to get started with the STM32 microcontroller
series: turn on the lights!

{{< thumb src="/static/img/stm32-examples/part0/stm32-basic-gpio-leds.jpeg" >}}

<!--more-->

{{< admonition warning "Windows Users" >}}
This series of write-ups assumes the reader is on a Linux operating
system. Windows users _can_ utilize the [**Windows Subsystems for
Linux**](https://docs.microsoft.com/en-us/windows/wsl/install-win10) though your
mileage may vary!

{{< /admonition >}}

# Straight to the Chase

For those that want to cut to the chase and save time, here is the full source
code with friendly names to get you started:

{{< admonition note "Source Code" true >}}
```C
#include <libopencm3/stm32/gpio.h>
#include <libopencm3/stm32/rcc.h>

#define LED_PORT    GPIOC
#define LED_BLU     GPIO8
#define LED_GRN     GPIO9

int main(void) {
    rcc_periph_clock_enable(RCC_GPIOC);
    gpio_mode_setup(LED_PORT, GPIO_MODE_OUTPUT, GPIO_PUPD_NONE, LED_BLU | LED_GRN);
    gpio_set_output_options(LED_PORT, GPIO_OTYPE_PP, GPIO_OSPEED_LOW, LED_BLU | LED_GRN);
    gpio_set(LED_PORT, LED_BLU | LED_GRN);

    while (1);
}
```
{{< /admonition >}}

# Getting Started with libopencm3
[libopencm3](https://github.com/libopencm3/libopencm3) is a very powerful,
useful, open-source firmware library for use in writing programs for various
different ARM Cortex-M microcontrollers. It's read me contains plenty of
information on the basics of getting started (typically done via `git
submodule`).

Additionally, there is a
[libopencm3-template](https://github.com/libopencm3/libopencm3-template)
repository to help in getting started.


## Dependencies
Prior to doing any ARM Cortex-M development, the necessary dependencies need to
be installed in order to successfully build/compile source code into a binary
capable of being flashed (written) onto the microcontroller:

- **GNU Arm Embedded Toolchain**[^1]: Typically available from the package manager
 (_i.e. `arm-none-eabi-gcc`, `arm-none-eabi-binutils`, `arm-none-eabi-newlib`, and
 optionally `arm-none-eabi-gdb`_)
- **make**: Usually pre-installed with most Linux distributions, a build
  automation tool exceptionally useful for C/C++ compiling.
- **Text Editor or IDE**: Anything, _really_.

## Flashing the STM32F0 Discovery Board
The discovery series boards provided by ST come with an on-board
[ST-LINK/V2](https://www.st.com/en/development-tools/st-link-v2.html)
programmer. There are several ways to flash your build programs using this,
though my preference is [stlink](https://github.com/texane/stlink) by Texane.

The GCC ARM GDB (GNU Debugger) _does_ let you write programs, but requires some
additional know-how and minor legwork that may complicate
understandings. However, it is an immensely powerful debugging tool that should
not be overlooked for too long! For the sake of brevity, this guide will omit
diving into that until later.

## Makefile
The aforementioned `libopencm3-examples` repository provides a useful, yet
overly complex, Makefile. For the reader, this has been boiled down (_assuming
they are also using `stlink` mentioned above_) the following, simple Makefile[^2] on
my GitLab[^3].

To flash, it's as simple as `make flash` (_will also build the binary for your
convenience_).

## Linker Script
The loader (`.ld`) file is specific to the _flavor_ of ARM Cortex-M
microcontroller being used. The authors of `libopencm3` provide example
loader files that can be used for most projects (_e.g. located in
`libopencm3/lib/stm32/f0/` of the repo_). However, these may not always be
available and may need to be modified or created from scratch, by the developer,
for proper use. There are several articles online that go into detail about
linker scripts

## Project Structure
The Makefile, as of writing this, assumes your project directory structure has
`libopencm3` either cloned, copied, or initialized as a git submodule within the
same directory of your `main.c`. It is advised that you look through the
Makefile's variables of things you may want to change:

```
.
├── libopencm3
├── main.c
├── Makefile
└── stm32f0.ld
```

# Explanation

{{< admonition info "Naming Convention" >}}
As a note to the reader: below I will not refer to the GPIO port or pins using
the `#define` friendly names from above. This is purely for the sake
of clarity in hopes of avoiding confusion.
{{< /admonition >}}

Although the source code is fairly simple, lets dive into it at least
_somewhat_.

For starters, why were pins `GPIO8` and `GPIO9` on the `GPIOC` port being used?
The answer can be found after a quick review of the STM32F0 Discovery User Manual[^4]:

{{< img src="/static/img/stm32-examples/part0/stm32f0-discover-led-diagram.png"
    sub="LEDs shown on circuit diagram connected to PC8 and PC9">}}

The Discovery board comes with two LEDs for use by the user, tied to Port C pins
8 (blue LED), and 9 (green LED).

## Reset and Clock Control (RCC)
The **RCC**, and it's registers, are an important part in _using_ the STM32
microcontroller's peripherals. Luckily, utilizing `libopencm3` we can forego
bit-banging our way through each register's bits found in the reference
manual[^5] and simply utilize the GPIO port that we need -- in this case
`GPIOC`:
```C
rcc_periph_clock_enable(RCC_GPIOC);
```

## GPIO Setup
Next, we need to define what mode we want the GPIO pins on their respective port
to be along with the internal pull-up or pull-down resistor mode:

| GPIO Mode          | Description                                                               |
|--------------------|---------------------------------------------------------------------------|
| `GPIO_MODE_INPUT`  | (**default**) Digital input                                               |
| `GPIO_MODE_OUTPUT` | Digital output                                                            |
| `GPIO_MODE_AF`     | Alternate Function (requires defining _which_ alternate function desired) |
| `GPIO_MODE_ANALOG` | Analog (for use with ADC or DAC capable GPIO)                             |

| PUPD Mode            | Description                                             |
|----------------------|---------------------------------------------------------|
| `GPIO_PUPD_NONE`     | (**default**) No internal pull-up or pull-down resistor |
| `GPIO_PUPD_PULLUP`   | Internal pull-up resistor                               |
| `GPIO_PUPD_PULLDOWN` | Internal pull-down resistor                             |

<center><sub><i>Note: The documentation for these functions, provided by `libopencm3`
authors, along with the function definition can be found
[**here**](https://libopencm3.org/docs/latest/html/)</i></sub></center>


Having clarified that, as we want to **drive** the LEDs, we will need to
configure the pins as outputs with no internal pull-up or pull-down resistor:
```C
gpio_mode_setup(GPIOC, GPIO_MODE_OUTPUT, GPIO_PUPD_NONE, GPIO8);
gpio_mode_setup(GPIOC, GPIO_MODE_OUTPUT, GPIO_PUPD_NONE, GPIO9);
```

_Simplified using bitwise[^6] OR:_
```C
gpio_mode_setup(GPIOC, GPIO_MODE_OUTPUT, GPIO_PUPD_NONE, GPIO8 | GPIO9);
```

## GPIO Output Options Setup
Now that the GPIO mode has been set up, the GPIO output options need to be
defined as well. This will encompass the output type, and output speed:

| Output Type      | Description                                 |
|------------------|---------------------------------------------|
| `GPIO_OTYPER_PP` | (**default**) Push-pull "totem pole" output |
| `GPIO_OTYPER_OD` | Open-drain output                           |

| Output Speed         | Description                                       |
|----------------------|---------------------------------------------------|
| `GPIO_OSPEED_HIGH`   | High output speed                                 |
| `GPIO_OSPEED_MED`    | Medium output speed                               |
| `GPIO_OSPEED_LOW`    | (**default**) Low output speed                    |
| `GPIO_OSPEED_100MHZ` | Up to 100MHz output speed (_equivalent to high_)  |
| `GPIO_OSPEED_50MHZ`  | Up to 50MHz output speed                          |
| `GPIO_OSPEED_25MHZ`  | Up to 25MHz output speed (_equivalent to medium_) |
| `GPIO_OSPEED_2MHZ`   | Up to 2MHz output speed (_equivalent to low_)     |

<center><sub><i>Refer to the device datasheet for the frequency specifications
and the power supply and load conditions for each speed</i></sub></center>

We'll be driving an output LED, as opposed to sinking it (_typical
open-drain/open-collector sink configuration_), push-pull output mode will be
required. Since there isn't any switching to be done aside from the initial
"on", we don't require _any_ "speed" -- "no speed" not being an option
`GPIO_OSPEED_LOW` will suffice:

```C
gpio_set_output_options(GPIOC, GPIO_OTYPE_PP, GPIO_OSPEED_LOW, GPIO8);
gpio_set_output_options(GPIOC, GPIO_OTYPE_PP, GPIO_OSPEED_LOW, GPIO9);
```

_Simplified[^6]:_
```C
gpio_set_output_options(GPIOC, GPIO_OTYPE_PP, GPIO_OSPEED_LOW, GPIO8 | GPIO9);
```

## Turn it on!
There are no additional options required for the user to be able to now set, or
clear, the desired GPIO pins. Thus, we set it _and forget it_:

```C
gpio_set(GPIOC, GPIO8);
gpio_set(GPIOC, GPIO9);
```

_Simplified[^6]:_
```C
gpio_set(GPIOC, GPIO8 | GPIO9);
```

Lastly, we need to make sure our program never **exits** and does something
_undesirable_ by keeping it inside a loop:
```C
while(1);
```

This is just a condensed version of the following:

```C
while(1) {
    ; // Do nothing
}
```

<center><sub><i>The details of why this is important can be found in the [While(1) in Embedded
C -
Explained](http://www.learningaboutelectronics.com/Articles/While-(1)-embedded-C.php) article</i></sub></center>

**Voila!**

[^1]: [GNU Arm Embedded Toolchain](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm)
[^2]: [Makefile](https://gitlab.com/bdebyl/stm32f0-example-project/blob/b858d5e38026bcce3b8aad4085ffb665ddf63eef/Makefile) as of writing this post
[^3]: https://gitlab.com/bdebyl
[^4]: [STM32F0 Discovery User Manual](https://www.st.com/content/ccc/resource/technical/document/user_manual/30/ae/6e/54/d3/b6/46/17/DM00050135.pdf/files/DM00050135.pdf/jcr:content/translations/en.DM00050135.pdf)
[^5]: [STM32F0 Reference Manual](https://www.st.com/content/ccc/resource/technical/document/reference_manual/c2/f8/8a/f2/18/e6/43/96/DM00031936.pdf/files/DM00031936.pdf/jcr:content/translations/en.DM00031936.pdf)
[^6]: [Bitwise Operators in C](https://en.wikipedia.org/wiki/Bitwise_operations_in_C)
