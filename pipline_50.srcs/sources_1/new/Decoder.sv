`timescale 1us/1us
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/12/15 21:48:15
// Design Name: 
// Module Name: Decoder
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

module Decoder(
    input  word_t instr,
    input  word_t pc,

    output reg_addr_t rs,
    output reg_addr_t rt,
    output reg_addr_t rd,
    output logic [4:0] shamt,
    output word_t imm_ext,
    output word_t link_addr,

    // pipeline control outputs
    output logic     reg_write,
    output wb_sel_t  wb_sel,
    output reg_addr_t dest,

    output logic     mem_read,
    output logic     mem_write,
    output mem_width_t mem_width,
    output logic     mem_unsigned,

    output logic     alu_src_imm,
    output alu_op_t  alu_op,

    output mdu_cmd_t mdu_cmd,

    output logic     is_syscall,

    // for HazardUnit: ID-stage control-flow instruction uses
    output logic     id_is_ctrl,
    output logic     id_uses_rs,
    output logic     id_uses_rt
);

    logic [5:0] op;
    logic [5:0] funct;
    logic [15:0] imm;
    logic [4:0] rt_field;

    always_comb begin
        op      = instr[31:26];
        rs      = instr[25:21];
        rt      = instr[20:16];
        rd      = instr[15:11];
        shamt   = instr[10:6];
        funct   = instr[5:0];
        imm     = instr[15:0];
        rt_field = instr[20:16];

        // defaults (NOP)
        imm_ext     = {{16{imm[15]}}, imm};
        link_addr   = pc + 32'd8;

        reg_write   = 1'b0;
        wb_sel      = WB_ALU;
        dest        = 5'd0;

        mem_read    = 1'b0;
        mem_write   = 1'b0;
        mem_width   = MEM_W;
        mem_unsigned = 1'b0;

        alu_src_imm = 1'b0;
        alu_op      = ALU_ADD;

        mdu_cmd     = MDUCMD_NONE;
        is_syscall  = 1'b0;

        id_is_ctrl  = 1'b0;
        id_uses_rs  = 1'b0;
        id_uses_rt  = 1'b0;

        unique case (op)
            OPC_RTYPE: begin
                unique case (funct)
                    FUNCT_ADD, FUNCT_ADDU: begin
                        reg_write = 1'b1;
                        dest      = rd;
                        wb_sel    = WB_ALU;
                        alu_op    = ALU_ADD;
                        alu_src_imm = 1'b0;
                    end
                    FUNCT_SUB, FUNCT_SUBU: begin
                        reg_write = 1'b1;
                        dest      = rd;
                        wb_sel    = WB_ALU;
                        alu_op    = ALU_SUB;
                        alu_src_imm = 1'b0;
                    end
                    FUNCT_AND: begin
                        reg_write = 1'b1;
                        dest      = rd;
                        wb_sel    = WB_ALU;
                        alu_op    = ALU_AND;
                        alu_src_imm = 1'b0;
                    end
                    FUNCT_OR: begin
                        reg_write = 1'b1;
                        dest      = rd;
                        wb_sel    = WB_ALU;
                        alu_op    = ALU_OR;
                        alu_src_imm = 1'b0;
                    end
                    FUNCT_XOR: begin
                        reg_write = 1'b1;
                        dest      = rd;
                        wb_sel    = WB_ALU;
                        alu_op    = ALU_XOR;
                        alu_src_imm = 1'b0;
                    end
                    FUNCT_NOR: begin
                        reg_write = 1'b1;
                        dest      = rd;
                        wb_sel    = WB_ALU;
                        alu_op    = ALU_NOR;
                        alu_src_imm = 1'b0;
                    end
                    FUNCT_SLT: begin
                        reg_write = 1'b1;
                        dest      = rd;
                        wb_sel    = WB_ALU;
                        alu_op    = ALU_SLT;
                        alu_src_imm = 1'b0;
                    end
                    FUNCT_SLTU: begin
                        reg_write = 1'b1;
                        dest      = rd;
                        wb_sel    = WB_ALU;
                        alu_op    = ALU_SLTU;
                        alu_src_imm = 1'b0;
                    end
                    FUNCT_SLL: begin
                        reg_write = 1'b1;
                        dest      = rd;
                        wb_sel    = WB_ALU;
                        alu_op    = ALU_SLL;
                        alu_src_imm = 1'b0;
                    end
                    FUNCT_SRL: begin
                        reg_write = 1'b1;
                        dest      = rd;
                        wb_sel    = WB_ALU;
                        alu_op    = ALU_SRL;
                        alu_src_imm = 1'b0;
                    end
                    FUNCT_SRA: begin
                        reg_write = 1'b1;
                        dest      = rd;
                        wb_sel    = WB_ALU;
                        alu_op    = ALU_SRA;
                        alu_src_imm = 1'b0;
                    end
                    FUNCT_SLLV: begin
                        reg_write = 1'b1;
                        dest      = rd;
                        wb_sel    = WB_ALU;
                        alu_op    = ALU_SLLV;
                        alu_src_imm = 1'b0;
                    end
                    FUNCT_SRLV: begin
                        reg_write = 1'b1;
                        dest      = rd;
                        wb_sel    = WB_ALU;
                        alu_op    = ALU_SRLV;
                        alu_src_imm = 1'b0;
                    end
                    FUNCT_SRAV: begin
                        reg_write = 1'b1;
                        dest      = rd;
                        wb_sel    = WB_ALU;
                        alu_op    = ALU_SRAV;
                        alu_src_imm = 1'b0;
                    end
                    FUNCT_JR: begin
                        id_is_ctrl = 1'b1;
                        id_uses_rs = 1'b1;
                    end
                    FUNCT_JALR: begin
                        id_is_ctrl = 1'b1;
                        id_uses_rs = 1'b1;
                        reg_write  = 1'b1;
                        dest       = rd;       // IMPORTANT: allow rd==0 (still should print)
                        wb_sel     = WB_LINK;
                    end
                    FUNCT_SYSCALL: begin
                        is_syscall = 1'b1;
                        // No reg/mem side effects besides syscall handling at commit
                    end
                    FUNCT_MULT: begin
                        mdu_cmd = MDUCMD_START_SIGNED_MUL;
                    end
                    FUNCT_MULTU: begin
                        mdu_cmd = MDUCMD_START_UNSIGNED_MUL;
                    end
                    FUNCT_DIV: begin
                        mdu_cmd = MDUCMD_START_SIGNED_DIV;
                    end
                    FUNCT_DIVU: begin
                        mdu_cmd = MDUCMD_START_UNSIGNED_DIV;
                    end
                    FUNCT_MFHI: begin
                        reg_write = 1'b1;
                        dest      = rd;
                        wb_sel    = WB_MDU;
                        mdu_cmd   = MDUCMD_READ_HI;
                    end
                    FUNCT_MFLO: begin
                        reg_write = 1'b1;
                        dest      = rd;
                        wb_sel    = WB_MDU;
                        mdu_cmd   = MDUCMD_READ_LO;
                    end
                    FUNCT_MTHI: begin
                        mdu_cmd   = MDUCMD_WRITE_HI;
                    end
                    FUNCT_MTLO: begin
                        mdu_cmd   = MDUCMD_WRITE_LO;
                    end
                    default: begin
                        // unsupported funct -> NOP
                    end
                endcase
            end

            // Immediate ALU
            OPC_ADDI, OPC_ADDIU: begin
                reg_write   = 1'b1;
                dest        = rt;
                wb_sel      = WB_ALU;
                alu_op      = ALU_ADD;
                alu_src_imm = 1'b1;
                imm_ext     = {{16{imm[15]}}, imm};
            end
            OPC_ANDI: begin
                reg_write   = 1'b1;
                dest        = rt;
                wb_sel      = WB_ALU;
                alu_op      = ALU_AND;
                alu_src_imm = 1'b1;
                imm_ext     = {16'h0000, imm};
            end
            OPC_ORI: begin
                reg_write   = 1'b1;
                dest        = rt;
                wb_sel      = WB_ALU;
                alu_op      = ALU_OR;
                alu_src_imm = 1'b1;
                imm_ext     = {16'h0000, imm};
            end
            OPC_XORI: begin
                reg_write   = 1'b1;
                dest        = rt;
                wb_sel      = WB_ALU;
                alu_op      = ALU_XOR;
                alu_src_imm = 1'b1;
                imm_ext     = {16'h0000, imm};
            end
            OPC_SLTI: begin
                reg_write   = 1'b1;
                dest        = rt;
                wb_sel      = WB_ALU;
                alu_op      = ALU_SLT;
                alu_src_imm = 1'b1;
                imm_ext     = {{16{imm[15]}}, imm};
            end
            OPC_SLTIU: begin
                reg_write   = 1'b1;
                dest        = rt;
                wb_sel      = WB_ALU;
                alu_op      = ALU_SLTU;
                alu_src_imm = 1'b1;
                imm_ext     = {{16{imm[15]}}, imm};
            end
            OPC_LUI: begin
                reg_write   = 1'b1;
                dest        = rt;
                wb_sel      = WB_ALU;
                alu_op      = ALU_LUI;
                alu_src_imm = 1'b1;
                imm_ext     = {16'h0000, imm};
            end

            // Loads
            OPC_LB, OPC_LBU, OPC_LH, OPC_LHU, OPC_LW: begin
                reg_write   = 1'b1;
                dest        = rt;
                wb_sel      = WB_MEM;
                mem_read    = 1'b1;
                mem_write   = 1'b0;
                alu_op      = ALU_ADD;
                alu_src_imm = 1'b1;
                imm_ext     = {{16{imm[15]}}, imm};
                unique case (op)
                    OPC_LW:  begin mem_width = MEM_W; mem_unsigned = 1'b0; end
                    OPC_LH:  begin mem_width = MEM_H; mem_unsigned = 1'b0; end
                    OPC_LHU: begin mem_width = MEM_H; mem_unsigned = 1'b1; end
                    OPC_LB:  begin mem_width = MEM_B; mem_unsigned = 1'b0; end
                    OPC_LBU: begin mem_width = MEM_B; mem_unsigned = 1'b1; end
                    default: begin mem_width = MEM_W; mem_unsigned = 1'b0; end
                endcase
            end

            // Stores
            OPC_SB, OPC_SH, OPC_SW: begin
                reg_write   = 1'b0;
                mem_read    = 1'b0;
                mem_write   = 1'b1;
                alu_op      = ALU_ADD;
                alu_src_imm = 1'b1;
                imm_ext     = {{16{imm[15]}}, imm};
                unique case (op)
                    OPC_SW: begin mem_width = MEM_W; end
                    OPC_SH: begin mem_width = MEM_H; end
                    OPC_SB: begin mem_width = MEM_B; end
                    default: mem_width = MEM_W;
                endcase
            end

            // Branches (resolved in ID with delay slot)
            OPC_BEQ: begin
                id_is_ctrl = 1'b1;
                id_uses_rs = 1'b1;
                id_uses_rt = 1'b1;
            end
            OPC_BNE: begin
                id_is_ctrl = 1'b1;
                id_uses_rs = 1'b1;
                id_uses_rt = 1'b1;
            end
            OPC_BLEZ: begin
                id_is_ctrl = 1'b1;
                id_uses_rs = 1'b1;
            end
            OPC_BGTZ: begin
                id_is_ctrl = 1'b1;
                id_uses_rs = 1'b1;
            end
            OPC_REGIMM: begin
                if (rt_field == RT_BLTZ || rt_field == RT_BGEZ) begin
                    id_is_ctrl = 1'b1;
                    id_uses_rs = 1'b1;
                end
            end

            // Jumps (resolved in ID with delay slot)
            OPC_J: begin
                id_is_ctrl = 1'b1;
            end
            OPC_JAL: begin
                id_is_ctrl = 1'b1;
                reg_write  = 1'b1;
                dest       = 5'd31;
                wb_sel     = WB_LINK;
            end

            default: begin
                // unsupported opcode -> NOP
            end
        endcase
    end
endmodule
