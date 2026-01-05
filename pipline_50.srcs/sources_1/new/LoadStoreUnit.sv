`timescale 1us/1us
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/12/15 21:49:38
// Design Name: 
// Module Name: LoadStoreUnit
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

module LoadStoreUnit(
    input  word_t addr,        // byte address (may be unaligned)
    input  word_t store_data,  // original store data (rt value)
    input  word_t rdata_word,  // word read from memory at addr_aligned

    input  logic is_load,
    input  logic is_store,
    input  mem_width_t width,
    input  logic mem_unsigned,

    output word_t load_data,
    output word_t addr_aligned,
    output logic  we_word,
    output word_t wdata_word
);

    logic [1:0] byte_off;
    logic       half_sel;

    logic [7:0]  byte_val;
    logic [15:0] half_val;

    always_comb begin
        addr_aligned = {addr[31:2], 2'b00};
        byte_off = addr[1:0];
        half_sel = addr[1];

        // -------------------------
        // Load path
        // -------------------------
        load_data = 32'h0000_0000;
        byte_val  = 8'h00;
        half_val  = 16'h0000;

        if (is_load) begin
            unique case (width)
                MEM_W: begin
                    load_data = rdata_word;
                end
                MEM_H: begin
                    half_val = half_sel ? rdata_word[31:16] : rdata_word[15:0];
                    if (mem_unsigned) load_data = {16'h0000, half_val};
                    else load_data = {{16{half_val[15]}}, half_val};
                end
                MEM_B: begin
                    unique case (byte_off)
                        2'd0: byte_val = rdata_word[7:0];
                        2'd1: byte_val = rdata_word[15:8];
                        2'd2: byte_val = rdata_word[23:16];
                        2'd3: byte_val = rdata_word[31:24];
                        default: byte_val = 8'h00;
                    endcase
                    if (mem_unsigned) load_data = {24'h000000, byte_val};
                    else load_data = {{24{byte_val[7]}}, byte_val};
                end
                default: load_data = rdata_word;
            endcase
        end

        // -------------------------
        // Store path (word write with merge)
        // -------------------------
        we_word    = is_store;
        wdata_word = rdata_word;

        if (is_store) begin
            unique case (width)
                MEM_W: begin
                    wdata_word = store_data;
                end
                MEM_H: begin
                    if (!half_sel) begin
                        // offset 0: replace low half
                        wdata_word = {rdata_word[31:16], store_data[15:0]};
                    end else begin
                        // offset 2: replace high half
                        wdata_word = {store_data[15:0], rdata_word[15:0]};
                    end
                end
                MEM_B: begin
                    unique case (byte_off)
                        2'd0: wdata_word = {rdata_word[31:8],  store_data[7:0]};
                        2'd1: wdata_word = {rdata_word[31:16], store_data[7:0], rdata_word[7:0]};
                        2'd2: wdata_word = {rdata_word[31:24], store_data[7:0], rdata_word[15:0]};
                        2'd3: wdata_word = {store_data[7:0],   rdata_word[23:0]};
                        default: wdata_word = rdata_word;
                    endcase
                end
                default: wdata_word = store_data;
            endcase
        end
    end
endmodule
