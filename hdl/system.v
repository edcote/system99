import bus_package::*;
import ring_package::*;

module system
#(
    parameter RING_NODES = 2
)
(
    input clock, reset_n,
    // Flash memory
    output [22:0] flash_address,
    input  [7:0]  flash_data,
    output        flash_cs_n,
    output        flash_oe_n,
    output        flash_we_n,
    // LED
    output [7:0] led
);

    wire reset = !reset_n;

    wire slow_clock = clock;

    /*************************************************************************/
    /* Ring network                                                          */
    /*************************************************************************/

    ring_packet_t packet[RING_NODES];

    wire ring_enable;

    /*************************************************************************/
    /* Node 0                                                                */
    /*************************************************************************/
    
    ncrh_interface ncrh_0();
    rnsrt_interface rnsrt_0();

    fifo_interface #(.DATA_WIDTH(RING_PACKET_SIZE))                  inbound_fifo_0 ();
    fifo           #(.DATA_WIDTH(RING_PACKET_SIZE), .ADDR_WIDTH(3)) _inbound_fifo_0 (
        slow_clock, inbound_fifo_0.io
        );

    fifo_interface #(.DATA_WIDTH(RING_PACKET_SIZE))                  outbound_fifo_0 ();
    fifo           #(.DATA_WIDTH(RING_PACKET_SIZE), .ADDR_WIDTH(3)) _outbound_fifo_0 (
        slow_clock, outbound_fifo_0.io
    );

    ring_node #(.NODE_ID(0)) node_0 ( 
        slow_clock, reset, ring_enable, 
        packet[0], packet[1], 
        inbound_fifo_0.put_io, 
        outbound_fifo_0.get_io, 
        ncrh_0.ring, rnsrt_0.ring
    );
   
    smp_main #(.NODE_ID(0)) smp_0 (
        slow_clock, reset, 
        inbound_fifo_0.get_io, outbound_fifo_0.put_io, 
        ncrh_0.bus, rnsrt_0.bus,
        flash_address, flash_data, flash_cs_n, flash_oe_n, flash_we_n, 
        led
    );

    /*************************************************************************/
    /* Node 1                                                                */
    /*************************************************************************/

    ncrh_interface ncrh_1();
    rnsrt_interface rnsrt_1();

    fifo_interface #(.DATA_WIDTH(RING_PACKET_SIZE))                  inbound_fifo_1 ();
    fifo           #(.DATA_WIDTH(RING_PACKET_SIZE), .ADDR_WIDTH(3)) _inbound_fifo_1 (
        slow_clock, inbound_fifo_1.io
        );

    fifo_interface #(.DATA_WIDTH(RING_PACKET_SIZE))                  outbound_fifo_1 ();
    fifo           #(.DATA_WIDTH(RING_PACKET_SIZE), .ADDR_WIDTH(3)) _outbound_fifo_1 (
        slow_clock, outbound_fifo_1.io
    );
    
    ring_node #(.NODE_ID(1)) node_1 ( 
        slow_clock, reset, ring_enable, 
        packet[1], packet[0], 
        inbound_fifo_1.put_io, 
        outbound_fifo_1.get_io, 
        ncrh_1.ring, rnsrt_1.ring
    );
   
    smp #(.NODE_ID(1)) smp_1 (
        slow_clock, reset, 
        inbound_fifo_1.get_io, outbound_fifo_1.put_io, 
        ncrh_1.bus, rnsrt_1.bus
    );

    /*************************************************************************/
    /* Ring flow control                                                     */
    /*************************************************************************/

    assign ring_enable = !(inbound_fifo_0.full || inbound_fifo_1.full);

endmodule // system
