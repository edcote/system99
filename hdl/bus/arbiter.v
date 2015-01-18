// Implementation based on paper: "Arbiters: Design Ideas and Coding Styles" (mask_expand) by Matt Weber
module arbiter 
#(
   parameter int N = 4
)
(
    input                clock, reset,
    input        [N-1:0] request,
    input                hold,
    output logic [N-1:0] grant
);
   
    logic [N-1:0] round_robin_ptr;

    // Priority arbiter for un-masked requests
    wire [N-1:0] unmask_temp; // Un-masked higher priority requests
    wire [N-1:0] unmask_grant;

    assign unmask_temp[N-1:1] = unmask_temp[N-2:0] | request[N-2:0];
    assign unmask_temp[0] = 0;
    assign unmask_grant = request & ~unmask_temp;

    // Priority arbiter for masked requests
    wire [N-1:0] mask_request;
    wire [N-1:0] mask_temp;  // Masked higher priority requests
    wire [N-1:0] mask_grant;

    // Mask requests which come before the one selected by the round-robin pointer   
    assign mask_request = request & round_robin_ptr; 
   
    assign mask_temp[N-1:1] = mask_temp[N-2:0] | mask_request[N-2:0];
    assign mask_temp[0] = 0;
    assign mask_grant = mask_request & ~mask_temp;

    // Use mask_grant if available, otherwise use unmask_grant
    logic [N-1:0] grant_tmp;
   
    always_comb
        if (~|mask_request)
            grant_tmp = unmask_grant;
        else
            grant_tmp = mask_grant;

    // Round-robin pointer update logic

    always_ff @(posedge clock, posedge reset)
        if (reset)
        begin 
            round_robin_ptr <= '1;
            grant <= '0;
        end
        else
        begin
            if (!hold)
            begin
                if (|mask_request)
                    round_robin_ptr <= mask_temp;
                else
                    round_robin_ptr <= unmask_temp;
            
                grant <= grant_tmp;
            end
        end
   
endmodule // request_arbiter
