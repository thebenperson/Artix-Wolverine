`timescale 1ns / 1ns

// testbench to print the font to the console

module testbench;

	// bitmap output
	wire [PKGFont::bitsFont - 1:0] out;

	// character number input
	reg  [PKGFont::bitsChar - 1:0] in;

	Font font(out, in);

	initial begin

		for (in = 0; in < PKGFont::chars; in++) begin

			// for every character in the font

			// print character number and opening brace
			$write("font[%d] = {\n\n\t", in);

			// for every

			for (int row = 0; row < PKGFont::fontHeight; row++) begin

				// for every row of the bitmap

				for (int col = 0; col < PKGFont::fontWidth; col++) begin

					// for every column of the bitmap

					// print pixel value
					$write("%s", (out[(row * PKGFont::fontWidth) + PKGFont::fontWidth - 1 - col]) ? "*" : " ");

				end

				// new line for next row
				$write("\n\t");

			end

			// print closing brace
			$write("\n}\n\n");

		end

	end

endmodule
