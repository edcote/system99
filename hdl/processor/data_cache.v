interface data_cache_interface;
        // controller
        logic [31:0]  miss_address;
        logic [127:0] miss_data;
        logic [1:0]   miss_command;
        logic         miss;
        logic         done;

        logic [31:0]  writeback_address;
        logic [127:0] writeback_data;
        logic         writeback;

        logic         increment;
        logic         decrement;

        // cache
        logic [31:0]  read_address;
        logic [127:0] read_data;
        logic [1:0]   read_state;
        logic         tag_match;

        logic [31:0]  replaced_address;

        logic [127:0] write_data;
        logic [1:0]   write_state;
        logic         write_enable;
        logic         state_write_enable;

        logic         set_pending;
        logic         clear_pending;
        logic         pending;

        // snoop
        logic         snoop;

        logic [31:0]  snoop_address;
        logic [1:0]   snoop_read_state;
        logic         snoop_tag_match;

        logic [1:0]   snoop_write_state;
        logic         snoop_state_write_enable;

    modport controller
    (
        // processor-side        
        // miss
        input  miss, miss_address, miss_command,
        output miss_data,
        input  writeback, writeback_address, writeback_data, // writeback
        input  increment, decrement,                         // crh

        output done,

        input  replaced_address,

        // bus-side
        output snoop, snoop_address,
        
        // read_port
        input  snoop_read_state, snoop_tag_match,        
        // write port
        output snoop_write_state, snoop_state_write_enable,

        output set_pending, clear_pending,
        input pending
    );

    modport cache
    (
        // processor-side
        input  miss, miss_address,
    
        // read port
        input  read_address,
        output read_data, read_state, tag_match,
        output replaced_address,
        // write port
        input  write_data, write_state, write_enable, state_write_enable,

        // bus-side
        input snoop, snoop_address,
        
        // read_port
        output snoop_read_state, snoop_tag_match,        
        // write port
        input  snoop_write_state, snoop_state_write_enable,
        
        input set_pending, clear_pending,
        output pending
    );

    modport pipeline
    (
        // miss
        output miss, miss_address, miss_command,
        input  miss_data,
        output writeback, writeback_address, writeback_data, // writeback
        output increment, decrement,                         // crh

        input done,
        
        // read port
        output read_address,
        input  read_data, read_state, tag_match,
        input  replaced_address,
        // write port
        output write_data, write_state, write_enable, state_write_enable
    );

endinterface // data_cache_interface

module data_cache
#(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 128,
    parameter int INDEX_WIDTH = 12,
    parameter int OFFSET_WIDTH = 4,
    parameter int TAG_WIDTH = ADDR_WIDTH-OFFSET_WIDTH-INDEX_WIDTH 
) 
(
    input clock, 
    data_cache_interface.cache cache
);

    /*************************************************************************/
    /* Processor input index                                                 */
    /*************************************************************************/
    
    wire [TAG_WIDTH-1:0] tag_in_a    = cache.miss_address[ADDR_WIDTH-1:ADDR_WIDTH-TAG_WIDTH];

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
    /* Processor tag match logic                                             */
    /*************************************************************************/

    logic [TAG_WIDTH-1:0] tag_a;

    always_comb
        if (tag_a == tag_in_a)
            cache.tag_match = 1;
        else
            cache.tag_match = 0;

    /*************************************************************************/
    /* Reconstruct replaced address (writeback or otherwise)                 */
    /*************************************************************************/

    assign cache.replaced_address[ADDR_WIDTH-1:ADDR_WIDTH-TAG_WIDTH]       = tag_a;
    assign cache.replaced_address[INDEX_WIDTH+OFFSET_WIDTH-1:OFFSET_WIDTH] = index_in_a;
    assign cache.replaced_address[OFFSET_WIDTH-1:0]                        = offset_in_a;

    /*************************************************************************/
    /* Snoop input index                                                     */
    /*************************************************************************/
    
    wire [TAG_WIDTH-1:0]    tag_in_b    = cache.snoop_address[ADDR_WIDTH-1:ADDR_WIDTH-TAG_WIDTH];
    wire [INDEX_WIDTH-1:0]  index_in_b  = cache.snoop_address[INDEX_WIDTH+OFFSET_WIDTH-1:OFFSET_WIDTH];    
    wire [OFFSET_WIDTH-1:0] offset_in_b = cache.snoop_address[OFFSET_WIDTH-1:0];

    /*************************************************************************/
    /* Snoop tag match logic                                                 */
    /*************************************************************************/

    logic [TAG_WIDTH-1:0] tag_b;

    always_comb
        if (tag_b == tag_in_b)
            cache.snoop_tag_match = 1;
        else
            cache.snoop_tag_match = 0;
    
    /*************************************************************************/
    /* RAM                                                                   */
    /*************************************************************************/

    dual_port_ram_mf #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(INDEX_WIDTH))
        data_ram (
            .clock (clock),

            .address_a (index_in_a),
            .data_a (cache.write_data),
            .wren_a (cache.write_enable),
            .q_a (cache.read_data),
            
            .address_b (index_in_b),
            .data_b ({DATA_WIDTH{1'b0}}), // fixme
            .wren_b (1'b0),
            .q_b ()
        );

    dual_port_ram_mf #(.DATA_WIDTH(TAG_WIDTH), .ADDR_WIDTH(INDEX_WIDTH), .RAM_BLOCK_TYPE("M4K"))
        tag_ram (
            .clock (clock),

            .address_a (index_in_a),
            .data_a (tag_in_a),
            .wren_a (cache.write_enable),
            .q_a (tag_a),
            
            .address_b (index_in_b),
            .data_b (tag_in_b),
            .wren_b (1'b0),
            .q_b (tag_b)
        );

    dual_port_ram_mf #(.DATA_WIDTH(2), .ADDR_WIDTH(INDEX_WIDTH), .RAM_BLOCK_TYPE("M4K"))
        state_ram (
            .clock (clock),

            .address_a (index_in_a),
            .data_a (cache.write_state),
            .wren_a (cache.write_enable || cache.state_write_enable),
            .q_a (cache.read_state),
            
            .address_b (index_in_b),
            .data_b (cache.snoop_write_state),
            .wren_b (cache.snoop_state_write_enable),
            .q_b (cache.snoop_read_state)
         );

    // Pending invalidation cache bit
    dual_port_ram_mf #(.DATA_WIDTH(1), .ADDR_WIDTH(INDEX_WIDTH), .RAM_BLOCK_TYPE("M4K"))
        pending_ram (
            .clock (clock),

            .address_a (index_in_a),
            .data_a (1'b0),
            .wren_a (cache.clear_pending),
            .q_a (cache.pending),
            
            .address_b (index_in_b),
            .data_b (1'b1),
            .wren_b (cache.set_pending),
            .q_b ()
         );

endmodule // data_cache

