`timescale 1 ns / 1 ns

// testbench to test the MIDI reciever

// meant for use with VMPK virtual keyboard
// keyboard output is meant to be piped to this testbench with the help
// of the midi.sh script

module testbench;

	// baud rate in nanoseconds
	localparam delta = 1e9 / MIDI::baud;

	// outputs

	MIDI::I midi;
	wire [7:0] dummy;

	// inputs

	reg tx;  // tx pin from the MIDI port
	reg clk; // clock input

	// 100 MHz clock
	always #5 clk <= !clk;

	MIDI_RX midi_rx(midi, dummy, tx, clk);

	// to store stdin file descriptor
	int stdin;

	initial begin;

		// open stdin stream
		stdin = $fopen("/dev/stdin", "r");

		// enable dump file
		$dumpfile("../dump.fst");
		$dumpvars;

		clk <= 0;
		tx  <= 1; // UART idles high

		#(delta);

		while (1) begin

			// read a byte from stdin stream

			int in;
			in = $fgetc(stdin);

			// exit loop if EOF found
			if (in == -1) $finish;

			// transmit start bit

			tx <= 0;
			#(delta);

			// transmit bits

			for (int i = 0; i < 8; i++) begin

				tx <= in[i];
				#(delta);

			end

			// transmit stop bit

			tx <= 1;
			#(delta);

		end

	end

endmodule
