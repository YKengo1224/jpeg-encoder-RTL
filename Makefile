#directory config
VIVADO_DIR      := vivado-work
PROJ_DIR        := vivado_proj
LOG_DIR         := log
TCL_DIR         := ./tcl
RTL_DIR         := ./rtl
TB_DIR          := ./tb
WAVE_DIR        := ./wave
SIM_LOG_DIR     := ./sim_log
SIM_WORK_DIR    := ./sim_work



#simulation test name
TEST_NAME       := Tb_Template

#RTL file
RTL             := $(wildcard $(RTL_DIR)/*.v $(RTL_DIR)/*.sv)

#simulator
SIMULATOR       := ic
#SIMULATOR       := xc

#simulation Makefile path
#SIM_MK          := ./sim_iverilog.mk
SIM_MK          := ./sim.mk
include $(SIM_MK)


#vivado file config
XPR_FILE        := $(PROJ_DIR)/$(PROJ_DIR).xpr;
BD_NAME         := design_1
BD_FILE         := $(CURDIR)/$(VIVADO_DIR)/$(PROJ_DIR)/$(PROJ_DIR).srcs/sources_1/bd/$(BD_NAME)/$(BD_NAME).bd
BD_TCL          := $(TCL_DIR)/gen_bd.tcl

#vivado option
VIVADO_OPTS     := -log $(LOG_DIR)/vivado.log -journal $(LOG_DIR)/vivado.jou
VIVADO_TCL_OPTS := -mode tcl -source

#simulator
##ic : icurus verilog   
##xc : xcelium
#SIMURATOR      = ic
SIMURATOR       = xc


##########################################################
#include file
#include $(SIM_DIR)/Makefile

.PHONY : create gui gen bd sim wave  help

.DEFAULT_GOAL := help

################vivado command################
create: ## create vivado proj  ## make create
	mkdir -p $(VIVADO_DIR)/$(LOG_DIR)
	cd $(VIVADO_DIR) && vivado $(VIVADO_OPTS) $(VIVADO_TCL_OPTS) ../$(TCL_DIR)/create_proj.tcl

gui: $(XPR_FILE) ## open vivado gui ## make gui
	mkdir -p $(VIVADO_DIR)/$(LOG_DIR)
	cd $(VIVADO_DIR) && vivado $(VIVADO_OPTS) $(XPR_FILE) &

gen: ## generate bitstream and hw platform  ## make gen
	mkdir -p $(VIVADO_DIR)/$(LOG_DIR)
	cd $(VIVADO_DIR) && vivado $(VIVADO_OPTS) $(VIVADO_TCL_OPTS) ../$(TCL_DIR)/generate_bitstream.tcl

bd: $(BD_FILE) ## export block design ## make bd
		cd $(VIVADO_DIR) && echo "open_project $(XPR_FILE);open_bd_design $(BD_FILE);write_bd_tcl -force ../$(BD_TCL)" | vivado $(VIVADO_OPTS) -mode tcl
##############################################




############simuration command################
#simulation command
#sim:
#
#clean:
#	$(MAKE) sim_clean
##############################################


help:  ## print this message
	@echo "RTL development pretarions by Makefile"
	@echo ""
	@echo "Usage : make SUB_COMMAND argument_name=argument_value"
	@echo ""
	@echo "Command list"
	@echo ""
	@echo =============Vivado============
	@echo
	@printf "\033[36m%-30s\033[0m %-50s %s\n" "[Sub command]" "[Description]" "[Example]"
	@grep -E '^[/a-zA-Z_-]+:.*?## .*$$' Makefile | perl -pe 's%^([/a-zA-Z_-]+):.*?(##)%$$1 $$2%' | awk -F " *?## *?" '{printf "\033[36m%-30s\033[0m %-50s %s\n", $$1, $$2, $$3}'
#@grep -E '^[/a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | perl -pe 's%^([/a-zA-Z_-]+):.*?(##)%$$1 $$2%' | awk -F " *?## *?" '{printf "\033[36m%-30s\033[0m %-50s %s\n", $$1, $$2, $$3}'
	@echo
	@echo ===========simulation==========
	@echo
	@printf "\033[36m%-30s\033[0m %-50s %s\n" "[Sub command]" "[Description]" "[Example]" 
	@$(MAKE)  --no-print-directory sim_help
