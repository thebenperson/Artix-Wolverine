`timescale 1 ns / 1 ns

package PKGFont;

	// character dimensions in pixels

	parameter fontWidth  = 8;
	parameter fontHeight = 16;

	// bits needed to store character dimensions

	parameter bitsFontWidth  = $clog2(fontWidth);
	parameter bitsFontHeight = $clog2(fontHeight);

	// number of pixels per character
	parameter bitsFont       = fontWidth * fontHeight;

	// number of characters in the font
	// !! UPDATE THIS NUMBER BASED ON THE genfont.sh SCRIPT OUTPUT !!

	parameter chars    = 81;

	// bits needed to store the character number
	parameter bitsChar = $clog2(chars);

endpackage

// Font bitmap lookup module

// outputs:

//     - character bitmap

// inputs:

//     - character number corresponding to the output bitmap

module Font(

	output [PKGFont::bitsFont - 1:0] out,
	input  [PKGFont::bitsChar - 1:0] in

);

	// rom stores a bitmap for every character
	reg [PKGFont::bitsFont - 1:0] rom [PKGFont::chars - 1:0];

	// initialize the rom from the provided file
	initial $readmemh("font.hex", rom);

	// retrieve the corresponding bitmap from the lookup table based on
	// the character number

	assign out = rom[in];

endmodule
