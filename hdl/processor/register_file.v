module register_file
(
    input               clock, reset, enable, 
    input        [4:0]  rs, rt, 
    output logic [31:0] rs_data, rt_data,
    input        [4:0]  writeback_address,
    input        [31:0] writeback_data,
    input               writeback_enable
);

    /*************************************************************************/
    /* Hardwire $R0                                                          */
    /*************************************************************************/

    logic writeback_enable_tmp;
    
    always_comb
        if (writeback_address == 5'b00000)
            writeback_enable_tmp = 0;
        else
            writeback_enable_tmp = writeback_enable;

    /*************************************************************************/
    /* Read port 1 (rs)                                                      */
    /*************************************************************************/
    
    wire [31:0] rs_data_tmp;
    
    single_port_ram_mf #(.DATA_WIDTH(32), .ADDR_WIDTH(5), .RAM_BLOCK_TYPE("M4K"))
        rs_port (
            .clock (clock),
            
            .rdaddress (rs),
            .rden (enable),
            .q (rs_data_tmp),

            .wraddress (writeback_address),
            .wren (writeback_enable_tmp),
            .data (writeback_data)
        );

    /*************************************************************************/
    /* Read port 2 (rt)                                                      */
    /*************************************************************************/

    wire [31:0] rt_data_tmp;
    
    single_port_ram_mf #(.DATA_WIDTH(32), .ADDR_WIDTH(5), .RAM_BLOCK_TYPE("M4K"))
        rt_port (
            .clock (clock),
            
            .rdaddress (rt),
            .rden (enable),
            .q (rt_data_tmp),

            .wraddress (writeback_address),
            .wren (writeback_enable_tmp),
            .data (writeback_data)
        );
        
    /*************************************************************************/
    /* Internal forwarding                                                   */
    /*************************************************************************/

    logic [31:0] writeback_data_tmp;
    logic        forward_rs, forward_rt;
    
    always_ff @(posedge clock, posedge reset)
        if (reset)
        begin
            forward_rs          <= 0;
            forward_rt          <= 0;
            writeback_data_tmp  <= '0;
        end
        else
        begin
            writeback_data_tmp <= writeback_data;

            if ((rs == writeback_address) && writeback_enable)
                forward_rs <= 1;
            else
                forward_rs <= 0;

            if ((rt == writeback_address) && writeback_enable)
                forward_rt <= 1;
             else
                forward_rt <= 0;
        end

    always_comb
        if (forward_rs)
            rs_data = writeback_data_tmp;
        else
            rs_data = rs_data_tmp;

    always_comb
        if (forward_rt)
            rt_data = writeback_data_tmp;
        else
            rt_data = rt_data_tmp;

endmodule // register_file