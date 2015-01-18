package cpu_package;
    // See A-51

    const bit [5:0] opcode_r_type = 6'd0;
    const bit [5:0] opcode_bcond  = 6'd1;
    const bit [5:0] opcode_j      = 6'd2;
    const bit [5:0] opcode_jal    = 6'd3;
    const bit [5:0] opcode_beq    = 6'd4;
    const bit [5:0] opcode_bne    = 6'd5;
    const bit [5:0] opcode_blez   = 6'd6;
    const bit [5:0] opcode_bgtz   = 6'd6;
    const bit [5:0] opcode_addi   = 6'd8;
    const bit [5:0] opcode_addiu  = 6'd9;
    const bit [5:0] opcode_slti   = 6'd10;
    const bit [5:0] opcode_sltiu  = 6'd11;
    const bit [5:0] opcode_andi   = 6'd12;
    const bit [5:0] opcode_ori    = 6'd13;
    const bit [5:0] opcode_xori   = 6'd14;
    const bit [5:0] opcode_lui    = 6'd15;

    const bit [5:0] opcode_lb  = 6'd32;
    const bit [5:0] opcode_lh  = 6'd33;
    const bit [5:0] opcode_lwl = 6'd34;
    const bit [5:0] opcode_lw  = 6'd35;
    const bit [5:0] opcode_lbu = 6'd36;
    const bit [5:0] opcode_lhu = 6'd37;
    const bit [5:0] opcode_lwr = 6'd38;

    const bit [5:0] opcode_sb  = 6'd40;
    const bit [5:0] opcode_sh  = 6'd41;
    const bit [5:0] opcode_swl = 6'd42;
    const bit [5:0] opcode_sw  = 6'd43;
    const bit [5:0] opcode_swr = 6'd46;

    const bit [5:0] opcode_ll = 6'd48;
    const bit [5:0] opcode_sc = 6'd56;

    const bit [5:0] funct_nop     = 6'd0;
    const bit [5:0] funct_sll     = 6'd0;
    const bit [5:0] funct_srl     = 6'd2;
    const bit [5:0] funct_sra     = 6'd3;
    const bit [5:0] funct_sllv    = 6'd4;
    const bit [5:0] funct_srlv    = 6'd6;
    const bit [5:0] funct_srav    = 6'd7;
    const bit [5:0] funct_jr      = 6'd8;
    const bit [5:0] funct_jalr    = 6'd9;
    const bit [5:0] funct_syscall = 6'd12;
    const bit [5:0] funct_break   = 6'd13;
    const bit [5:0] funct_mfhi    = 6'd16;
    const bit [5:0] funct_mthi    = 6'd17;
    const bit [5:0] funct_mflo    = 6'd18;
    const bit [5:0] funct_mtlo    = 6'd19;
    const bit [5:0] funct_add     = 6'd32;
    const bit [5:0] funct_addu    = 6'd33;
    const bit [5:0] funct_sub     = 6'd34;
    const bit [5:0] funct_subu    = 6'd35;
    const bit [5:0] funct_and     = 6'd36;
    const bit [5:0] funct_or      = 6'd37;
    const bit [5:0] funct_xor     = 6'd38;
    const bit [5:0] funct_nor     = 6'd39;
    const bit [5:0] funct_slt     = 6'd42;
    const bit [5:0] funct_sltu    = 6'd43;

    const bit [4:0] bcond_bltz   = 5'd0;
    const bit [4:0] bcond_bgez   = 5'd1;
    const bit [4:0] bcond_bltzal = 5'd16;
    const bit [4:0] bcond_bgezal = 5'd17;

    typedef struct packed {
        bit r_type, i_type, j_type, store, load, alu_src_immediate, no_overflow, zero_extend, link, writeback;
    } flags_t;

    typedef struct packed {
        bit [31:0] pc, next_pc;
        bit        take_branch;
    } if_id_t;
       
    typedef struct packed {
        flags_t flags;
        bit [31:0] ir, next_pc;
        bit [31:0] immediate;
       } id_ex_t;

    typedef struct packed {
        flags_t    flags;
        bit [31:0] ir, next_pc;
        bit [31:0] rs_data, rt_data;
        bit [31:0] alu_out;
        bit        alu_zero;    
        bit [31:0] branch_address;
        bit [4:0]  writeback_register;
    } ex_mem_t;

    typedef struct packed {
        flags_t    flags;
        bit [31:0] ir, next_pc;
        bit [4:0]  writeback_register;
        bit [31:0] memory_data, register_data;
    } mem_wb_t;

endpackage // cpu_package
