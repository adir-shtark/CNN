# Recreate the CNN Vivado project from the sources in this repository.
#
# Tracked inputs:
#   rtl/            Verilog sources, including the testbench top_sim.v
#   rtl/*.mif       pretrained weights, biases, and the sigmoid ROM
#   constraints/    XDC constraints
#   IP/             Xilinx IP customization files (.xci), if any are added
#   sim/test_data/  vectors read by top_sim
#
# Generated output (not tracked):
#   work/cnn/
#
# From the repository root, in Vivado batch mode:
#   vivado -mode batch -source create_project.tcl
#
# Or from the Vivado Tcl console, after cd to the repository root:
#   source create_project.tcl
#
# Written for Vivado 2023.1, part xc7z007sclg400-1, board cora-z7-07s.
# Design top is zyNet. Simulation top is top_sim.

set origin_dir [file normalize [file dirname [info script]]]

proc fwd {path} {
    return [string map {\\ /} [file normalize $path]]
}

set proj_name cnn
set part      xc7z007sclg400-1
set board     digilentinc.com:cora-z7-07s:part0:1.1
set proj_dir  [fwd [file join $origin_dir work $proj_name]]
set rtl_dir   [file join $origin_dir rtl]
set ip_dir    [file join $origin_dir IP]
set xdc_dir   [file join $origin_dir constraints]
set test_dir  [file join $origin_dir sim test_data]

file mkdir [file join $origin_dir work]

if {[llength [get_projects -quiet]]} {
    close_project
}

create_project $proj_name $proj_dir -part $part -force
set_property target_language Verilog [current_project]
set_property simulator_language Verilog [current_project]
set_property default_lib xil_defaultlib [current_project]

if {[catch {set_property board_part $board [current_project]} board_err]} {
    puts "WARNING: board part '$board' was not applied: $board_err"
    puts "WARNING: the FPGA part '$part' is still selected."
}

set rtl_files {}
foreach f [lsort [glob -nocomplain -directory $rtl_dir *.v]] {
    if {[file tail $f] eq "top_sim.v"} {
        continue
    }
    lappend rtl_files [fwd $f]
}
if {[llength $rtl_files] == 0} {
    error "No RTL files found in [fwd $rtl_dir]"
}
add_files -norecurse $rtl_files

set mif_files {}
foreach f [lsort [glob -nocomplain -directory $rtl_dir *.mif]] {
    lappend mif_files [fwd $f]
}
if {[llength $mif_files] > 0} {
    add_files -norecurse $mif_files
}

set xdc_files {}
foreach f [lsort [glob -nocomplain -directory $xdc_dir *.xdc]] {
    lappend xdc_files [fwd $f]
}
if {[llength $xdc_files] > 0} {
    add_files -fileset constrs_1 -norecurse $xdc_files
}

set xci_files [lsort [glob -nocomplain -directory $ip_dir *.xci */*.xci]]
if {[llength $xci_files] > 0} {
    set xci_paths {}
    foreach f $xci_files {
        lappend xci_paths [fwd $f]
    }
    import_ip $xci_paths
    foreach ip [get_ips] {
        if {[get_property IS_LOCKED $ip]} {
            upgrade_ip $ip
        }
    }
    generate_target all [get_ips]
}

set tb_path [fwd [file join $rtl_dir top_sim.v]]
if {![file exists $tb_path]} {
    error "Missing testbench: $tb_path"
}
add_files -fileset sim_1 -norecurse $tb_path
set_property top top_sim [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]
set_property used_in_synthesis false [get_files $tb_path]
set_property used_in_implementation false [get_files $tb_path]

# top_sim loads these by file name with $readmemb. Adding them to sim_1
# makes Vivado copy them into the simulator run directory.
set test_files {}
foreach f [lsort [glob -nocomplain -directory $test_dir *.txt]] {
    lappend test_files [fwd $f]
}
if {[llength $test_files] > 0} {
    add_files -fileset sim_1 -norecurse $test_files
}

set_property top zyNet [current_fileset]
set_property include_dirs [list [fwd $rtl_dir]] [get_filesets sources_1]
set_property include_dirs [list [fwd $rtl_dir]] [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "INFO: Project created: [file join $proj_dir ${proj_name}.xpr]"
close_project
