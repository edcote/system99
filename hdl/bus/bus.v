import bus_package::*;

interface request_bus_interface;
    logic [31:0]          address;
    logic [CMD_WIDTH-1:0] command;
    logic [TAG_WIDTH-1:0] tag;
    logic                 valid;
    
    logic [31:0] replaced_address;
    logic        increment, decrement;

    wor inhibit;
    wor nack;

    logic external, coherent;

    modport master
    (
        input address, command, tag,
        input nack, external, coherent
    );
        
    modport slave
    (
        input address, command, tag,
        input inhibit
    );

    modport address_decoder
    (
        input  address, valid,
        output external, coherent
    );

    modport ring_interface
    (
        input address, command, tag,
        input nack, external, coherent,
        input replaced_address, increment, decrement
    );

endinterface // request_bus_interface

interface response_bus_interface;
    logic [TAG_WIDTH-1:0]  tag;
    logic [DATA_WIDTH-1:0] data;
    
    modport pipeline
    (
        input data
    );

    modport master
    (
        input tag, data
    );

    modport slave
    (
        input tag, data
    );

endinterface // response_bus_interface
