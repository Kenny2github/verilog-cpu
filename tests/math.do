do _pre.do

### test MATH with various operands ###

do load_mem.do math.hex
do run_until_halt.do

# cleanup
do _post.do
