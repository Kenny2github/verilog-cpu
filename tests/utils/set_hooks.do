when -label halt {
	/cpu/u_control/m_current_state = 9'h000
	and /cpu/u_control/m_current_cycle = 3'd1
} {
	stop
	echo Halted.
}
when -label wrim {
	/cpu/u_control/m_current_state = 9'h102
	and /cpu/u_control/m_current_cycle = 3'd4
} {
	stop
	echo Run `do provide_input.do <1-byte hex>` to continue.
}
when -label shom {
	/cpu/u_control/m_current_state = 9'h10e
	and /cpu/u_control/m_current_cycle = 3'd4
} {
	stop
	echo Run `do provide_input.do 00` to continue.
}
