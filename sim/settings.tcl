# Simulator options
set vsim_opt {-voptargs=+acc}

# Compiler options
set vlog_opt {-work work -vlog01compat +incdir+../../../hdl/utils +define+MODELSIM}
set svlog_opt {-work work -sv +incdir+../../../hdl/utils +define+MODELSIM}
set vcom_opt {}

# Top level module
set top_module sort_tb

# Wave format files
set wave_files {wave.do}

set modelsim_edition altera

# for modelsim altera edition library format is simple list
# set altera_library {altera altera_mf cycloneii_ver}

# for modelsim other edition you should to set path to
# compiled altera libraries
# set altera_library {{lib1_path {lib11 lib12}} {lib2_path {lib21 lib22 }}} 

set altera_library {altera_ver altera_mf_ver cyclonev_ver altera_lnsim_ver cyclonev_ver}

#
# Design files
# set design_library { {path1 {file1_1 file1_2}} {path2 {file2_1 file2_2}} }
#

set design_library {
    {
        ../rtl
        {
            sort.sv
        }
    }
    {
        ../sim
        {
            sort_tb.sv  
        }
    }
}