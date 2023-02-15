`timescale 1 ns / 1 ns

// testbench for the function generator
// !! NOT COMPLETE !!

module testbench;

	wire [11:0] out;

	PKG_FunctionGenerator::type_t sel = PKG_FunctionGenerator::TRIANGLE;
	wire delta = 10;
	reg clk = 0;

	FunctionGenerator fg(out, sel, delta, clk);

	initial #100 $finish;

	// 100 MHz clock
	always #5 clk <= !clk;

endmodule
