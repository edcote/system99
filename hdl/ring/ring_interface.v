import bus_package::*;
import ring_package::*;

module ring_interface
#(
    parameter int NODE_ID = 0,
    parameter int ID = 0,
    parameter int REGION_WIDTH = 2, 
    parameter int COUNT_WIDTH = 32-REGION_WIDTH // fixme
)
(
    input clock, reset,
    // Request bus
    request_bus_interface.ring_interface request,
    output logic [31:0]                  request_address,
    output logic [CMD_WIDTH-1:0]         request_command,
    output logic [TAG_WIDTH-1:0]         request_tag,
    output logic                         request_oe,
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
    // Wired-OR
    output logic inhibit, nack,
    // Inbound and outbound FIFOs
    fifo_interface.get_io inbound_fifo,
    fifo_interface.put_io outbound_fifo,
    // Adaptive ring traffic filters
    ncrh_interface.bus ncrh,
    rnsrt_interface.bus rnsrt
);

    assign inhibit = 0;

    /*************************************************************************/
    /* NCRH input address registers                                          */
    /*************************************************************************/

    logic [31:0] request_address_reg;
    logic        increment_reg;

    always_ff @(posedge clock, posedge reset)
        if (reset)
        begin
            request_address_reg <= '0;
            increment_reg       <= 0;
        end
        else if (request.external && request.increment)
        begin
            request_address_reg <= request.address;
            increment_reg       <= 1;
        end
        else
        begin
            request_address_reg <= '0;
            increment_reg       <= 0;
        end
        
    logic [31:0] replaced_address_reg;
    logic        decrement_reg;

    always_ff @(posedge clock, posedge reset)
        if (reset)
        begin
            replaced_address_reg <= '0;
            decrement_reg        <= 0;
        end
        else if (request.decrement && (request.replaced_address[31:28] != NODE_ID)) // fix me?
        begin
            replaced_address_reg <= request.replaced_address;
            decrement_reg        <= 1;
        end
        else
        begin
            replaced_address_reg <= '0;
            decrement_reg        <= 0;
        end

    logic ncrh_probe_reg;

    always_ff @(posedge clock, posedge reset)
        if (reset)
            ncrh_probe_reg <= 0;
        else if (!request.decrement)
            ncrh_probe_reg <= ncrh.probe;
        else
            ncrh_probe_reg <= 0;

    /*************************************************************************/
    /* NCRH RAM                                                              */
    /*************************************************************************/

    logic [REGION_WIDTH-1:0] ncrh_region_a, ncrh_region_b;
    wire  [COUNT_WIDTH-1:0]  count_a, count_b;

    dual_port_ram_mf #(.DATA_WIDTH(COUNT_WIDTH), .ADDR_WIDTH(REGION_WIDTH), .RAM_BLOCK_TYPE("M4K")) ncrh_ram (
        .clock (clock),

        .address_a (ncrh_region_a),
        .data_a (count_a + 1'b1),
        .wren_a (increment_reg),
        .q_a (count_a),

        .address_b (ncrh_region_b),
        .data_b (count_b - 1'b1),
        .wren_b (decrement_reg),
        .q_b (count_b)
    );

    /*************************************************************************/
    /* NCRH input address mapping (fixme)                                    */
    /*************************************************************************/

    // Port A (increment)
    always_comb
        if (increment_reg)
            ncrh_region_a = request_address_reg[31:32-REGION_WIDTH];
        else
            ncrh_region_a = request.address[31:32-REGION_WIDTH];

    // Port B (decrement or probe)
    always_comb
        if (decrement_reg)
            ncrh_region_b = replaced_address_reg[31:32-REGION_WIDTH];
        else if (request.decrement)
            ncrh_region_b = request.address[31:32-REGION_WIDTH];
        else
            ncrh_region_b = ncrh.address[31:32-REGION_WIDTH];

    /*************************************************************************/
    /* NCRH ring filter                                                      */
    /*************************************************************************/

    always_comb
        if (ncrh_probe_reg)
            ncrh.non_shared = ~{|count_b};
        else
            ncrh.non_shared = 0;

    /*************************************************************************/
    /* RNSRT                                                                 */
    /*************************************************************************/

    logic [31:0] rnsrt_address_reg;
    logic        rnsrt_invalidate_reg;

    always_ff @(posedge clock, posedge reset)
        if (reset)
        begin
            rnsrt_address_reg    <= '0;
            rnsrt_invalidate_reg <= 0;
        end
        else if (rnsrt.invalidate)
        begin
            rnsrt_address_reg    <= rnsrt.address;
            rnsrt_invalidate_reg <= 1;
        end
        else
        begin
            rnsrt_address_reg    <= '0;
            rnsrt_invalidate_reg <= 0;
        end

    always_comb
        if (rnsrt_invalidate_reg && rnsrt_valid)
        begin
            rnsrt_write_enable  = 1;
            rnsrt_write_address = rnsrt_address_reg;
            rnsrt_write_data    = 0; // invalid
        end



    
    // PORT A
    // PROBE
    
    

    /*************************************************************************/
    /* Inbound and outbound ring packets, outbound FIFO arbitration          */
    /*************************************************************************/
    
    ring_packet_t request_packet;
    ring_packet_t response_packet;

    logic outbound_fifo_request_we, outbound_fifo_response_we;
    
    always_comb
        if (outbound_fifo_request_we)
            outbound_fifo.data = request_packet;
        else
            outbound_fifo.data = response_packet;
            
    assign outbound_fifo.wrreq = outbound_fifo_request_we || outbound_fifo_response_we;

    ring_packet_t inbound_packet;
    assign inbound_packet = inbound_fifo.q;

    /*************************************************************************/
    /* Ring response register                                                */
    /*************************************************************************/

    logic [127:0] bus_data;
    logic         bus_data_we;

    always_ff @(posedge clock, posedge reset)
        if (reset)
            bus_data <= '0;
        else if (bus_data_we)
            bus_data <= response.data;

    /*************************************************************************/
    /* Service inbound requests (from ring)                                  */
    /*************************************************************************/

    enum bit [2:0] { INBOUND_FIFO_READ_ST, RING_REQUEST_ST, RING_REQUEST_DELAY_ST, WAIT_RESPONSE_DELAY_ST, WAIT_RESPONSE_ST, OUTBOUND_FIFO_WRITE_ST } next_state, state;

    always_ff @(posedge clock, posedge reset)
        if (reset)
            state <= INBOUND_FIFO_READ_ST;
        else
            state <= next_state;

    always_comb
    begin
        // Default
        { request_address, request_command, request_tag, request_oe } = '0;
        { request_breq, request_bhold } = '0;    
    
        { response_tag, response_data, response_oe } = '0;
        { response_breq, response_bhold } = '0;
        
        inbound_fifo.rdreq = 0;
        bus_data_we = 0;        
        outbound_fifo_response_we = 0;
        
        response_packet = '0;
        
        next_state = state;

        case (state)
            INBOUND_FIFO_READ_ST:
                if (!inbound_fifo.empty)
                begin
                    inbound_fifo.rdreq = 1;
                    next_state = RING_REQUEST_ST;
                end
            
            RING_REQUEST_ST:
            begin
                request_breq  = (inbound_packet.command == ring_read) || (inbound_packet.command == ring_upgrade);

                if (request_bgnt && request_breq)
                begin
                    request_bhold = 1;
                    
                    request_address = inbound_packet.address;
                    request_command = inbound_packet.command[1:0];
                    request_tag     = 1 << ID;
                    request_oe      = 1;

                    if (inbound_packet.command == ring_read)
                        next_state = WAIT_RESPONSE_DELAY_ST;
                    else if (inbound_packet.command == ring_upgrade)
                        next_state = RING_REQUEST_DELAY_ST;
                end
                
                response_breq = (inbound_packet.command == ring_response);

                if (response_bgnt && response_breq) 
                begin
                    response_tag  = inbound_packet.tag;
                    response_data = inbound_packet.data;
                    response_oe   = 1;

                    next_state = INBOUND_FIFO_READ_ST;
                end
            end
            
            RING_REQUEST_DELAY_ST:
            begin
                request_bhold = 1;
                next_state = INBOUND_FIFO_READ_ST;
            end
            
            WAIT_RESPONSE_DELAY_ST:
            begin
                request_bhold = 1;
                next_state = WAIT_RESPONSE_ST;
            end
            
            WAIT_RESPONSE_ST:
                if (response.tag[ID])
                begin
                    // Latch incoming response
                    bus_data_we = 1;
                    next_state = OUTBOUND_FIFO_WRITE_ST;
                end

            OUTBOUND_FIFO_WRITE_ST:
            begin
                // Build response packet
                response_packet.valid     = 1;
                response_packet.address   = inbound_packet.address;
                response_packet.command   = ring_response;
                response_packet.data      = bus_data;
                response_packet.tag       = inbound_packet.tag;
                response_packet.src       = NODE_ID;
                response_packet.dest      = inbound_packet.src;
                response_packet.broadcast = 0;

                if (!outbound_fifo.full && !outbound_fifo_request_we)
                begin
                    outbound_fifo_response_we = 1;
                    next_state = INBOUND_FIFO_READ_ST;
                end
         end
        endcase
    end

    /*************************************************************************/
    /* Service outbound requests (to ring)                                   */
    /*************************************************************************/
    
    always_comb
    begin
        // Default
        nack = 0;
        request_packet = '0;
        outbound_fifo_request_we = 0;
        
        if (request.external && (request.command == bus_read))
        begin
            if (!outbound_fifo.full)
            begin
                // Build response packet
                request_packet.valid      = 1;
                request_packet.broadcast  = 0;
                request_packet.address    = request.address;
                request_packet.command    = ring_read;
                request_packet.data       = '0;
                request_packet.tag        = request.tag;
                request_packet.src        = NODE_ID;
                request_packet.dest       = request.address[31:28];
                request_packet.non_shared = 0;
                
                // Send to outbound FIFO
                outbound_fifo_request_we = 1;
            end
            else
                nack = 1;
        end
        else if (!request.external && ((request.command == bus_readex) || (request.command == bus_upgrade)))
        begin
            if (!outbound_fifo.full)
            begin
                // Build response packet
                request_packet.valid      = 1;
                request_packet.broadcast  = 1;
                request_packet.address    = request.address;
                request_packet.command    = ring_upgrade;
                request_packet.data       = '0;
                request_packet.tag        = request.tag;
                request_packet.src        = NODE_ID;
                request_packet.dest       = NODE_ID;
                request_packet.non_shared = 1;
                
                // Send to outbound FIFO
                outbound_fifo_request_we = 1;
            end
            else
                nack = 1;
        end
    end

endmodule // ring_interface
