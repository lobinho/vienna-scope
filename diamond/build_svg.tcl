# Open project if desired or run from diamond tcl console
# prj_project open vienna-scope.ldf

# Force synthesis, Map, P&R and Export bitstream as bit file
prj_run Export -impl impl1 -forceAll

# Bit to svg file for libxsvf tool (batch mode of deployment tool - call GUI with: deployment)
exec ddtcmd -oft -svfsingle -if "impl1/vienna-scope_impl1.bit" -dev LCMXO2-4000HC -op "SRAM Fast Program" -revd -runtest -of "impl1/vienna-scope_impl1.svf"
