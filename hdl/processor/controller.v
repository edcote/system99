import bus_package::*;
import cache_package::*;

module controller
#(
    parameter int ID = 0
)
(
    input clock, reset,
    // Instruction and data cache
    instruction_cache_interface.controller icache,
    data_cache_interface.controller dcache,
    // Request bus
    request_bus_interface.master request,
    output logic [31:0]          request_address,
    output logic [CMD_WIDTH-1:0] request_command,
    output logic [TAG_WIDTH-1:0] request_tag,
    output logic                 request_oe,
    // Request bus arbiter
    output logic request_breq, request_bhold, 
    input        request_bgnt,
    // Response bus
    response_bus_interface.master response,
    output logic [127:0]          response_data,
    output logic [TAG_WIDTH-1:0]  response_tag,
    output logic                  response_oe,
    // Response bus arbiter
    output logic response_breq, response_bhold, 
    input        response_bgnt,
    // NCRH
    output logic [31:0] ncrh_replaced_address,
    output logic        ncrh_increment,
    output logic        ncrh_decrement,
    // Wired-OR
    output logic inhibit, nack
);

    assign nack    = 0;
    assign inhibit = 0;
    
    /*************************************************************************/
    /* Processor-side controller                                             */
    /*************************************************************************/

    enum bit [2:0] { WAIT_MISS_ST, 
                     ICACHE_REQUEST_ST, WAIT_ICACHE_RESPONSE_ST, 
                     DCACHE_REQUEST_ST, DCACHE_DELAY_ST, WAIT_DCACHE_RESPONSE_ST, 
                     WRITEBACK_ST } state, next_state;

    always_ff @(posedge clock, posedge reset)
        if (reset)
            state <= WAIT_MISS_ST;
        else 
            state <= next_state;

    always_comb
    begin
        { request_breq, request_bhold } = '0;
        { request_address, request_command, request_tag, request_oe } = '0;
        { ncrh_replaced_address, ncrh_increment, ncrh_decrement } = '0;

        { response_breq, response_bhold } = '0;
        { response_tag, response_data, response_oe } = '0;

        dcache.clear_pending = 0;

        icache.done = 0;
        dcache.done = 0;
        
        next_state = state;

        case (state)
            WAIT_MISS_ST:
            begin
                if (icache.miss)
                    next_state = ICACHE_REQUEST_ST;
                else if (!icache.miss && dcache.writeback)
                    next_state = WRITEBACK_ST;
                else if (!icache.miss && dcache.miss && !dcache.writeback)
                    next_state = DCACHE_REQUEST_ST;                   
            end

            ICACHE_REQUEST_ST:
            begin
                // Request bus
                request_breq = 1;
                
                if (request_bgnt && request.nack)
                    next_state = WAIT_MISS_ST;
                else if (request_bgnt && !request.nack)
                begin
                    request_bhold = 1;

                    request_address = icache.miss_address;
                    request_command = bus_read;
                    request_tag     = (1 << ID);
                    request_oe      = 1;
                    
                    next_state = WAIT_ICACHE_RESPONSE_ST;
                end
            end

            WAIT_ICACHE_RESPONSE_ST:
                if (response.tag[ID])
                begin
                    icache.done = 1;
                    next_state = WAIT_MISS_ST;
                end

            WRITEBACK_ST:
            begin
                // Request both buses
                request_breq  = 1;
                response_breq = 1;
                
                if (request_bgnt)
                    request_bhold = 1;

                if (response_bgnt)
                    response_bhold = 1;

                if (request_bgnt && response_bgnt)
                begin
                    request_address = dcache.writeback_address;
                    request_command = bus_writeback;
                    request_tag     = (1 << ID);
                    request_oe      = 1;
                    
                    response_tag     = (1 << ID);
                    response_data    = dcache.writeback_data;
                    response_oe      = 1;

                    if (dcache.miss)
                        next_state = DCACHE_REQUEST_ST;
                    else
                    begin
                        dcache.done = 1;
                        next_state = WAIT_MISS_ST;
                    end
                end
            end

            DCACHE_REQUEST_ST:
            begin
                // Request bus
                request_breq = 1;

                if (request_bgnt && request.nack)
                    next_state = WAIT_MISS_ST;
                else if (request_bgnt && !request.nack)
                begin
                    request_bhold = 1;

                    request_address = dcache.miss_address;
                    request_command = dcache.miss_command;
                    request_tag     = (1 << ID);
                    request_oe      = 1;

                    // increment and/or decrement NCRH
                    ncrh_replaced_address = dcache.replaced_address; 
                    ncrh_increment        = dcache.increment;
                    ncrh_decrement        = dcache.decrement || dcache.pending;

                    // clear pending bit
                    dcache.clear_pending = dcache.pending;

                    next_state = DCACHE_DELAY_ST;
                end
            end
            
            DCACHE_DELAY_ST:
            begin
                request_bhold = 1;
                if (dcache.miss_command == bus_upgrade)
                begin
                    dcache.done = 1;
                    next_state = WAIT_MISS_ST;
                end
                else
                    next_state = WAIT_DCACHE_RESPONSE_ST;
            end
            
            WAIT_DCACHE_RESPONSE_ST:
                if (response.tag[ID])
                begin
                    dcache.done = 1;
                    next_state = WAIT_MISS_ST;
                end

        endcase
    end

    /*************************************************************************/
    /* Bus-side controller                                                   */
    /*************************************************************************/

    /*************************************************************************/
    /* Snoop input register                                                  */
    /*************************************************************************/

    wire snoop_enable = request.coherent && !request_bgnt;

    logic [31:0] snoop_address;
    logic [1:0]  snoop_command;
    logic        snoop_valid;

    always_ff @(posedge clock, posedge reset)
        if (reset)
        begin
            snoop_address <= '0;
            snoop_command <= '0;
            snoop_valid   <= 0;
        end
        else
        begin
            snoop_address <= request.address;
            snoop_command <= request.command;
            snoop_valid   <= snoop_enable;
        end

    /*************************************************************************/
    /* Snoop cache coherence protocol                                        */
    /*************************************************************************/

    logic [1:0] snoop_end_state;
    logic       snoop_invalidate;
    logic       snoop_supply_data;

    
    always_comb
    begin
        { snoop_end_state, snoop_invalidate, snoop_supply_data } = '0;

        // fixme
        if (snoop_valid && dcache.snoop_tag_match && (dcache.snoop_read_state == M) && (snoop_command == bus_readex))
        begin
            snoop_end_state   = I;
            snoop_invalidate  = 1;
            snoop_supply_data = 1;
        end
        else if (snoop_valid && dcache.snoop_tag_match && (dcache.snoop_read_state == M) && (snoop_command == bus_read))
        begin
            snoop_end_state   = S;
            snoop_invalidate  = 0;
            snoop_supply_data = 1;
        end
        else if (snoop_valid && dcache.snoop_tag_match && (dcache.snoop_read_state == S) && ((snoop_command == bus_readex) || (snoop_command == bus_upgrade)))
        begin
            snoop_end_state   = I;
            snoop_invalidate  = 1;
            snoop_supply_data = 0;
        end
    end
    
    /*************************************************************************/
    /* Snoop input port arbitration                                          */
    /*************************************************************************/

    assign dcache.snoop                    = snoop_enable;    
    assign dcache.snoop_write_state        = snoop_end_state;
    assign dcache.snoop_state_write_enable = snoop_invalidate;

    always_comb
        if (snoop_invalidate)
            dcache.snoop_address = snoop_address;
        else
            dcache.snoop_address = request.address;

    /*************************************************************************/
    /* Pending invalidation support                                          */
    /*************************************************************************/
    
    assign dcache.set_pending = snoop_invalidate;
   
endmodule // controller

// add the late eviction thing...
