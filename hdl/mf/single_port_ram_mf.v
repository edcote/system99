module single_port_ram_mf 
#(
    parameter int DATA_WIDTH = 32,
    parameter int ADDR_WIDTH = 16,
    parameter RAM_BLOCK_TYPE = "AUTO"
)
(
    input                   clock,
    input  [ADDR_WIDTH-1:0] rdaddress, wraddress,
    input  [DATA_WIDTH-1:0] data,
    input                   rden, wren,
    output [DATA_WIDTH-1:0] q
);

    // A: WRITE
    // B: READ

    altsyncram altsyncram_component (
        .wren_a (wren),
        .clock0 (clock),
        .address_a (wraddress),
        .address_b (rdaddress),
        .rden_b (rden),
        .data_a (data),
        .q_b (q),
        .aclr0 (1'b0),
        .aclr1 (1'b0),
        .addressstall_a (1'b0),
        .addressstall_b (1'b0),
        .byteena_a (1'b1),
        .byteena_b (1'b1),
        .clock1 (1'b1),
        .clocken0 (1'b1),
        .clocken1 (1'b1),
//        .clocken2 (1'b1),
//        .clocken3 (1'b1),
        .data_b ({DATA_WIDTH{1'b1}}),
//        .eccstatus (),
        .q_a (),
//        .rden_a (1'b1),
        .wren_b (1'b0)
    );

    defparam
        altsyncram_component.address_aclr_a = "NONE",
        altsyncram_component.address_aclr_b = "NONE",
        altsyncram_component.address_reg_b = "CLOCK0",
        altsyncram_component.indata_aclr_a = "NONE",
        altsyncram_component.intended_device_family = "Stratix",
        altsyncram_component.lpm_type = "altsyncram",
        altsyncram_component.numwords_a = 1 << ADDR_WIDTH,
        altsyncram_component.numwords_b = 1 << ADDR_WIDTH,
        altsyncram_component.operation_mode = "DUAL_PORT",
        altsyncram_component.outdata_aclr_b = "NONE",
        altsyncram_component.outdata_reg_b = "UNREGISTERED",
        altsyncram_component.power_up_uninitialized = "FALSE",
        altsyncram_component.rdcontrol_aclr_b = "NONE",
        altsyncram_component.rdcontrol_reg_b = "CLOCK0",
        altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
        altsyncram_component.widthad_a = ADDR_WIDTH,
        altsyncram_component.widthad_b = ADDR_WIDTH,
        altsyncram_component.width_a = DATA_WIDTH,
        altsyncram_component.width_b = DATA_WIDTH,
        altsyncram_component.width_byteena_a = 1,
        altsyncram_component.wrcontrol_aclr_a = "NONE",
        altsyncram_component.ram_block_type = RAM_BLOCK_TYPE;
        
endmodule
