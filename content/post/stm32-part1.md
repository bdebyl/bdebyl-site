---
title: "STM32F0 with libopencm3 - Part 1: Simple Timer"
date: 2020-02-12
lastmod: 2020-02-12
draft: true
tags: ["libopencm3", "stm32", "tutorial"]
categories: ["Tutorial"]
contentCopyright: false
hideHeaderAndFooter: false
---
After having reviewed [**Part 0**](/post/stm32-part0) of this series, we can now
explore controlling GPIO with the hardware timers! Other tutorials have used the
Systick timer as a good introduction to adding a delay for blinking an
LED. However, it is my belief that this leads to confusion for beginners and
only opens the door to misunderstandings. That being said, we will be using
timers and their associated GPIO ports with Alternate Function modes.

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
    gpio_set_output_options(LED_PORT, GPIO_OTYPE_PP, GPIO_OSPEED_HIGH, LED_PIN_BLU | LED_PIN_GRN);
    gpio_set_af(LED_PORT, GPIO_AF0, LED_PIN_BLU | LED_PIN_GRN);

    timer_set_mode(TIM3, TIM_CR1_CKD_CK_INT, TIM_CR1_CMS_CENTER_1, TIM_CR1_DIR_UP);

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
    }

    timer_enable_oc_output(TIM3, TIM_OC3);
    timer_enable_oc_output(TIM3, TIM_OC4);

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

## Alternate Functions
The STM32 microcontroller's GPIO has a hardware feature allowing you to tie
certain port's pins to a different register as part of the output or input
control:
{{< img src="/static/img/stm32-examples/part1/stm32-af-diagram.png"
    sub="GPIO Alternate Function Diagram" >}}

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
    sub="STM32F051 Alternate Function Mapping" >}}


Ultimately, the code with `libopencm3` becomes the following for our use case:
```C
gpio_mode_setup(GPIOC, GPIO_MODE_AF, GPIO_PUPD_NONE, GPIO8 | GPIO9);
gpio_set_output_options(GPIOC, GPIO_OTYPE_PP, GPIO_OSPEED_HIGH, GPIO8 | GPIO9);
gpio_set_af(GPIOC, GPIO_AF0, GPIO8 | GPIO9);
```
