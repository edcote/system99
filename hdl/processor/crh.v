// "NEW" CRH implementation
// FIX, PROBE OUT
// FIX, SAME INCR/DECR. ADDRESS
// FIX ENABLE


module crh 
#(
    parameter int REGION_WIDTH = 11,  // 2048 entries
    parameter int COUNT_WIDTH = 16
)
(
    input  clock, reset, enable,
    input  increment, 
    input  [31:0] increment_address,
    input  decrement, 
    input  [31:0] decrement_address,
    input  probe,
    input  [31:0] probe_address,
    output p
);
/*
    // CRH update takes 2 clock cycles, all inputs must be held!!!
    // Port A: increment
    // Port B: decrement and/or probe (decrement has higher priority)

    // Address mapping
    wire [REGION_WIDTH-1:0] increment_region = increment_address[31:32-REGION_WIDTH];
    wire [REGION_WIDTH-1:0] decrement_region = decrement_address[31:32-REGION_WIDTH];
    wire [REGION_WIDTH-1:0] probe_region     = probe_address[31:32-REGION_WIDTH];
   
    logic [REGION_WIDTH-1:0] port_b_region;
    
    always_comb
        if (decrement && probe)
            port_b_region = decrement_region;
        else if (decrement && !probe)
            port_b_region = decrement_region;
        else
            port_b_region = probe_region;

    // Increment pipeline
    logic increment_reg;

    always_ff @(posedge clock, posedge reset)
        if (reset)
            increment_reg <= 0;
        else if (increment && !increment_reg)
            increment_reg <= 1;
        else
            increment_reg <= 0;

    // Decrement pipeline
    logic decrement_reg;

    always_ff @(posedge clock, posedge reset)
        if (reset)
            decrement_reg <= 0;
        else if (decrement && !decrement_reg)
            decrement_reg <= 1;
        else
            decrement_reg <= 0;

    // Dual-port memory
    wire  [COUNT_WIDTH-1:0] increment_count, port_b_count;

    dual_port_ram_mf #(.DATA_WIDTH(COUNT_WIDTH), .ADDR_WIDTH(REGION_WIDTH), .RAM_BLOCK_TYPE("M4K")) crh_ram (
        .clock (clock),
        // Port A
        .address_a (increment_region),
        .data_a (increment_count + 1),
        .wren_a (increment_reg),
        .q_a (increment_count),
        
        // Port B
        .address_a (port_b_region),
        .data_a (port_b_count - 1),
        .wren_a (decrement_reg),
        .q_a (port_b_count)
    );
    
    // Filter output (p = 1, count = 0 | p = 0, count > 0)   
    always_comb    
        if (probe_reg)
            p = ~{|port_b_count}
        else
            p = 0;
*/
endmodule // crh
