`timescale 1 ns / 1 ns

package PKGVideo;

	// screen dimensions in number of characters

	parameter int charsH = $floor(VGA::resH / PKGFont::fontWidth);
	parameter int charsV = $floor(VGA::resV / PKGFont::fontHeight);

	// bits needed to store the screen dimensions in number of characters

	parameter bitsCharsH = $clog2(charsH);
	parameter bitsCharsV = $clog2(charsV);

	// total number of characters
	parameter chars = charsH * charsV;

	// bits needed to store the total number of characters
	parameter bitsChars = $clog2(chars);

	// number of numbers to display on the left of the screen
	parameter numbers    = 10;

	// number of bits each number should have
	parameter bitsNumber = 8;

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

	// set pixel to white if text is located where the pixel is at
	// don't output pixel if it is off screen
	// extend to four bits because the Basys 3 has 4 bit color

	assign vga.r = { 4{ valueText & enable } };
	assign vga.g = { 4{ valueText & enable } };
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
	input [MIDI::bits - 1:0] velocity

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

	wire [PKGVideo::bitsCharsH - 1:0] x;
	wire [PKGVideo::bitsCharsV - 1:0] y;

	assign x = column / PKGFont::fontWidth;
	assign y = row    / PKGFont::fontHeight;

	// find pixel offset within the character

	wire [PKGFont::bitsFontWidth  - 1:0] xr;
	wire [PKGFont::bitsFontHeight - 1:0] yr;

	assign xr = column - (x * PKGFont::fontWidth);
	assign yr = row    - (y * PKGFont::fontHeight);

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

			// character 3 is '0'

			// number zero

			getIDX(03, 10): return 3 + (numbers[0] / 100);
			getIDX(03, 11): return 3 + (numbers[0] % 100) / 10;
			getIDX(03, 12): return 3 + (numbers[0] % 100) % 10;

			// number one

			getIDX(05, 10): return 3 + (numbers[1] / 100);
			getIDX(05, 11): return 3 + (numbers[1] % 100) / 10;
			getIDX(05, 12): return 3 + (numbers[1] % 100) % 10;

			// number two

			getIDX(07, 10): return 3 + (numbers[2] / 100);
			getIDX(07, 11): return 3 + (numbers[2] % 100) / 10;
			getIDX(07, 12): return 3 + (numbers[2] % 100) % 10;

			// number three

			getIDX(09, 10): return 3 + (numbers[3] / 100);
			getIDX(09, 11): return 3 + (numbers[3] % 100) / 10;
			getIDX(09, 12): return 3 + (numbers[3] % 100) % 10;

			// number four

			getIDX(11, 10): return 3 + (numbers[4] / 100);
			getIDX(11, 11): return 3 + (numbers[4] % 100) / 10;
			getIDX(11, 12): return 3 + (numbers[4] % 100) % 10;

			// number five

			getIDX(13, 10): return 3 + (numbers[5] / 100);
			getIDX(13, 11): return 3 + (numbers[5] % 100) / 10;
			getIDX(13, 12): return 3 + (numbers[5] % 100) % 10;

			// number six

			getIDX(15, 10): return 3 + (numbers[6] / 100);
			getIDX(15, 11): return 3 + (numbers[6] % 100) / 10;
			getIDX(15, 12): return 3 + (numbers[6] % 100) % 10;

			// number seven

			getIDX(17, 10): return 3 + (numbers[7] / 100);
			getIDX(17, 11): return 3 + (numbers[7] % 100) / 10;
			getIDX(17, 12): return 3 + (numbers[7] % 100) % 10;

			// number eight

			getIDX(19, 10): return 3 + (numbers[8] / 100);
			getIDX(19, 11): return 3 + (numbers[8] % 100) / 10;
			getIDX(19, 12): return 3 + (numbers[8] % 100) % 10;

			// number nine

			getIDX(21, 10): return 3 + (numbers[9] / 100);
			getIDX(21, 11): return 3 + (numbers[9] % 100) / 10;
			getIDX(21, 12): return 3 + (numbers[9] % 100) % 10;

			// last note value

			getIDX(26, 03): return 3 + (note % 100) / 10;
			getIDX(26, 04): return 3 + (note % 100) % 10;

			// last velocity value

			getIDX(26, 75): return 3 + (velocity % 100) / 10;
			getIDX(26, 76): return 3 + (velocity % 100) % 10;

			// if a key is pressed then indicate what key it was
			// character 1 is a music note and character 2 is a space

			getIDX(27, 08): return (note == 41) ? 1 : 2;
			getIDX(27, 09): return (note == 41) ? 1 : 2;
			getIDX(25, 10): return (note == 42) ? 1 : 2;
			getIDX(27, 12): return (note == 43) ? 1 : 2;
			getIDX(25, 14): return (note == 44) ? 1 : 2;
			getIDX(27, 16): return (note == 45) ? 1 : 2;
			getIDX(25, 18): return (note == 46) ? 1 : 2;

			getIDX(27, 19): return (note == 47) ? 1 : 2;
			getIDX(27, 20): return (note == 47) ? 1 : 2;
			getIDX(27, 22): return (note == 48) ? 1 : 2;
			getIDX(27, 23): return (note == 48) ? 1 : 2;

			getIDX(25, 24): return (note == 49) ? 1 : 2;
			getIDX(27, 26): return (note == 50) ? 1 : 2;
			getIDX(25, 28): return (note == 51) ? 1 : 2;
			getIDX(27, 29): return (note == 52) ? 1 : 2;
			getIDX(27, 30): return (note == 52) ? 1 : 2;

			getIDX(27, 32): return (note == 53) ? 1 : 2;
			getIDX(27, 33): return (note == 53) ? 1 : 2;

			getIDX(25, 34): return (note == 54) ? 1 : 2;
			getIDX(27, 36): return (note == 55) ? 1 : 2;
			getIDX(25, 38): return (note == 56) ? 1 : 2;
			getIDX(27, 40): return (note == 57) ? 1 : 2;
			getIDX(25, 42): return (note == 58) ? 1 : 2;

			getIDX(27, 43): return (note == 59) ? 1 : 2;
			getIDX(27, 44): return (note == 59) ? 1 : 2;
			getIDX(27, 46): return (note == 60) ? 1 : 2;
			getIDX(27, 47): return (note == 60) ? 1 : 2;

			getIDX(25, 48): return (note == 61) ? 1 : 2;
			getIDX(27, 50): return (note == 62) ? 1 : 2;
			getIDX(25, 52): return (note == 63) ? 1 : 2;

			getIDX(27, 53): return (note == 64) ? 1 : 2;
			getIDX(27, 54): return (note == 64) ? 1 : 2;
			getIDX(27, 56): return (note == 65) ? 1 : 2;
			getIDX(27, 57): return (note == 65) ? 1 : 2;

			getIDX(25, 58): return (note == 66) ? 1 : 2;
			getIDX(27, 60): return (note == 67) ? 1 : 2;
			getIDX(25, 62): return (note == 68) ? 1 : 2;
			getIDX(27, 64): return (note == 69) ? 1 : 2;
			getIDX(25, 66): return (note == 70) ? 1 : 2;
			getIDX(27, 67): return (note == 71) ? 1 : 2;
			getIDX(27, 68): return (note == 71) ? 1 : 2;
			getIDX(27, 70): return (note == 72) ? 1 : 2;
			getIDX(27, 71): return (note == 72) ? 1 : 2;

			// none of the overrides matched -- look up what character
			// to use from memory

			default: return memory[idx];

		endcase

	endfunction

endmodule
