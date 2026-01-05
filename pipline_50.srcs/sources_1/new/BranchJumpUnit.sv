`timescale 1us/1us
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/12/15 21:48:54
// Design Name: 
// Module Name: BranchJumpUnit
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

module BranchJumpUnit(
    input  word_t pc,
    input  word_t instr,
    input  word_t rs_val,
    input  word_t rt_val,
    output logic  redirect,
    output word_t redirect_target
);

    logic [5:0] op;
    logic [5:0] funct;
    logic [4:0] rt_field;
    logic [15:0] imm;
    logic [25:0] target;

    word_t pc_plus4;
    word_t imm_sext;
    word_t branch_target;
    word_t jump_target;

    logic take_branch;

    always_comb begin
        op       = instr[31:26];
        funct    = instr[5:0];
        rt_field = instr[20:16];
        imm      = instr[15:0];
        target   = instr[25:0];

        pc_plus4 = pc + 32'd4;
        imm_sext = {{16{imm[15]}}, imm};

        branch_target = pc_plus4 + (imm_sext << 2);
        jump_target   = {pc_plus4[31:28], target, 2'b00};

        take_branch = 1'b0;
        redirect = 1'b0;
        redirect_target = 32'h0000_0000;

        unique case (op)
            OPC_BEQ:  take_branch = (rs_val == rt_val);
            OPC_BNE:  take_branch = (rs_val != rt_val);
            OPC_BLEZ: take_branch = ($signed(rs_val) <= 0);
            OPC_BGTZ: take_branch = ($signed(rs_val) > 0);
            OPC_REGIMM: begin
                if (rt_field == RT_BLTZ) take_branch = ($signed(rs_val) < 0);
                else if (rt_field == RT_BGEZ) take_branch = ($signed(rs_val) >= 0);
            end
            default: take_branch = 1'b0;
        endcase

        // Branch redirect (with delay slot: affects next cycle fetch only)
        if (take_branch) begin
            redirect = 1'b1;
            redirect_target = branch_target;
        end else begin
            // Jump / JR / JAL / JALR redirect
            unique case (op)
                OPC_J, OPC_JAL: begin
                    redirect = 1'b1;
                    redirect_target = jump_target;
                end
                OPC_RTYPE: begin
                    if (funct == FUNCT_JR || funct == FUNCT_JALR) begin
                        redirect = 1'b1;
                        redirect_target = rs_val;
                    end
                end
                default: begin
                    redirect = 1'b0;
                    redirect_target = 32'h0000_0000;
                end
            endcase
        end
    end
endmodule
