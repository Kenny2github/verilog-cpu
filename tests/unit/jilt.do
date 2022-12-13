do _pre.do

### JILT to write different register values based on less than ###

do load_mem.do jilt.hex
do run_until_halt.do

# cleanup
do _post.do
