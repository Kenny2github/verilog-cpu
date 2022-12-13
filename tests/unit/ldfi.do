do _pre.do

### LDFI to registers 0 and 1 ###

do load_mem.do ldfi.hex
do run_until_halt.do

# cleanup
do _post.do
