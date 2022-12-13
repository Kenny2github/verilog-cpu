do _pre.do

### JIEQ to write different register values based on equal ###

do load_mem.do jieq.hex
do run_until_halt.do

# cleanup
do _post.do
