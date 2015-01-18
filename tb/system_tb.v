module system_tb
#(
    parameter int CYCLE = 10
);

    /*************************************************************************/
    /* Clock and reset generator                                             */
    /*************************************************************************/

    logic clock_tmp = 0;
    always #(CYCLE/2) clock_tmp = ~clock_tmp;
    
    wire clock = clock_tmp;

    logic reset_n;

    initial
    begin
                   reset_n = 0;
        #(CYCLE*10) reset_n = 1;
    end

    /*************************************************************************/
    /* Flash memory model                                                    */
    /*************************************************************************/

    wire  [22:0] flash_address;
    logic [7:0]  flash_data;
    wire         flash_cs_n, flash_oe_n, flash_we_n;

    // 2 MB
    logic [7:0] mem [(1 << 22)-1:0];

    integer file, i;

    initial
    begin
        file = $fopen("flash.bin", "rb");
        if (!file)
        begin
            $display("$Unable to open flash.bin!\n");
            $finish;
        end
        i = $fread(mem, file);
        $fclose(file);
  end

    always_comb
        if (!flash_cs_n && !flash_oe_n)
            flash_data = mem[flash_address];
        else
            flash_data = 'z;

    /*************************************************************************/
    /* LED                                                                   */
    /*************************************************************************/
    
    wire [7:0] led;

    /*************************************************************************/
    /* Device under test                                                     */
    /*************************************************************************/

    system dut(clock, reset_n, flash_address, flash_data, flash_cs_n, flash_oe_n, flash_we_n, led);

endmodule // system_tb
