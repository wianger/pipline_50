`timescale 1us/1us
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/12/15 21:47:11
// Design Name: 
// Module Name: PipelineCPU
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`include "mips_defs.svh"

module PipelineCPU(
    input  logic reset,
    input  logic clock,

    output word_t imem_addr,
    input  word_t imem_rdata,

    output word_t dmem_addr_aligned,
    input  word_t dmem_rdata_word,
    output logic  dmem_we_word,
    output word_t dmem_wdata_word
);

    // -------------------------------------------------------------------------
    // IF stage
    // -------------------------------------------------------------------------

    word_t pc_q, pc_next;
    word_t pc_plus4_if;

    assign imem_addr = pc_q;
    assign pc_plus4_if = pc_q + 32'd4;

    // IF/ID pipeline register
    if_id_t if_id_d, if_id_q;

    // -------------------------------------------------------------------------
    // ID stage
    // -------------------------------------------------------------------------

    // Decode outputs
    reg_addr_t id_rs, id_rt, id_rd;
    logic [4:0] id_shamt;
    word_t id_imm_ext, id_link_addr;

    logic      id_reg_write;
    wb_sel_t   id_wb_sel;
    reg_addr_t id_dest;

    logic       id_mem_read;
    logic       id_mem_write;
    mem_width_t id_mem_width;
    logic       id_mem_unsigned;

    logic     id_alu_src_imm;
    alu_op_t  id_alu_op;

    mdu_cmd_t id_mdu_cmd;
    logic     id_is_syscall;

    logic     id_is_ctrl;
    logic     id_uses_rs;
    logic     id_uses_rt;

    Decoder u_dec (
        .instr        (if_id_q.instr),
        .pc           (if_id_q.pc),
        .rs           (id_rs),
        .rt           (id_rt),
        .rd           (id_rd),
        .shamt        (id_shamt),
        .imm_ext      (id_imm_ext),
        .link_addr    (id_link_addr),

        .reg_write    (id_reg_write),
        .wb_sel       (id_wb_sel),
        .dest         (id_dest),

        .mem_read     (id_mem_read),
        .mem_write    (id_mem_write),
        .mem_width    (id_mem_width),
        .mem_unsigned (id_mem_unsigned),

        .alu_src_imm  (id_alu_src_imm),
        .alu_op       (id_alu_op),

        .mdu_cmd      (id_mdu_cmd),
        .is_syscall   (id_is_syscall),

        .id_is_ctrl   (id_is_ctrl),
        .id_uses_rs   (id_uses_rs),
        .id_uses_rt   (id_uses_rt)
    );

    // Register file
    reg_addr_t rf_raddr1, rf_raddr2;
    word_t rf_rs_data, rf_rt_data;
    word_t rf_v0_value, rf_a0_value;

    // WB stage writeback (from MEM/WB register)
    logic      wb_we;
    reg_addr_t wb_waddr;
    word_t     wb_wdata;

    // During an EX-stage MDU stall we temporarily repurpose the 2 RF read ports
    // to read the stalled instruction's rs/rt, so we can refresh operands even
    // after older instructions have already written back and left MEM/WB.
    // This fixes operand-staleness bugs for queued MDU ops (multi-cycle waits).
    assign rf_raddr1 = stall_idex ? id_ex_q.rs : id_rs;
    assign rf_raddr2 = stall_idex ? id_ex_q.rt : id_rt;

    RegisterFile u_rf (
        .clock    (clock),
        .reset    (reset),
        .we       (wb_we),
        .waddr    (wb_waddr),
        .wdata    (wb_wdata),
        .raddr1   (rf_raddr1),
        .rdata1   (rf_rs_data),
        .raddr2   (rf_raddr2),
        .rdata2   (rf_rt_data),
        .v0_value (rf_v0_value),
        .a0_value (rf_a0_value)
    );

    // ID/EX pipeline register
    id_ex_t id_ex_d, id_ex_q;

    // -------------------------------------------------------------------------
    // EX stage
    // -------------------------------------------------------------------------

    ex_mem_t ex_mem_d, ex_mem_q;

    // Forwarding / Hazard control
    logic [1:0] fwd_id_rs_sel, fwd_id_rt_sel;
    logic [1:0] fwd_ex_rs_sel, fwd_ex_rt_sel;

    logic stall_pc, stall_ifid, stall_idex, flush_idex, bubble_exmem;

    // MDU
    logic mdu_busy;
    word_t mdu_dataRead;
    // NOTE: MultiplicationDivisionUnit defines mdu_operation_t in its own file scope.
    // To avoid cross-file typedef visibility / duplicate-definition issues, we drive
    // the underlying 3-bit encoding directly here.
    logic [2:0] mdu_operation;
    logic mdu_start;
    word_t mdu_operand1, mdu_operand2;

    localparam logic [2:0] MDU_OP_READ_HI            = 3'd0;
    localparam logic [2:0] MDU_OP_READ_LO            = 3'd1;
    localparam logic [2:0] MDU_OP_WRITE_HI           = 3'd2;
    localparam logic [2:0] MDU_OP_WRITE_LO           = 3'd3;
    localparam logic [2:0] MDU_OP_START_SIGNED_MUL   = 3'd4;
    localparam logic [2:0] MDU_OP_START_UNSIGNED_MUL = 3'd5;
    localparam logic [2:0] MDU_OP_START_SIGNED_DIV   = 3'd6;
    localparam logic [2:0] MDU_OP_START_UNSIGNED_DIV = 3'd7;

    // MEM/WB pipeline register
    mem_wb_t mem_wb_d, mem_wb_q;

    // -------------------------------------------------------------------------
    // MEM stage helpers (also used for forwarding)
    // -------------------------------------------------------------------------

    word_t mem_load_data;
    word_t mem_aligned_addr;
    logic  mem_we_word;
    word_t mem_wdata_word;

    LoadStoreUnit u_lsu (
        .addr         (ex_mem_q.mem_addr),
        .store_data   (ex_mem_q.store_data),
        .rdata_word   (dmem_rdata_word),
        .is_load      (ex_mem_q.mem_read),
        .is_store     (ex_mem_q.mem_write),
        .width        (ex_mem_q.mem_width),
        .mem_unsigned (ex_mem_q.mem_unsigned),
        .load_data    (mem_load_data),
        .addr_aligned (mem_aligned_addr),
        .we_word      (mem_we_word),
        .wdata_word   (mem_wdata_word)
    );

    // Drive external data memory (word interface)
    assign dmem_addr_aligned = mem_aligned_addr;
    assign dmem_wdata_word   = mem_wdata_word;
    assign dmem_we_word      = ex_mem_q.valid && mem_we_word;

    // Forwardable values from MEM/WB pipeline stages
    word_t mem_fwd_value;
    word_t wb_fwd_value;

    assign mem_fwd_value = (ex_mem_q.mem_read) ? mem_load_data : ex_mem_q.ex_result;
    assign wb_fwd_value  = mem_wb_q.wb_data;

    // EX stage forwarding selections
    logic ex_is_load;
    logic ex_is_mdu;

    assign ex_is_load = id_ex_q.valid && id_ex_q.mem_read && (id_ex_q.wb_sel == WB_MEM);
    assign ex_is_mdu  = id_ex_q.valid && (id_ex_q.mdu_cmd != MDUCMD_NONE);

    ForwardUnit u_fwd (
        .id_rs        (id_rs),
        .id_rt        (id_rt),
        .ex_rs        (id_ex_q.rs),
        .ex_rt        (id_ex_q.rt),
        .ex_reg_write (id_ex_q.valid && id_ex_q.reg_write),
        .ex_is_load   (ex_is_load),
        .ex_dest      (id_ex_q.dest),
        .mem_reg_write(ex_mem_q.valid && ex_mem_q.reg_write),
        .mem_dest     (ex_mem_q.dest),
        .wb_reg_write (mem_wb_q.valid && mem_wb_q.reg_write),
        .wb_dest      (mem_wb_q.dest),
        .fwd_id_rs_sel(fwd_id_rs_sel),
        .fwd_id_rt_sel(fwd_id_rt_sel),
        .fwd_ex_rs_sel(fwd_ex_rs_sel),
        .fwd_ex_rt_sel(fwd_ex_rt_sel)
    );

    HazardUnit u_hzd (
        .id_is_ctrl  (if_id_q.valid && id_is_ctrl),
        .id_uses_rs  (id_uses_rs),
        .id_uses_rt  (id_uses_rt),
        .id_rs       (id_rs),
        .id_rt       (id_rt),
        .ex_is_load  (ex_is_load),
        .ex_reg_write(id_ex_q.valid && id_ex_q.reg_write),
        .ex_dest     (id_ex_q.dest),
        .ex_is_mdu   (ex_is_mdu),
        .mdu_busy    (mdu_busy),
        .stall_pc    (stall_pc),
        .stall_ifid  (stall_ifid),
        .stall_idex  (stall_idex),
        .flush_idex  (flush_idex),
        .bubble_exmem(bubble_exmem)
    );

    // ID stage forwarding for branch/jump compare
    word_t id_rs_val_fwd, id_rt_val_fwd;

    always_comb begin
        id_rs_val_fwd = rf_rs_data;
        unique case (fwd_id_rs_sel)
            2'b00: id_rs_val_fwd = rf_rs_data;
            2'b01: id_rs_val_fwd = ex_mem_d.ex_result; // EX stage computed value (see below)
            2'b10: id_rs_val_fwd = mem_fwd_value;
            2'b11: id_rs_val_fwd = wb_fwd_value;
            default: id_rs_val_fwd = rf_rs_data;
        endcase

        id_rt_val_fwd = rf_rt_data;
        unique case (fwd_id_rt_sel)
            2'b00: id_rt_val_fwd = rf_rt_data;
            2'b01: id_rt_val_fwd = ex_mem_d.ex_result;
            2'b10: id_rt_val_fwd = mem_fwd_value;
            2'b11: id_rt_val_fwd = wb_fwd_value;
            default: id_rt_val_fwd = rf_rt_data;
        endcase
    end

    // Branch / jump resolution in ID (with delay slot)
    logic id_redirect;
    word_t id_redirect_target;

    BranchJumpUnit u_bju (
        .pc             (if_id_q.pc),
        .instr          (if_id_q.instr),
        .rs_val         (id_rs_val_fwd),
        .rt_val         (id_rt_val_fwd),
        .redirect       (id_redirect),
        .redirect_target(id_redirect_target)
    );

    // PC update (delay slot: redirect affects next cycle fetch)
    always_comb begin
        pc_next = pc_plus4_if;
        if (if_id_q.valid && id_redirect) begin
            pc_next = id_redirect_target;
        end
    end

    always_ff @(posedge clock) begin
        if (reset) begin
            pc_q <= RESET_PC;
        end else if (!stall_pc) begin
            pc_q <= pc_next;
        end
    end

    // -------------------------------------------------------------------------
    // IF/ID register write
    // -------------------------------------------------------------------------

    always_comb begin
        if_id_d.valid = 1'b1;
        if_id_d.pc    = pc_q;
        if_id_d.instr = imem_rdata;
    end

    PipeRegIFID u_ifid (
        .clock (clock),
        .reset (reset),
        .en    (!stall_ifid),
        .flush (1'b0),
        .d     (if_id_d),
        .q     (if_id_q)
    );

    // -------------------------------------------------------------------------
    // ID/EX register write
    // -------------------------------------------------------------------------

    always_comb begin
        id_ex_d = '0;
        id_ex_d.valid        = if_id_q.valid;
        id_ex_d.pc           = if_id_q.pc;
        id_ex_d.rs           = id_rs;
        id_ex_d.rt           = id_rt;
        id_ex_d.rd           = id_rd;
        id_ex_d.shamt        = id_shamt;
        id_ex_d.dest         = id_dest;
        id_ex_d.rs_val       = rf_rs_data;
        id_ex_d.rt_val       = rf_rt_data;
        id_ex_d.imm_ext      = id_imm_ext;
        id_ex_d.link_addr    = id_link_addr;
        id_ex_d.reg_write    = id_reg_write;
        id_ex_d.wb_sel       = id_wb_sel;
        id_ex_d.mem_read     = id_mem_read;
        id_ex_d.mem_write    = id_mem_write;
        id_ex_d.mem_width    = id_mem_width;
        id_ex_d.mem_unsigned = id_mem_unsigned;
        id_ex_d.alu_src_imm  = id_alu_src_imm;
        id_ex_d.alu_op       = id_alu_op;
        id_ex_d.mdu_cmd      = id_mdu_cmd;
        id_ex_d.is_syscall   = id_is_syscall;

        // For pure control-flow instructions (no link), kill side effects in later stages.
        if (id_is_ctrl && !(id_reg_write && (id_wb_sel == WB_LINK))) begin
            id_ex_d.reg_write = 1'b0;
            id_ex_d.mem_read  = 1'b0;
            id_ex_d.mem_write = 1'b0;
            id_ex_d.mdu_cmd   = MDUCMD_NONE;
            id_ex_d.is_syscall = 1'b0;
        end
    end

    PipeRegIDEX u_idex (
        .clock (clock),
        .reset (reset),
        .en    (!stall_idex),
        .flush (flush_idex),
        .d     (id_ex_d),
        .q     (id_ex_q)
    );

    // -------------------------------------------------------------------------
    // EX stage execute
    // -------------------------------------------------------------------------

    word_t ex_rs_val, ex_rt_val;
    word_t ex_rs_base, ex_rt_base;
    word_t ex_rs_hold, ex_rt_hold;
    logic  ex_hold_valid;
    word_t ex_alu_b;
    word_t ex_alu_y;
    word_t ex_result_value;

    // Track when an MDU instruction is stalled in EX (MDU busy).
    // - While stalled, base operands come from RF live reads (rf_rs_data/rt_data)
    // - When stall is released (busy -> 0), use the held operands for 1 cycle,
    //   because RF ports must immediately return to ID stage for branch/jump.
    wire ex_mdu_stall = stall_idex;
    wire ex_use_hold  = (!ex_mdu_stall) && ex_hold_valid;

    always_comb begin
        // Base operands
        if (ex_mdu_stall) begin
            ex_rs_base = rf_rs_data;
            ex_rt_base = rf_rt_data;
        end else if (ex_use_hold) begin
            ex_rs_base = ex_rs_hold;
            ex_rt_base = ex_rt_hold;
        end else begin
            ex_rs_base = id_ex_q.rs_val;
            ex_rt_base = id_ex_q.rt_val;
        end

        // Apply forwarding on top of base
        ex_rs_val = ex_rs_base;
        unique case (fwd_ex_rs_sel)
            2'b00: ex_rs_val = ex_rs_base;
            2'b01: ex_rs_val = mem_fwd_value;
            2'b10: ex_rs_val = wb_fwd_value;
            default: ex_rs_val = ex_rs_base;
        endcase

        ex_rt_val = ex_rt_base;
        unique case (fwd_ex_rt_sel)
            2'b00: ex_rt_val = ex_rt_base;
            2'b01: ex_rt_val = mem_fwd_value;
            2'b10: ex_rt_val = wb_fwd_value;
            default: ex_rt_val = ex_rt_base;
        endcase
    end

    // Hold the resolved operands while stalling in EX, and keep the hold valid
    // for exactly 1 cycle after stall is released.
    always_ff @(posedge clock) begin
        if (reset) begin
            ex_rs_hold   <= 32'h0000_0000;
            ex_rt_hold   <= 32'h0000_0000;
            ex_hold_valid <= 1'b0;
        end else begin
            if (ex_mdu_stall) begin
                // Capture the latest resolved operands (includes MEM/WB forwarding)
                ex_rs_hold <= ex_rs_val;
                ex_rt_hold <= ex_rt_val;
                ex_hold_valid <= 1'b1;
            end else begin
                ex_hold_valid <= 1'b0;
            end
        end
    end

    assign ex_alu_b = id_ex_q.alu_src_imm ? id_ex_q.imm_ext : ex_rt_val;

    ALU u_alu (
        .a     (ex_rs_val),
        .b     (ex_alu_b),
        .shamt (id_ex_q.shamt),
        .op    (id_ex_q.alu_op),
        .y     (ex_alu_y)
    );

    // MDU wiring
    always_comb begin
        // Defaults
        mdu_operand1  = 32'h0000_0000;
        mdu_operand2  = 32'h0000_0000;
        mdu_operation = MDU_OP_READ_HI;
        mdu_start     = 1'b0;

        // Operand mapping
        if (id_ex_q.mdu_cmd != MDUCMD_NONE) begin
            // For MTHI/MTLO: operand1 is rs value; for MULT/DIV: operand1/2 are rs/rt
            mdu_operand1 = ex_rs_val;
            mdu_operand2 = ex_rt_val;
        end

        unique case (id_ex_q.mdu_cmd)
            MDUCMD_READ_HI:            mdu_operation = MDU_OP_READ_HI;
            MDUCMD_READ_LO:            mdu_operation = MDU_OP_READ_LO;
            MDUCMD_WRITE_HI:           mdu_operation = MDU_OP_WRITE_HI;
            MDUCMD_WRITE_LO:           mdu_operation = MDU_OP_WRITE_LO;
            MDUCMD_START_SIGNED_MUL:   mdu_operation = MDU_OP_START_SIGNED_MUL;
            MDUCMD_START_UNSIGNED_MUL: mdu_operation = MDU_OP_START_UNSIGNED_MUL;
            MDUCMD_START_SIGNED_DIV:   mdu_operation = MDU_OP_START_SIGNED_DIV;
            MDUCMD_START_UNSIGNED_DIV: mdu_operation = MDU_OP_START_UNSIGNED_DIV;
            default:                   mdu_operation = MDU_OP_READ_HI;
        endcase

        // Start pulse for START_* commands when ready
        if (id_ex_q.valid) begin
            if (id_ex_q.mdu_cmd == MDUCMD_START_SIGNED_MUL ||
                id_ex_q.mdu_cmd == MDUCMD_START_UNSIGNED_MUL ||
                id_ex_q.mdu_cmd == MDUCMD_START_SIGNED_DIV ||
                id_ex_q.mdu_cmd == MDUCMD_START_UNSIGNED_DIV) begin
                if (!mdu_busy) begin
                    mdu_start = 1'b1;
                end
            end
        end
    end

    MultiplicationDivisionUnit u_mdu (
        .reset    (reset),
        .clock    (clock),
        .operand1 (mdu_operand1),
        .operand2 (mdu_operand2),
        .operation(mdu_operation),
        .start    (mdu_start),
        .busy     (mdu_busy),
        .dataRead (mdu_dataRead)
    );

    // EX stage writeback value (also used by ID forwarding via ex_mem_d.ex_result)
    always_comb begin
        unique case (id_ex_q.wb_sel)
            WB_LINK: ex_result_value = id_ex_q.link_addr;
            WB_MDU:  ex_result_value = mdu_dataRead;
            default: ex_result_value = ex_alu_y;
        endcase
    end

    // EX/MEM input
    always_comb begin
        if (bubble_exmem) begin
            ex_mem_d = '0;
        end else begin
            ex_mem_d = '0;
            ex_mem_d.valid        = id_ex_q.valid;
            ex_mem_d.pc           = id_ex_q.pc;
            ex_mem_d.reg_write    = id_ex_q.reg_write;
            ex_mem_d.wb_sel       = id_ex_q.wb_sel;
            ex_mem_d.dest         = id_ex_q.dest;
            ex_mem_d.ex_result    = ex_result_value;
            ex_mem_d.mem_read     = id_ex_q.mem_read;
            ex_mem_d.mem_write    = id_ex_q.mem_write;
            ex_mem_d.mem_width    = id_ex_q.mem_width;
            ex_mem_d.mem_unsigned = id_ex_q.mem_unsigned;
            ex_mem_d.mem_addr     = ex_alu_y;
            ex_mem_d.store_data   = ex_rt_val;
            ex_mem_d.is_syscall   = id_ex_q.is_syscall;
        end
    end

    PipeRegEXMEM u_exmem (
        .clock (clock),
        .reset (reset),
        .en    (1'b1),
        .flush (1'b0),
        .d     (ex_mem_d),
        .q     (ex_mem_q)
    );

    // -------------------------------------------------------------------------
    // MEM/WB
    // -------------------------------------------------------------------------

    always_comb begin
        mem_wb_d = '0;
        mem_wb_d.valid   = ex_mem_q.valid;
        mem_wb_d.pc      = ex_mem_q.pc;
        mem_wb_d.reg_write = ex_mem_q.reg_write;
        mem_wb_d.dest      = ex_mem_q.dest;
        mem_wb_d.wb_data   = (ex_mem_q.wb_sel == WB_MEM) ? mem_load_data : ex_mem_q.ex_result;

        mem_wb_d.mem_write_commit       = ex_mem_q.valid && ex_mem_q.mem_write;
        mem_wb_d.mem_write_addr_aligned = mem_aligned_addr;
        mem_wb_d.mem_write_data_word    = mem_wdata_word;

        mem_wb_d.is_syscall = ex_mem_q.is_syscall;
    end

    PipeRegMEMWB u_memwb (
        .clock (clock),
        .reset (reset),
        .en    (1'b1),
        .flush (1'b0),
        .d     (mem_wb_d),
        .q     (mem_wb_q)
    );

    // WB connections
    assign wb_we    = mem_wb_q.valid && mem_wb_q.reg_write;
    assign wb_waddr = mem_wb_q.dest;
    assign wb_wdata = mem_wb_q.wb_data;

    // Commit / trace
    TraceCommit u_commit (
        .clock                   (clock),
        .reset                   (reset),
        .wb_valid                (mem_wb_q.valid),
        .wb_pc                   (mem_wb_q.pc),
        .wb_reg_write            (mem_wb_q.reg_write),
        .wb_waddr                (mem_wb_q.dest),
        .wb_wdata                (mem_wb_q.wb_data),
        .wb_mem_write_commit     (mem_wb_q.mem_write_commit),
        .wb_mem_write_addr_aligned(mem_wb_q.mem_write_addr_aligned),
        .wb_mem_write_data_word  (mem_wb_q.mem_write_data_word),
        .wb_is_syscall           (mem_wb_q.is_syscall),
        .rf_v0_value             (rf_v0_value),
        .rf_a0_value             (rf_a0_value)
    );
endmodule
