set top_level "system"

# Create new project
project_new -overwrite quartus
set_global_assignment -name PROJECT_OUTPUT_DIRECTORY ./quartus

# Specify top-level entity
set_global_assignment -name TOP_LEVEL_ENTITY "$top_level"
set_global_assignment -name EDIF_FILE "$top_level.edf"

# Select FPGA device
set_global_assignment -name FAMILY "Stratix"
set_global_assignment -name DEVICE "EP1S40F780C5"

# Optimize for speed
set_global_assignment -name OPTIMIZATION_TECHNIQUE "speed"

# Turn-on FastFit fitter option
#set_global_assignment -name FITTER_EFFORT "Fast Fit"
set_global_assignment -name FITTER_EFFORT "Standard Fit"

# Precision RTL specific settings
set_global_assignment -section_id EDA_DESIGN_SYNTHESIS -name EDA_DESIGN_ENTRY_SYNTHESIS_TOOL "PRECISION SYNTHESIS"
set_global_assignment -section_id EDA_DESIGN_SYNTHESIS -name EDA_SIMULATION_TOOL "MODELSIM (VERILOG HDL OUTPUT FROM QUARTUS II)"
set_global_assignment -section_id EDA_DESIGN_SYNTHESIS -name EDA_USE_LMF "mentor.lmf"
set_global_assignment -section_id EDA_DESIGN_SYNTHESIS -name EDA_INPUT_GND_NAME "GND"
set_global_assignment -section_id EDA_DESIGN_SYNTHESIS -name EDA_INPUT_VCC_NAME "VCC"
set_global_assignment -section_id EDA_DESIGN_SYNTHESIS -name EDA_SHOW_LMF_MAPPING_MESSAGES "OFF"
set_global_assignment -section_id EDA_DESIGN_SYNTHESIS -name EDA_RUN_TOOL_AUTOMATICALLY "OFF"
set_global_assignment -section_id EDA_DESIGN_SYNTHESIS -name EDA_INPUT_DATA_FORMAT "EDIF"
set_global_assignment -section_id EDA_DESIGN_SYNTHESIS -name EDA_OUTPUT_DATA_FORMAT "EDIF"

set_global_assignment -section_id EDA_SIMULATION -name EDA_FLATTEN_BUSES "OFF"
set_global_assignment -section_id EDA_TIMING_ANALYSIS -name EDA_FLATTEN_BUSES "OFF"

# Enable SignalTap II logic analyzer
set_global_assignment -name ENABLE_LOGIC_ANALYZER_INTERFACE "ON"
set_global_assignment -name ENABLE_SIGNALTAP "ON"

# Tweak device pin options
set_global_assignment -name RESERVE_ALL_UNUSED_PINS "As input tri-stated"
set_global_assignment -name RESERVE_DATA0_AFTER_CONFIGURATION "Use as regular io"

# Specify synthesis and pnr constraints
create_base_clock -fmax 50MHz "clock"

set_location -to clock "PIN_K17"
# set_location -to reset_n AC9

set_location -to clock "PIN_K17"
set_location -to reset_n "PIN_AC9"

set_location -to flash_address[0] "PIN_A4"
set_location -to flash_address[1] "PIN_A3"
set_location -to flash_address[2] "PIN_B3"
set_location -to flash_address[3] "PIN_B5"
set_location -to flash_address[4] "PIN_B4"
set_location -to flash_address[5] "PIN_C4"
set_location -to flash_address[6] "PIN_A5"
set_location -to flash_address[7] "PIN_C5"
set_location -to flash_address[8] "PIN_D5"
set_location -to flash_address[9] "PIN_E6"
set_location -to flash_address[10] "PIN_A6"
set_location -to flash_address[11] "PIN_B7"
set_location -to flash_address[12] "PIN_D6"
set_location -to flash_address[13] "PIN_A7"
set_location -to flash_address[14] "PIN_D7"
set_location -to flash_address[15] "PIN_C6"
set_location -to flash_address[16] "PIN_C7"
set_location -to flash_address[17] "PIN_B6"
set_location -to flash_address[18] "PIN_D8"
set_location -to flash_address[19] "PIN_C8"
set_location -to flash_address[20] "PIN_E8"
set_location -to flash_address[21] "PIN_D9"
set_location -to flash_address[22] "PIN_B9"

set_location -to flash_data[0] "PIN_H12"
set_location -to flash_data[1] "PIN_F12"
set_location -to flash_data[2] "PIN_J12"
set_location -to flash_data[3] "PIN_M12"
set_location -to flash_data[4] "PIN_H17"
set_location -to flash_data[5] "PIN_K18"
set_location -to flash_data[6] "PIN_H18"
set_location -to flash_data[7] "PIN_G18"

set_location -to flash_cs_n "PIN_K19"
set_location -to flash_oe_n "PIN_F19"
set_location -to flash_we_n "PIN_G19"

set_location -to led[0] "PIN_H27"
set_location -to led[1] "PIN_H28"
set_location -to led[2] "PIN_L23"
set_location -to led[3] "PIN_L24"
set_location -to led[4] "PIN_J25"
set_location -to led[5] "PIN_J26"
set_location -to led[6] "PIN_L20"
set_location -to led[7] "PIN_L19"
