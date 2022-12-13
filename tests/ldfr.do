do _pre.do

### LDFR to registers 2 and 3 ###

do load_mem.do ldfr.hex
do run_until_halt.do

# cleanup
do _post.do
