import bus_package::*;

module ram
#(
    parameter int ADDR_WIDTH = 12
)
(
    input clock, reset, enable,
    // Request bus    
    request_bus_interface.slave request,
    // Response bus
    response_bus_interface.slave response,
    output logic [127:0]          response_data,
    output logic [TAG_WIDTH-1:0]  response_tag,
    output logic                  response_oe,
    // Response bus arbiter
    output logic response_breq, response_bhold, 
    input        response_bgnt,
    // Wired-OR
    output logic nack
);

   /**************************************************************************/
   /* Input FIFO buffer                                                      */
   /**************************************************************************/

    logic [REQUEST_WIDTH-1:0] fifo_data, fifo_data_reg, fifo_data_out;
    logic                     fifo_read_enable, fifo_write_enable, fifo_write_enable_reg;
    wire                      fifo_empty, fifo_full;

    fifo_mf #(.DATA_WIDTH(REQUEST_WIDTH), .ADDR_WIDTH(2)) fifo_inst (
        .clock (clock),
        .data (fifo_data_reg),
        .rdreq (fifo_read_enable), .wrreq (fifo_write_enable),
        .empty (fifo_empty), .full (fifo_full),
        .q (fifo_data_out)
    );

    // FIFO write port

    assign fifo_data[REQUEST_WIDTH-1:TAG_WIDTH+CMD_WIDTH+32]       = response.data;
    assign fifo_data[TAG_WIDTH+CMD_WIDTH+32-1:TAG_WIDTH+CMD_WIDTH] = request.address;
    assign fifo_data[TAG_WIDTH+CMD_WIDTH-1:TAG_WIDTH]              = request.command;
    assign fifo_data[TAG_WIDTH-1:0]                                = request.tag;

    // FIFO read port

    wire [DATA_WIDTH-1:0] fifo_request_data    = fifo_data_out[REQUEST_WIDTH-1:TAG_WIDTH+CMD_WIDTH+32];
    wire [31:0]           fifo_request_address = fifo_data_out[TAG_WIDTH+CMD_WIDTH+32-1:TAG_WIDTH+CMD_WIDTH];
    wire [CMD_WIDTH-1:0]  fifo_request_command = fifo_data_out[TAG_WIDTH+CMD_WIDTH-1:TAG_WIDTH];
    wire [TAG_WIDTH-1:0]  fifo_request_tag     = fifo_data_out[TAG_WIDTH-1:0];
    
   /**************************************************************************/
   /* On-chip RAM                                                            */
   /**************************************************************************/

    wire [DATA_WIDTH-1:0] ram_data;
    logic                 ram_read_enable, ram_write_enable;

    single_port_ram_mf #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) ram (
        .clock (clock),
        .rdaddress ({fifo_request_address[ADDR_WIDTH-1:4], 4'b0000}),
        .wraddress ({fifo_request_address[ADDR_WIDTH-1:4], 4'b0000}),
        .data(fifo_request_data),
        .rden(ram_read_enable), .wren(ram_write_enable),
        .q (ram_data)
    );


   /**************************************************************************/
   /* Service and pipeline incoming requests                                 */
   /**************************************************************************/

    // Stage 1
    always_comb
        if (enable && fifo_full)
            nack = 1;
        else
            nack = 0;

    // Pipeline register
    always_ff @(posedge clock, posedge reset)
        if (reset)
            { fifo_data_reg, fifo_write_enable_reg } <= '0;
        else if (enable && !fifo_full)
        begin
            fifo_data_reg         <= fifo_data;
            fifo_write_enable_reg <= 1;
        end
        else
            { fifo_data_reg, fifo_write_enable_reg } <= '0;

    // Stage 2 (request.inhibit is available only on the following cycle)
    always_comb
        if (fifo_write_enable_reg && !request.inhibit)
            fifo_write_enable = 1;
        else
            fifo_write_enable = 0;

   /**************************************************************************/
   /* Process buffered requests                                              */
   /**************************************************************************/

    enum bit [1:0] { FIFO_READ_ST, RESPONSE_BREQ_ST, RESPONSE_OUT_ST } next_state, state;

   always_ff @(posedge clock, posedge reset)
     if (reset)
       state <= FIFO_READ_ST;
     else
       state <= next_state;

    always_comb
    begin
        // Default
        fifo_read_enable = 0;
        { ram_read_enable, ram_write_enable } = '0;
        { response_breq, response_bhold } = '0;
        { response_data, response_tag, response_oe } = '0;

        next_state  = state;

        case (state)
            FIFO_READ_ST:
                if (!fifo_empty)
                begin
                    fifo_read_enable = 1;
                    next_state = RESPONSE_BREQ_ST;
                end

            RESPONSE_BREQ_ST:
                if ((fifo_request_command == bus_read) || (fifo_request_command == bus_readex))
                begin                    
                    response_breq = 1;
                    ram_read_enable = 1; // fixme!??

                    if (response_bgnt)
                        next_state = RESPONSE_OUT_ST;
                end
                else if (fifo_request_command == bus_writeback)
                begin
                    ram_write_enable = 1;
                    next_state = FIFO_READ_ST;
                end
                else
                    next_state = FIFO_READ_ST;
            
            RESPONSE_OUT_ST:
            begin
                response_bhold = 1;

                response_data = ram_data;
                response_tag  = fifo_request_tag;
                response_oe   = 1;

                next_state = FIFO_READ_ST;
            end
        endcase
    end

endmodule // ram
