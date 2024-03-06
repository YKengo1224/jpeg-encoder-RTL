
#top file define
##################################################################
# #directory config
# VIVADO_DIR      := 
# PROJ_DIR        := 
# LOG_DIR         := 
# TCL_DIR         := 
# RTL_DIR         := 
# TB_DIR          := 
# WAVE_DIR        := 
# SIM_LOG_DIR     := 
# SIM_WORK_DIR    := 

# #simulation test name
# TEST_NAME       := 

# #RTL file
# RTL             := 

# #simulation Makefile path
# SIM_MK          := 
# include $(SIM_MK)
##################################################################

#simulator config
#SIMULATOR = xsim
# SIMULATOR  = ic
# SIMULATOR  = xc

SLOG_DIR  = $(SIM_LOG_DIR)/$(SIMULATOR)
SWORK_DIR = $(SIM_WORK_DIR)/$(SIMULATOR)
SWAVE_DIR = $(WAVE_DIR)/$(SIMULATOR)

#test bench file
TESTBENCH  := ./tb/$(TEST_NAME).sv


#wave file
WAVE_FILE = 
#compile file
COMP_FILE = 
#log file
LOG_FILE  = 
#compile option
COMP_OPTS = 
#simulation aption
SIM_OPTS  = 
#compile command	
COMP_COM  = 
#simulation command
SIM_COM   = 
#wave comaand
WAVE_COM  = 


ifeq ($(SIMULATOR),xc)
	WAVE_FILE = $(TEST_NAME).shm
	COMP_FILE = xcelium.d 
	LOG_FILE  = xmverilog.history xmverilog.log

	COMP_OPTS = +access+r +nowarn+NONPRT
	SIM_OPTS  = 

	COMP_COM  =  xmverilog $(SIM_OPTS) $(TESTBENCH) $(RTL) 
	SIM_COM   = 
	WAVE_COM  = simvision

else
	WAVE_FILE = $(TEST_NAME).vcd
	COMP_FILE = work
	LOG_FILE  = comp.log

	COMP_OPTS = -g 2012
	SIM_OPTS  = -l $(SLOG_DIR)/simlog.log

	COMP_COM  = iverilog $(TESTBENCH) $(RTL) $(COMP_OPTS) -s $(TEST_NAME) -o $(COMP_FILE) 2>&1 | tee $(LOG_FILE)
	SIM_COM   = vvp $(SIM_OPTS) $(SWORK_DIR)/$(COMP_FILE)
	WAVE_COM  = gtkwave 
endif
# ifeq($(SIMULATOR),xc)
# 	TARGET   := compile
# 	SIM_COM  := xsim $(SIM) -t ../$(RUN_TCL)
# 	RUN_DIR  := xsim/run
# 	WAVE_COM := gtkwave $(WAVE_NAME).vcd &

.PHONY :comp sim wav sim_clean

comp: $(TESTBENCH) $(RTL)
	@mkdir -p $(SWORK_DIR)
	@mkdir -p $(SLOG_DIR)
	$(COMP_COM)
	mv $(COMP_FILE) $(SWORK_DIR)
	mv $(LOG_FILE) $(SLOG_DIR)

sim: comp  ## run simyuration Icurus Verilog(ic) or xcelium(xc) ## [make sim SIMULATOR=ic] or [make sim SIMULATOR=xc] (default:ic)
	@mkdir -p $(WAVE_DIR)
	$(SIM_COM)
	mv $(WAVE_FILE) $(SWAVE_DIR)/


wav: $(SWAVE_DIR)/$(WAVE_FILE) ## open wave ## make wav
	cd $(SWAVE_DIR) && $(WAVE_COM) $(WAVE_FILE) & 

sim_clean:
	rm -rf $(SIM_LOG_DIR) $(SIM_WORK_DIR) $(WAVE_DIR)

sim_help:
	@grep -E '^[/a-zA-Z_-]+:.*?## .*$$' $(SIM_MK) | perl -pe 's%^([/a-zA-Z_-]+):.*?(##)%$$1 $$2%' | awk -F " *?## *?" '{printf "\033[36m%-30s\033[0m %-50s %s\n", $$1, $$2, $$3}'

