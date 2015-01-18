module fifo_mf
#(
    parameter int DATA_WIDTH = 32,
    parameter int ADDR_WIDTH = 16
)        
(
    input                   clock,
    input  [DATA_WIDTH-1:0] data,
    input                   rdreq, wrreq,
    output                  empty, full,
    output [DATA_WIDTH-1:0] q
);

    scfifo scfifo_component (
        .rdreq (rdreq),
        .clock (clock),
        .wrreq (wrreq),
        .data (data),
        .empty (empty),
        .q (q),
        .full (full),
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

endmodule // fifo_mf
