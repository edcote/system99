add wave -hex /dut/clock

add wave -divider
add wave -hex /dut/smp_0/cpu0/take_branch
add wave -hex /dut/smp_0/cpu0/icache_stall
add wave -hex /dut/smp_0/cpu0/dcache_stall

add wave -divider
add wave -hex /dut/smp_0/cpu0/branch_address
add wave -hex /dut/smp_0/cpu0/next_pc
add wave -hex /dut/smp_0/cpu0/if_id.pc

add wave -divider
add wave -hex /dut/smp_0/cpu0/pc

add wave -divider
add wave -hex /dut/smp_0/cpu0/if_id.next_pc
add wave -hex /dut/smp_0/cpu0/if_id.pc

add wave -divider
add wave -hex /dut/smp_0/cpu0/icache_hit
add wave -hex /dut/smp_0/icache0_if/*

add wave -divider
add wave -hex /dut/smp_0/cpu0/id_ex

add wave -divider
add wave -hex /dut/smp_0/cpu0/ex_mem

add wave -divider
add wave -hex /dut/smp_0/cpu0/mem_wb



