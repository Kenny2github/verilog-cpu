do _pre.do

do load_mem.do wrim.hex
run 1ns
force {i_execute} 1
run 1ns
force {i_execute} 0
run 7ns

# write NOOP, rest of memory should be halts
force {i_data_in} 8'h01
run 1ns
force {i_input_taken} 1
run 1ns
force {i_input_taken} 0
run 10ns

# cleanup
do _post.do
