SIMULATOR = xsim
SIMULATOR = xcelium


DESIGN     = ../hdl/*
SIM_DESIGN = sim_topmodule
WAVE_NAME  = sim_topmodule

ifeq($(SIMULATOR),xcelium)
	TARGET   = $(DESIGN)
	SIM_COM  = xmverilog +access+r +nowarn+NONPRT $^ $(DESIGN)
	RUN_DIR  = sim/run
	WAVE_COM = simvision $(WAVE_NAME).shm&
else
	TARGET   = compile
	SIM_COM  = xsim $(SIM) -t ../$(RUN_TCL)
	RUN_DIR  = xsim/run
	WAVE_COM = gtkwave $(WAVE_NAME).vcd &
endif


RUN_TCL = run_sim.tcl


.PHONY :vlog,compile,sim,vision

vlog:$(DESIGN)
	mkdir -p $(RUN_DIR)
	cd $(RUN_DIR) && xvlog -sv $^ ../$(SIM).sv

compile:vlog $(SIM_DESIGN).sv
	cd $(RUN_DIR) && xelab --debug all --notimingchecks $(SIM)

sim:$(TARGET)
	cd $(RUN_DIR) && $(SIM_COM)

wave:sim
	cd $(RUN_DIR) && $(WAVE_COM)

