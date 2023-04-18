// DAC module

// outputs:

//     - SPI chip select
//     - SPI master out slave in
//     - SPI serial clock

// inputs:

//     - output address
//     - output value
//     - output trigger
//     - 100 MHz clock

module DAC(

	output cs,
	output reg mosi,
	output reg sclk,

	input [02:0] address,
	input [11:0] value,
	input        trigger,

	input clk

);

	// set SPI serial clock to zero at time t = 0
	initial sclk <= 0;

	// counter to divide clock
	reg [01:0] counter = 0;

	// initial command to initialize DAC
	reg [03:0] command = 4'b1000;

	// instruction format
	wire [32:0] instruction = { 4'bX, command, 1'b0, address, value, 7'bX, 1'b1 };

	// current bit of instruction to output
	reg  [05:0] idx = 0;

	// initial state OUTPUT in order to initialize DAC
	enum { WAIT, OUTPUT } state = OUTPUT;

	always @(posedge clk) begin

		case (state)

			WAIT: begin

				if (trigger) begin

					// command to set specific output

					command <= 4'b0011;
					state   <= OUTPUT;
					counter <= 0;
					idx     <= 0;

				end

			end

			OUTPUT: begin

				// divide clock by three
				if (counter >= 3) begin

					// drive SPI serial clock
					sclk <= !sclk;

					if (!sclk) begin

						// change on rising edge

						// output instruction over SPI
						mosi <= instruction[31 - idx];

						if (idx >= 32) begin

							// go back to WAIT state after last bit

							state <= WAIT;
							sclk  <= 0;

						end else idx <= idx + 1;

					end

					// reset counter
					counter <= 0;

				end else counter <= counter + 1;

			end

		endcase

	end

	// SPI chip select is active low
	assign cs = (state == WAIT);

endmodule
