do _pre.do

### LDFR to registers 2 and 3 ###

do load_mem.do ldfr.hex

run 1ns
force {i_execute} 1
run 1ns
force {i_execute} 0
run 20ns

# cleanup
do _post.do
