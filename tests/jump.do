do _pre.do

### JUMP to NOOP ###

do load_mem.do jump.hex
do run_until_halt.do

# cleanup
do _post.do
