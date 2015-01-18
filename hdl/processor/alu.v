import alu_package::*;

module alu
(
    input        [31:0] a,
    input        [31:0] b,
    input        [2:0]  op,
    output logic        zero,
    output logic        overflow,
    output       [31:0] f
);

    logic [31:0] f_tmp;
    always_comb
    begin
        // Default
        f_tmp = '0;
        
        case (op)
            alu_add: f_tmp = a + b;
            alu_sub: f_tmp = a - b;
            alu_and: f_tmp = a & b;
            alu_or : f_tmp = a | b;
            alu_xor: f_tmp = a ^ b;
            alu_nor: f_tmp = ~(a | b);
            alu_slt: f_tmp = (a < b) ? 1 : 0;
            alu_lui:
            begin
                f_tmp[31:16] = b [15:0];
                f_tmp[15:0] = '0;
            end
        endcase
    end

    always_comb
        if (f_tmp == 32'h00000000)
            zero = 1;
        else
            zero = 0;

   assign overflow = 0;
   assign f = f_tmp;

endmodule // alu
