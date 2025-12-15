`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/12/15 21:49:51
// Design Name: 
// Module Name: TraceCommit
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

module TraceCommit(
    input logic  clock,
    input logic  reset,

    input logic  wb_valid,
    input word_t wb_pc,

    // Register writeback trace
    input logic      wb_reg_write,
    input reg_addr_t wb_waddr,
    input word_t     wb_wdata,

    // Memory write trace (whole-word view)
    input logic  wb_mem_write_commit,
    input word_t wb_mem_write_addr_aligned,
    input word_t wb_mem_write_data_word,

    // Syscall commit
    input logic  wb_is_syscall,
    input word_t rf_v0_value,
    input word_t rf_a0_value
);

    // NOTE: this is a simulation-only commit logger (uses $display / $finish).
    // Use plain always @(posedge clock) so we can legally use #delay before $finish.
    always @(posedge clock) begin
        if (!reset) begin
            if (wb_valid) begin
                if (wb_reg_write) begin
                    $display("@%08h: $%2d <= %08h", wb_pc, wb_waddr, wb_wdata);
                end
                if (wb_mem_write_commit) begin
                    $display("@%08h: *%08h <= %08h", wb_pc, wb_mem_write_addr_aligned, wb_mem_write_data_word);
                end

                if (wb_is_syscall) begin
                    if (rf_v0_value == 32'd1) begin
                        // MARS syscall 1: print integer in $a0
                        $display("%0d", $signed(rf_a0_value));
                    end
                    if (rf_v0_value == 32'd10) begin
                        // MARS syscall 10: exit
                        #1 $finish;
                    end
                end
            end
        end
    end
endmodule
