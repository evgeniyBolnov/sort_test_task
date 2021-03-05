onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /sort_tb/snk_clock
add wave -noupdate /sort_tb/src_clock
add wave -noupdate /sort_tb/snk_reset
add wave -noupdate /sort_tb/src_reset
add wave -noupdate /sort_tb/snk_sop
add wave -noupdate /sort_tb/snk_eop
add wave -noupdate /sort_tb/snk_valid
add wave -noupdate -format Analog-Step -height 74 -max 65511.999999999993 -radix unsigned /sort_tb/snk_data
add wave -noupdate /sort_tb/snk_ready
add wave -noupdate /sort_tb/src_valid
add wave -noupdate /sort_tb/src_sop
add wave -noupdate /sort_tb/src_eop
add wave -noupdate -format Analog-Step -height 74 -max 65511.999999999993 -radix unsigned /sort_tb/src_data
add wave -noupdate /sort_tb/ref_ready
add wave -noupdate /sort_tb/ref_sop
add wave -noupdate /sort_tb/ref_eop
add wave -noupdate /sort_tb/ref_valid
add wave -noupdate -format Analog-Step -height 74 -max 65511.999999999993 -radix unsigned /sort_tb/ref_data
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {36652590 ps} 0} {{Cursor 2} {194790 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {775051730 ps} {778512960 ps}
