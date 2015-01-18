import bus_package::*;

module smp
#(
    parameter int NODE_ID = 1,
    parameter int NUM_MASTER = 2,
    parameter int NUM_SLAVE = 1
)
(
    input clock, reset,
    // Inbound and outbound FIFOs
    fifo_interface.get_io inbound_fifo,
    fifo_interface.put_io outbound_fifo,
    // Adaptive ring traffic filters
    ncrh_interface.bus ncrh,
    rnsrt_interface.bus rnsrt
);

    /*************************************************************************/
    /* Request bus                                                           */
    /*************************************************************************/

    request_bus_interface request();

    wire [31:0]          request_address[NUM_MASTER-1:0];
    wire [CMD_WIDTH-1:0] request_command[NUM_MASTER-1:0];
    wire [TAG_WIDTH-1:0] request_tag[NUM_MASTER-1:0];
    wire                 request_oe[NUM_MASTER-1:0];

    wire [31:0] ncrh_replaced_address[NUM_MASTER-2:0];
    wire        ncrh_increment[NUM_MASTER-2:0];
    wire        ncrh_decrement[NUM_MASTER-2:0];

    always_comb
    begin      
        { request.address, request.command, request.tag, request.valid } = '0;
        { request.replaced_address, request.increment, request.decrement } = '0;

        for (integer i=0; i<NUM_MASTER; i++)        
            if (request_oe[i])
            begin
                request.address = request_address[i];
                request.command = request_command[i];
                request.tag     = request_tag[i];
                request.valid   = 1;
            end

        for (integer i=0; i<NUM_MASTER-1; i++)
            if (request_oe[i])
            begin
                request.replaced_address = ncrh_replaced_address[i];
                request.increment        = ncrh_increment[i];
                request.decrement        = ncrh_decrement[i];
            end            
    end

    /*************************************************************************/
    /* Request bus arbiter                                                   */
    /*************************************************************************/

    logic [NUM_MASTER-1:0] request_breq, request_bhold;
    wire  [NUM_MASTER-1:0] request_bgnt;

    arbiter #(.N(NUM_MASTER)) request_arbiter (
        clock, reset, request_breq, |request_bhold, request_bgnt
    );

    /*************************************************************************/
    /* Response bus                                                          */
    /*************************************************************************/
    
    response_bus_interface response();
    
    wire [DATA_WIDTH-1:0] response_data[NUM_MASTER+NUM_SLAVE-1:0];
    wire [TAG_WIDTH-1:0]  response_tag[NUM_MASTER+NUM_SLAVE-1:0];
    wire                  response_oe[NUM_MASTER+NUM_SLAVE-1:0];

    always_comb
    begin      
        { response.tag, response.data } = '0;

        for (integer i=0; i<NUM_MASTER+NUM_SLAVE; i++)        
            if (response_oe[i])
            begin
                response.data = response_data[i];
                response.tag  = response_tag[i];
            end
    end

    /*************************************************************************/
    /* Response bus arbiter                                                  */
    /*************************************************************************/
    
    logic [NUM_MASTER+NUM_SLAVE-1:0] response_breq, response_bhold;
    wire  [NUM_MASTER+NUM_SLAVE-1:0] response_bgnt;

    arbiter #(.N(NUM_MASTER+NUM_SLAVE)) response_arbiter ( 
        clock, reset, response_breq, |response_bhold, response_bgnt
    );
   
    /*************************************************************************/
    /* Wired-OR bus lines                                                    */
    /*************************************************************************/

    wire [NUM_MASTER-1:0] inhibit;
    assign request.inhibit = |inhibit;

    wire [NUM_MASTER+NUM_SLAVE-1:0] nack;
    assign request.nack = |nack; 

    /*************************************************************************/
    /* Address decoder                                                       */
    /*************************************************************************/

    wire [NUM_SLAVE-1:0] enable;

    address_decoder #(.NODE_ID(NODE_ID), .NUM_SLAVE(NUM_SLAVE)) decoder (
        request.address_decoder, enable
    );

    /*************************************************************************/
    /* Processor 0                                                           */
    /*************************************************************************/
    
    instruction_cache_interface icache_0_if();
    data_cache_interface dcache_0_if();

    // Five-stage, single issue pipeline
    pipeline #(.ID(0), .NODE_ID(NODE_ID)) cpu_0 (
        clock, reset, 
        response.pipeline,
        icache_0_if.pipeline, dcache_0_if.pipeline
    );

    // Instruction and data caches
    instruction_cache icache_0 (clock, icache_0_if.cache);
    data_cache dcache_0 (clock, dcache_0_if.cache);

    // Level-1 cache controller
   controller #(.ID(0)) controller_0 (
        clock, reset,
        // Instruction and data caches
        icache_0_if.controller, dcache_0_if.controller,
        // Request bus
        request.master, 
        request_address[0], request_command[0], request_tag[0], request_oe[0],
        request_breq[0], request_bhold[0], request_bgnt[0],
        // Response bus
        response.master, 
        response_data[0], response_tag[0], response_oe[0],
        response_breq[0], response_bhold[0], response_bgnt[0],
        // NCRH
        ncrh_replaced_address[0], ncrh_increment[0], ncrh_decrement[0],
        // Wired-OR
        inhibit[0], nack[0]
    );

    /*************************************************************************/
    /* Ring Interface                                                        */
    /*************************************************************************/

    ring_interface #(.ID(1), .NODE_ID(NODE_ID)) ring_interface_0 (
        clock, reset,
        // Request bus
        request.ring_interface,
        request_address[1], request_command[1], request_tag[1], request_oe[1],
        request_breq[1], request_bhold[1], request_bgnt[1],
        // Response bus
        response.master,
        response_data[1], response_tag[1], response_oe[1],
        response_breq[1], response_bhold[1], response_bgnt[1],
        // Wired-OR
        inhibit[1], nack[1],
        // Ring
        inbound_fifo, outbound_fifo,
        ncrh, rnsrt
    );

    /*************************************************************************/
    /* Bus slaves                                                            */
    /*************************************************************************/

    // RAM (64 kB)
    ram #(.ADDR_WIDTH(12)) ram_inst (
        clock, reset, enable[0], 
        // Request bus
        request.slave,
        // Response bus
        response.slave,
        response_data[NUM_MASTER+0], response_tag[NUM_MASTER+0], response_oe[NUM_MASTER+0],
        response_breq[NUM_MASTER+0], response_bhold[NUM_MASTER+0], response_bgnt[NUM_MASTER+0],
        // Wired-OR
        nack[NUM_MASTER+0]
    );

endmodule // smp

module address_decoder
#(
    parameter int NODE_ID   = 0,
    parameter int NUM_SLAVE = 1

)
(
    request_bus_interface.address_decoder request,
    output logic [NUM_SLAVE-1:0] enable
);

    always_comb
        if (request.valid && (request.address[31:28] != NODE_ID))
            request.external = 1;
        else
            request.external = 0;
    
    always_comb
        if (!request.address[27] && request.valid)
            request.coherent = 1;
        else
            request.coherent = 0;

    always_comb
    begin
        // Default
        enable = '0;

        if (request.valid && !request.external)
            case (request.address[27:24])
                // RAM (0x00000000 <-> 0x00FFFFFF)
                4'h0:    enable = 1'b1;
                default: enable = '0;
            endcase
    end

endmodule // address_decoder
