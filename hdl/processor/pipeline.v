import bus_package::*;
import cache_package::*;
import cpu_package::*;
import alu_package::*;

module pipeline
#(
    parameter int NODE_ID = 0,
    parameter int ID = 0
)
(
    input clock, reset,
    response_bus_interface.pipeline response,
    
    instruction_cache_interface.pipeline icache,
    data_cache_interface.pipeline dcache
);

    /*************************************************************************/
    /* Forward declarations                                                  */
    /*************************************************************************/

    // IF/ID
    if_id_t if_id;

    logic [31:0] if_id_ir;
    
    wire [4:0]  if_id_rs        = if_id_ir[25:21];
    wire [4:0]  if_id_rt        = if_id_ir[20:16];
    wire [4:0]  if_id_rd        = if_id_ir[15:11];
    wire [4:0]  if_id_shamt     = if_id_ir[10:6];
    wire [5:0]  if_id_opcode    = if_id_ir[31:26];
    wire [5:0]  if_id_funct     = if_id_ir[5:0];
    wire [25:0] if_id_target    = if_id_ir[25:0];
    wire [15:0] if_id_immediate = if_id_ir[15:0];
    
    logic icache_stall;
    
    // ID/EX
    id_ex_t id_ex;
    
    wire [4:0]  id_ex_rs        = id_ex.ir[25:21];
    wire [4:0]  id_ex_rt        = id_ex.ir[20:16];
    wire [4:0]  id_ex_rd        = id_ex.ir[15:11];
    wire [4:0]  id_ex_shamt     = id_ex.ir[10:6];
    wire [5:0]  id_ex_opcode    = id_ex.ir[31:26];
    wire [5:0]  id_ex_funct     = id_ex.ir[5:0];
    wire [25:0] id_ex_target    = id_ex.ir[25:0];
    wire [15:0] id_ex_immediate = id_ex.ir[15:0];
    
    logic [31:0] id_ex_rs_data, id_ex_rt_data;

    // EX/DC
    ex_mem_t ex_mem;

    wire [4:0]  ex_mem_rs        = ex_mem.ir[25:21];
    wire [4:0]  ex_mem_rt        = ex_mem.ir[20:16];
    wire [4:0]  ex_mem_rd        = ex_mem.ir[15:11];
    wire [4:0]  ex_mem_shamt     = ex_mem.ir[10:6];
    wire [5:0]  ex_mem_opcode    = ex_mem.ir[31:26];
    wire [5:0]  ex_mem_funct     = ex_mem.ir[5:0];
    wire [25:0] ex_mem_target    = ex_mem.ir[25:0];
    wire [15:0] ex_mem_immediate = ex_mem.ir[15:0];

    logic [31:0] branch_address;
    logic        take_branch;

    logic dcache_stall;

    // MEM/WB
    mem_wb_t mem_wb;
 
    wire [4:0]  mem_wb_rs        = mem_wb.ir[25:21];
    wire [4:0]  mem_wb_rt        = mem_wb.ir[20:16];
    wire [4:0]  mem_wb_rd        = mem_wb.ir[15:11];
    wire [4:0]  mem_wb_shamt     = mem_wb.ir[10:6];
    wire [5:0]  mem_wb_opcode    = mem_wb.ir[31:26];
    wire [5:0]  mem_wb_funct     = mem_wb.ir[5:0];
    wire [25:0] mem_wb_target    = mem_wb.ir[25:0];
    wire [15:0] mem_wb_immediate = mem_wb.ir[15:0];

    logic halt;

    logic [31:0] writeback_data;
    logic [4:0]  writeback_address;
    logic        writeback_enable;
    
    /*************************************************************************/
    /* Pipeline control                                                      */
    /*************************************************************************/

    // Flush the pipeline when a branch is taken
    wire flush_pipeline = take_branch;

    wire stall_pipeline = icache_stall || dcache_stall || halt;

    /*************************************************************************/
    /* Forwarding unit                                                       */
    /*************************************************************************/

    logic [1:0] forward_a;

    // todo move priority around... make MEM at top of loop
    always_comb
        if ( (mem_wb.writeback_register != 5'b00000) && 
             (ex_mem.writeback_register != id_ex_rs) && 
             (mem_wb.writeback_register == id_ex_rs) && 
             mem_wb.flags.writeback ) // MEM
            forward_a = 2'b01;
        else if ( (ex_mem.writeback_register != 5'b00000) && 
                  (ex_mem.writeback_register == id_ex_rs) && 
                  ex_mem.flags.writeback ) // EX
            forward_a = 2'b10;
     else
            forward_a = 2'b00;

    logic [1:0] forward_b;

    always_comb
        if ( (mem_wb.writeback_register != 5'b00000) && 
             (ex_mem.writeback_register != id_ex_rt) && 
             (mem_wb.writeback_register == id_ex_rt) && 
             mem_wb.flags.writeback ) // MEM
            forward_b = 2'b01;
        else if ( (ex_mem.writeback_register != 5'b00000) && 
                  (ex_mem.writeback_register == id_ex_rt) && 
                  ex_mem.flags.writeback ) // EX
            forward_b = 2'b10;
     else
            forward_b = 2'b00;

    logic forward_c;

    always_comb
        if ( (ex_mem.writeback_register == mem_wb.writeback_register) && 
             ex_mem.flags.store && mem_wb.flags.writeback
           )
            forward_c = 1;
        else
            forward_c = 0;
  
    /*************************************************************************/
    /* Hazard detection unit                                                 */
    /*************************************************************************/

    // fixme

    logic pc_enable, if_id_enable;
    logic insert_bubble;

    always_comb
        if (id_ex.flags.load && ((id_ex_rt == if_id_rs) || (id_ex_rt == if_id_rt)))
        begin
            { if_id_enable, pc_enable }  = '0;
            insert_bubble = 1;
        end
        else
        begin
            { if_id_enable, pc_enable }  = '1;
            insert_bubble = 0;
        end

    /*************************************************************************/
    /* Instruction fetch                                                     */
    /*************************************************************************/

    logic [31:0] next_pc, pc;
    
    always_comb
        next_pc = pc + 32'd4;

    // Hardware PC reset address (ROM)
    wire [31:0] reset_address;
    // 0x08000?00 (? = NODE_ID)
    assign reset_address[31:28] = 0; 
    assign reset_address[27:24] = 4'b1000;
    assign reset_address[23:12] = '0;
    assign reset_address[11:8]  = NODE_ID;
    assign reset_address[7:0]   = '0;
   
    // Program counter register
    always_ff @(posedge clock, posedge reset)
        if (reset)
            pc <= reset_address;
        else if (pc_enable && !stall_pipeline)
        begin
            if (take_branch)
                pc <= branch_address;
            else 
                pc <= next_pc;
        end
    
    always_comb
        if (stall_pipeline)
            icache.read_address = if_id.pc;
        else
            icache.read_address = pc;    

    // Pipeline register
    always_ff @(posedge clock, posedge reset)
        if (reset)
        begin
            if_id.pc          <= reset_address;
            if_id.next_pc     <= reset_address+4;
            if_id.take_branch <= 0;
        end
        else if (!stall_pipeline)
        begin
            if_id.pc           <= pc;
            if_id.next_pc      <= next_pc;
            // will this fix the problem ???!?.. this is like for 1 shitty case
            if_id.take_branch  <= take_branch;
        end

    /*************************************************************************/
    /* Instruction decode                                                    */
    /*************************************************************************/

    // Check for instruction cache hit/miss
    logic icache_hit;

    always_comb
        if (icache.tag_match && (icache.read_state == S))
        begin
            icache_hit  = 1;
            icache.miss = 0;
        end
        else if (!icache.tag_match && (icache.read_state == S))
        begin
            icache_hit  = 0;
            icache.miss = 1;
        end
        else if (icache.read_state == I)
        begin
            icache_hit  = 0; 
            icache.miss = 1;
        end
        else
        begin
            icache_hit  = 0;
            icache.miss = 0;
        end

    // Stall pipeline on miss
    assign icache_stall = !icache_hit;

    // Instruction register squash
    always_comb
        if (!icache_hit)
            if_id_ir = '0;
        else
        begin
            if_id_ir = '0;
            case (if_id.pc[3:2])
                2'b00:   if_id_ir = icache.read_data[127:96];
                2'b01:   if_id_ir = icache.read_data[95:64];
                2'b10:   if_id_ir = icache.read_data[63:32];
                2'b11:   if_id_ir = icache.read_data[31:0];
                default: if_id_ir = '0;
            endcase
        end

    // Cache controller 'control'
    assign icache.miss_address = if_id.pc;

    // Instruction cache memory write port
    assign icache.write_data   = response.data;
    assign icache.write_state  = S;
    assign icache.write_enable = icache.done;

    // Register file

    register_file regfile (
        .clock (clock), .reset (reset), .enable(!stall_pipeline),
        .rs (if_id_rs), .rt (if_id_rt),
        .rs_data (id_ex_rs_data), .rt_data (id_ex_rt_data),
        .writeback_address (writeback_address),
        .writeback_data (writeback_data),
        .writeback_enable (writeback_enable)
    );

    // Sign extension
    wire [31:0] sign_extend;

    assign sign_extend[31:16] = if_id_immediate[15] ? 16'hFFFF : 16'h0000;
    assign sign_extend[15:0]  = if_id_immediate[15:0];
    
    // Zero extension
    wire [31:0] zero_extend;

    assign zero_extend[31:16] = '0;
    assign zero_extend[15:0]  = if_id_immediate[15:0];

    // Instruction decoder
    flags_t flags_tmp;

    instruction_decoder decoder(if_id_ir, flags_tmp);
    
    // Insert pipeline bubble
    flags_t flags;

    always_comb
        if (insert_bubble || flush_pipeline || if_id.take_branch)
            flags = '0;
        else
            flags = flags_tmp;
    
    // Pipeline register
    always_ff @(posedge clock, posedge reset)
        if (reset)
            id_ex <= '0;
        else if (!stall_pipeline)
        begin
            id_ex.flags     <= flags;
            id_ex.ir        <= if_id_ir;
            id_ex.next_pc   <= if_id.next_pc;
            id_ex.immediate <= (flags.zero_extend) ? zero_extend : sign_extend;
        end

    /*************************************************************************/
    /* Execute                                                               */
    /*************************************************************************/

    // ALU
    logic [31:0] alu_a, alu_b, alu_b_tmp;
    wire  [31:0] alu_out;
    wire         alu_zero;
    wire         alu_overflow;

    // Forwarding multiplexors
    always_comb
        if (forward_a == 2'b10)
            alu_a = ex_mem.alu_out;
        else if (forward_a == 2'b01)
            alu_a = writeback_data;
        else
            alu_a = id_ex_rs_data;

    always_comb
        if (forward_b == 2'b10)
            alu_b_tmp = ex_mem.alu_out;
        else if (forward_b == 2'b01)
            alu_b_tmp = writeback_data;
        else
            alu_b_tmp = id_ex_rt_data;

    // Immediate select
    always_comb
        if (id_ex.flags.alu_src_immediate)
            alu_b = id_ex.immediate;
        else
            alu_b = alu_b_tmp;
    
    // ALU control
    logic [2:0] alu_op;

    always_comb
    begin
     // Default
     alu_op = '0;

     if (id_ex.flags.r_type && !id_ex.flags.i_type) // R-type
        case (id_ex_funct)
            funct_add:  alu_op = alu_add;
            funct_sub:  alu_op = alu_sub;
            funct_addu: alu_op = alu_add;
            funct_subu: alu_op = alu_sub;
            funct_and:  alu_op = alu_and;
            funct_or:   alu_op = alu_or;
            funct_xor:  alu_op = alu_xor;
            funct_nor:  alu_op = alu_nor;
            funct_slt:  alu_op = alu_slt;
            funct_sltu: alu_op = alu_slt;
            default:     alu_op = '0;
        endcase
     else if (!id_ex.flags.r_type && id_ex.flags.i_type) // I-type
        case(id_ex_opcode)
            opcode_addi:  alu_op = alu_add;
            opcode_addiu: alu_op = alu_add;
            opcode_andi:  alu_op = alu_and;
            opcode_ori:   alu_op = alu_or;
            opcode_lw:    alu_op = alu_add;
            opcode_sw:    alu_op = alu_add;
            opcode_lui:   alu_op = alu_lui;
            opcode_beq:   alu_op = alu_sub;
            opcode_bne:   alu_op = alu_sub;
            opcode_slti:  alu_op = alu_slt;
            opcode_sltiu: alu_op = alu_slt;
            default:       alu_op = '0;
        endcase
    end
    
    // ALU
    alu alu_inst(alu_a, alu_b, alu_op, alu_zero, alu_overflow, alu_out);
    
    // Data cache memory read port
    assign dcache.read_address = alu_out;

    // fixme, shouldn't I be flushing here??. .no.. 
    // Pipeline register 
    always_ff @(posedge clock, posedge reset)
        if (reset)
            ex_mem <= '0;
        else if (!stall_pipeline)
        begin
            ex_mem.flags              <= id_ex.flags;
            ex_mem.ir                 <= id_ex.ir;
            ex_mem.next_pc            <= id_ex.next_pc;
            ex_mem.rs_data            <= id_ex_rs_data;
            ex_mem.rt_data            <= alu_b_tmp; // forwarded
            ex_mem.alu_out            <= alu_out;
            ex_mem.alu_zero           <= alu_zero;
            ex_mem.branch_address     <= id_ex.next_pc + (id_ex.immediate << 2);
            ex_mem.writeback_register <= (id_ex.flags.r_type) ? id_ex_rd : id_ex_rt;
        end

    /*************************************************************************/
    /* Branch resolution logic                                               */
    /*************************************************************************/

    always_comb
        if ((ex_mem_opcode == opcode_beq) && ex_mem.alu_zero && ex_mem.flags.i_type)
        begin
            branch_address = ex_mem.branch_address;
            take_branch    = 1;
        end
        else if ((ex_mem_opcode == opcode_bne) && !ex_mem.alu_zero && ex_mem.flags.i_type)
        begin
            branch_address = ex_mem.branch_address;
            take_branch    = 1;
        end
        else if (ex_mem.flags.j_type && ex_mem.flags.r_type && ((ex_mem_funct == funct_jr) || (ex_mem_funct == funct_jalr)))
        begin
            branch_address = ex_mem.alu_out;
            take_branch    = 1;
         end            
        else if (ex_mem.flags.j_type && !ex_mem.flags.r_type && ((ex_mem_opcode == opcode_j) || (ex_mem_opcode == opcode_jal)))
        begin
            branch_address[31:28] = ex_mem.next_pc[31:28];
            branch_address[27:0]  = ex_mem_target << 2;
            take_branch = 1;
        end
        else
        begin
            branch_address = '0;
            take_branch    = 0;
        end

    /*************************************************************************/
    /* Memory access                                                         */
    /*************************************************************************/

    wire [31:0] store_data = (forward_c) ? writeback_data : ex_mem.rt_data;
    
    wire coherent_request = !ex_mem.alu_out[27];

    // MSI cache coherence protocol

    wire hit, miss, writeback;
    wire [1:0] state_out;
    wire [1:0] command_out;
    wire increment, decrement;

    msi_protocol msi_inst (
        coherent_request, // not required
        ex_mem.flags.load, ex_mem.flags.store, dcache.tag_match, dcache.read_state,
        hit, miss, writeback,
        state_out, command_out,
        increment, decrement
    );
   
    always_comb
        if (coherent_request)
        begin
            dcache_stall = !hit || writeback;

            dcache.miss_address = ex_mem.alu_out;
            dcache.miss_command = command_out;
            dcache.miss         = miss;

            dcache.writeback_address = dcache.replaced_address;
            dcache.writeback_data    = dcache.read_data;
            dcache.writeback         = writeback;

            dcache.increment = increment;
            dcache.decrement = decrement;

            dcache.write_state        = state_out;
            dcache.write_enable       = dcache.done;
            dcache.state_write_enable = hit && (ex_mem.flags.store || ex_mem.flags.load);
        end
        else
        begin
            dcache_stall = (ex_mem.flags.load || ex_mem.flags.store) && !dcache.done;

            dcache.miss_address = ex_mem.alu_out;
            dcache.miss_command = bus_read;
            dcache.miss         = ex_mem.flags.load;

            dcache.writeback_address      = ex_mem.alu_out;
            dcache.writeback_data[127:32] = '0;
            dcache.writeback_data[31:0]   = store_data;
            dcache.writeback              = ex_mem.flags.store;    

            dcache.increment = 0;
            dcache.decrement = 0;
            
            dcache.write_state        = '0;
            dcache.write_enable       = 0;
            dcache.state_write_enable = 0;
        end

    always_comb
    begin
        dcache.write_data = response.data;
        case (ex_mem.alu_out[3:2])
            2'b00: dcache.write_data[127:96] = store_data;
            2'b01: dcache.write_data[95:64]  = store_data;
            2'b10: dcache.write_data[63:32]  = store_data;
            2'b11: dcache.write_data[31:0]   = store_data;
        endcase
    end

    logic [31:0] memory_data;

    always_comb
    begin
        memory_data = '0;
        case (ex_mem.alu_out[3:2])
            2'b00:   memory_data = dcache.read_data[127:96];
            2'b01:   memory_data = dcache.read_data[95:64];
            2'b10:   memory_data = dcache.read_data[63:32];
            2'b11:   memory_data = dcache.read_data[31:0];
            default: memory_data = '0;
        endcase
    end

    // Pipeline register
    always_ff @(posedge clock, posedge reset)
        if (reset)
            mem_wb <= '0;
        else if (!stall_pipeline)
        begin
            mem_wb.flags              <= ex_mem.flags;
            mem_wb.ir                 <= ex_mem.ir;
            mem_wb.next_pc            <= ex_mem.next_pc;
            
            mem_wb.writeback_register <= ex_mem.writeback_register;
            mem_wb.register_data      <= ex_mem.alu_out;
            mem_wb.memory_data        <= memory_data;
        end
    
    /*************************************************************************/
    /* Writeback                                                             */
    /*************************************************************************/

    // Halt register
    always_ff @(posedge clock, posedge reset)
        if (reset)
            halt = 0;
        else if ((mem_wb_opcode == opcode_r_type) && (mem_wb_funct == funct_break) && mem_wb.flags.writeback)
            halt = 1;

    // Writeback data select
    always_comb
        if (mem_wb.flags.load && !mem_wb.flags.link)
            writeback_data = mem_wb.memory_data;
        else if (!mem_wb.flags.load && mem_wb.flags.link)
            writeback_data = mem_wb.next_pc;
        else
            writeback_data = mem_wb.register_data;

    // Writeback address select
    always_comb
        if (mem_wb.flags.link)
            writeback_address = 5'b11111;
        else
            writeback_address = mem_wb.writeback_register;

    assign writeback_enable = mem_wb.flags.writeback;

endmodule // pipeline