`include "defines.vh"

module alu (
	input wire [7:0] i_A,
	input wire [7:0] i_B,
	input wire i_signed,
	input wire [6:0] i_op,
	output reg [7:0] o_G,
	output reg o_carry_out,
	output wire o_equal,
	output wire o_less_than,
	output wire o_zero,
	output wire o_one,
	output wire o_overflow
);
	assign o_equal = (i_A == i_B);
	assign o_less_than = (i_A < i_B);
	assign o_zero = (o_G == 8'b0);
	assign o_one = ((~o_G) == 8'b0);
	assign o_overflow = i_signed
		? (i_A[7] == i_B[7]) && (o_G[7] != i_A[7])
		: o_carry_out;

	always @(*) begin
		o_carry_out = 1'b0;
		case (i_op)
			`MATH_ADD: {o_carry_out, o_G} = i_A + i_B;
			`MATH_SUB: {o_carry_out, o_G} = i_A - i_B;
			`MATH_MUL: o_G = i_A * i_B;
			`MATH_DIV: o_G = i_A / i_B;
			`MATH_MOD: o_G = i_A % i_B;
			`MATH_IOR: o_G = i_A | i_B;
			`MATH_AND: o_G = i_A & i_B;
			`MATH_XOR: o_G = i_A ^ i_B;
			`MATH_NOR: o_G = ~(i_A | i_B);
			`MATH_NAND: o_G = ~(i_A & i_B);
			`MATH_XNOR: o_G = ~(i_A ^ i_B);
			`MATH_NOT: o_G = ~i_A;
			`MATH_NEG: o_G = -i_A;
			`MATH_LSHIFT: o_G = i_A << i_B;
			`MATH_RSHIFT: o_G = i_A >> i_B;
			`MATH_LIOR: o_G = i_A || i_B;
			`MATH_LAND: o_G = i_A && i_B;
			`MATH_LXOR: o_G = (|{i_A}) ^ (|{i_B});
			`MATH_LNOR: o_G = !(i_A || i_B);
			`MATH_LNAND: o_G = !(i_A && i_B);
			`MATH_LXNOR: o_G = !((|{i_A}) ^ (|{i_B}));
			`MATH_LNOT: o_G = !i_A;
			`MATH_UIOR: o_G = |{i_A};
			`MATH_UAND: o_G = &{i_A};
			`MATH_UXOR: o_G = ^{i_A};
			`MATH_CMP: o_G = i_A;
			default: o_G = 8'b0;
		endcase
	end
endmodule
