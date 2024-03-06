#IC:Icurus Verilog

#top file define
##################################################################
#directory config
# VIVADO_DIR      := 
# PROJ_DIR        := 
# LOG_DIR         := 
# TCL_DIR         := 
# RTL_DIR         := 
# TB_DIR          := 
# WAVE_DIR        := 
# SIM_LOG_DIR     := 
# SIM_WORK_DIR    := 
# SIM_IC_DIR      := 
# SIM_XC_DIR      := 

# #simulation Makefile path
# SIM_MK          := 
# include $(SIM_MK)

# #RTL file
# RTL             := 

# #simulation test name
# TEST_NAME       := 
###################################################################




#test name
IC_TESTNAME := $(TEST_NAME)


IC_LOG_DIR  := $(SIM_LOG_DIR)/ic
IC_WORK_DIR := $(SIM_WORK_DIR)/ic
IC_WAVE_DIR := $(WAVE_DIR)/ic

#test bench file
IC_TESTBENCH := ./tb/$(IC_TESTNAME).sv


#wave file
IC_WAVE_FILE := $(IC_TESTNAME).vcd

#compile file name
IC_CMP_FILE := work

#compile option
IC_COM_OPTS :=-g 2012

#simulation option
IC_SIM_OPTS := -l $(IC_LOG_DIR)/simlog.log



##############################################

.PHONY : ic_comp ic_sim


$(IC_WORK_DIR)/$(IC_CMP_FILE) : $(IC_TESTBENCH) $(RTL)
	@mkdir -p $(IC_WORK_DIR)
	@mkdir -p $(IC_LOG_DIR)
	iverilog $(IC_TESTBENCH) $(RTL)  $(IC_COM_OPTS) -s $(IC_TESTNAME) -o $@ 2>&1 | tee $(IC_LOG_DIR)/comp.log


ic_sim:$(IC_WORK_DIR)/$(IC_CMP_FILE)
	@mkdir -p $(IC_LOG_DIR)
	@mkdir -p $(IC_WAVE_DIR)
	vvp $(IC_SIM_OPTS) $(IC_WORK_DIR)/$(IC_CMP_FILE)
	mv $(IC_WAVE_FILE)  $(IC_WAVE_DIR)/

ic_wave:
	gtkwave $(IC_WAVE_DIR)/$(IC_WAVE_FILE)









