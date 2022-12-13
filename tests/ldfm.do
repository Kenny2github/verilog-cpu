do _pre.do

### LDFM to registers 0 and 1 ###

do load_mem.do ldfm.hex

run 1ns
force {i_execute} 1
run 1ns
force {i_execute} 0
run 10ns

# cleanup
do _post.do
