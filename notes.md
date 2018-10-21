# Notes

The NES PPU, or Picture Processing Unit, generates a composite video signal with 240 lines of pixels

## DMA

Direct memory access (DMA) is a feature of computer systems that allows certain hardware subsystems to access main system memory (random-access memory), independent of the central processing unit (CPU).

Without DMA, when the CPU is using programmed input/output, it is typically fully occupied for the entire duration of the read or write operation, and is thus unavailable to perform other work. With DMA, the CPU first initiates the transfer, then it does other operations while the transfer is in progress, and it finally receives an interrupt from the DMA controller when the operation is done. This feature is useful at any time that the CPU cannot keep up with the rate of data transfer, or when the CPU needs to perform work while waiting for a relatively slow I/O data transfer. Many hardware systems use DMA, including disk drive controllers, graphics cards, network cards and sound cards. DMA is also used for intra-chip data transfer in multi-core processors. Computers that have DMA channels can transfer data to and from devices with much less CPU overhead than computers without DMA channels. Similarly, a processing element inside a multi-core processor can transfer data to and from its local memory without occupying its processor time, allowing computation and data transfer to proceed in parallel.

## NMI

In computing, a non-maskable interrupt (NMI) is a hardware interrupt that standard interrupt-masking techniques in the system cannot ignore. It typically occurs to signal attention for non-recoverable hardware errors.

https://wiki.nesdev.com/w/index.php/NMI
In the case of the NES, the /NMI line is connected to the NES PPU and is used to detect vertical blanking.

https://en.wikipedia.org/wiki/Vertical_blanking_interval
In a raster graphics display, the vertical blanking interval (VBI), also known as the vertical interval or VBLANK, is the time between the end of the final line of a frame or field and the beginning of the first line of the next frame.

### The frame and NMI
https://wiki.nesdev.com/w/index.php/The_frame_and_NMIs
The PPU generates a video signal for one frame of animation, then it rests for a brief period called vertical blanking. The CPU can load graphics data into the PPU only during this rest period. From NMI to the pre-render scanline, the NTSC NES PPU stays off the bus for 20 scanlines or 2273 cycles. Taking into account overhead to get in and out of the NMI handler, you can probably use roughly 2250 cycles. To get the most out of limited vblank time, don't compute your changes in vblank time. Instead, prepare a buffer in main RAM (for example, use unused parts of the stack at $0100-$019F) before vblank, and then copy from that buffer into VRAM during vblank.

you can only draw during VBlank

The PPU operates on a series of frames. The PPU does all this work to output a frame to the TV, then it repeats the exact same process. The frame can further be split into two generalized sections: VBlank and Rendering time.

There is, however, a way your program can be notified when VBlank first starts (as soon as the minute hand hits the 12 on the clock). This notification comes in the form of an NMI, or "non-maskable interrupt". No other way to know how soon is VBLANK and how much time is left in VBLANK.

NMI is a notification, whereas VBlank is a time period. 

A lot of newbies wonder why their drawing code is spilling outside of VBlank when they finish it all before their rti. They think that because NMI happens at the start of VBlank, then rti must be the end of VBlank. This, of course, is totally wrong. As soon as VBlank happens, it's like a race for you to get all of your drawing code done before time is up. Time may run out long before you hit your rti.

#### Separating Drawing from Logic

A solution to this is to flag that the drawing needs to be done, and then actually do it next VBlank. This could be done like so:

Do we keep 10 flags and check them all every VBlank? Not very efficient. In practice, you'll want to do something a little more generalized than this, something that will work with virtually everything.

The better solution to this is to buffer your drawing. That is, you copy what you want drawn somewhere to memory, then copy it to the PPU next VBlank. 

#### Buffering

Just like you need to designate a full page of RAM to shadow OAM, you should probably designate a significant portion of RAM to your drawing buffer. It doesn't have to be a full page, but you don't want to run out of space.

https://en.wikipedia.org/wiki/Run-length_encoding
"RLE scheme"
Run-length encoding (RLE) is a very simple form of lossless data compression in which runs of data (that is, sequences in which the same data value occurs in many consecutive data elements) are stored as a single data value and count, rather than as the original run. 

#### When to Turn Off PPU, NMIs

2 kind of drawing: bulk drawing and updating

Therefore, you should [safely] switch the PPU off, then do your bulk drawing.

Palette updates should be in VBlank (buffered), even if the PPU is off. T

As a general rule of thumb, leave NMIs on all the time. The only time they should be off is during your startup code where you're initializing everything. After that, once you turn them on, leave them on unless you have a very compelling reason to turn them off. There are many reasons for this:

!!!
Just do not have NMI or IRQ share variables or RAM space with your main code (or with each other -- remember that while an IRQ during NMI is impossible, an NMI during IRQ is very possible!). Of course, you'll still need some variables that both your interrupts and your main code use in order to communicate between them, such as needdraw in the above example.

!!!
Beware, however, that these variables need to be quickly accessible. You are most vulnerable to conflicts when something critical takes multiple instructions. For example, looking at the above you might think "He's got 3 'needsomething' flags up there, and they're all separate variables. That's wasteful. I'm going to combine all of those into a single variable where each bit is a flag." Sounds smart, right? Use 1 byte of RAM instead of 3, and all the flags are consolidated into a single variable. The downside to this, however, is it makes you vulnerable to conflicts because changing a flag now requires a series of instructions, rather than a single sta command:

!!!
Just remember the key to being interrupt-aware is to spot vulnerabilities. You're most vulnerable when something seemingly basic takes several instructions to do. Just be extra careful when writing code like that in your program, and make state changing code in your NMI/IRQ handlers conditional so that your main code can disable it for sections where it might introduce conflict vulnerabilities.

## Someone else's guide on NMI
https://wiki.nesdev.com/w/index.php/NMI_thread

----------

## Raster graphics
https://en.wikipedia.org/wiki/Raster_graphics

In computer graphics, a raster graphics or bitmap image is a dot matrix data structure that represents a generally rectangular grid of pixels (points of color), viewable via a monitor, paper, or other display medium. Raster images are stored in image files with varying formats.

A bitmap, a single-bit raster,[1] corresponds bit-for-bit with an image displayed on a screen, generally in the same format used for storage in the display's video memory, or maybe as a device-independent bitmap. A raster is technically characterized by the width and height of the image in pixels and by the number of bits per pixel (or color depth, which determines the number of colors it can represent).[2]

## PPU nametables
https://wiki.nesdev.com/w/index.php/PPU_nametables

         (0,0)     (256,0)     (511,0)
           +-----------+-----------+
           |           |           |
           |           |           |
           |   $2000   |   $2400   |
           |           |           |
           |           |           |
    (0,240)+-----------+-----------+(511,240)
           |           |           |
           |           |           |
           |   $2800   |   $2C00   |
           |           |           |
           |           |           |
           +-----------+-----------+
         (0,479)   (256,479)   (511,479)

A nametable is a 1024 byte area of memory used by the PPU to lay out backgrounds. Each byte in the nametable controls one 8x8 pixel character cell, and each nametable has 30 rows of 32 tiles each, for 960 ($3C0) bytes; the rest is used by each nametable's attribute table. With each tile being 8x8 pixels, this makes a total of 256x240 pixels in one map, the same size as one full screen.

## CPU References

Memory Map
https://wiki.nesdev.com/w/index.php/CPU_memory_map

CPU Registers
https://wiki.nesdev.com/w/index.php/CPU_registers

CPU status flags
https://wiki.nesdev.com/w/index.php/Status_flags

    Bit 7: Negative
    Bit 6: Overflow
    Bit 5: Always set
    Bit 4: Clear if interrupt vectoring, set if BRK or PHP
    Bit 3: Decimal mode (exists for compatibility, does not function on the Famicom/NES's 2A03/2A07)
    Bit 2: Interrupt disable
    Bit 1: Zero
    Bit 0: Carry

## RAM layout example
https://wiki.nesdev.com/w/index.php/Sample_RAM_map

Documents about programming for systems using the 6502 CPU often refer to RAM in 256-byte "pages". The NES has a 2048 byte RAM connected to the CPU, which provides eight such pages at $0000-$07FF. 

Indirect addressing modes on 6502 rely on the "zero page" or "direct page", which lies at $0000-$00FF. Some other addressing modes can read or write the zero page slightly faster. The stack instructions (PHA, PLA, PHP, PLP, JSR, RTS, BRK, RTI) always access the "stack page", which lies at $0100-$01FF. But you can use the parts of the stack page that those instructions aren't using.

$0000-$000F 16 bytes    Local variables and function arguments
$0010-$00FF 240 bytes   Global variables accessed most often, including certain pointer tables
$0100-$019F 160 bytes   Data to be copied to nametable during next vertical blank (see The frame and NMIs)
$01A0-$01FF 96 bytes    Stack
$0200-$02FF 256 bytes   Data to be copied to OAM during next vertical blank
$0300-$03FF 256 bytes   Variables used by sound player, and possibly other variables
$0400-$07FF 1024 bytes  Arrays and less-often-accessed global variables

## APU 
https://wiki.nesdev.com/w/index.php/APU

The NES APU is the audio processing unit in the NES console which generates sound for games.

APU Registers
https://wiki.nesdev.com/w/index.php/APU_registers

## ALU
Arithmetic logic unit

Is a thing. Accesses the accumulator in NES.

## PPU 
Picture processing unit.

PPU Registers
https://wiki.nesdev.com/w/index.php/PPU_registers

## NES Programming cheat sheet
https://en.wikibooks.org/wiki/NES_Programming

----------

I feel generally confused about how sprites are laid out. 

## PPU Nametables
https://wiki.nesdev.com/w/index.php/PPU_nametables

Are the sprite maps.

## OAM

The OAM (Object Attribute Memory) is internal memory inside the PPU that contains a display list of up to 64 sprites, where each sprite's information occupies 4 bytes.

----------

## Useful placeholder graphics
https://wiki.nesdev.com/w/index.php/Placeholder_graphics

Develop an engine
Make a playable tech demo
Attract artists
Make the game itself, as a total conversion mod of the demo that you produced in step 2

---------

## Drawing NES Screens

NES Screen tool - Download link.
https://shiru.untergrund.net/software.shtml

NES ripped fonts
https://forums.nesdev.com/viewtopic.php?t=8440

---------

To generate NES Images
1. Rip some png of a font
2. Open with I-CHR tool. It will convert to a chr binary.
3. IT WORKS. import into the game as a `incbin`

---------

## Text Engine

Given english text
Convert to encoding of tile offset into the chr data.
given start (x,y), write out the text to the buffer of the nametable(?)

Buffer storage format:

    byte    0 = length of data (0 = no more data)
    byte    1 = high byte of target PPU address
    byte    2 = low byte of target PPU address
    byte    3 = drawing flags:
                bit 0 = set if inc-by-32, clear if inc-by-1
    bytes 4-X = the data to draw (number of bytes determined by the length)