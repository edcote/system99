import bus_package::*;

interface instruction_cache_interface;
        // controller
        logic [31:0]  miss_address;
        logic [127:0] miss_data;
        logic         miss;
        logic         done;
        
        // cache
        logic [31:0]  read_address;
        logic [127:0] read_data;
        logic [1:0]   read_state;
        logic         tag_match;

        logic [127:0] write_data;
        logic [1:0]   write_state;
        logic         write_enable;

    modport controller
    (
        // miss
        input  miss_address, miss,
        output miss_data,
        output done
    );

    modport cache
    (
        input miss_address, miss,

        // read port
        input  read_address,
        output read_data, read_state, tag_match,
        // write port
        input write_data, write_state, write_enable
    );

    modport pipeline
    (
        // miss
        output miss_address, miss,
        input  miss_data,
        input  done,

        // read port
        output read_address,
        input  read_data, read_state, tag_match,
        // write port
        output write_data, write_state, write_enable
    );

endinterface // instruction_cache_interface


module instruction_cache 
#(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 128,
    parameter int INDEX_WIDTH = 12,
    parameter int OFFSET_WIDTH = 4,
    parameter int TAG_WIDTH = ADDR_WIDTH-OFFSET_WIDTH-INDEX_WIDTH 
) 
(
    input clock, 
    instruction_cache_interface.cache cache
);

    /*************************************************************************/
    /* Input index                                                           */
    /*************************************************************************/

    wire [TAG_WIDTH-1:0]    tag_in_a    = cache.miss_address[ADDR_WIDTH-1:ADDR_WIDTH-TAG_WIDTH];

    // Input address select
    logic [31:0] address_in;
    
    always_comb
        if (!cache.miss)
            address_in = cache.read_address;
        else
            address_in = cache.miss_address;

    wire [INDEX_WIDTH-1:0]  index_in_a  = address_in[INDEX_WIDTH+OFFSET_WIDTH-1:OFFSET_WIDTH];    
    wire [OFFSET_WIDTH-1:0] offset_in_a = address_in[OFFSET_WIDTH-1:0];

    /*************************************************************************/
    /* Tag match logic                                                       */
    /*************************************************************************/

    wire [TAG_WIDTH-1:0] tag_a;

    always_comb
        if (tag_a == tag_in_a)
            cache.tag_match = 1;
        else
            cache.tag_match = 0;

    /*************************************************************************/
    /* RAM                                                                   */
    /*************************************************************************/
    
    dual_port_ram_mf #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(INDEX_WIDTH)) data_ram (
        .clock (clock),

        .address_a (index_in_a),
        .data_a (cache.write_data),
        .wren_a (cache.write_enable),
        .q_a (cache.read_data),
            
        .address_b ({INDEX_WIDTH{1'b0}}),
        .data_b ({DATA_WIDTH{1'b0}}),
        .wren_b (1'b0),
        .q_b ()
    );

    dual_port_ram_mf #(.DATA_WIDTH(TAG_WIDTH), .ADDR_WIDTH(INDEX_WIDTH), .RAM_BLOCK_TYPE("M4K")) tag_ram (
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

    dual_port_ram_mf #(.DATA_WIDTH(2), .ADDR_WIDTH(INDEX_WIDTH), .RAM_BLOCK_TYPE("M4K")) state_ram (
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

endmodule // instruction_cache

