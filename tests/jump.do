do _pre.do

### JUMP to NOOP ###

do load_mem.do jump.hex

run 1ns
force {i_execute} 1
run 1ns
force {i_execute} 0
run 10ns

# cleanup
do _post.do
