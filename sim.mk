
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
# SIMULATOR  = xsim

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

else ifeq ($(SIMULATOR),ic)
	WAVE_FILE = $(TEST_NAME).vcd
	COMP_FILE = work
	LOG_FILE  = comp.log

	COMP_OPTS = -g 2012
	SIM_OPTS  = -l $(SLOG_DIR)/simlog.log

	COMP_COM  = iverilog $(TESTBENCH) $(RTL) $(COMP_OPTS) -s $(TEST_NAME) -o $(COMP_FILE) 2>&1 | tee $(LOG_FILE)
	SIM_COM   = vvp $(SIM_OPTS) $(SWORK_DIR)/$(COMP_FILE)
	WAVE_COM  = gtkwave 

else
	WAVE_FILE = $(TEST_NAME).vcd
	COMP_FILE = axsim.sh xsim.dir
	LOG_FILE  = xelab* xvlog*

	COMP_OPTS = --timescale 1ns/1ps --standalone --debug typical
	SIM_OPTS  = 

	COMP_COM  = xvlog -sv $(TESTBENCH) $(RTL) && xelab $(TEST_NAME) $(COMP_OPTS) && sed -i 's|xsim.dir/work.$(TEST_NAME)/axsim|$(SWORK_DIR)/xsim.dir/work.$(TEST_NAME)/axsim|' axsim.sh
	SIM_COM   = $(SWORK_DIR)/axsim.sh  && mv xsim.log $(SLOG_DIR)
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
	cp -r  $(COMP_FILE) $(SWORK_DIR)
	rm -rf $(COMP_FILE) 
	mv $(LOG_FILE) $(SLOG_DIR)

sim: comp  ## run simyuration [iverilog,xcelium,vivado sim] ## make sim SIMULATOR={ic,xc.xsim} (default:ic)
	@mkdir -p $(SWAVE_DIR)
	$(SIM_COM)
	cp -r $(WAVE_FILE) $(SWAVE_DIR)/
	rm -rf $(WAVE_FILE)

wav: $(SWAVE_DIR)/$(WAVE_FILE) ## open wave ## make wav SIMULATOR={ic,xc.xsim} (default:ic) 
	cd $(SWAVE_DIR) && $(WAVE_COM) $(WAVE_FILE) & 

verify: ##check simulation result
	cd $(VERIFY_DIR) && cargo run


clean: ## clean simulation result file ## make clean
	$(MAKE) sim_clean

sim_clean:
	rm -rf $(SIM_LOG_DIR) $(SIM_WORK_DIR) $(WAVE_DIR)

sim_help:
	@grep -E '^[/a-zA-Z_-]+:.*?## .*$$' $(SIM_MK) | perl -pe 's%^([/a-zA-Z_-]+):.*?(##)%$$1 $$2%' | awk -F " *?## *?" '{printf "\033[36m%-30s\033[0m %-50s %s\n", $$1, $$2, $$3}'

