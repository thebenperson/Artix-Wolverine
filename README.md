# Artix Wolverine
## 2023 UVU Capstone Project
### Ethan Granucci and Ben Stockett

---

### Project Structure:

```
.
├── bin
│   └── *
├── doc
│   └── *
├── Makefile
├── README.md
├── res
│   ├── font.psfu
│   └── text.txt
├── src
│   ├── agv.sv
│   ├── constraints.xdc
│   ├── font.hex
│   ├── font.sv
│   ├── midi.sv
│   ├── oediv.sv
│   ├── text.hex
│   └── top.sv
├── tests
│   ├── font.sv
│   ├── midi.sv
│   ├── top.sv
│   ├── vga.sv
│   └── video.sv
└── tools
    ├── genfont.sh
    ├── gentext.sh
    └── midi.sh
```

### `bin/`: Executables

---

`Makefile`: A [Makefile](https://www.gnu.org/software/make) to build simulations with the [Icarus Verilog](http://iverilog.icarus.com) simulator.

`README.md`: This document.

---

### `doc/`: Documentation

---

### `res/`: Data and resources
- `font.psfu`: The [PC screen font](https://en.wikipedia.org/wiki/PC_Screen_Font) used in this project.
- `text.txt`: Static text to be displayed on the screen.

---

### `src/`: Project sources
- `agv.sv`: Generation of VGA timing signals.
- `constraints.xdc`: Maps port names to their corresponding pins on the Basys 3 FPGA.
- `font.hex`: Contents of the font ROM.
- `font.sv`: Retrieves bitmaps corresponding to character numbers.
- `midi.sv`: A MIDI reciever module used to detect keyboard events.
- `oediv.sv`: Logic for drawing characters and numbers.
- `text.hex`: Contents of the ROM for static text to be displayed on the screen.
- `top.sv`: The top module.

---

### `tests/`: Testbenches
- `font.sv`: Testbench for the font module.
- `midi.sv`: Testbench for the MIDI reciever.
- `top.sv`: Testbench for the top module.
- `vga.sv`: Testbench for the VGA module.
- `video.sv`: Testbench for the video module.

---

### `tools/`: Various scripts
- `genfont.sh`: A script to extract the characters we want from the font.
- `gentext.sh`: A script to convert an ASCII text file to a binary encoding suitable for this project.
- `midi.sh`: A script to test the MIDI receiver module with [VMPK, a virtual MIDI keyboard](https://vmpk.sourceforge.io).

---

## Icarus Verilog Simulation:

Running `make` in the project directory will build the simulation with the testbench for the top module by default. To change the testbench, set the makefile variable `test`.

> For example, to include the testbench for the MIDI module, run `make test=midi`.

Run `make test` to start the simulation.

### Note:

Icarus Verilog has some trouble with files that start with `v`. That's why `agv.sv` is not named `vga.sv` and `oediv.sv` is not named `video.sv`.

---

## Synthesis:

Synthesis needs to be performed in Xilinx Vivado. Run `make export` and import the contents of the `src/` folder into a new Vivado project.
