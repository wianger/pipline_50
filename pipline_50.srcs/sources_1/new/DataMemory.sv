`timescale 1us/1us
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/12/15 21:46:51
// Design Name: 
// Module Name: DataMemory
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

module DataMemory(
    input  logic clock,
    input  logic reset,
    input  addr_t addr_aligned,
    output word_t rdata_word,
    input  logic we_word,
    input  word_t wdata_word
);

    localparam int DM_DEPTH_WORDS = 2048;

    word_t mem [0:DM_DEPTH_WORDS-1];

    initial begin
        integer i;
        for (i = 0; i < DM_DEPTH_WORDS; i = i + 1) begin
            mem[i] = 32'h0000_0000;
        end
        $readmemh("data.txt", mem);
    end

    // Combinational read (word addressed)
    localparam int DM_WORD_INDEX_BITS = $clog2(DM_DEPTH_WORDS); // 11 for 2048
    wire [DM_WORD_INDEX_BITS-1:0] word_index = addr_aligned[DM_WORD_INDEX_BITS+1:2];
    wire dm_in_range = (addr_aligned[31:DM_WORD_INDEX_BITS+2] == '0);

    always_comb begin
        rdata_word = 32'h0000_0000;
        if (dm_in_range) begin
            rdata_word = mem[word_index];
        end
    end

    // Synchronous word write
    always_ff @(posedge clock) begin
        if (we_word && dm_in_range) begin
            mem[word_index] <= wdata_word;
        end
    end
endmodule
