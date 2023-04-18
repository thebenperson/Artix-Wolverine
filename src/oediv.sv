`timescale 1 ns / 1 ns

package PKGVideo;

	// screen dimensions in number of characters

	parameter int charsH = $floor(VGA::resH / PKGFont::fontWidth);
	parameter int charsV = $floor(VGA::resV / PKGFont::fontHeight);

	// total number of characters
	parameter chars = charsH * charsV;

	// bits needed to store the total number of characters
	parameter bitsChars = $clog2(chars);

	// bits needed to store the screen dimensions in number of characters

	parameter bitsCharsH = $clog2(charsH);
	parameter bitsCharsV = $clog2(charsV);

	// number of numbers to display on the left of the screen
	parameter numbers    = 1;

	// number of bits each number should have
	parameter bitsNumber = 8;

	parameter plotResH = (62 * PKGFont::fontWidth)  + 6;
	parameter plotResV = (09 * PKGFont::fontHeight) + 8 + 7;

	parameter bitsPlotResH = $clog2(plotResH);
	parameter bitsPlotResV = $clog2(plotResV);

endpackage

// the main video module

// outputs:
//     - all VGA signals

// inputs:

//     - 10 numbers to display on screen
//     - note number of last key to be pressed
//     - how hard last key was pressed
//     - 10 MHz clock

module Video(

	output VGA::I vga,

	input [PKGVideo::bitsNumber - 1:0] numbers [PKGVideo::numbers - 1:0],
	input [MIDI::bits - 1:0] note,
	input [MIDI::bits - 1:0] velocity,
	input [31:0] keys,

	input [PKG_ADC::bits - 1:0] adc [PKG_ADC::inputs - 1:0],
	input ready,

	input clk

);

	// VGA_SM outputs:

	// whether or not pixel is on screen
	wire enable;

	// current pixel coordinates

	wire [VGA::bitsResV - 1:0] row;
	wire [VGA::bitsResH - 1:0] column;

	// VGA state machine -- drives VGA timing signals
	VGA_SM vga_sm(enable, vga.syncH, vga.syncV, row, column, clk);

	// TextMode outputs:

	// whether or not text is located where the pixel is at
	wire valueText;

	// text module -- determines what text is displayed on screen
	TextMode tm(valueText, row, column, numbers, note, velocity);

	wire boundsH = (column > 132) && (column < 635);

	wire plotEnable1 = boundsH && (row > 039) && (row < 199);
	wire plotEnable2 = boundsH && (row > 199) && (row < 359);

	reg [PKGVideo::bitsPlotResV - 1:0] plot1 [PKGVideo::plotResH - 1:0];
	reg [PKGVideo::bitsPlotResV - 1:0] plot2 [PKGVideo::plotResH - 1:0];

	reg [PKGVideo::bitsPlotResH - 1:0] idx = 0;

	always @(posedge ready) begin

	   if (idx < PKGVideo::plotResH - 1) idx <= idx + 1;
	   else idx <= 0;

	   plot1[idx] <= (adc[0] * PKGVideo::plotResV) / { PKG_ADC::bits {1'b1} };
	   plot2[idx] <= (adc[1] * PKGVideo::plotResV) / { PKG_ADC::bits {1'b1} };

	end

	assign plotValue1 = plot1[column - 133] == 198 - row;
	assign plotValue2 = plot2[column - 133] == 358 - row;

	// set pixel to white if text is located where the pixel is at
	// don't output pixel if it is off screen
	// extend to four bits because the Basys 3 has 4 bit color

	assign vga.r = { 4{ enable & ((plotEnable1 & plotValue1 ) | valueText) } };
	assign vga.g = { 4{ enable & ((plotEnable2 & plotValue2 ) | valueText) } };
	assign vga.b = { 4{ valueText & enable } };

endmodule

// determines what text is displayed on screen

// outputs:

//     - whether or not text is located where the pixel is at

// inputs:

//     - pixel vertical coordinate
//     - pixel horizontal coordinate
//     - 10 numbers to display on screen
//     - note number of last key to be pressed
//     - how hard last key was pressed

module TextMode(

	output value,

	input [VGA::bitsResV - 1:0] row,
	input [VGA::bitsResH - 1:0] column,
	input [PKGVideo::bitsNumber - 1:0] numbers [PKGVideo::numbers - 1:0],
	input [MIDI::bits - 1:0] note,
	input [MIDI::bits - 1:0] velocity,
	input [31:0] keys

);

	// turns pixel coordinates into logical index
	// this is useful so that only one number needs to be compared
	// instead of two

	function int getIDX(int y, int x);

		return (y * PKGVideo::charsH) + x;

	endfunction

	// define memory to store characters to display on screen
	reg [PKGFont::bitsChar - 1:0] memory [PKGVideo::chars - 1:0];

	// define memory contents
	initial $readmemh("text.hex", memory);

	// find coordinates in terms of characters

	wire [PKGVideo::bitsCharsH - 1:0] x = column / PKGFont::fontWidth;
	wire [PKGVideo::bitsCharsV - 1:0] y = row    / PKGFont::fontHeight;

	// find pixel offset within the character

	wire [PKGFont::bitsFontWidth  - 1:0] xr = column - (x * PKGFont::fontWidth);
	wire [PKGFont::bitsFontHeight - 1:0] yr = row    - (y * PKGFont::fontHeight);

	// Font output:

	// bitmap of the current character
	wire [PKGFont::bitsFont - 1:0] out;

	// Font input:

	// the current pixel's logical index
	wire [PKGVideo::bitsChars - 1:0] idx = getIDX(y, x);

	// find the current character's bitmap from its logical index
	Font lut(out, f(idx));

	// find the current pixel within the bitmap
	assign value = out[(yr * PKGFont::fontWidth) + PKGFont::fontWidth - 1 - xr];

	// function returns the character number to use based on the cell's
	// logical index and the 10 numbers

	function [PKGFont::bitsChar - 1:0] f([PKGVideo::bitsChars - 1:0] idx);

		case (idx)

			// character 5 is '0'
			// number one

			getIDX(03, 13): return 5 + (numbers[0] / 100);
			getIDX(03, 14): return 5 + (numbers[0] % 100) / 10;
			getIDX(03, 15): return 5 + (numbers[0] % 100) % 10;

			// last note value

			getIDX(26, 03): return 5 + (note % 100) / 10;
			getIDX(26, 04): return 5 + (note % 100) % 10;

			// last note value

			getIDX(26, 75): return 5 + (velocity % 100) / 10;
			getIDX(26, 76): return 5 + (velocity % 100) % 10;

			// if a key is pressed then indicate what key it was
			// character 1 is a music note and character 2 is a space

			getIDX(27, 08): return keys[00] ? 1 : 2;
			getIDX(27, 09): return keys[00] ? 1 : 2;

			getIDX(25, 10): return keys[01] ? 1 : 2;
			getIDX(27, 12): return keys[02] ? 1 : 2;
			getIDX(25, 14): return keys[03] ? 1 : 2;
			getIDX(27, 16): return keys[04] ? 1 : 2;
			getIDX(25, 18): return keys[05] ? 1 : 2;

			getIDX(27, 19): return keys[06] ? 1 : 2;
			getIDX(27, 20): return keys[06] ? 1 : 2;

			getIDX(27, 22): return keys[07] ? 1 : 2;
			getIDX(27, 23): return keys[07] ? 1 : 2;

			getIDX(25, 24): return keys[08] ? 1 : 2;
			getIDX(27, 26): return keys[09] ? 1 : 2;
			getIDX(25, 28): return keys[10] ? 1 : 2;

			getIDX(27, 29): return keys[11] ? 1 : 2;
			getIDX(27, 30): return keys[11] ? 1 : 2;

			getIDX(27, 32): return keys[12] ? 1 : 2;
			getIDX(27, 33): return keys[12] ? 1 : 2;

			getIDX(25, 34): return keys[13] ? 1 : 2;
			getIDX(27, 36): return keys[14] ? 1 : 2;
			getIDX(25, 38): return keys[15] ? 1 : 2;
			getIDX(27, 40): return keys[16] ? 1 : 2;
			getIDX(25, 42): return keys[17] ? 1 : 2;

			getIDX(27, 43): return keys[18] ? 1 : 2;
			getIDX(27, 44): return keys[18] ? 1 : 2;

			getIDX(27, 46): return keys[19] ? 1 : 2;
			getIDX(27, 47): return keys[19] ? 1 : 2;

			getIDX(25, 48): return keys[20] ? 1 : 2;
			getIDX(27, 50): return keys[21] ? 1 : 2;
			getIDX(25, 52): return keys[22] ? 1 : 2;

			getIDX(27, 53): return keys[23] ? 1 : 2;
			getIDX(27, 54): return keys[23] ? 1 : 2;

			getIDX(27, 56): return keys[24] ? 1 : 2;
			getIDX(27, 57): return keys[24] ? 1 : 2;

			getIDX(25, 58): return keys[25] ? 1 : 2;
			getIDX(27, 60): return keys[26] ? 1 : 2;
			getIDX(25, 62): return keys[27] ? 1 : 2;
			getIDX(27, 64): return keys[28] ? 1 : 2;
			getIDX(25, 66): return keys[29] ? 1 : 2;

			getIDX(27, 67): return keys[30] ? 1 : 2;
			getIDX(27, 68): return keys[30] ? 1 : 2;

			getIDX(27, 70): return keys[31] ? 1 : 2;
			getIDX(27, 71): return keys[31] ? 1 : 2;

			// none of the overrides matched -- look up what character
			// to use from memory

			default: return memory[idx];

		endcase

	endfunction

endmodule
