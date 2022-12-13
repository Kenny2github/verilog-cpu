do _pre.do

### test MATH with various operands ###

do load_mem.do math.hex

run 1ns
force {i_execute} 1
run 1ns
force {i_execute} 0
run 100ns

# cleanup
do _post.do
