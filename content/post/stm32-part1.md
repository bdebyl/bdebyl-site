---
title: "STM32F0 with libopencm3 - Part 1: Simple Timer"
date: 2020-02-12
lastmod: 2020-02-17
tags: ["libopencm3", "stm32", "tutorial"]
categories: ["Tutorial"]
contentCopyright: true
hideHeaderAndFooter: false
preview: "/static/img/stm32-examples/part1/blinky.gif"
---
After having reviewed [**Part 0**](/post/stm32-part0) of this series, we can now
explore controlling GPIO with the hardware timers! Other tutorials have used the
Systick timer as a good introduction to adding a delay for blinking an
LED. However, it is my belief that this leads to confusion for beginners and
only opens the door to misunderstandings. That being said, we will be using
timers and their associated GPIO ports with Alternate Function modes.

{{< img src="/static/img/stm32-examples/part1/blinky.gif"
    alt="Animated picture showing alternating blinking green and blue LEDs" >}}

<!--more-->

# Straight to the Chase

For those that want to cut to the chase and save time, here is the full source
code with friendly names to get you started:

{{< admonition note "Source Code" true >}}

```C
#include <libopencm3/stm32/gpio.h>
#include <libopencm3/stm32/rcc.h>
#include <libopencm3/stm32/timer.h>

#define LED_PORT    GPIOC
#define LED_PIN_BLU GPIO8
#define LED_PIN_GRN GPIO9
#define TIM_PSC_DIV 48000
#define SECONDS     1

volatile unsigned int i;

int main(void) {
    rcc_clock_setup_in_hsi_out_48mhz();
    rcc_periph_clock_enable(RCC_GPIOC);
    rcc_periph_clock_enable(RCC_TIM3);

    gpio_mode_setup(LED_PORT, GPIO_MODE_AF, GPIO_PUPD_NONE, LED_PIN_BLU | LED_PIN_GRN);
    gpio_set_output_options(LED_PORT, GPIO_OTYPE_PP, GPIO_OSPEED_HIGH,
                            LED_PIN_BLU | LED_PIN_GRN);
    gpio_set_af(LED_PORT, GPIO_AF0, LED_PIN_BLU | LED_PIN_GRN);

    timer_set_mode(TIM3, TIM_CR1_CKD_CK_INT, TIM_CR1_CMS_EDGE, TIM_CR1_DIR_UP);

    // The math for seconds isn't quite right here
    timer_set_prescaler(TIM3, (rcc_apb1_frequency/TIM_PSC_DIV)/2*SECONDS);
    timer_disable_preload(TIM3);
    timer_continuous_mode(TIM3);
    timer_set_period(TIM3, TIM_PSC_DIV);

    timer_set_oc_mode(TIM3, TIM_OC3, TIM_OCM_PWM1);
    timer_set_oc_mode(TIM3, TIM_OC4, TIM_OCM_PWM2);

    int tim_oc_ids[2] = { TIM_OC3, TIM_OC4 };

    for (i = 0; i < (sizeof(tim_oc_ids)/sizeof(tim_oc_ids[0])); ++i) {
        timer_set_oc_value(TIM3, tim_oc_ids[i], (TIM_PSC_DIV/2));
        timer_enable_oc_output(TIM3, tim_oc_ids[i]);
    }

    timer_enable_counter(TIM3);

    while (1) {
        ;
    }

    return 0;
}
```

{{< /admonition >}}

# Set up the GPIO

Assuming the reader is either familiar with GPIO setup for the STM32F0, or has
reviewed [**Part 0**](/post/stm32-part0) of this series we will set up the GPIO
pins tied to the LEDs (_port C, pins 8 and 9_) in the Alternate Function mode.

Knowing that we'll be using `GPIOC`, we should enable this peripheral:

```C
rcc_periph_clock_enable(RCC_GPIOC);
```

## Alternate Functions

The STM32 microcontroller's GPIO has a hardware feature allowing you to tie
certain port's pins to a different register as part of the output or input
control:
{{< img src="/static/img/stm32-examples/part1/stm32-af-diagram.png"
    sub="GPIO Alternate Function Diagram"
    alt="Screenshots of alternate function circuit diagram for the STM32F0" >}}

For accomplishing this, a few things need to happen:

1. The desired GPIO pins need to be set to `GPIO_MODE_AF` in `gpio_mode_setup()`
1. The alternate function mode number `GPIO_AFx` has to be set for the pins using `gpio_set_af()`

{{< admonition warning "Note for Different STM32Fx Microcontrollers" >}}
Review the datasheet for the specific **STM32Fx** microcontroller being
programmed, as the Alternate Function mappings may be *significantly* different!
{{< /admonition >}}

## GPIO Alternate Function Setup

For the STM32F0 we are using in this series, the Alternate Function selection
number desired is `GPIO_AF0` for use with `TIM3_CH3` (_timer 3, channel 3_) and
`TIM3_CH4` (_timer 3, channel 4_):
{{< img src="/static/img/stm32-examples/part1/stm32-af-gpiomap.png"
    sub="STM32F051 Alternate Function Mapping"
    alt="Screenshot of alternate function pin definition table for STM32F0" >}}

Ultimately, the code with `libopencm3` becomes the following for our use case:

```C
gpio_mode_setup(GPIOC, GPIO_MODE_AF, GPIO_PUPD_NONE, GPIO8 | GPIO9);
gpio_set_output_options(GPIOC, GPIO_OTYPE_PP, GPIO_OSPEED_HIGH, GPIO8 | GPIO9);
gpio_set_af(GPIOC, GPIO_AF0, GPIO8 | GPIO9);
```

# Set up the General Purpose Timer

From the previous section we chose the two on-board LEDs on the STM32F0
Discovery board tied to `PC8` and `PC9`. From the Alternate Function GPIO
mapping, we know these will be Timer 3 (_channels 3, and 4_).

Knowing that we'll be using `TIM3`, we should enable this peripheral:

```C
rcc_periph_clock_enable(RCC_TIM3);
```

## Timer Mode

The first step in setting up the timer, similar to GPIO, is setting the timer
mode. The encompass the divider amount (_dividing the peripheral clock_),
alignment for capture/compare, and up or down counting:

| Divider Mode            | Description                                    |
|-------------------------|------------------------------------------------|
| `TIM_CR1_CKD_INT`       | No division (_use peripheral clock frequency_) |
| `TIM_CR1_CKD_INT_MUL_2` | Twice the the timer clock frequency            |
| `TIM_CR1_CKD_INT_MUL_4` | Four times the timer clock frequency           |

| Alignment Mode         | Description                                                                                        |
|------------------------|----------------------------------------------------------------------------------------------------|
| `TIM_CR1_CMS_EDGE`     | Edge alignment, counter counts up or down depending on direction                                   |
| `TIM_CR1_CMS_CENTER_1` | Center mode 1: counter counts up and down alternatively (_interrupts on counting down_)            |
| `TIM_CR1_CMS_CENTER_2` | Center mode 2: counter counts up and down alternatively (_interrupts on counting up_)              |
| `TIM_CR1_CMS_CENTER_3` | Center mode 3: counter counts up and down alternatively (_interrupts on both counting up or down_) |

| Direction          | Description   |
|--------------------|---------------|
| `TIM_CR1_DIR_UP`   | Up-counting   |
| `TIM_CR1_DIR_DOWN` | Down-counting |

For our purpose, it's easier to have no division (_multiplication_), edge
alignment, using up counting direction (_can be down-counting, too_):

```C
timer_set_mode(TIM3, TIM_CR1_CKD_CK_INT, TIM_CR1_CMS_EDGE, TIM_CR1_DIR_UP);
```

## Timer Prescaler

In addition to the timer clock, set by the peripheral clock (internal), each
timer has a perscaler value. This determines the counter clock frequency and is
equal to `Frequency/(Prescaler + 1)`. This is the value the timer will count to prior
resetting (default behavior). We can get the exact value of this frequency,
provided we didn't change the clock divisions via `rcc_apb1_frequency` (_unsigned
integer value_).

For the sake of simplicity in dividing the clock into easy decimal values, we
will utilize setting up the High Speed Internal clock to 48MHz and dividing by
48,000:

```C
rcc_clock_setup_in_hsi_out_48mhz(); // Place at the beginning of your int 'main(void)'
...

// SECONDS: integer value of period (seconds) of LED blink
timer_set_prescaler(TIM3, (rcc_apb1_frequency/48000)/2*SECONDS));
```

## Timer Period

Having set the prescaler to determine the maximum count of the timer, there is
an additional period we need to set. For our purposes, this will simply be the
same value of the prescaler:

```C
timer_set_period(TIM3, 48000);
```

## Timer Additional Configuration

There are two minor settings we want to configure for the timer:

1. Disable preloading the ARR[^1] (auto-reload register) when the timer is reset
1. Run the timer in continuous mode (never stop counting, clear the status
   register automatically)

```C
timer_disable_preload(TIM3);
timer_continuous_mode(TIM3);
```

## Timer Channel Output Compare Mode

Since we are utilizing Timer 3's channel 3 (`GPIOC8`), and channel 4 (`GPIOC9`)
we need to determine the output compare mode we want to use for each channel. By
default the mode for each channel is frozen (unaffected by the comparison of the
timer count and output compare value).

| Output Compare Mode  | Description                                                                        |
|----------------------|------------------------------------------------------------------------------------|
| `TIM_OCM_FROZEN`     | (default) Frozen -- output unaffected by timer count vs. output compare value      |
| `TIM_OCM_ACTIVE`     | Output active (high) when count equals output compare value                        |
| `TIM_OCM_TOGGLE`     | Similar to active, toggles the output state when count equals output compare value |
| `TIM_OCM_FORCE_LOW`  | Forces the output to low regardless of counter value                               |
| `TIM_OCM_FORCE_HIGH` | Forces the output to high regardless of counter value                              |
| `TIM_OCM_PWM1`       | Output is active (high) when counter is **less than** output compare value         |
| `TIM_OCM_PWM2`       | Output is active (high) when counter is **greater than** output compare value      |

Essentially, what we will be doing is using PWM (pulse-width modulation) at a
very slow speed to create an alternating "blinky" effect on the LEDs. Using the
alternating PWM output-compare modes will yield this effect:

```C
timer_set_oc_mode(TIM3, TIM_OC3, TIM_OCM_PWM1);
timer_set_oc_mode(TIM3, TIM_OC4, TIM_OCM_PWM2);
```

In layman's terms: _only one LED will be on at a time, alternating._

## Timer Channel Output Compare Value

Lastly, we need to set the values that the output compare looks to for it's
comparison. For this example, we want a 50%-on/50%-off time for ease of timing
the duration of LEDs on-time determined by the frequency and period of the
timer:

```C
// (48,000 / 2) = 24,000
timer_set_oc_value(TIM3, TIM_OC3, 24000);
timer_set_oc_value(TIM3, TIM_OC4, 24000);
```

### Exercise for the Reader

A fun exercise in C to reduce repetition would be by creating an array of timer
output compare address values and looping through them to set them to the same
value.

Garbage collection _may_ be discussed in a future post in this series, however
this is not intended to be a "How-To C" series and should instead focus on the
microcontroller. That being said, there is still some fun to have.

The following snippet will be provided as a note and exercise for the reader in
exploring memory allocation and garbage collection:

```C
int tim_oc_ids[2] = { TIM_OC3, TIM_OC4 };

for (i = 0; i < (sizeof(tim_oc_ids)/sizeof(tim_oc_ids[0])); ++i) {
    timer_set_oc_value(TIM3, tim_oc_ids[i], 24000);
}
```

<center><sub>_Determining the 'length' of an array in C is different than in
other languages.[^2]_</sub></center>

## Enable the Timer

Lastly, to kick everything off we need to enable both the timer and the relevant
output-compare outputs.

```C
// Note: these cannot be OR'd together
timer_enable_oc_output(TIM3, TIM_OC3);
timer_enable_oc_output(TIM3, TIM_OC4);

timer_enable_counter(TIM3);
```

### Another Exercise for the Reader

The same for loop for `timer_set_oc_value()` can be appended to
for `timer_enable_oc_output()` as discussed previously:

```C
int tim_oc_ids[2] = { TIM_OC3, TIM_OC4 };

for (i = 0; i < (sizeof(tim_oc_ids)/sizeof(tim_oc_ids[0])); ++i) {
    timer_set_oc_value(TIM3, tim_oc_ids[i], 24000);
    timer_enable_oc_output(TIM3, tim_oc_ids[i]);
}
```

# Fin

Lastly, as always, we should not forget to place the microcontroller in an
infinite loop:

```C
while (1);
```

The reasons for why this is done was discussed in [**Part
0: Turn it on!**](/post/stm32-part0/#turn-it-on)

[^1]: The Auto-Reload Register is the value automatically loaded into the timer when it finishes counting
[^2]: [Determining the size of an array in C](https://stackoverflow.com/a/37539)
