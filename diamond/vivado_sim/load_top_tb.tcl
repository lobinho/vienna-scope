# Load top simulation
# From vivado tcl console: 
# source ./Documents/git_repos/vienna-scope-git/diamond/vivado_sim/load_top_tb.tcl

# optionally do before:
# close_sim
# launch_simulation

restart
add_force {/top_tb/i_dut/s_clk_sys} -radix hex {0 0ns} {1 5000ps} -repeat_every 10000ps
run 500 us
