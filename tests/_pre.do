vlib work
vlog -incr +incdir+../includes ../src/cpu.v ../src/ram.v ../src/alu.v
vsim -L altera_mf_ver cpu
log {/cpu/*}
log {/cpu/u_control/*}
log {/cpu/u_datapath/*}
add wave -radix unsigned {/cpu/*}
add wave -radix hexadecimal {/cpu/u_control/*}
add wave -radix hexadecimal {/cpu/u_datapath/*}

force {i_clk} 0 0ps , 1 250ps -r 500ps

force {i_load_addr} 0
force {i_load_data} 0
force {i_execute} 0
force {i_input_taken} 0
force {i_data_in} 00000000

force {i_reset} 1
run 500ps
force {i_reset} 0
run 500ps
