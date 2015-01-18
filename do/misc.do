add wave -divider "forward_a"
add wave -hex /dut/smp_0/cpu0/forward_a
add wave -hex /dut/smp_0/cpu0/id_ex_rs
add wave -hex /dut/smp_0/cpu0/writeback_data
add wave -hex /dut/smp_0/cpu0/ex_mem.alu_out
add wave -hex /dut/smp_0/cpu0/id_ex_rs_data
add wave -hex /dut/smp_0/cpu0/alu_a


add wave -divider "forward_b"
add wave -hex /dut/smp_0/cpu0/forward_b
add wave -hex /dut/smp_0/cpu0/id_ex_rt
add wave -hex /dut/smp_0/cpu0/writeback_data
add wave -hex /dut/smp_0/cpu0/ex_mem.alu_out
add wave -hex /dut/smp_0/cpu0/id_ex_rt_data
add wave -hex /dut/smp_0/cpu0/alu_b_tmp
add wave -hex /dut/smp_0/cpu0/alu_b


add wave -divider alu
add wave -hex /dut/smp_0/cpu0/alu_inst/a 
add wave -hex /dut/smp_0/cpu0/alu_inst/b
add wave -hex /dut/smp_0/cpu0/alu_inst/op
add wave -hex /dut/smp_0/cpu0/alu_inst/zero
add wave -hex /dut/smp_0/cpu0/alu_inst/overflow
add wave -hex /dut/smp_0/cpu0/alu_inst/f
