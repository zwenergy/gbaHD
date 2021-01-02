# gbaHD
A GBA to DVI converter.

To create a stable HDMI signal without buffering whole frames, but rather
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
the GBA motherboard. I only used a 40 pin model so far, but the 32 pin
should have a similar layout. The test points can be found on the
frontside of the GBA motherboard close to the top.

![SEA pins](./figures/displaypins.png "Display pins")

The connections between the GBA display signals and the FPGA board are 
as follows (check the previous figures for the pin names):

| GBA Display Pin | FPGA Pin |
|-----------------|----------|
| 2               | IO0   |
| 5               | IO1   |
| 6               | ARD5  |
| 7               | IO2   |
| 8               | ARD6  |
| 9               | IO3   |
| 10              | ARD7  |
| 11              | IO4   |
| 12              | ARD8  |
| 13              | IO5   |
| 14              | ARD9  |
| 15              | IO6   |
| 16              | ARD10 |
| 17              | IO7   |
| 18              | ARD11 |
| 19              | ARD13 |
| 22              | IO9   |

## TODOs

*README TODO:*
- Add the rest of the wiring.
- Describe the overall project.
- Describe the different modules.
- Describe pinouts.
- Describe GBA video timing.

*General TODO:*
- Cleanup
- Design PCB shield
- 1080p output
