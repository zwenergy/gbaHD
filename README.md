# gbaHD
An open-source GBA consolizer.

To create a stable video signal without buffering whole frames, but rather
go line-by-line, the quartz crystal of the GBA is removed. Instead, 
the FPGA generates the clock signal for the GBA.

## Wiring
You need some basic soldering skills to wire all signals of the GBA to the
FPGA board and the controller to the Arduino. All responsibility is on
you. **I do not take any responsibility for any potential damages.** The 
following wiring works well for me. **Yet again, all risk is up to you.
If you want a more out-of-the-box experience, I strongly suggest you to
do not tinker around with your devices.** This is a simply hobby project of 
mine without a lot of testing.

In general, the test points of the GBA motherboard are not made for a
lot of soldering, so try to keep your soldering quick.

### SEA pins
The following figure shows an overview of the pins used for signals on
the Spartan Edge Accelerator board and the pin names used.

![SEA pins](./figures/seapins.png "SEA pins")

### Video signals
The following figure shows the test points for the display signals on
the GBA motherboard. I only used a 32 pin model so far, but the 40 pin
should have a similar layout. The test points can be found on the
frontside of the GBA motherboard close to the top.

![SEA pins](./figures/displaypins.png "Display pins")

The connections between the GBA display signals and the FPGA board are 
as follows (check the previous figures for the pin names). The "GBA Testpoint" 
column notes the testpoint to be connected to the corresponding FPGA
pin. The next columns (GBA LCD XX-pin) give additional information where
this signal is placed on the display ribbon cable.

| **FPGA Pin** | **GBA Testpoint** | GBA LCD 40-pin | GBA LCD 32-Pin | GBA SP 34-Pin |
|-|-|-|-|-|
| IO0 | 2 | 26 | 25 | 25 |
| IO1 | 5 | 23 | 22 | 22 |
| ARD5 | 6 | 22 | 21 | 21 |
| IO2 | 7 | 21 | 20 | 20 |
| ARD6 | 8 | 20 | 19 | 19 |
| IO3 | 9 | 19 | 18 | 18 |
| ARD7 | 10 | 17 | 16 | 16 |
| IO4 | 11 | 16 | 15 | 15 |
| ARD8 | 12 | 15 | 14 | 14 |
| IO5 | 13 | 14 | 13 | 13 |
| ARD9 | 14 | 13 | 12 | 12 |
| IO6 | 15 | 12 | 11 | 11 |
| ARD10 | 16 | 11 | 10 | 10 |
| IO7 | 17 | 10 | 9 | 9 |
| ARD11 | 18 | 9 | 8 | 8 |
| ARD13 | 19 | 8 | 7 | 7 |
| IO9 | 22 | 3 | 2 | 2 |

### Audio signals
The GBA generates a stereo 8 bit audio signals as a PWM which is then
amplified. We pick up both PWM signals using the following two
connections (the test point names can be found on the silkscreen of the
GBA motherboard).

| GBA Test Point  | FPGA Pin |
|-----------------|----------|
| S01             | ARD2 |
| S02             | ARD3 |

### Clock signal
The clock crystal has to be removed and a pad of the former crystal is 
connected to an FPGA pin. The following figure shows which pad has to be 
connected (the highlighted one) to the FPGA pin.

![XTAL pin](./figures/xtal.png "XTAL pin")

| GBA | FPGA Pin |
|-----|----------|
| XTAL pad  | IO8 |


### Controller signals
A cheap Arduino (e.g., a small Nano) handles the controller input (the 
FPGA board is not used here, as we would run out of pins here). The
following figure shows the pinout of a SNES controller plug.

![SNES pinput](./figures/snes.png "SNES pinout")

The SNES controller port is connected to the Arduino pins as follows:

| SNES controller | Arduino Pin |
|-----------------|-------------|
| 5V              | 5V |
| Clk             | A1 |
| Latch           | A0 |
| Data            | A2 |
| Gnd             | Gnd |


The following table shows the connections between the GBA motherboard
and Arduino pins for simulating the button presses.

|  GBA Test Point  | Arduino Pin |
|------------------|-------------|
| TP6              | D2 |
| TP7              | D3 |
| TP5              | D4 |
| TP4              | D5 |
| TP0              | D6 |
| TP1              | D7 |
| TP9              | D8 |
| TP8              | D9 |
| TP3              | D10 |
| TP2              | D11 |

### Arduino-FPGA connection
To activate or change the pixel grid, a connection between the Arduino
and the FPGA board is needed.

|  FPGA Pin  | Arduino Pin |
|------------|-------------|
| ARD4       | A3 |


### Power connections
The GBA and Arduino can be powered via pins of the FPGA board. For the
GBA, the battery holders on the motherboard can be desoldered, as they are
not required anymore. Then connect the "B+" pad of the GBA motherboard to
the "3V3" pin of the SEA board and the GBA's "B-" pad to a GND pin of the
SEA board. Keep the power switch of the GBA on the ON position
(preferably fix it in this position, as the switch is quite smooth-running).

The Arduino requires 5V instead of 3.3V. For this, put the jumper 
"PWR_MODE" to the "ON" position. Then connect the 5V pin of the SEA
board's Arduino ICSP pins to the 5V pin of the Arduino.

## Custom Borders
Custom borders are currently in a kind of experimental state. Border images 
have to be in the dimensions of 320x180 pixels (going with the same resolution
of the Game Boy). Only the border is taken into account, the display area 
(middle 240x160) is ignored (see template.bmp). To generate a custom border, 
execute

`makeBorder.py <IMAGEFILE> (<CUTBITS>)`

The first parameter is the image file for the border, the second is an 
optional parameter for reducing the image color depth. After executing 
the script a new .vhdl should have been created. Replace the original 
`borderGen.vhdl` with this one and run the synthesis.

If the synthesis fails, the border is too complex. Try to simplify the 
border image or use the color depth reduction of the makeBorder.py script. 
The optional parameter sets the number of bits to reduce in color space. 
E.g., setting CUTBITS to 2 will reduce the color depth per color from 
8 bits to 6 bits.

## OSD, Smoothing and Pixel Grid
A 2x smoothing and 4x smoothing can be activated. These are slightly adapted
versions of the Scale2x algorithm. Note: Smoothing is currently disabled 
for 1080p resolution.

The pixel grid feature is currently also in an experimental state. Two
different pixel grids can be applied, a "bright" pixel grid (AGS feeling) 
or a "dark" pixel grid (AGB feeling).

To enter the OSD, press L+R+Select+Right. Smoothing and pixel grids can be activated there.

For the OSD, the connection between the 
FPGA board and the Arduino board (see previous sections) needs to be wired.


## FPGA Firmware
You can find the latest bitstream under the folder *bitstream*.

## TODOs

*README TODO:*
- Describe the overall project.
- Describe the different modules.
- Describe pinouts.
- Describe GBA video timing.
