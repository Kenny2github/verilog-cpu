`ifndef SEL_REG0

// Registers 0 to 7
`define SEL_REG0	5'h00
`define SEL_REG1	5'h01
`define SEL_REG2	5'h02
`define SEL_REG3	5'h03
`define SEL_REG4	5'h04
`define SEL_REG5	5'h05
`define SEL_REG6	5'h06
`define SEL_REG7	5'h07
// Arithmetic accumulator
`define SEL_RAX		5'h08
// Instruction pointer
`define SEL_RIP		5'h09
/* The above double as 4-bit register codes */
// Instruction pointer + 1
`define SEL_RIP_1	5'h10
// Physical data in
`define SEL_D_IN	5'h11
// RAM output
`define SEL_RAM		5'h12
// Hardwired zero
`define SEL_ZERO	5'h13

// Arithmetic addition
`define MATH_ADD	7'h00
// Arithmetic subtraction
`define MATH_SUB	7'h01
// Arithmetic multiplication
`define MATH_MUL	7'h02
// Arithmetic division
`define MATH_DIV	7'h03
// Arithmetic modulo
`define MATH_MOD	7'h04
// Bitwise (inclusive) OR
`define MATH_IOR	7'h05
// Bitwise AND
`define MATH_AND	7'h06
// Bitwise exclusive OR
`define MATH_XOR	7'h07
// Bitwise NOR
`define MATH_NOR	7'h08
// Bitwise NAND
`define MATH_NAND	7'h09
// Bitwise exclusive NOR
`define MATH_XNOR	7'h0a
// One's complement
`define MATH_NOT	7'h0b
// Two's complement
`define MATH_NEG	7'h0c

`endif
