module single_port_rom_mf
#(
    parameter int DATA_WIDTH = 32,
    parameter int ADDR_WIDTH = 16,
    parameter INIT_FILE = "dummy.hex"
)
(
    input                   clock, 
    input  [ADDR_WIDTH-1:0] address,
    output [DATA_WIDTH-1:0] q
);

    // A: ????
    // B: READ

    altsyncram altsyncram_component (
        .clock0 (clock),
        .address_a (address),
        .q_a (q),
        .aclr0 (1'b0),
        .aclr1 (1'b0),
        .address_b (1'b1),
        .addressstall_a (1'b0),
        .addressstall_b (1'b0),
        .byteena_a (1'b1),
        .byteena_b (1'b1),
        .clock1 (1'b1),
        .clocken0 (1'b1),
        .clocken1 (1'b1),
//        .clocken2 (1'b1),
//        .clocken3 (1'b1),
        .data_a ({DATA_WIDTH{1'b1}}),
        .data_b (1'b1),
//        .eccstatus (),
        .q_b (),
//        .rden_a (1'b1),
        .rden_b (1'b1),
        .wren_a (1'b0),
        .wren_b (1'b0)
    );

    defparam
        altsyncram_component.address_aclr_a = "NONE",
        altsyncram_component.init_file = INIT_FILE,
        altsyncram_component.intended_device_family = "Stratix",
        altsyncram_component.lpm_hint = "ENABLE_RUNTIME_MOD=NO",
        altsyncram_component.lpm_type = "altsyncram",
        altsyncram_component.numwords_a = 1 << ADDR_WIDTH,
        altsyncram_component.operation_mode = "ROM",
        altsyncram_component.outdata_aclr_a = "NONE",
        altsyncram_component.outdata_reg_a = "UNREGISTERED",
        altsyncram_component.ram_block_type = "M4K",
        altsyncram_component.widthad_a = ADDR_WIDTH,
        altsyncram_component.width_a = DATA_WIDTH,
        altsyncram_component.width_byteena_a = 1;

endmodule // single_port_rom_mf
