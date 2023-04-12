`timescale 1 ns / 1 ns

package PKG_FunctionGenerator;

	typedef enum { SAWTOOTH, TRIANGLE, SINE } type_t;

	parameter bitsDelta = 8;

endpackage

module FunctionGenerator(

	output reg [11:0] out,

	input PKG_FunctionGenerator::type_t sel,
	input [PKG_FunctionGenerator::bitsDelta - 1:0] delta,
	input clk

);

	initial out <= 0;

	// set up sine lookup table

	//~ reg [11:0] sineTable [2046:0];

	//~ localparam PI_2 = 1.57079632679489661923;
	//~ localparam stepMin = PI_2 - $asin(2046 / 2047);
	//~ localparam step = 0;

	//~ initial begin

		//~ out <= 0;

		//~ for (int i = 0; i < 2047; i++) begin

			//~ step = $asin((i + 1) / 2047) - $asin(i / 2047);
			//~ sineTable[i] = $ceil(stepMin / step);

		//~ end

	//~ end

	reg trigger = 0;

	reg [PKG_FunctionGenerator::bitsDelta - 1:0] counter = 0;

	always @(posedge clk) begin

		if (counter >= delta) begin

			trigger <= !trigger;
			counter <= 0;

		end else counter <= counter + 1;

	end

	reg dir = 1;

	wire counterSine = 0;
	reg [11:0] idxSine = 0;

	always @(posedge trigger) begin

		case (sel)

			PKG_FunctionGenerator::SAWTOOTH: out <= out + 1;
			PKG_FunctionGenerator::TRIANGLE: begin

				case (out)

					12'h000: dir = 1;
					12'hFFF: dir = 0;

				endcase

				if (dir) out = out + 1;
				else     out = out - 1;

			end

			//~ PKG_FunctionGenerator::SINE: begin

				//~ if (counterSine >= sineTable[idxSine]) begin

					//~ counterSine <= 0;
					//~ idxSine <= idxSine + 1;

				//~ end else counter <= counter + 1;

				//~ out <= idxSine;

			//~ end

		endcase

	end

endmodule
