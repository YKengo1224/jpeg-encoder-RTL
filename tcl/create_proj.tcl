# env
set CURRENT_DIR        [pwd]
set HOME_DIR           [file dirname $CURRENT_DIR]
set WORKSPACE_DIR      "vivado_proj"
set PROJECT_NAME       "vivado_proj"
set BD_TCL             ${HOME_DIR}/tcl/gen_bd.tcl
lappend ip_repo_path_list [file join ${CURRENT_DIR} "ip_repo"]
set ZYBO               "zyboz7-20"
set KV260              "kv260"
set BOARD              ${ZYBO}
#set BOARD              "kv260"
#set CHIP               "xczu9eg-ffvb1156-2-e"

# Create IP NAMEs
set AXI_CLK_GEN        "AXI_CLK_GEN"
set PIXEL_CLK_GEN      "PIXEL_CLK_GEN"
set ZYNQ_MP            "ZYNQMP"

#select port
if {  ${BOARD}  == ${ZYBO} } then {
    set CHIP          "xc7z020clg400-1"
    set BOARD_PORT    "digilentinc.com:zybo-z7-20:part0:1.1"

} elseif {  ${BOARD}  == ${KV260} } then {
    set CHIP          "xck26-sfvc784-2LV-c"
    set BOARD_PORT    "xilinx.com:kv260_som:part0:1.4"
    
} else {
    puts "ERROR:not supported board at this tcl script"
    return 1
    
}


# create project
if { [ file exists ${WORKSPACE_DIR}/${PROJECT_NAME}.xpr ] == 0 } then {
    create_project -force ${PROJECT_NAME} ${WORKSPACE_DIR} -part ${CHIP}
    set_property board_part  ${BOARD_PORT} [current_project]
    #set ip repo
    if {[info exists ip_repo_path_list] && [llength $ip_repo_path_list] > 0 } {
        set_property ip_repo_paths $ip_repo_path_list [current_fileset]
        update_ip_catalog
    }
    #import bd
    if {[file exists ${BD_TCL}] == 1 } then {
        source ${BD_TCL}
        regenerate_bd_layout
        save_bd_design
        set design_bd_name  [get_bd_designs]
        make_wrapper -files [get_files $design_bd_name.bd] -top -import
    }

}

exit
