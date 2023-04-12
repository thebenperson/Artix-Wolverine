`timescale 1 ns / 1 ns

module top;

	wire cs;
	wire mosi;
	wire sclk;

	reg [02:0] address;
	reg [11:0] value;
	reg        trigger;

	reg clk;

	DAC dac(cs, mosi, sclk, address, value, trigger, clk);

	always #5 clk <= !clk;

	initial begin

		$dumpfile("dump.fst");
		$dumpvars;

		address <= 0;
		value   <= 0;
		trigger <= 0;
		clk     <= 0;

		#3000

		address <= 5;
		value   <= 12;
		trigger <= 1;

		#10 trigger <= 0;
		#10000 $finish;

	end

endmodule

module DAC(

	output cs,
	output reg mosi,
	output reg sclk,

	input [02:0] address,
	input [11:0] value,
	input        trigger,

	input clk

);

	initial sclk <= 0;

	reg [01:0] counter = 0;
	reg [03:0] command = 4'b1000;

	wire [32:0] instruction = { 4'bX, command, 1'b0, address, value, 7'bX, 1'b1 };
	reg  [05:0] idx = 0;

	enum { WAIT, OUTPUT } state = OUTPUT;

	always @(posedge clk) begin

		case (state)

			WAIT: begin

				if (trigger) begin

					command <= 4'b0011;
					state   <= OUTPUT;
					counter <= 0;
					idx     <= 0;

				end

			end

			OUTPUT: begin

				if (counter >= terminalcount) begin

					sclk <= !sclk;

					if (!sclk) begin

						mosi <= instruction[31 - idx];

						if (idx >= 32) begin

							state <= WAIT;
							sclk  <= 0;

						end else idx <= idx + 1;

					end

					counter <= 0;

				end else counter <= counter + 1;

			end

		endcase

	end

	assign cs = (state == WAIT);

endmodule
