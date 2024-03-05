
#SIM_MK  := 

#SIMULATOR = xsim
SIMULATOR  := ic
SIMULATOR  := xc


DESIGN     = ../hdl/*
SIM_DESIGN = sim_topmodule
WAVE_NAME  = sim_topmodule

# ifeq($(SIMULATOR),xcelium)
# 	TARGET   = $(DESIGN)
# 	SIM_COM  = xmverilog +access+r +nowarn+NONPRT $^ $(DESIGN)
# 	RUN_DIR  = sim/run
# 	WAVE_COM = simvision $(WAVE_NAME).shm&
# ifeq($(SIMULATOR),xc)
# 	TARGET   := compile
# 	SIM_COM  := xsim $(SIM) -t ../$(RUN_TCL)
# 	RUN_DIR  := xsim/run
# 	WAVE_COM := gtkwave $(WAVE_NAME).vcd &
# else
# 	TARGET   := 
# endif


RUN_TCL = run_sim.tcl


.PHONY :vlog,compile,sim,vision

vlog:$(DESIGN) ## compile ## hoge
	mkdir -p $(RUN_DIR)
	cd $(RUN_DIR) && xvlog -sv $^ ../$(SIM).sv

compile:vlog $(SIM_DESIGN).sv
	cd $(RUN_DIR) && xelab --debug all --notimingchecks $(SIM)

sim:$(TARGET)
	cd $(RUN_DIR) && $(SIM_COM)

wave:sim
	cd $(RUN_DIR) && $(WAVE_COM)

sim_help:
	@grep -E '^[/a-zA-Z_-]+:.*?## .*$$' $(SIM_MK) | perl -pe 's%^([/a-zA-Z_-]+):.*?(##)%$$1 $$2%' | awk -F " *?## *?" '{printf "\033[36m%-30s\033[0m %-50s %s\n", $$1, $$2, $$3}'