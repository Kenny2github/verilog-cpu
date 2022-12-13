do _pre.do

do load_mem.do wrim.hex
run 1ns
force {i_execute} 1
run 1ns
force {i_execute} 0
run 7ns

# write NOOP, rest of memory should be halts
force {i_data_in} 8'h01
when -label halt {
	/cpu/u_control/m_current_state = 9'h000
	and /cpu/u_control/m_current_cycle = 3'd1
} {stop}
run 1ns
force {i_input_taken} 1
run 1ns
force {i_input_taken} 0
run -all

nowhen halt

# cleanup
do _post.do
