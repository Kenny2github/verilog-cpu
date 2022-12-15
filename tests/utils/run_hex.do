# Usage: do run.do <hex file name>
do ../utils/_pre.do
do ../utils/load_mem.do $1
do ../utils/run_until_halt.do
do ../utils/_post.do
