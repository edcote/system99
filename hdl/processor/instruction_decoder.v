import cpu_package::*;

module instruction_decoder
(
    input [31:0]   ir,
    output flags_t flags
);

    wire [4:0]  rs, rt, rd, shamt;
    wire [5:0]  opcode, funct;
    wire [25:0] target;
    wire [15:0] immediate;
         
//    assign rs        = ir[25:21];
    assign rt        = ir[20:16];
//    assign rd        = ir[15:11];
//    assign shamt     = ir[10:6];
    assign opcode    = ir[31:26];
    assign funct     = ir[5:0];        
//    assign target    = ir[25:0];
//    assign immediate = ir[15:0];

    always_comb
    begin
        // Default
        flags = '0;
        
        case (opcode)
            opcode_r_type: 
                case (funct)
                    funct_nop:   { flags.r_type, flags.writeback } = '0;
                    funct_jr:    { flags.r_type, flags.j_type } = '1;
                    funct_jalr:  { flags.r_type, flags.j_type, flags.link, flags.writeback } = '1;
                    funct_break: { flags.writeback } = '1;
                    default:      { flags.r_type, flags.writeback } = '1;
                endcase
            opcode_bcond:
                case (rt)
                    bcond_bltz:   { flags.i_type } = '1;
                    bcond_bgez:   { flags.i_type } = '1;
                    bcond_bltzal: { flags.i_type } = '1;
                    bcond_bgezal: { flags.i_type } = '1;
                    default:       flags = '0;
                endcase
            opcode_addi:   { flags.i_type, flags.writeback, flags.alu_src_immediate } = '1;
            opcode_addiu:  { flags.i_type, flags.writeback, flags.no_overflow, flags.alu_src_immediate } = '1;
            opcode_andi:   { flags.i_type, flags.writeback, flags.zero_extend, flags.alu_src_immediate } = '1;
            opcode_ori:    { flags.i_type, flags.writeback, flags.zero_extend, flags.alu_src_immediate } = '1;
            opcode_xori:   { flags.i_type, flags.writeback, flags.zero_extend, flags.alu_src_immediate } = '1;
            opcode_lw:     { flags.load, flags.writeback, flags.i_type, flags.alu_src_immediate } = '1;
            opcode_sw:     { flags.store, flags.i_type, flags.alu_src_immediate } = '1;
            opcode_lui:    { flags.i_type, flags.writeback, flags.zero_extend, flags.alu_src_immediate } = '1;
            opcode_beq:    { flags.i_type } = '1;
            opcode_bne:    { flags.i_type } = '1;
            opcode_slti:   { flags.i_type, flags.writeback, flags.alu_src_immediate } = '1;
            opcode_sltiu:  { flags.i_type, flags.writeback, flags.no_overflow, flags.alu_src_immediate } = '1;
            opcode_j:      flags.j_type = 1;
            opcode_jal:    { flags.j_type, flags.writeback, flags.link } = '1;
            default:        flags = '0;
        endcase
    end

endmodule // instruction_decoder
