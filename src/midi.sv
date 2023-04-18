`timescale 1 ns / 1 ns

package MIDI;

	// bits needed to store the note and velocity
	parameter bits = 7;

	// MIDI signals

	typedef struct packed {

		logic ready;                 // indicates the outputs are valid
		logic value;                 // 0 for key up and 1 for key down
		logic [bits - 1:0] note;     // key number
		logic [bits - 1:0] velocity; // how hard the key was pressed

	} I;

endpackage

// MIDI reciever

// outputs:

//     - MIDI signals
//     - the last status byte (for debugging)

// inputs:

//     - UART signal from the MIDI keyboard
//     - 100 MHz clock

module MIDI_RX(output MIDI::I midi, input rx, input clk);

	// set ready to low at time t = 0
	initial midi.ready <= 0;

	// inputs from the UART module

	wire readyRX;
	wire [7:0] in;

	// the UART module
	MIDI_UART midi_uart(readyRX, in, rx, clk);

	// state register for this module's state machine
	enum { READ, NOTE, VELOCITY, CONTROLLER } state = READ;

	// triggered when a new byte is recieved from the UART module
	always @(posedge clk) begin

		if (readyRX) begin

			if (in[7]) begin

				// bit seven indicates a status byte

				case (in[6:4])

					// Channel Voice Messages

					3'b000: begin

						midi.value <= 0; // note off
						state <= NOTE;   // read note byte

					end

					3'b001: begin

						midi.value <= 1; // note on
						state <= NOTE;   // read note byte

					end

					3'b011: begin

						// set the outputs to indicate this is a
						// controller event

						midi.value <= 0;
						midi.note  <= 32;

						// read controller bytes next
						state <= CONTROLLER;

					end

				endcase

			end else begin

				// not a status byte

				case (state)

					NOTE: begin

						// this state reads the note byte

						// set note pressed (note inputs start at 41)
						midi.note <= in[MIDI::bits - 1:0] - 41;

						// read the velocity byte
						state <= VELOCITY;

					end

					VELOCITY: begin

						// set velocity of the note
						midi.velocity <= in[MIDI::bits - 1:0];

						// read the next status byte
						state         <= READ;

					end

					// ignore first byte and save the controller value
					// in the velocity register
					CONTROLLER: state <= VELOCITY;

				endcase

			end

		end

	end

	assign midi.ready = (state == VELOCITY);

endmodule

// UART module used by the module above

// outputs:

//     - flag to indicate output is valid
//     - UART output

// inputs:

//     - UART signal from the MIDI keyboard
//     - 100 MHz clock

module MIDI_UART(

	output           ready,
	output reg [7:0] out,

	input rx,
	input clk

);

	// MIDI baud rate (bps)
	localparam baud = 31250;

	// baud period in clock cycles
	localparam int period = 100e6 / baud;

	// half of the baud period
	localparam delta = ((period - 1) / 2) + 1;

	// number of bits required for the period
	localparam bitsPeriod = $clog2(period);

	// state register for state machine
	enum { WAIT, INIT, READ, END } state = WAIT;

	// counter to store the time
	reg [bitsPeriod - 1:0] counter;

	always @(posedge clk) begin

		case (state)

			WAIT: begin

				// this state waits for rx to fall

				if (!rx) begin

					// if rx has fallen

					counter <= 0;
					state   <= INIT; // delay for half the baud period

				end

			end

			INIT: begin

				// this state waits for half of the baud period so that
				// rx is sampled halfway between its rising and falling
				// edges

				if (counter >= delta) begin

					// if half the baud period has passed

					counter <= 0;     // reset counter
					out     <= 8'h80; // reset output register
					state   <= READ;  // read the data bits

				end else begin

					// otherwise increment the counter
					counter <= counter + 1'b1;

				end

			end

			READ: begin

				// this state reads in new bits LSB first; the output
				// register is initialized to 0x80; it is shifted to the
				// right each time a bit is read; when out[0] is 1 that
				// means the last bit is here

				if (counter >= period) begin

					// if one baud period has passed

					// shift out to the right and set the MSB of out to
					// rx
					out <= (rx << 7) | (out >> 1);

					// reset the counter
					counter <= 0;

					// if this was the last bit then wait for stop bit
					if (out[0]) state <= END;

				end else begin

					// otherwise increment counter
					counter <= counter + 1'b1;

				end

			end

			END: state <= WAIT;

		endcase

	end

	assign ready = (state == END);

endmodule
