`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/12/15 21:49:12
// Design Name: 
// Module Name: ForwardUnit
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

module ForwardUnit(
    // ID stage sources
    input  reg_addr_t id_rs,
    input  reg_addr_t id_rt,

    // EX stage sources (current instruction in EX)
    input  reg_addr_t ex_rs,
    input  reg_addr_t ex_rt,

    // EX stage destination (instruction currently in EX, used for ID-stage forwarding)
    input  logic      ex_reg_write,
    input  logic      ex_is_load,
    input  reg_addr_t ex_dest,

    // MEM stage destination
    input  logic      mem_reg_write,
    input  reg_addr_t mem_dest,

    // WB stage destination
    input  logic      wb_reg_write,
    input  reg_addr_t wb_dest,

    // ID forwarding selects: 00=RF, 01=EX, 10=MEM, 11=WB
    output logic [1:0] fwd_id_rs_sel,
    output logic [1:0] fwd_id_rt_sel,

    // EX forwarding selects: 00=IDEX, 01=MEM, 10=WB
    output logic [1:0] fwd_ex_rs_sel,
    output logic [1:0] fwd_ex_rt_sel
);

    always_comb begin
        // Defaults
        fwd_id_rs_sel = 2'b00;
        fwd_id_rt_sel = 2'b00;
        fwd_ex_rs_sel = 2'b00;
        fwd_ex_rt_sel = 2'b00;

        // -------------------------
        // ID stage forwarding
        // -------------------------
        if (id_rs != 0) begin
            if (ex_reg_write && !ex_is_load && (ex_dest != 0) && (ex_dest == id_rs)) begin
                fwd_id_rs_sel = 2'b01;
            end else if (mem_reg_write && (mem_dest != 0) && (mem_dest == id_rs)) begin
                fwd_id_rs_sel = 2'b10;
            end else if (wb_reg_write && (wb_dest != 0) && (wb_dest == id_rs)) begin
                fwd_id_rs_sel = 2'b11;
            end
        end

        if (id_rt != 0) begin
            if (ex_reg_write && !ex_is_load && (ex_dest != 0) && (ex_dest == id_rt)) begin
                fwd_id_rt_sel = 2'b01;
            end else if (mem_reg_write && (mem_dest != 0) && (mem_dest == id_rt)) begin
                fwd_id_rt_sel = 2'b10;
            end else if (wb_reg_write && (wb_dest != 0) && (wb_dest == id_rt)) begin
                fwd_id_rt_sel = 2'b11;
            end
        end

        // -------------------------
        // EX stage forwarding
        // -------------------------
        if (ex_rs != 0) begin
            if (mem_reg_write && (mem_dest != 0) && (mem_dest == ex_rs)) begin
                fwd_ex_rs_sel = 2'b01;
            end else if (wb_reg_write && (wb_dest != 0) && (wb_dest == ex_rs)) begin
                fwd_ex_rs_sel = 2'b10;
            end
        end

        if (ex_rt != 0) begin
            if (mem_reg_write && (mem_dest != 0) && (mem_dest == ex_rt)) begin
                fwd_ex_rt_sel = 2'b01;
            end else if (wb_reg_write && (wb_dest != 0) && (wb_dest == ex_rt)) begin
                fwd_ex_rt_sel = 2'b10;
            end
        end
    end
endmodule
