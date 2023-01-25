`timescale 1 ns / 1 ns

// testbench for the video module
// !! NOT COMPLETE !!

module testbench;

	// outputs

	VGA::I vga;

	reg [PKGVideo::bitsNumber - 1:0] numbers [PKGVideo::numbers - 1:0];

	reg [MIDI::bits - 1:0] note;
	reg [MIDI::bits - 1:0] velocity;

	// inputs

	reg clk;

	Video video(vga, numbers, note, velocity, clk);

	initial begin

		clk = 0;

		$dumpfile("dump.fst");
		$dumpvars;

		#50000000 $finish;

	end

	// 100 MHz clock
	always #5 clk = !clk;

endmodule
