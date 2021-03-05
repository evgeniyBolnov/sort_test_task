# Top level entity
TOP_ENTITY = sort_tb

# Path and source files
vpath %.sv ../rtl 
vpath %.v ../rtl/Sharkov
HDL_SRC += sort_reference.sv sort_tb.sv
HDL_SRC += fifo.v read_fifo_fsm.v sort.v sort_top.v src.v sync.v write_fifo_fsm.v

LIBRARY = 

MODELSIM_BIN_PATH := C:/modeltech64_10.6d/win64
QUARTUS_ROOTDIR   := C:/intelFPGA/18.1/quartus

VLOG_OPT = +define+SEED=$(shell date +%s)

include ./modelsim.mk