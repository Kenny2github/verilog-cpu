do _pre.do

### NOOP, NOOP, HALT ###

# load NOOP
force {i_data_in} 8'h00
run 1ns
force {i_load_addr} 1
run 1ns
force {i_load_addr} 0
force {i_data_in} 8'h01
run 1ns
force {i_load_data} 1
run 1ns
force {i_load_data} 0

# load NOOP
force {i_data_in} 8'h01
run 1ns
force {i_load_addr} 1
run 1ns
force {i_load_addr} 0
force {i_data_in} 8'h01
run 1ns
force {i_load_data} 1
run 1ns
force {i_load_data} 0

# load HALT
force {i_data_in} 8'h02
run 1ns
force {i_load_addr} 1
run 1ns
force {i_load_addr} 0
force {i_data_in} 8'h00
run 1ns
force {i_load_data} 1
run 1ns
force {i_load_data} 0

# run!
run 1ns
force {i_execute} 1
run 1ns
force {i_execute} 0
run 10ns

# test running a second time to ensure RIP is reset
force {i_execute} 1
run 1ns
force {i_execute} 0
run 8ns

# cleanup
do _post.do
