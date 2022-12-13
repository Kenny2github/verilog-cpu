do _pre.do
log {/cpu/*}
add wave -radix hexadecimal {/cpu/*}

do load_mem.do wrim.hex
do run_until_halt.do
do provide_input.do 01
