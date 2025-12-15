`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/12/15 21:45:11
// Design Name: 
// Module Name: TopLevel
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

module TopLevel(
    input  logic reset,
    input  logic clock
);

    // Instruction memory interface
    word_t imem_addr;
    word_t imem_rdata;

    // Data memory interface (word-granularity)
    word_t dmem_addr_aligned;
    word_t dmem_rdata_word;
    logic  dmem_we_word;
    word_t dmem_wdata_word;

    InstructionMemory u_imem (
        .clock (clock),
        .reset (reset),
        .addr  (imem_addr),
        .rdata (imem_rdata)
    );

    DataMemory u_dmem (
        .clock        (clock),
        .reset        (reset),
        .addr_aligned (dmem_addr_aligned),
        .rdata_word   (dmem_rdata_word),
        .we_word      (dmem_we_word),
        .wdata_word   (dmem_wdata_word)
    );

    PipelineCPU u_cpu (
        .reset             (reset),
        .clock             (clock),
        .imem_addr         (imem_addr),
        .imem_rdata        (imem_rdata),
        .dmem_addr_aligned (dmem_addr_aligned),
        .dmem_rdata_word   (dmem_rdata_word),
        .dmem_we_word      (dmem_we_word),
        .dmem_wdata_word   (dmem_wdata_word)
    );
endmodule
