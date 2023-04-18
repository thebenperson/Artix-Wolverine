`timescale 1 ns / 1 ns

package PKG_ADC;

	// precision of the ADC
	parameter bits   = 12;

	// number of ADC inputs
	parameter inputs = 3;

endpackage

// ADC module

// outputs:

//     - array of ADC outputs
//     - flag for when outputs are valid

// inputs:

//     - first input positive
//     - first input negative
//     - second input positive
//     - second input negative
//     - third input negative
//     - third input negative
//     - 100 MHz clock

module ADC(

	output reg [PKG_ADC::bits - 1:0] out [PKG_ADC::inputs - 1:0],
	output done,

	input p1,
	input n1,
	input p2,
	input n2,
	input p3,
	input n3,

	input clk

);

	wire [04:00] channel; // the current input being read
	wire         eoc;     // end of conversion signal
	wire [15:00] data;    // ADC output (only upper 12 bits are used)
	wire         ready;   // signals the data is ready to read
	wire         eos;     // end of sequence signal

	// ADC wizard module

	// channel sequencer mode, no alarms, only vauxpn6 and vauxpn14
	// selected

	xadc_wiz_0 adc(

		.daddr_in(channel),    // Address bus for the dynamic reconfiguration port
		.dclk_in(clk),         // Clock input for the dynamic reconfiguration port
		.den_in(eoc),          // Enable Signal for the dynamic reconfiguration port
		.di_in(0),             // Input data bus for the dynamic reconfiguration port
		.dwe_in(0),            // Write Enable for the dynamic reconfiguration port
		.vauxp6(p1),           // Auxiliary channel 6
		.vauxn6(n1),
		.vauxp14(p2),          // Auxiliary channel 14
		.vauxn14(n2),
		.vauxn7(p3),           // Auxiliary channel 7
		.vauxn7(n3),
		.busy_out(),           // ADC Busy signal
		.channel_out(channel), // Channel Selection Outputs
		.do_out(data),         // Output data bus for dynamic reconfiguration port
		.drdy_out(ready),      // Data ready signal for the dynamic reconfiguration port
		.eoc_out(eoc),         // End of Conversion Signal
		.eos_out(eos),         // End of Sequence Signal
		.alarm_out(),          // OR'ed output of all the Alarms
		.vp_in(),              // Dedicated Analog Input Pair
		.vn_in()

	);

	always @(posedge clk) begin

		if (ready) begin

			// triggered when an input is read

			case (channel)

				7'h16: out[0] <= data[15:4];
				7'h1E: out[1] <= data[15:4];
				7'h17: out[2] <= data[15:4];

			endcase

		end

	end

	// only when last input is read
	assign done = ready && (channel == 7'h17);

endmodule
