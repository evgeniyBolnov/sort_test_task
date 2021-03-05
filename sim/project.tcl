transcript off
eval "do settings.tcl"
if [file exists work] {
    vdel -all
}
vlib work
vmap work work
set altera_libs [list]
if {[string match *altera* $modelsim_edition]} {
    puts "altera edition"
    foreach libname $altera_library {
        lappend altera_libs "-L"
        lappend altera_libs $libname
    }
} else {
    puts "not altera edition"
    foreach lib $altera_library {
        set lib_path [lindex $lib 0]
        set lib_names [lindex $lib 1]
        foreach name $lib_names {
            vmap $name $lib_path/$name
            lappend altera_libs "-L"
            lappend altera_libs $name
        }
    }
}
set design_files [list]
foreach lib $design_library {
    set lib_path [lindex $lib 0]
    set lib_files [lindex $lib 1]
    foreach file $lib_files {
        lappend design_files $lib_path/$file
    }   
}
set last_compile_time 0
proc rc {args} {
    global design_files last_compile_time
    global vcom_opt vlog_opt svlog_opt
    set unix_time [clock seconds]
	foreach file $design_files {
        if {[string match *.vhd $file]} {
            eval "vcom $vcom_opt $file" 
        } elseif {[string match *.v $file]} {
            eval "vlog $vlog_opt $file" 
        } elseif {[string match *.sv $file]} {
            eval "vlog $svlog_opt $file" 
        } else {
            error "Unsuppored design file type!"
        }
    }
    set last_compile_time [clock seconds]
}
proc c {args} {
    global design_files last_compile_time
    global vcom_opt vlog_opt svlog_opt    
    foreach file $design_files {
        if {$last_compile_time < [file mtime $file]} {
            if {[string match *.vhd $file]} {
                eval "vcom $vcom_opt $file" 
            } elseif {[string match *.v $file]} {
                eval "vlog $vlog_opt $file" 
            } elseif {[string match *.sv $file]} {
                eval "vlog $svlog_opt $file" 
            } else {
                error "Unsuppored design file type!"
            }
        }
    }
    set last_compile_time [clock seconds]
}
proc ss {args} {
    global altera_libs vsim_opt top_module wave_files
    view wave -title "test" -undock -x 1920 -y 0 -width 1920 -height 1080

    eval "vsim $vsim_opt $altera_libs work.$top_module"
    foreach file $wave_files {
        eval "do $file" 
    }
    #wm state .main_pane.wave zoomed
}
proc rs {args} {
    eval "restart -force" 
    eval "run -all"
}
proc qs {args} {
    eval "quit -sim"
}
proc cl {args} {
    set files [glob -nocomplain *]
    foreach file $files {
        if {![string match *.tcl $file] 
         && ![string match *.do $file] 
         && ![string match vsim.wlf $file]
		 && ![string match *.v $file]
		 && ![string match *.sv $file]} {
            file delete -force $file
        } 
    }
}
proc com_qsys {args} {
    global svlog_opt
    eval  vlog $svlog_opt -sv "./sub/verbosity_pkg.sv"              
    eval  vlog $svlog_opt -sv "./sub/avalon_mm_pkg.sv"              
    eval  vlog $svlog_opt -sv "./sub/avalon_utilities_pkg.sv"       
    eval  vlog $svlog_opt -sv "./sub/altera_avalon_mm_master_bfm.sv"
}
proc hp {args} {
    puts "Modelsim general compile script"
    puts "Author : Aleksey Golovchenko\n"

    puts "c  - compile out of date design files"
    puts "rc - recompile all design files"
    puts "ss - start simulation"
    puts "rs - restart and rerun simulation"
    puts "qs - end simulation"
    puts "cl - clean project directory\n"
    puts "hp  - print this message"
}

eval hp