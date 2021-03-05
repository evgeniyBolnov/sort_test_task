CUR_FILE_DIR := $(dir $(lastword $(MAKEFILE_LIST)))

################################################################################

ifdef MODELSIM_BIN_PATH
	VMAP := $(MODELSIM_BIN_PATH)/vmap
	VLIB := $(MODELSIM_BIN_PATH)/vlib
	VLOG := $(MODELSIM_BIN_PATH)/vlog
	VCOM := $(MODELSIM_BIN_PATH)/vcom
	VSIM := $(MODELSIM_BIN_PATH)/vsim
else
	VMAP := vmap
	VLIB := vlib
	VLOG := vlog
	VCOM := vcom
	VSIM := vsim
endif

ifdef QUARTUS_ROOTDIR
	QSYS_GEN  := $(QUARTUS_ROOTDIR)/sopc_builder/bin/qsys-generate
	QSYS_EDIT := $(QUARTUS_ROOTDIR)/sopc_builder/bin/qsys-edit
	QSH       := $(QUARTUS_ROOTDIR)/bin64/quartus_sh
else
	QSYS_GEN  := qsys-generate
	QSYS_EDIT := qsys-edit
	QSH       := quartus_sh
endif

RTL_LIBRARY       = work
COMPILED_LIBRARY  = ../ip/compiled_library
DEPS_DIR          = .deps
COM_LOG_FILES     = $(addprefix $(DEPS_DIR)/, $(addsuffix .log,$(HDL_SRC)))
VSIM_RUN_SCRIPT   = .run.tcl
VSIM_COVER_SCRIPT = .cover.tcl
HTML_REPORT_DIR   = coverage_report
PLAIN_REPORT_FILE = report.txt

VSIM_CMD = $(VSIM) -c -onfinish exit
VSIM_GUI = $(VSIM) -gui -onfinish stop

VSIM_OPT = -voptargs=+acc -msgmode both

QSYS_OUT_DIR     = .qsys_out
QSYS_NAMES       = $(basename $(notdir $(QSYS_SRC)))
QSYS_MSIMCOM_TCL = $(foreach i, $(QSYS_NAMES), $(QSYS_OUT_DIR)/$i_msim.tcl)
QSYS_MSIMCOM_LOG = $(foreach i, $(QSYS_NAMES), $(QSYS_OUT_DIR)/$i_msim.log)

ifdef QSYS_SRC
QSYS_PKG_LIBS = $(addprefix -L , $(QSYS_NAMES))
VLOG_OPT     += $(QSYS_PKG_LIBS)
VSIM_OPT     += $(QSYS_PKG_LIBS)
endif

ifndef PYTHON3
PYTHON3 := python
endif

################################################################################

.SECONDARY: $(QSYS_MSIMCOM_TCL)
$(QSYS_OUT_DIR)/%_msim.tcl : %.qsys
	$(QSYS_GEN) $^ -sim=VERILOG -sp="$(QSYS_LIB_PATH),$$" -od="$(QSYS_OUT_DIR)/$(basename $(notdir $^))"
	$(PYTHON3) $(CUR_FILE_DIR)/spd2msimtcl.py -od=$(QSYS_OUT_DIR)/$(basename $(notdir $^)) \
	-spd=$(QSYS_OUT_DIR)/$(basename $(notdir $^))/$(basename $(notdir $^)).spd -tcl=$@

$(QSYS_OUT_DIR)/%_msim.log: $(QSYS_OUT_DIR)/%_msim.tcl
	$(VSIM_CMD) -do $^
	touch $@

qsyscom: $(QSYS_MSIMCOM_LOG)

.PHONY: qsyscom_force
qsyscom_force: $(QSYS_MSIMCOM_TCL)
	$(VSIM_CMD) -do $^

qsysclean:
	rm -rf $(QSYS_OUT_DIR)
	rm -rf libraries
	rm -rf .qsys_edit
	rm -f  *.sopcinfo

# Run qsys-edit without Quartus
qsysedit:
	$(QSYS_EDIT)

qsystest:
	@echo $(QSYS_NAMES)
	@echo $(QSYS_MSIMCOM_TCL)
	@echo $(QSYS_MSIMCOM_LOG)

.PHONY: qsysclean qsysedit qsystest

#--------------------------------------------------
#    Full compile
#--------------------------------------------------


.PHONY: com
com: $(RTL_LIBRARY) $(DEPS_DIR) $(COM_LOG_FILES)

#--------------------------------------------------
#    Compile Altera library
#--------------------------------------------------

.PHONY: libcom
libcom:
	$(QSH) --simlib_comp -tool modelsim -language verilog -tool_path $(MODELSIM_BIN_PATH) -directory $(COMPILED_LIBRARY)/ -rtl_only

#--------------------------------------------------
#    Compile HDL Sources
#--------------------------------------------------

$(DEPS_DIR):
	mkdir -p $(DEPS_DIR)

$(RTL_LIBRARY):
	$(VLIB) $(RTL_LIBRARY)
	$(VMAP) $(RTL_LIBRARY) $(RTL_LIBRARY)

$(DEPS_DIR)/%.sv.log: %.sv
	$(VLOG) -sv -work $(RTL_LIBRARY) $(VLOG_OPT) +cover $^
	touch $@

$(DEPS_DIR)/%.v.log: %.v
	$(VLOG) -sv -work $(RTL_LIBRARY) $(VLOG_OPT) +cover $^
	touch $@

$(DEPS_DIR)/%.vhd.log: %.vhd
	$(VCOM) -work $(RTL_LIBRARY) $(VCOM_OPT) +cover $^
	touch $@

#--------------------------------------------------
#    Run Coverage Report
#--------------------------------------------------

.PHONY: coverage
coverage: com $(VSIM_COVER_SCRIPT) $(CUR_FILE_DIR)/alias.tcl
	@echo "===========Run COVERAGE===================="
	$(VSIM) -c -onfinish stop -coverage -do $(VSIM_COVER_SCRIPT)

$(VSIM_COVER_SCRIPT): $(CUR_FILE_DIR)/alias.tcl
	@echo "set MAKE_CMD {$(MAKE)}" > $@
	@echo "source $(CUR_FILE_DIR)/alias.tcl" >> $@
	@for d in $(LIBRARY) ; do \
		echo "vmap $$d $(COMPILED_LIBRARY)/verilog_libs/$${d}_ver" >> $@ ; \
	done
	@echo "vsim -GSEED=[clock seconds] -L $(RTL_LIBRARY) $(addprefix "-L ", $(LIBRARY)) $(VSIM_OPT) -coverage $(RTL_LIBRARY).$(TOP_ENTITY) $(SV_DPI_LD_LIBS_VSIM_OPT)" >> $@
ifdef PRE_RUN_SCRIPT
	@echo "source $(PRE_RUN_SCRIPT)" >> $@
endif
	@echo "run -all" >> $@
ifdef POST_RUN_SCRIPT
	@echo "source $(POST_RUN_SCRIPT)" >> $@
endif
	@echo "coverage report -file $(PLAIN_REPORT_FILE) -byinstance -assert -directive -cvg -codeAll" >> $@
	@echo "coverage report -html -htmldir $(HTML_REPORT_DIR) -source -details -assert -directive -cvg -code bcefst -threshL 50 -threshH 90" >> $@
	@echo "exit" >> $@

#--------------------------------------------------
#    Run Simulation
#--------------------------------------------------

.PHONY: sim
sim: com $(VSIM_RUN_SCRIPT)
	@echo "===========Run SIMULATION==================="
	$(VSIM_CMD) -coverage -do $(VSIM_RUN_SCRIPT)

.PHONY: gui
gui: com $(VSIM_RUN_SCRIPT)
	@echo "==============Run GUI======================="
	$(VSIM_GUI) -coverage -do $(VSIM_RUN_SCRIPT)

$(VSIM_RUN_SCRIPT): $(CUR_FILE_DIR)/alias.tcl
	@echo "===========Generate $(VSIM_RUN_SCRIPT)==================="
	@echo "set MAKE_CMD {$(MAKE)}" > $@
	@echo "source $(CUR_FILE_DIR)/alias.tcl" >> $@
	@for d in $(LIBRARY) ; do \
		echo "vmap $$d $(COMPILED_LIBRARY)/verilog_libs/$${d}_ver" >> $@ ; \
	done
	@echo "vsim -GSEED=[clock seconds] -L $(RTL_LIBRARY) $(addprefix "-L ", $(LIBRARY)) $(VSIM_OPT) $(RTL_LIBRARY).$(TOP_ENTITY) $(SV_DPI_LD_LIBS_VSIM_OPT)" >> $@
ifneq ("$(wildcard wave.do)","")
	@echo "do wave.do" >> $@
endif
ifdef PRE_RUN_SCRIPT
	@echo "source $(PRE_RUN_SCRIPT)" >> $@
endif
	@echo "run -all" >> $@
ifdef POST_RUN_SCRIPT
	@echo "source $(POST_RUN_SCRIPT)" >> $@
endif

#--------------------------------------------------
#    Run GTKWAVE
#--------------------------------------------------

.PHONY: gtkwave
gtkwave: vcd_gen
	@echo "===========Run GTKWAVE==================="
	$(GTK) vsim.vcd &

#--------------------------------------------------
#    Convert WLF to VCD for GTKWAVE
#--------------------------------------------------

.PHONY: vcd_gen
vcd_gen: sim
	@echo "===========Generate VCD=================="
	wlf2vcd -o vsim.vcd vsim.wlf

clean: 
	rm -rf $(RTL_LIBRARY)
	rm -rf $(HTML_REPORT_DIR) $(PLAIN_REPORT_FILE)
	rm -rf $(COMPILED_LIBRARY) $(QSYS_OUT_DIR)
	rm -rf $(DEPS_DIR)
	rm -f  $(VSIM_RUN_SCRIPT) $(VSIM_COVER_SCRIPT)
	rm -f  modelsim.ini
	rm -f  transcript
	rm -f  *.wlf
	rm -f  wlf*
	rm -f  *.vcd

cleanall: clean qsysclean