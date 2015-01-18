module dual_port_ram_mf
#(
    parameter int DATA_WIDTH = 32,
    parameter int ADDR_WIDTH = 16,
    parameter RAM_BLOCK_TYPE = "AUTO"
)
(
    input                   clock,
    input  [ADDR_WIDTH-1:0] address_a,
    input  [ADDR_WIDTH-1:0] address_b,
    input  [DATA_WIDTH-1:0] data_a,
    input  [DATA_WIDTH-1:0] data_b,
    input                   wren_a,
    input                   wren_b,
    output [DATA_WIDTH-1:0] q_a,
    output [DATA_WIDTH-1:0] q_b
);

    altsyncram altsyncram_component (
        .wren_a (wren_a),
        .clock0 (clock),
        .wren_b (wren_b),
        .address_a (address_a),
        .address_b (address_b),
        .data_a (data_a),
        .data_b (data_b),
        .q_a (q_a),
        .q_b (q_b),
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
//        .eccstatus (),
//        .rden_a (1'b1),
        .rden_b (1'b1)
    );

    defparam
        altsyncram_component.address_aclr_a = "NONE",
        altsyncram_component.address_aclr_b = "NONE",
        altsyncram_component.address_reg_b = "CLOCK0",
        altsyncram_component.indata_aclr_a = "NONE",
        altsyncram_component.indata_aclr_b = "NONE",
        altsyncram_component.indata_reg_b = "CLOCK0",
        altsyncram_component.intended_device_family = "Stratix",
        altsyncram_component.lpm_type = "altsyncram",
        altsyncram_component.numwords_a = 1 << ADDR_WIDTH,
        altsyncram_component.numwords_b = 1 << ADDR_WIDTH,
        altsyncram_component.operation_mode = "BIDIR_DUAL_PORT",
        altsyncram_component.outdata_aclr_a = "NONE",
        altsyncram_component.outdata_aclr_b = "NONE",
        altsyncram_component.outdata_reg_a = "UNREGISTERED",
        altsyncram_component.outdata_reg_b = "UNREGISTERED",
        altsyncram_component.power_up_uninitialized = "FALSE",
        altsyncram_component.read_during_write_mode_mixed_ports = "DONT_CARE",
        altsyncram_component.widthad_a = ADDR_WIDTH,
        altsyncram_component.widthad_b = ADDR_WIDTH,
        altsyncram_component.width_a = DATA_WIDTH,
        altsyncram_component.width_b = DATA_WIDTH,
        altsyncram_component.width_byteena_a = 1,
        altsyncram_component.width_byteena_b = 1,
        altsyncram_component.wrcontrol_aclr_a = "NONE",
        altsyncram_component.wrcontrol_aclr_b = "NONE",
        altsyncram_component.wrcontrol_wraddress_reg_b = "CLOCK0",
        altsyncram_component.ram_block_type = RAM_BLOCK_TYPE;

endmodule
