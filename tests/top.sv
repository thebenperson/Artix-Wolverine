`timescale 1 ns / 1 ns

// testbench for the top module
// !! NOT COMPLETE !!

module testbench;

	wire [3:0] r;
	wire [3:0] g;
	wire [3:0] b;

	wire syncH;
	wire syncV;

	reg tx;
	reg clk = 0;

	Top top(r, g, b, syncH, syncV, tx, clk);

	// 100 MHz clock
	always #5 clk <= !clk;

endmodule
