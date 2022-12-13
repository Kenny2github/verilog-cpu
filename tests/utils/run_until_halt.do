do ../utils/set_hooks.do

run 1ns
force {i_execute} 1
run 1ns
force {i_execute} 0
run -all

do ../utils/unset_hooks.do
