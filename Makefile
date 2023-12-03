PROJ_DIR        = vivado-work/vivado_proj
LOG_DIR         = vivado-work/log
VIVADO_OPTS     = -log $(LOG_DIR)/vivado.log -journal $(LOG_DIR)/vivado.jou
VIVADO_TCL_OPTS = -mode tcl -source tcl/create_proj.tcl

.PHONY : create

create:
	mkdir -p $(LOG_DIR)
	vivado $(VIVADO_OPTS) $(VIVADO_TCL_OPTS) tcl/create_proj.tcl

gui :
	mkdir -p $(LOG_DIR)
	vivado $(VIVADO_OPTS) $(PROJ_DIR)/*.xpr &

gen :
	mkdir -p $(LOG_DIR)
	vivado $(VIVADO_OPTS) $(VIVADO_TCL_OPTS) tcl/generate_bitstream.tcl

