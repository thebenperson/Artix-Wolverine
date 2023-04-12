`timescale 1 ns / 1 ns

// testbench for the function generator
// !! NOT COMPLETE !!

module testbench;

	wire [11:0] out;

	import PKG_FunctionGenerator::type_t;

	type_t sel = PKG_FunctionGenerator::TRIANGLE;
	wire [7:0] delta = 1;
	reg clk = 0;

	FunctionGenerator fg(out, sel, delta, clk);

	initial begin

		$dumpfile("dump.vcd");
		$dumpvars;

		#200000 $finish;

	end

	// 100 MHz clock
	always #1 clk <= !clk;

endmodule
