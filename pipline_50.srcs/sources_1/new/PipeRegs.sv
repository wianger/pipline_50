`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/12/15 21:47:35
// Design Name: 
// Module Name: PipeRegs
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

module PipeRegIFID(
    input  logic clock,
    input  logic reset,
    input  logic en,
    input  logic flush,
    input  if_id_t d,
    output if_id_t q
);
    always_ff @(posedge clock) begin
        if (reset) begin
            q <= '0;
        end else if (flush) begin
            q <= '0;
        end else if (en) begin
            q <= d;
        end
    end
endmodule

module PipeRegIDEX(
    input  logic clock,
    input  logic reset,
    input  logic en,
    input  logic flush,
    input  id_ex_t d,
    output id_ex_t q
);
    always_ff @(posedge clock) begin
        if (reset) begin
            q <= '0;
        end else if (flush) begin
            q <= '0;
        end else if (en) begin
            q <= d;
        end
    end
endmodule

module PipeRegEXMEM(
    input  logic clock,
    input  logic reset,
    input  logic en,
    input  logic flush,
    input  ex_mem_t d,
    output ex_mem_t q
);
    always_ff @(posedge clock) begin
        if (reset) begin
            q <= '0;
        end else if (flush) begin
            q <= '0;
        end else if (en) begin
            q <= d;
        end
    end
endmodule

module PipeRegMEMWB(
    input  logic clock,
    input  logic reset,
    input  logic en,
    input  logic flush,
    input  mem_wb_t d,
    output mem_wb_t q
);
    always_ff @(posedge clock) begin
        if (reset) begin
            q <= '0;
        end else if (flush) begin
            q <= '0;
        end else if (en) begin
            q <= d;
        end
    end
endmodule

module PipeRegs(

    );
endmodule
