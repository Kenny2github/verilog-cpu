module top (
	input CLOCK_50,
	input wire [9:0] SW,
	input wire [3:0] KEY,
	output wire [9:0] LEDR,
	output wire [6:0] HEX0,
	output wire [6:0] HEX1,
	output wire [6:0] HEX2,
	output wire [6:0] HEX3,
);
	wire [7:0] m_data_out;

	cpu CPU0(
		.i_clk(CLOCK_50),
		.i_reset(!KEY[0]),
		.i_load_addr(!KEY[1]),
		.i_load_data(!KEY[2]),
		.i_execute(!KEY[3]),
		.i_input_taken(!KEY[3]),
		.i_data_in(SW[7:0]),
		.o_data_out(m_data_out),
		.o_waiting(LEDR[9]),
		.o_take_input(LEDR[8]),
	);

	assign LEDR[7:0] = m_data_out;
	hex_decoder D0(.c(m_data_out[3:0]), .display(HEX0));
	hex_decoder D1(.c(m_data_out[7:4]), .display(HEX1));
	hex_decoder D2(.c(SW[3:0]), .display(HEX2));
	hex_decoder D3(.c(SW[7:4]), .display(HEX3));
endmodule
