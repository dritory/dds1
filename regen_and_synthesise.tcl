cd [file dirname [file normalize [info script]]]

set origin_dir "."
#executing the script will change the current directory
#calculate the locations before executing starts
set regen 	[file normalize "${origin_dir}/regenerate_projects.tcl"]
set regenip [file normalize "${origin_dir}/generate_IP.tcl"]
set synth 	[file normalize "${origin_dir}/synthesize.tcl"]

source -notrace $regen
source -notrace $regenip
source -notrace $synth