interface fifo_interface 
#(
    parameter DATA_WIDTH = 4
);

    logic [DATA_WIDTH-1:0] data, q;
    logic                  wrreq, rdreq;
    logic                  full, empty;

    modport put_io
    (
        input  full,
        output data, wrreq
    );

    modport get_io
    (
        input  empty, q,
        output rdreq
    );
   
    modport io
    (
        // put
        output full, 
        input  data, wrreq,
        // get
        output empty, q,
        input  rdreq
    );

endinterface // fifo_interface

module fifo
#(
    parameter int DATA_WIDTH = 32,
    parameter int ADDR_WIDTH = 16
)        
(
    input                   clock,
    fifo_interface.io       fifo
);

    scfifo scfifo_component (
        .rdreq (fifo.rdreq),
        .clock (clock),
        .wrreq (fifo.wrreq),
        .data (fifo.data),
        .empty (fifo.empty),
        .q (fifo.q),
        .full (fifo.full),
        .aclr (),
        .almost_empty (),
        .almost_full (),
        .sclr (),
        .usedw ()
    );
    
    defparam
        scfifo_component.add_ram_output_register = "OFF",
        scfifo_component.intended_device_family = "Stratix",
        scfifo_component.lpm_numwords = 1 << ADDR_WIDTH,
        scfifo_component.lpm_showahead = "OFF",
        scfifo_component.lpm_type = "scfifo",
        scfifo_component.lpm_width = DATA_WIDTH,
        scfifo_component.lpm_widthu = ADDR_WIDTH,
        scfifo_component.overflow_checking = "ON",
        scfifo_component.underflow_checking = "ON",
        scfifo_component.use_eab = "ON";

endmodule // fifo
