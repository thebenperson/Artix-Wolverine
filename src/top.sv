`timescale 1 ns / 1 ns

// the top module

// outputs:

//     - DAC SPI outputs
//     - VGA red signal
//     - VGA green signal
//     - VGA blue signal
//     - VGA horizontal timing signal
//     - VGA vertical timing signal

// inputs:

//     - UART output from the MIDI keyboard
//     - ADC inputs
//     - 100 MHz clock

module Top(

	output dac_cs,
	output dac_mosi,
	output dac_sclk,

	output [3:0] vgaRed,
	output [3:0] vgaGreen,
	output [3:0] vgaBlue,
	output Hsync,
	output Vsync,

	input midi_rx,
	input [7:0] JXADC,
	input clk

);

	// outputs

	// bitmap representing current key states
	reg [31:0] keys = 0;

	// vga signals

	VGA::I vga;

	assign vgaRed   = vga.r;
	assign vgaGreen = vga.g;
	assign vgaBlue  = vga.b;
	assign Hsync	= vga.syncH;
	assign Vsync	= vga.syncV;

	/******************************************************************/

	// inputs

	reg [02:0] dac_address; // what DAC output to select
	reg [11:0] dac_value;   // what value to send to the current output

	reg dac_trigger = 0;    // set high to trigger the DAC

	DAC dac(dac_cs, dac_mosi, dac_sclk, dac_address, dac_value, dac_trigger, clk);

	// numbers that can be displayed on screen
	wire [PKGVideo::bitsNumber - 1:0] numbers [PKGVideo::numbers - 1:0];

	// note number of key that was last pressed
	reg [MIDI::bits - 1:0] note;

	// how hard the last note was pressed
	reg [MIDI::bits - 1:0] velocity;

	// last ADC readings
	wire [PKG_ADC::bits - 1:0] adc_out [PKG_ADC::inputs - 1:0];

	// signals that adc_out is ready to be read.
	wire adc_ready;

	Video video(vga, numbers, note, velocity, keys, adc_out, adc_ready, clk);

	/******************************************************************/

	// VCO enable signals
	reg [4:0] vco_enable = 0;

	// high if a VCO is available to use
	wire vco_available = |(~vco_enable);

	// what VCO is available
	wire [2:0] available_vco =

	   !vco_enable[0] ? 0 :
	   !vco_enable[1] ? 1 :
	   !vco_enable[2] ? 2 :
	   !vco_enable[3] ? 3 :
	                    4 ;

	// this array maps keys to frequencies
    reg [11:0] keys_dac_map [31:0] = '{

        1261,
        1327,
        1392,
        1441,
        1507,
        1556,
        1605,
        1654,
        1704,
        1744,
        1785,
        1818,
        1867,
        1892,
        1933,
        1949,
        1998,
        2015,
        2048,
        2072,
        2097,
        2113,
        2129,
        2146,
        2162,
        2179,
        2195,
        2211,
        2228,
        2244,
        2260,
        2277

    };

	/******************************************************************/

	// a bitmap of what keys are currently assigned a VCO
	reg [31:0] keys_mapped     = 0;

	// this array maps keys to VCOs
	reg [02:0] keys_vco_map [31:0];

	// true if a key is pressed that is not mapped to a VCO
	wire key_pending = |(keys & (~keys_mapped));

	// priority encoder for the next key that should be assigned a VCO
	wire [4:0] pending_key =

		(keys[00] && !keys_mapped[00]) ? 00 :
		(keys[01] && !keys_mapped[01]) ? 01 :
		(keys[02] && !keys_mapped[02]) ? 02 :
		(keys[03] && !keys_mapped[03]) ? 03 :
		(keys[04] && !keys_mapped[04]) ? 04 :
		(keys[05] && !keys_mapped[05]) ? 05 :
		(keys[06] && !keys_mapped[06]) ? 06 :
		(keys[07] && !keys_mapped[07]) ? 07 :
		(keys[08] && !keys_mapped[08]) ? 08 :
		(keys[09] && !keys_mapped[09]) ? 09 :
		(keys[10] && !keys_mapped[10]) ? 10 :
		(keys[11] && !keys_mapped[11]) ? 11 :
		(keys[12] && !keys_mapped[12]) ? 12 :
		(keys[13] && !keys_mapped[13]) ? 13 :
		(keys[14] && !keys_mapped[14]) ? 14 :
		(keys[15] && !keys_mapped[15]) ? 15 :
		(keys[16] && !keys_mapped[16]) ? 16 :
		(keys[17] && !keys_mapped[17]) ? 17 :
		(keys[18] && !keys_mapped[18]) ? 18 :
		(keys[19] && !keys_mapped[19]) ? 19 :
		(keys[20] && !keys_mapped[20]) ? 20 :
		(keys[21] && !keys_mapped[21]) ? 21 :
		(keys[22] && !keys_mapped[22]) ? 22 :
		(keys[23] && !keys_mapped[23]) ? 23 :
		(keys[24] && !keys_mapped[24]) ? 24 :
		(keys[25] && !keys_mapped[25]) ? 25 :
		(keys[26] && !keys_mapped[26]) ? 26 :
		(keys[27] && !keys_mapped[27]) ? 27 :
		(keys[28] && !keys_mapped[28]) ? 28 :
		(keys[29] && !keys_mapped[29]) ? 29 :
		(keys[30] && !keys_mapped[30]) ? 30 :
										 31 ;

	/******************************************************************/

	// MIDI logic

	MIDI::I midi;
	MIDI_RX midi_rx(midi, midi_rx, clk);

	always @(posedge clk) begin

		// start by assuming no DAC output is needed
        dac_trigger = 0;

		if (midi.ready) begin

			// if the MIDI module has something for us

			// ignore invalid note numbers
			if (midi.note < 32) begin

				// display the event information on screen

				// display "0" for note number if it's a key up event
				note     <= midi.value ? midi.note : 0;

				velocity <= midi.velocity;

				// update keystate bitmap
				keys[midi.note] <= midi.value;

				if (midi.value) begin

					// if it's a key down event

					if (!keys_mapped[midi.note] && vco_available) begin

						// key not mapped to a VCO and VCO is available

						// set DAC output corresponding to the available
						// VCO and the frequency of that key minus the
						// VCO frequency input

						dac_address <= available_vco;
						dac_value   <= keys_dac_map[midi.note] - adc_out[2];
						dac_trigger  = 1;

						// update enabled VCO bitmap
						vco_enable[available_vco] <= 1;

						// map key to the available VCO

						keys_vco_map[midi.note] <= available_vco;
						keys_mapped[midi.note]  <= 1;

					end

				end else if (keys_mapped[midi.note]) begin

					// if the key released was mapped to a VCO

				    dac_address <= keys_vco_map[midi.note];
			       	dac_value   <= 12'hFFF;
			       	dac_trigger  = 1;

					// disable VCO
					vco_enable[keys_vco_map[midi.note]] <= 0;

					// unmap current key
					keys_mapped[midi.note] <= 0;

				end

			end

		end

	end

	/******************************************************************/

	// get ADC outputs for the two waveform plots and the VCO frequency
	// adjust input

	ADC adc(

	   adc_out,
	   adc_ready,
	   JXADC[0],
	   JXADC[4],
	   JXADC[1],
	   JXADC[5],
	   JXADC[2],
	   JXADC[6],
	   clk

	);

	/******************************************************************/

    assign numbers[0] = adc_out[2][11:4]; // VCO Frequency Adjust

endmodule
