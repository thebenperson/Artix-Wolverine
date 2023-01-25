`timescale 1 ns / 1 ns

// the top module

// outputs:

//     - VGA red signal
//     - VGA green signal
//     - VGA blue signal
//     - VGA horizontal timing signal
//     - VGA vertical timing signal

// inputs:

//     - UART output from the MIDI keyboard
//     - 100 MHz clock

module Top(

	output [3:0] vgaRed,
	output [3:0] vgaGreen,
	output [3:0] vgaBlue,
	output Hsync,
	output Vsync,

	input JA,
	input clk

);

	// outputs

	VGA::I vga;

	assign vgaRed   = vga.r;
	assign vgaGreen = vga.g;
	assign vgaBlue  = vga.b;
	assign Hsync	= vga.syncH;
	assign Vsync	= vga.syncV;

	// inputs

	// some numbers that can be displayed on the screen
	wire [PKGVideo::bitsNumber - 1:0] numbers [PKGVideo::numbers - 1:0];

	// set the first number to the last MIDI status byte

	MIDI::I midi;
	MIDI_RX midi_rx(midi, numbers[0], JA, clk);

	reg [MIDI::bits - 1:0] note;
	reg [MIDI::bits - 1:0] velocity;
	reg [MIDI::bits - 1:0] volume;

	always @(posedge midi.ready) begin

		// wait for a MIDI event

		// if value and note are zero this means it was a volume event
		if (!midi.value && !midi.note) volume <= midi.velocity;
		else begin

			// if it was a normal event

			// display the note that was pressed and only if it was a
			// key down event

			note     <= midi.value ? midi.note : 0;

			// display how hard the key was pressed
			velocity <= midi.velocity;

		end

	end

	// set the last number to the current volume
	assign numbers[9] = { 1'b0, volume };

	// set the other numbers to zero
	// eventually we will use these numbers to display the dial and
	// switch values

	assign numbers[1] = 0;
	assign numbers[2] = 0;
	assign numbers[3] = 0;
	assign numbers[4] = 0;
	assign numbers[5] = 0;
	assign numbers[6] = 0;
	assign numbers[7] = 0;
	assign numbers[8] = 0;

	// have the video module display the numbers, the note numbers, and
	// the note velocity

	Video video(vga, numbers, note, velocity, clk);

endmodule
