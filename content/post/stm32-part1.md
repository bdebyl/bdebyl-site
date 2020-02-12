---
title: "STM32 with libopencm3 - Part 1: Simple Timer"
date: 2020-02-12
lastmod: 2020-02-12
draft: true
tags: ["libopencm3", "stm32", "tutorial"]
categories: ["Tutorial"]
contentCopyright: false
hideHeaderAndFooter: false
---
After having reviewed [part 0](/post/stm32-part0) of this series, we can now
explore controlling GPIO with the hardware timers! Other tutorials have used the
Systick timer as a good introduction to adding a delay for blinking an
LED. However, it is my belief that this leads to confusion for beginners and
only opens the door to misunderstandings. That being said, we will be using
timers and their associated GPIO ports with Alternate Function modes.

<!--more-->
