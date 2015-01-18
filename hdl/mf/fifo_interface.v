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
