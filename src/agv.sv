`timescale 1 ns / 1 ns

package VGA;

	// VGA resolution

	parameter resH = 640;
	parameter resV = 480;

	// bits needed to store resolution

	parameter bitsResH = $clog2(resH);
	parameter bitsResV = $clog2(resV);

	// all VGA signals

	typedef struct packed {

		logic [3:0] r;
		logic [3:0] g;
		logic [3:0] b;

		logic syncH;
		logic syncV;

	} I;

endpackage

// VGA state machine to drive timing signals

// outputs:

//     - whether or not pixel is on screen
//     - horizontal timing signal
//     - vertical timing signal
//     - current vertical pixel coordinate
//     - current horizontal pixel coordinate

// inputs:

//     - 100 MHz clock

module VGA_SM(

	output enable,

	output syncH,
	output syncV,

	output reg [VGA::bitsResV - 1:0] countV,
	output reg [VGA::bitsResH - 1:0] countH,

	input clk

);

	// clock frequency (Hz)
	localparam freqCLK = 100e6;

	// timing characteristics
	// see http://www.tinyvga.com/vga-timing/640x480@60Hz

	// pixel frequency (Hz)
	localparam freqPixel = 25.175e6;

	// half the pixel frequency in number of clock cycles rounded to
	// the nearest integer
	localparam delta = int'($floor((freqCLK / (2 * freqPixel)) + 0.5));

	// bits required to hold delta
	localparam bitsDelta = $clog2(delta);

	// horizontal timing (pixels)

	localparam sizeHBackPorch  = 48;
	localparam sizeHFrontPorch = 16;
	localparam sizeHSync       = 96;

	// vertical timing (rows)

	localparam sizeVBackPorch  = 33;
	localparam sizeVFrontPorch = 10;
	localparam sizeVSync       = 2;

	initial begin

		// start in top left corner

		countH <= 0;
		countV <= 0;

	end

	// define state machine states
	typedef enum { SYNC, BACK_PORCH, READY, FRONT_PORCH } state_t;

	// start out in the SYNC state
	state_t stateH = SYNC;
	state_t stateV = SYNC;

	// output high if state is SYNC

	assign syncH = (stateH == SYNC);
	assign syncV = (stateV == SYNC);

	// counter to divide clk into clockH
	reg [bitsDelta - 1:0] timer = 0;

	// clocks for horizontal and vertical timing

	reg clockH = 0;
	reg clockV = 0;

	// pixel values are only valid when both timing signals are in the
	// READY state

	assign enable = (stateH == READY) && (stateV == READY);

	// block to divide clk into clockH

	always @(posedge clk) begin

		if (timer >= delta - 1) begin

			clockH <= !clockH;
			timer  <= 0;

		end	else timer <= timer + 1;

	end

	// block for horizontal timing

	always @(posedge clockH) begin

		case (stateH)

			SYNC: begin

				if (countH >= sizeHSync - 1) begin

					stateH <= BACK_PORCH;
					countH <= 0;

					clockV <= 0;

				end else countH <= countH + 1;

			end

			BACK_PORCH: begin

				if (countH >= sizeHBackPorch - 1) begin

					stateH <= READY;
					countH <= 0;

				end else countH <= countH + 1;

			end

			READY: begin

				if (countH >= VGA::resH - 1) begin

					stateH <= FRONT_PORCH;
					countH <= 0;

				end else countH <= countH + 1;

			end

			FRONT_PORCH: begin

				if (countH >= sizeHFrontPorch - 1) begin

					stateH <= SYNC;
					countH <= 0;

					clockV <= 1;

				end else countH <= countH + 1;

			end

		endcase

	end

	always @(posedge clockV) begin

		case (stateV)

			SYNC: begin

				if (countV >= sizeVSync - 1) begin

					stateV <= BACK_PORCH;
					countV <= 0;

				end else countV <= countV + 1;

			end

			BACK_PORCH: begin

				if (countV >= sizeVBackPorch - 1) begin

					stateV <= READY;
					countV <= 0;

				end else countV <= countV + 1;

			end

			READY: begin

				if (countV >= VGA::resV - 1) begin

					stateV <= FRONT_PORCH;
					countV <= 0;

				end else countV <= countV + 1;

			end

			FRONT_PORCH: begin

				if (countV >= sizeVFrontPorch - 1) begin

					stateV <= SYNC;
					countV <= 0;

				end else countV <= countV + 1;

			end

		endcase

	end

endmodule
