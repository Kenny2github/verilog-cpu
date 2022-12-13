when -label halt {
	/cpu/u_control/m_current_state = 9'h000
	and /cpu/u_control/m_current_cycle = 3'd1
} {stop}

run 1ns
force {i_execute} 1
run 1ns
force {i_execute} 0
run -all

nowhen halt
