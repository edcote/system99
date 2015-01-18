import ring_package::*;

module ring_node 
#(
   parameter int NODE_ID = 0
)
(
    input  clock, reset, enable,
    // Incoming and outgoing packets
    input  ring_packet_t packet_in,
    output ring_packet_t packet_out,
    // Ring FIFOs
    fifo_interface.put_io inbound_fifo,
    fifo_interface.get_io outbound_fifo,
    // Adaptive ring traffic filters
    ncrh_interface.ring ncrh,
    rnsrt_interface.ring rnsrt
);

    /*************************************************************************/
    /* Control signals                                                       */
    /*************************************************************************/

    wire dest_node_match = packet_in.valid && (packet_in.dest == NODE_ID);

    wire src_node_match = packet_in.valid && (packet_in.src == NODE_ID);

    wire pass_it_on = packet_in.valid && 
                     ( (!packet_in.broadcast && !dest_node_match) || ( packet_in.broadcast && !src_node_match) );

    wire accept_it  = packet_in.valid && 
                     ( (!packet_in.broadcast &&  dest_node_match) || ( packet_in.broadcast && !src_node_match) );
   
    wire remove_it  = packet_in.valid && 
                     ( ( !packet_in.broadcast && dest_node_match) || (packet_in.broadcast && src_node_match) );

    wire put_packet_on_ring = !packet_in.valid && !outbound_fifo.empty && enable; // if incoming packet is empty

    /**************************************************************************/
    /* Ring Filter                                                            */
    /**************************************************************************/

    assign ncrh.probe   = packet_in.valid && (packet_in.command == ring_upgrade) && !remove_it;
    assign ncrh.address = packet_in.address;

    /*************************************************************************/
    /* Inbound and outbound FIFO control                                     */
    /*************************************************************************/

    assign outbound_fifo.rdreq = put_packet_on_ring;

    /*************************************************************************/
    /* Ring data register                                                    */
    /*************************************************************************/
    
    ring_packet_t packet_out_tmp;

    always_ff @(posedge clock, posedge reset)
        if (reset)
            packet_out_tmp <= '0;
        else if (enable)
            packet_out_tmp <= packet_in;

    /*************************************************************************/
    /* Ring control register signals                                         */
    /*************************************************************************/

    logic dest_node_match_reg;
    logic src_node_match_reg;
    logic pass_it_on_reg;
    logic accept_it_reg;   
    logic remove_it_reg;
    logic put_packet_on_ring_reg;
    logic ncrh_probe_reg;
    
    always_ff @(posedge clock, posedge reset)
        if (reset)
        begin
            dest_node_match_reg    = '0;
            src_node_match_reg     = '0;
            pass_it_on_reg         = '0;
            accept_it_reg          = '0;
            remove_it_reg          = '0;
            put_packet_on_ring_reg = '0;
            ncrh_probe_reg         = 0;
        end
        else if (enable)
        begin
            dest_node_match_reg    = dest_node_match;
            src_node_match_reg     = src_node_match;
            pass_it_on_reg         = pass_it_on;
            accept_it_reg          = accept_it;
            remove_it_reg          = remove_it;
            put_packet_on_ring_reg = put_packet_on_ring;
            ncrh_probe_reg         = ncrh.probe;
        end

    /*************************************************************************/
    /* Packet out multiplexor                                                */
    /*************************************************************************/
    
    // this ain't pretty - fixme

    always_comb
        if (pass_it_on_reg && !put_packet_on_ring_reg)
        begin
            if (ncrh_probe_reg)
                packet_out.non_shared = packet_out_tmp.non_shared && ncrh.non_shared;
            packet_out = packet_out_tmp;
        end
        else if (!pass_it_on_reg && put_packet_on_ring_reg)
            packet_out = outbound_fifo.q;
        else if (remove_it_reg && !put_packet_on_ring_reg)
            packet_out = '0;
        else
            packet_out = 'x;

    // fixme
//    always_comb
//        if (pass_it_on_reg && !put_packet_on_ring_reg)
//        begin            
//            packet_out = packet_out_tmp;            
//            // "Annotate" packet with region-level sharing information
//            if (packet_out_tmp.valid && (packet_out_tmp.command == ring_upgrade) && pass_it_on_reg)
//                packet_out.non_shared = packet_out_tmp.non_shared && ring_filter;
//        end
//        else if (!pass_it_on_reg && put_packet_on_ring_reg)
//            packet_out = outbound_fifo.q;
//        else
//            packet_out = packet_out_tmp;            
            
    assign inbound_fifo.data = packet_out_tmp;
    assign inbound_fifo.wrreq = accept_it_reg && !inbound_fifo.full && !ncrh.non_shared;
    
    /*************************************************************************/
    /* RNSRT                                                                 */
    /*************************************************************************/

    assign rnsrt.insert     = remove_it && packet_in.non_shared && (packet_in.command == ring_upgrade);
    assign rnsrt.invalidate = accept_it && !remove_it && (packet_in.command == ring_read);    
    assign rnsrt.address    = packet_in.address;
    
endmodule // ring_node
   