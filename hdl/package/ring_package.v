package ring_package;
    parameter int RING_PACKET_SIZE = 178;
   
    typedef struct packed {
        bit         valid;
        bit         broadcast;
        bit         non_shared;
        bit [2:0]   command;
        bit [3:0]   tag;
        bit [3:0]   src, dest;
        bit [31:0]  address;
        bit [127:0] data;
    } ring_packet_t;

    const bit [2:0] ring_read      = 3'b000;
    const bit [2:0] ring_readex    = 3'b001;
    const bit [2:0] ring_upgrade   = 3'b010;
    const bit [2:0] ring_writeback = 3'b011;
    const bit [2:0] ring_response  = 3'b100;

endpackage // ring_package
