`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/12/15 21:45:32
// Design Name: 
// Module Name: InstructionMemory
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

module InstructionMemory(
    input  logic clock,
    input  logic reset,
    input  addr_t addr,
    output word_t rdata
);

    localparam int IM_DEPTH_WORDS = 2048;
    localparam word_t BASE_PC = RESET_PC;

    word_t mem [0:IM_DEPTH_WORDS-1];

    initial begin
        integer i;
        for (i = 0; i < IM_DEPTH_WORDS; i = i + 1) begin
            mem[i] = 32'h0000_0000;
        end
        $readmemh("code.txt", mem);
    end

    always_comb begin
        rdata = 32'h0000_0000;
        if (addr >= BASE_PC) begin
            int unsigned idx;
            idx = (addr - BASE_PC) >> 2;
            if (idx < IM_DEPTH_WORDS) begin
                rdata = mem[idx];
            end
        end
    end
endmodule
