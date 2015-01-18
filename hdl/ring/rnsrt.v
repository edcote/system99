interface rnsrt_interface;
    logic [31:0] address;
    logic        insert;
    logic        invalidate;

    modport bus
    (
        input address,
        input insert, invalidate
    );
    
    modport ring
    (
        output address,
        output invalidate, insert
    );
endinterface // rnsrt_interface
    
module rnsrt_cache
#(
    parameter int REGION_WIDTH = 32,
    parameter int INDEX_WIDTH = 2,
    parameter int TAG_WIDTH = REGION_WIDTH-INDEX_WIDTH 
) 
(
    input clock,
    input [REGION_WIDTH-1:0] region,
    input invalidate,
    output valid
);

    /*************************************************************************/
    /* Input index                                                           */
    /*************************************************************************/

    wire [TAG_WIDTH-1:0]    tag_in    = region[REGION_WIDTH-1:REGION_WIDTH-TAG_WIDTH];
    wire [INDEX_WIDTH-1:0]  index_in  = region[INDEX_WIDTH+OFFSET_WIDTH-1:OFFSET_WIDTH];    
    wire [OFFSET_WIDTH-1:0] offset_in = region[OFFSET_WIDTH-1:0];

    /*************************************************************************/
    /* Tag match logic                                                       */
    /*************************************************************************/

    wire [TAG_WIDTH-1:0] tag_a;

    always_comb
        if (tag_a == tag_in_a)
            valid = 1;
        else
            valid = 0;

    /*************************************************************************/
    /* RAM                                                                   */
    /*************************************************************************/
    
    dual_port_ram_mf #(.DATA_WIDTH(1), .REGION_WIDTH(INDEX_WIDTH)) data_ram (
        .clock (clock),

        .address_a (index_in),
        .data_a (cache.write_data),
        .wren_a (cache.write_enable),
        .q_a (cache.read_data),
            
        .address_b ({INDEX_WIDTH{1'b0}}),
        .data_b ({DATA_WIDTH{1'b0}}),
        .wren_b (1'b0),
        .q_b ()
    );

    dual_port_ram_mf #(.DATA_WIDTH(TAG_WIDTH), .REGION_WIDTH(INDEX_WIDTH), .RAM_BLOCK_TYPE("M4K")) tag_ram (
        .clock (clock),

        .address_a (index_in_a),
        .data_a (tag_in_a),
        .wren_a (cache.write_enable),
        .q_a (tag_a),

        .address_b ({INDEX_WIDTH{1'b0}}),
        .data_b ({TAG_WIDTH{1'b0}}),
        .wren_b (1'b0),
        .q_b ()
    );

    dual_port_ram_mf #(.DATA_WIDTH(2), .REGION_WIDTH(INDEX_WIDTH), .RAM_BLOCK_TYPE("M4K")) state_ram (
        .clock (clock),

        .address_a (index_in_a),
        .data_a (cache.write_state),
        .wren_a (cache.write_enable),
        .q_a (cache.read_state),
            
        .address_b ({INDEX_WIDTH{1'b0}}),
        .data_b (2'b00),
        .wren_b (1'b0),
        .q_b ()
    );

endmodule // rnsrt_cache

