package bus_package;
    const bit [1:0] bus_read      = 2'b00;
    const bit [1:0] bus_readex    = 2'b01;
    const bit [1:0] bus_upgrade   = 2'b10;
    const bit [1:0] bus_writeback = 2'b11;

    parameter int DATA_WIDTH         = 128;
    parameter int CMD_WIDTH          = 2;
    parameter int TAG_WIDTH          = 4;
//    parameter int READ_REQUEST_WIDTH = 32+CMD_WIDTH+TAG_WIDTH;
//    parameter int REQUEST_WIDTH      = 32+CMD_WIDTH+TAG_WIDTH+DATA_WIDTH;
    parameter int READ_REQUEST_WIDTH = 38;
    parameter int REQUEST_WIDTH      = 166;
endpackage // bus_package
