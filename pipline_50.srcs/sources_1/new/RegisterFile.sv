`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/12/15 21:47:56
// Design Name: 
// Module Name: RegisterFile
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

module RegisterFile(
    input  logic      clock,
    input  logic      reset,

    input  logic      we,
    input  reg_addr_t waddr,
    input  word_t     wdata,

    input  reg_addr_t raddr1,
    output word_t     rdata1,
    input  reg_addr_t raddr2,
    output word_t     rdata2,

    // Convenience reads for syscall handling
    output word_t     v0_value,
    output word_t     a0_value
);

    word_t regs [0:31];

    integer i;
    always_ff @(posedge clock) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1) begin
                regs[i] <= 32'h0000_0000;
            end
        end else begin
            if (we && (waddr != 0)) begin
                regs[waddr] <= wdata;
            end
        end
    end

    // Asynchronous reads with write-through bypass
    always_comb begin
        // Read port 1
        if (raddr1 == 0) rdata1 = 32'h0000_0000;
        else rdata1 = regs[raddr1];

        if (we && (waddr != 0) && (waddr == raddr1)) begin
            rdata1 = wdata;
        end

        // Read port 2
        if (raddr2 == 0) rdata2 = 32'h0000_0000;
        else rdata2 = regs[raddr2];

        if (we && (waddr != 0) && (waddr == raddr2)) begin
            rdata2 = wdata;
        end

        // v0 ($2) and a0 ($4)
        v0_value = regs[2];
        a0_value = regs[4];
        if (we && (waddr != 0) && (waddr == 5'd2)) v0_value = wdata;
        if (we && (waddr != 0) && (waddr == 5'd4)) a0_value = wdata;
    end
endmodule
