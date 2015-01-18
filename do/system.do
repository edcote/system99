vsim -L ./altera_mf -novopt -quiet system_tb

add wave -hex /dut/clock
add wave -hex /dut/led


# -- SMP 0 --------------------------------------------------------------------
add wave -divider "SMP0"

add wave -divider "REQUEST BUS"
add wave -hex /dut/smp_0/request/*

add wave -divider "RESPONSE BUS"
add wave -hex /dut/smp_0/response/*

# -- CPU 0 --------------------------------------------------------------------
add wave -divider "CPU0"
add wave -hex /dut/smp_0/cpu_0/icache_stall
add wave -hex /dut/smp_0/cpu_0/dcache_stall
add wave -hex /dut/smp_0/cpu_0/stall_pipeline
add wave -hex /dut/smp_0/cpu_0/flush_pipeline

add wave -divider "PC"
add wave -hex /dut/smp_0/cpu_0/next_pc
add wave -hex /dut/smp_0/cpu_0/branch_address
add wave -hex /dut/smp_0/cpu_0/take_branch
add wave -hex /dut/smp_0/cpu_0/pc
add wave -hex /dut/smp_0/icache_0_if/read_address

add wave -divider "ICACHE"
add wave -hex /dut/smp_0/icache_0_if/miss_address
add wave -hex /dut/smp_0/icache_0_if/tag_match
add wave -hex /dut/smp_0/icache_0_if/miss
add wave -hex /dut/smp_0/cpu_0/icache_hit

add wave -divider "IF/ID"
add wave -hex /dut/smp_0/cpu_0/if_id_ir
add wave -hex /dut/smp_0/cpu_0/if_id

add wave -divider "ID/EX"
add wave -hex /dut/smp_0/cpu_0/id_ex.ir
add wave -hex /dut/smp_0/cpu_0/id_ex

add wave -divider "EX/MEM"
add wave -hex /dut/smp_0/cpu_0/ex_mem.ir
add wave -hex /dut/smp_0/cpu_0/ex_mem

add wave -divider "MSI"
add wave -hex /dut/smp_0/cpu_0/msi_inst/*

add wave -divider "MEM/WB"
add wave -hex /dut/smp_0/cpu_0/mem_wb.ir
add wave -hex /dut/smp_0/cpu_0/mem_wb
add wave -hex /dut/smp_0/cpu_0/writeback_address
add wave -hex /dut/smp_0/cpu_0/writeback_data
add wave -hex /dut/smp_0/cpu_0/writeback_enable

add wave -divider "data cache"
add wave -hex /dut/smp_0/dcache_0_if/*

# -- CONTROLLER ---------------------------------------------------------------
add wave -divider "CONTROLLER"

add wave -hex /dut/smp_0/controller_0/snoop_enable
add wave -hex /dut/smp_0/controller_0/snoop_address
add wave -hex /dut/smp_0/controller_0/snoop_command
add wave -hex /dut/smp_0/controller_0/snoop_valid
add wave -hex /dut/smp_0/controller_0/snoop_end_state
add wave -hex /dut/smp_0/controller_0/snoop_invalidate
add wave -hex /dut/smp_0/controller_0/snoop_supply_data

add wave -hex /dut/smp_0/controller_0/state

# -- RING INTERFACE -----------------------------------------------------------
add wave -divider "NCRH"

add wave -hex /dut/system/ncrh_0/*
add wave -hex /dut/system/rnsrt_0/*

add wave -hex /dut/smp_0/ring_interface_0/increment_reg
add wave -hex /dut/smp_0/ring_interface_0/decrement_reg
add wave -hex /dut/smp_0/ring_interface_0/count_a
add wave -hex /dut/smp_0/ring_interface_0/count_b

# -- RING INTERFACE -----------------------------------------------------------
add wave -divider "RING INTERFACE"

add wave -hex /dut/smp_0/ring_interface_0/request_packet 
add wave -hex /dut/smp_0/ring_interface_0/response_packet 
add wave -hex /dut/smp_0/ring_interface_0/outbound_fifo_request_we 
add wave -hex /dut/smp_0/ring_interface_0/outbound_fifo_response_we 
add wave -hex /dut/smp_0/ring_interface_0/inbound_packet 
add wave -hex /dut/smp_0/ring_interface_0/bus_data 
add wave -hex /dut/smp_0/ring_interface_0/bus_data_we
add wave -hex /dut/smp_0/ring_interface_0/state

# -- RING NODE -----------------------------------------------------------
add wave -divider "RING NODE"

add wave -hex /dut/node_0/enable
add wave -hex /dut/node_0/packet_in

add wave -hex /dut/node_0/dest_node_match
add wave -hex /dut/node_0/src_node_match
add wave -hex /dut/node_0/pass_it_on
add wave -hex /dut/node_0/accept_it
add wave -hex /dut/node_0/remove_it
add wave -hex /dut/node_0/put_packet_on_ring

add wave -hex /dut/node_0/dest_node_match_reg
add wave -hex /dut/node_0/src_node_match_reg
add wave -hex /dut/node_0/pass_it_on_reg
add wave -hex /dut/node_0/accept_it_reg
add wave -hex /dut/node_0/remove_it_reg
add wave -hex /dut/node_0/put_packet_on_ring_reg

add wave -hex /dut/node_0/packet_out_tmp
add wave -hex /dut/node_0/packet_out

# -- INBOUND AND OUTBOUND FIFOs -----------------------------------------------
add wave -divider "INBOUND AND OUTBOUND FIFO"
add wave -hex /dut/inbound_fifo_0/*
add wave -hex /dut/outbound_fifo_0/*

# -- SMP 1 --------------------------------------------------------------------
add wave -divider
add wave -divider
add wave -divider
add wave -divider
add wave -divider
add wave -divider
add wave -divider
add wave -divider
add wave -divider
add wave -divider
add wave -divider

add wave -divider "SMP1"

add wave -divider "REQUEST BUS"
add wave -hex /dut/smp_1/request/*

add wave -divider "RESPONSE BUS"
add wave -hex /dut/smp_1/response/*

# -- CPU 1 --------------------------------------------------------------------
add wave -divider "CPU1"
add wave -hex /dut/smp_1/cpu_0/icache_stall
add wave -hex /dut/smp_1/cpu_0/dcache_stall
add wave -hex /dut/smp_1/cpu_0/stall_pipeline
add wave -hex /dut/smp_1/cpu_0/flush_pipeline

add wave -divider "PC"
add wave -hex /dut/smp_1/cpu_0/next_pc
add wave -hex /dut/smp_1/cpu_0/branch_address
add wave -hex /dut/smp_1/cpu_0/take_branch
add wave -hex /dut/smp_1/cpu_0/pc
add wave -hex /dut/smp_1/icache_0_if/read_address

add wave -divider "ICACHE"
add wave -hex /dut/smp_1/icache_0_if/miss_address
add wave -hex /dut/smp_1/icache_0_if/tag_match
add wave -hex /dut/smp_1/icache_0_if/miss
add wave -hex /dut/smp_1/cpu_0/icache_hit

add wave -divider "IF/ID"
add wave -hex /dut/smp_1/cpu_0/if_id_ir
add wave -hex /dut/smp_1/cpu_0/if_id

add wave -divider "ID/EX"
add wave -hex /dut/smp_1/cpu_0/id_ex.ir
add wave -hex /dut/smp_1/cpu_0/id_ex

add wave -divider "EX/MEM"
add wave -hex /dut/smp_1/cpu_0/ex_mem.ir
add wave -hex /dut/smp_1/cpu_0/ex_mem

add wave -divider "MSI"
add wave -hex /dut/smp_1/cpu_0/msi_inst/*

add wave -divider "MEM/WB"
add wave -hex /dut/smp_1/cpu_0/mem_wb.ir
add wave -hex /dut/smp_1/cpu_0/mem_wb
add wave -hex /dut/smp_1/cpu_0/writeback_address
add wave -hex /dut/smp_1/cpu_0/writeback_data
add wave -hex /dut/smp_1/cpu_0/writeback_enable

add wave -divider "data cache"
add wave -hex /dut/smp_1/dcache_0_if/*

# -- CONTROLLER ---------------------------------------------------------------
add wave -divider "CONTROLLER"

add wave -hex /dut/smp_1/controller_0/snoop_enable
add wave -hex /dut/smp_1/controller_0/snoop_address
add wave -hex /dut/smp_1/controller_0/snoop_command
add wave -hex /dut/smp_1/controller_0/snoop_valid
add wave -hex /dut/smp_1/controller_0/snoop_end_state
add wave -hex /dut/smp_1/controller_0/snoop_invalidate
add wave -hex /dut/smp_1/controller_0/snoop_supply_data

add wave -hex /dut/smp_1/controller_0/state

# -- NCRH ---------------------------------------------------------------------
add wave -divider "NCRH"

add wave -hex /dut/system/ncrh_1/*
add wave -hex /dut/system/rnsrt_1/*

add wave -hex /dut/smp_1/ring_interface_0/increment_reg
add wave -hex /dut/smp_1/ring_interface_0/decrement_reg
add wave -hex /dut/smp_1/ring_interface_0/count_a
add wave -hex /dut/smp_1/ring_interface_0/count_b

# -- RING INTERFACE -----------------------------------------------------------
add wave -divider "RING INTERFACE"

add wave -hex /dut/smp_1/ring_interface_0/request_packet 
add wave -hex /dut/smp_1/ring_interface_0/response_packet 
add wave -hex /dut/smp_1/ring_interface_0/outbound_fifo_request_we 
add wave -hex /dut/smp_1/ring_interface_0/outbound_fifo_response_we 
add wave -hex /dut/smp_1/ring_interface_0/inbound_packet 
add wave -hex /dut/smp_1/ring_interface_0/bus_data 
add wave -hex /dut/smp_1/ring_interface_0/bus_data_we
add wave -hex /dut/smp_1/ring_interface_0/state

# -- RING NODE -----------------------------------------------------------
add wave -divider "RING NODE"

add wave -hex /dut/node_1/enable
add wave -hex /dut/node_1/packet_in

add wave -hex /dut/node_1/dest_node_match
add wave -hex /dut/node_1/src_node_match
add wave -hex /dut/node_1/pass_it_on
add wave -hex /dut/node_1/accept_it
add wave -hex /dut/node_1/remove_it
add wave -hex /dut/node_1/put_packet_on_ring

add wave -hex /dut/node_1/dest_node_match_reg
add wave -hex /dut/node_1/src_node_match_reg
add wave -hex /dut/node_1/pass_it_on_reg
add wave -hex /dut/node_1/accept_it_reg
add wave -hex /dut/node_1/remove_it_reg
add wave -hex /dut/node_1/put_packet_on_ring_reg

add wave -hex /dut/node_1/packet_out_tmp
add wave -hex /dut/node_1/packet_out

# -- INBOUND AND OUTBOUND FIFO ------------------------------------------------
add wave -divider "INBOUND AND OUTBOUND FIFO"
add wave -hex /dut/inbound_fifo_1/*
add wave -hex /dut/outbound_fifo_1/*

# -- MISC ---------------------------------------------------------------------
add wave -divider "MISC"


view -undock -x 0 -y 0 wave
wave zoomfull

