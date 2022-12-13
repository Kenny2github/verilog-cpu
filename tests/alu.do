vlib work
vlog +incdir+../includes ../src/alu.v
vsim alu
log {/alu/*}
add wave -radix unsigned {/alu/*}

force {i_A} 8'b11010011
force {i_B} 8'b10110101
force {i_signed} 0

# MATH_ADD
force {i_op} 7'h00
run 100ps

# MATH_SUB
force {i_op} 7'h01
run 100ps

# MATH_MUL
force {i_op} 7'h02
run 100ps

# MATH_DIV
force {i_op} 7'h03
run 100ps

# MATH_MOD
force {i_op} 7'h04
run 100ps

# MATH_IOR
force {i_op} 7'h05
run 100ps

# MATH_AND
force {i_op} 7'h06
run 100ps

# MATH_XOR
force {i_op} 7'h07
run 100ps

# MATH_NOR
force {i_op} 7'h08
run 100ps

# MATH_NAND
force {i_op} 7'h09
run 100ps

# MATH_XNOR
force {i_op} 7'h0a
run 100ps

# MATH_NOT
force {i_op} 7'h0b
run 100ps

# MATH_NEG
force {i_op} 7'h0c
run 100ps

# MATH_LSHIFT
force {i_B} 8'd1
force {i_op} 7'h0d
run 100ps

# MATH_RSHIFT
force {i_op} 7'h0e
run 100ps

# MATH_LIOR
force {i_B} 8'd0
force {i_op} 7'h0f
run 100ps

# MATH_LAND
force {i_op} 7'h10
run 100ps

# MATH_LXOR
force {i_op} 7'h11
run 100ps

# MATH_LNOR
force {i_op} 7'h12
run 100ps

# MATH_LNAND
force {i_op} 7'h13
run 100ps

# MATH_LXNOR
force {i_op} 7'h14
run 100ps

# MATH_LNOT
force {i_op} 7'h15
run 100ps

# MATH_UIOR
force {i_op} 7'h16
run 100ps

# MATH_UAND
force {i_op} 7'h17
run 100ps

# MATH_UXOR
force {i_op} 7'h18
run 100ps

# MATH_CMP
force {i_op} 7'h7f
run 100ps

# test no carry out (carry out tested in ADD)
force {i_A} 8'b01011011
force {i_B} 8'b00100100
force {i_op} 7'h00
run 100ps

# test equal
force {i_A} 8'b00100100
force {i_B} 8'b00100100
run 100ps

# test less than
force {i_B} 8'b01011011
run 100ps

# test zero
force {i_B} 8'b00100100
force {i_op} 7'h01
run 100ps

# test one
force {i_B} 8'b00100101
run 100ps

# test signed overflow (unsigned tested in ADD)
force {i_signed} 1
run 100ps
force {i_op} 7'h00
force {i_A} 8'b10110101
force {i_B} 8'b10010011
run 100ps

# cleanup
do _post.do
