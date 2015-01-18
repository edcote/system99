import bus_package::*;

module leds
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
    output nack,
    // Pins
    output logic [7:0] led
);
    assign { response_data, response_tag, response_oe } = '0;
    assign { response_breq, response_bhold } = '0;

    assign nack = 0;

    /**************************************************************************/
    /* Service incoming request                                               */
    /**************************************************************************/

    always_ff @(posedge clock, posedge reset)
        if (reset)
            led <= '0;
        else if (enable && (request.command == bus_writeback))
            led <= response.data[7:0]; // fixme

endmodule // leds
