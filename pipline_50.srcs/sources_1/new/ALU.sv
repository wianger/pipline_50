`timescale 1us/1us
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/12/15 21:48:34
// Design Name: 
// Module Name: ALU
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

module ALU(
    input  word_t   a,
    input  word_t   b,
    input  logic [4:0] shamt,
    input  alu_op_t op,
    output word_t   y
);

    always_comb begin
        unique case (op)
            ALU_ADD:  y = a + b;
            ALU_SUB:  y = a - b;
            ALU_AND:  y = a & b;
            ALU_OR:   y = a | b;
            ALU_XOR:  y = a ^ b;
            ALU_NOR:  y = ~(a | b);
            ALU_SLT:  y = ($signed(a) < $signed(b)) ? 32'h0000_0001 : 32'h0000_0000;
            ALU_SLTU: y = (a < b) ? 32'h0000_0001 : 32'h0000_0000;

            // Immediate shifts: use shamt
            ALU_SLL:  y = b << shamt;
            ALU_SRL:  y = b >> shamt;
            ALU_SRA:  y = $signed(b) >>> shamt;

            // Variable shifts: use a[4:0] as shift amount
            ALU_SLLV: y = b << a[4:0];
            ALU_SRLV: y = b >> a[4:0];
            ALU_SRAV: y = $signed(b) >>> a[4:0];

            ALU_LUI:  y = {b[15:0], 16'h0000};

            default:  y = 32'h0000_0000;
        endcase
    end
endmodule
