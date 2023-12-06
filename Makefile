VIVADO_DIR      = vivado-work
PROJ_DIR        = vivado_proj
LOG_DIR         = log
TCL_DIR         = ../tcl

XPR_FILE        = $(PROJ_DIR)/$(PROJ_DIR).xpr;
BD_NAME         = design_1
BD_FILE         = $(CURDIR)/$(VIVADO_DIR)/$(PROJ_DIR)/$(PROJ_DIR).srcs/sources_1/bd/$(BD_NAME)/$(BD_NAME).bd
BD_TCL          = $(TCL_DIR)/gen_bd.tcl

VIVADO_OPTS     = -log $(LOG_DIR)/vivado.log -journal $(LOG_DIR)/vivado.jou
VIVADO_TCL_OPTS = -mode tcl -source

.PHONY : create

create:
	mkdir -p $(VIVADO_DIR)/$(LOG_DIR)
	cd $(VIVADO_DIR) && vivado $(VIVADO_OPTS) $(VIVADO_TCL_OPTS) $(TCL_DIR)/create_proj.tcl

gui :
	mkdir -p $(VIVADO_DIR)/$(LOG_DIR)
	cd $(VIVADO_DIR) && vivado $(VIVADO_OPTS) $(PROJ_DIR)/*.xpr &

gen :
	mkdir -p $(VIVADO_DIR)/$(LOG_DIR)
	cd $(VIVADO_DIR) && vivado $(VIVADO_OPTS) $(VIVADO_TCL_OPTS) $(TCL_DIR)/generate_bitstream.tcl

bd :
		cd $(VIVADO_DIR) && echo "open_project $(XPR_FILE);open_bd_design $(BD_FILE);write_bd_tcl -force $(BD_TCL)" | vivado $(VIVADO_OPTS) -mode tcl
