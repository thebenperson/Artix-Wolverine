`timescale 1 ns / 1 ns

// testbench for the VGA module
// runs for about three frames

module testbench;

	// outputs

	wire enable;

	wire syncH;
	wire syncV;

	wire [VGA::bitsResV - 1:0] row;
	wire [VGA::bitsResH - 1:0] col;

	// inputs

	reg clk;

	VGA_SM vga_sm(enable, syncH, syncV, row, col, clk);

	initial begin

		clk <= 0;

		$dumpfile("../dump.fst");
		$dumpvars;

		#50000000 $finish;

	end

	// 100 MHz clock
	always #5 clk <= !clk;

endmodule
