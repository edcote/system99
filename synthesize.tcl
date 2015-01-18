# Create new project
new_project -name system -folder ./precision -createimpl -createimpl_name system_impl -force

# Setup design
setup_design -design system
setup_design -language_syntax_verilog="sv"
setup_design -frequency 50
setup_design -manufacturer Altera -family Stratix -part EP1S40F780C -speed 5
setup_design -edif
setup_design -search_path "../hdl"
setup_design -resource_sharing="false"

# Add files to project
set input [open ../compile_list]
while { [gets $input file] >= 0 } {
    if { $file != "" } {
        add_input_file ../$file
    }
}
close $input

save_project

# Compile
compile

# Specify design constraints 
create_clock -period 20 clock

# Synthesize
synthesize

# Save project and close
save_impl
close_project
