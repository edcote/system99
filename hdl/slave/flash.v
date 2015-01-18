import bus_package::*;

module flash
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
    output logic nack,
    // Pins
    output logic [22:0] flash_address,
    input        [7:0]  flash_data,
    output              flash_cs_n,
    output              flash_oe_n,
    output              flash_we_n
);

   /**************************************************************************/
   /* Input FIFO buffer                                                      */
   /**************************************************************************/

    wire [READ_REQUEST_WIDTH-1:0] fifo_data, fifo_data_out;
    logic                         fifo_read_enable, fifo_write_enable;
    wire                          fifo_empty, fifo_full;

    fifo_mf #(.DATA_WIDTH(READ_REQUEST_WIDTH), .ADDR_WIDTH(2)) fifo_inst (
        .clock (clock),
        .data (fifo_data),
        .rdreq (fifo_read_enable), .wrreq (fifo_write_enable),
        .empty (fifo_empty), .full (fifo_full),
        .q (fifo_data_out)
    );

    // FIFO write port
    
    assign fifo_data[READ_REQUEST_WIDTH-1:TAG_WIDTH+CMD_WIDTH] = request.address;
    assign fifo_data[TAG_WIDTH+CMD_WIDTH-1:TAG_WIDTH]          = request.command;
    assign fifo_data[TAG_WIDTH-1:0]                            = request.tag;

    // FIFO read port
    
    wire [31:0]          fifo_request_address = fifo_data_out[READ_REQUEST_WIDTH-1:TAG_WIDTH+CMD_WIDTH];
    wire [CMD_WIDTH-1:0] fifo_request_command = fifo_data_out[TAG_WIDTH+CMD_WIDTH-1:TAG_WIDTH];
    wire [TAG_WIDTH-1:0] fifo_request_tag     = fifo_data_out[TAG_WIDTH-1:0];

    /**************************************************************************/
    /* Flash ROM interface                                                    */
    /**************************************************************************/

    logic flash_read_enable;
    
    assign flash_cs_n    = !flash_read_enable;
    assign flash_oe_n    = !flash_read_enable;
    assign flash_we_n    = 0;
  
    logic [3:0] counter;
    logic       counter_enable, counter_reset;
    
    // fixme, why is a latch inferred !??
    always_ff @(posedge clock, posedge reset)
        if (reset)
            counter <= '0;
        else if (counter_reset)
            counter <= '0;
        else if (counter_enable)
            counter <= counter + 1;

    always_ff @(posedge clock, posedge reset)
        if (reset)
            response_data <= '0;
        else if (!flash_read_enable)
            response_data <= '0;
        else if (flash_read_enable)
            case (counter)
                8'd15 :   response_data[7:0]     <= flash_data;
                8'd14 :   response_data[15:8]    <= flash_data;
                8'd13 :   response_data[23:16]   <= flash_data;
                8'd12 :   response_data[31:24]   <= flash_data;
                8'd11 :   response_data[39:32]   <= flash_data;
                8'd10 :   response_data[47:40]   <= flash_data;
                8'd9  :   response_data[55:48]   <= flash_data;
                8'd8  :   response_data[63:56]   <= flash_data;
                8'd7  :   response_data[71:64]   <= flash_data;
                8'd6  :   response_data[79:72]   <= flash_data;
                8'd5  :   response_data[87:80]   <= flash_data;
                8'd4  :   response_data[95:88]   <= flash_data;
                8'd3  :   response_data[103:96]  <= flash_data;
                8'd2  :   response_data[111:104] <= flash_data;
                8'd1  :   response_data[119:112] <= flash_data;
                8'd0  :   response_data[127:120] <= flash_data;
                default : response_data <= '0;
            endcase

   /**************************************************************************/
   /* Service incoming request                                               */
   /**************************************************************************/

    always_comb
        if (enable && (request.command == bus_read) && fifo_full)
            nack = 1;
        else
            nack = 0;

    always_comb
        if (enable && (request.command == bus_read) && !fifo_full)
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
        { response_breq, response_bhold } = '0;
        { response_tag, response_oe } = '0;

        { flash_address, flash_read_enable } = '0;
        { counter_enable, counter_reset } = '0;

        next_state  = state;

        case (state)
            FIFO_READ_ST:
            begin
                counter_reset = 1;

                if (!fifo_empty)
                begin
                    fifo_read_enable = 1;
                    next_state = RESPONSE_BREQ_ST;
                end
            end

            RESPONSE_BREQ_ST:
            begin
                counter_enable = 1;

                flash_address     = { fifo_request_address[22:4], counter };
                flash_read_enable = 1;

                if (counter == 4'b1111)
                begin
                    counter_enable = 0;
                    response_breq = 1;

                    if (response_bgnt)
                        next_state = RESPONSE_OUT_ST;
                end
            end
            
            RESPONSE_OUT_ST:
            begin
                response_bhold = 1;
                
                counter_reset = 1;

                flash_read_enable = 1;

                response_tag  = fifo_request_tag;
                response_oe   = 1;

                next_state = FIFO_READ_ST;
            end
        endcase
    end

endmodule // flash