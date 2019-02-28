---
title: "ThinkPad USB Port Fix"
date: 2019-02-28
lastmod: 2019-02-28
categories: ["Blog"]
tags: ["electronics"]
---
From the moment that I first had my (_used_) ThinkPad X220, the bottom-right USB
port nearest to the SD card reader had been broken. The pad (_or bolster_) was
missing, along with 3 out of 4 pins having been completely broken off. Needless
to say this required fixing.

<!--more-->
{{< thumb src="/img/thinkpad-usb-fix/DSC04781.jpg" sub="Final result" >}}


# Damage Assessment
The first step was to look at the PCB to assess how this could be, if at all,
replaced. From the outside you could see the damage done. Note the single
pin left and lack of the inner pad (_bolster?_).

{{< thumb src="/img/thinkpad-usb-fix/DSC04722.jpg" sub="One pin remains" >}}


# Measure Twice
Next on the list: measurements. To find a suitable replacement receptacle, I
needed to have the relevant dimensions in comparing to receptacle part drawings
of those available for sale.

{{< thumbgallery >}}
    {{< thumb src="/img/thinkpad-usb-fix/DSC04714.jpg" >}}
    {{< thumb src="/img/thinkpad-usb-fix/DSC04718.jpg" >}}
{{< /thumbgallery >}}

Using generic, non-branded digital calipers I was able to get the following
**approximate** dimensions:

| Description                  |    Value |
|:-----------------------------|---------:|
| Total Length                 | _14.7mm_ |
| Total Width                  | _13.2mm_ |
| Pad Spacing (_along length_) |  _9.1mm_ |
| Pad Spacing (_along width_)  | _15.4mm_ |
| Pad Width                    |  _1.9mm_ |
<center><sub>Fig. 1</sub></center>


# Shopping with Purpose
Using the value above, I was able to track down a USB receptacle[^1] on
Digi-Key[^2] that matched my requirements very, _very_
closely.

## Resounding Comparison
Keep in mind the measured values were an eyeball approximation with a low cost,
unbranded digital caliper. Those values are nearly spot-on.

| Description                  | Measured |      Part | Difference  |
|:-----------------------------|---------:|----------:|:-----------:|
| Total Length                 | _14.7mm_ | _14.00mm_ | _**+.7mm**_ |
| Total Width                  | _13.2mm_ | _13.10mm_ | _**+.1mm**_ |
| Pad Spacing (_along length_) |  _9.1mm_ |   _9.1mm_ | **---**     |
| Pad Spacing (_along width_)  | _15.4mm_ |  _15.7mm_ | _**-.3mm**_ |
| Pad Width                    |  _1.9mm_ |  _2.30mm_ | _**-.4mm**_ |
<center><sub>Fig. 2</sub></center>

The part was ordered, and arrived quickly at my doorstep. Stacked on top of each
other the two receptacles matched up just as I had hoped.. **Fantastic!**

{{< thumb src="/img/thinkpad-usb-fix/DSC04773.jpg" >}}

# It's not Over yet
Initial attempts at desoldering the existing (_broken_) receptacle proved
futile. Even with liberal application of flux, high soldering iron temperatures
well beyond typical soldering temperatures[^3], the solder would not flow and
the part would not budge. However, I was able to remove the surface mount pads
though this proved useless later on.

I quickly realized it did not matter to take care in not damaging a broken part
for removal. Grabbing a nearby set of flush cutters I was able to easily remove
the broken receptacle! _However_, this wasn't **yet** the end.

The leftover cutoff pins still attached to the PCB proved impossible to
remove. I was able to get all through-hole header pins removed but one. After
having spent about half an hour on it with tweezers, solder wick, a solder
sucker (_desoldering pump_), and flush cutters, I gave up.

# Throwing in the Towel
It turned out the only way to attach the replacement was to modify the new part
to fit -- _luckily I had ordered two replacements as I broke the first one in
the modification "process"_. Cutting and bending the pins, I was able to get it
soldered on (poorly). There wasn't much wiggle room for cleaning up the
bodged-in replacement; this will have to do.

{{< thumb src="/img/thinkpad-usb-fix/DSC04774.jpg" >}}

The part was essentially soldered as a wholly surface mount part, which it is
not. This could have future issues due to a lack of solder-terminated strain
relief in connecting and disconnecting USB devices. In hindsight, I may have
been able to bend the flat pads towards the entry of the receptacle down to
attempt to solder them to the surface mount pads.

# All the King's horses, all the King's men
Alas, it was time to put the laptop back together. To my dismay there were
further problems. Due to the modification and forced fitment of the replacement,
the USB receptacle was sticking out too far off of the PCB preventing the
motherboard from correctly fitting. This was quickly solved by using a Dremel
with a low-grit sanding drum and removing material off of the receptacle. The
result was acceptable, and provided a tight fitment into the laptop case.

{{< thumb src="/img/thinkpad-usb-fix/DSC04775.jpg" sub="End of the journey" >}}

[^1]: [Molex Part No. 482580002](https://www.molex.com/molex/products/datasheet.jsp?part=active/0482580002_IO_CONNECTORS.xml&channel=Products)
[^2]: [Digi-Key Part No. WM7087CT-ND](https://www.digikey.com/products/en?keywords=WM7087CT-ND)
[^3]: Typical soldering temperatures are around 315-370°C (_600-700°F_)
