# Usage: do provide_input.do <1-byte hex I/O input>
do ../utils/set_hooks.do

force {i_data_in} 8'h$1
run 1ns
force {i_input_taken} 1
run 1ns
force {i_input_taken} 0
run -all

do ../utils/unset_hooks.do

do ../utils/_post.do
