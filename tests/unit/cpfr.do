do _pre.do

### CPFR to registers 2 and 3 ###

do load_mem.do cpfr.hex
do run_until_halt.do

# cleanup
do _post.do
