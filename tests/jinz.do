do _pre.do

### JINZ to write different register values based on zero ###

do load_mem.do jinz.hex
do run_until_halt.do

# cleanup
do _post.do
