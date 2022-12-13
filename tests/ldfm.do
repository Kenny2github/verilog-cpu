do _pre.do

### LDFM to registers 0 and 1 ###

do load_mem.do ldfm.hex
do run_until_halt.do

# cleanup
do _post.do
