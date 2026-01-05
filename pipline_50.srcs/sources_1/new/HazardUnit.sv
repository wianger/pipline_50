`timescale 1us/1us
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/12/15 21:49:25
// Design Name: 
// Module Name: HazardUnit
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

module HazardUnit(
    // ID stage (control-flow instruction) usage
    input  logic      id_is_ctrl,
    input  logic      id_uses_rs,
    input  logic      id_uses_rt,
    input  reg_addr_t id_rs,
    input  reg_addr_t id_rt,

    // EX stage (for load -> ctrl hazard)
    input  logic      ex_is_load,
    input  logic      ex_reg_write,
    input  reg_addr_t ex_dest,

    // MDU stall (instruction in EX needs MDU, but MDU is busy)
    input  logic      ex_is_mdu,
    input  logic      mdu_busy,

    // Outputs
    output logic stall_pc,
    output logic stall_ifid,
    output logic stall_idex,     // freeze ID/EX (EX-stage stall)
    output logic flush_idex,     // insert bubble into ID/EX (ID-stage stall)
    output logic bubble_exmem    // insert bubble into EX/MEM while EX is stalled
);

    logic ctrl_load_hazard;
    logic mdu_hazard;

    always_comb begin
        // defaults
        stall_pc     = 1'b0;
        stall_ifid   = 1'b0;
        stall_idex   = 1'b0;
        flush_idex   = 1'b0;
        bubble_exmem = 1'b0;

        // EX-stage MDU busy: stall IF/ID/EX, but keep MEM/WB running.
        mdu_hazard = ex_is_mdu && mdu_busy;

        // ID-stage ctrl uses a value being loaded in EX (cannot be forwarded into ID in time).
        ctrl_load_hazard =
            id_is_ctrl &&
            ex_is_load &&
            ex_reg_write &&
            (ex_dest != 0) &&
            ( (id_uses_rs && (ex_dest == id_rs)) ||
              (id_uses_rt && (ex_dest == id_rt)) );

        if (mdu_hazard) begin
            stall_pc     = 1'b1;
            stall_ifid   = 1'b1;
            stall_idex   = 1'b1;   // keep the MDU instruction in EX
            bubble_exmem = 1'b1;   // prevent re-executing the previous MEM stage op
        end else if (ctrl_load_hazard) begin
            stall_pc   = 1'b1;
            stall_ifid = 1'b1;
            flush_idex = 1'b1;     // bubble into EX so the load can proceed
        end
    end
endmodule
