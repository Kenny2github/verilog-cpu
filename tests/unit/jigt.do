do _pre.do

### JIGT to write different register values based on greater than ###

do load_mem.do jigt.hex
do run_until_halt.do

# cleanup
do _post.do
