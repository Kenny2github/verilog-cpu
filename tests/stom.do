do _pre.do

### STOM from registers 0 and 1 ###

do load_mem.do stom.hex
do run_until_halt.do

# cleanup
do _post.do
