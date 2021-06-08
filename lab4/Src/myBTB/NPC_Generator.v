`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC CS
// Engineer: Zhu Ying
// 
// Design Name: RISCV-Pipline CPU
// Module Name: NPC_Generator
// Target Devices: Nexys4
// Description: Choose Next PC value
//////////////////////////////////////////////////////////////////////////////////

//Already completed

module NPC_Generator(
    input wire [31:0] PCF,JalrTarget, BranchTarget, JalTarget,
    input wire BranchE,JalD,JalrE,
    output reg [31:0] PC_In,
    // BTB
    input clk,rst,
    input wire BrInstr_EX,
    input wire BTB_hit_EX,
    input wire StallF,
    input [31:0] PCE,
    output wire BTB_hit
    );
    
    // signals
    wire [31:0] BTB_NPC;
    wire BTB_fail;

    // EX jumps are prior than others because they are earlier
    always@(*) 
    begin
        if(JalrE) PC_In <= JalrTarget;
        else if(!BranchE && BTB_fail) PC_In <= PCE + 4;
        else if(BranchE && BTB_fail) PC_In <= BranchTarget;
        else if(JalD) PC_In <= JalTarget;
        else if(BTB_hit) PC_In <= BTB_NPC;
        else PC_In <= PCF + 4; 
    end

    BTB BTBinst(
        .clk(clk),
        .rst(rst),
        .PCE(PCE),
        .PC(PCF),
        .StallF(StallF),
        .Branch(BranchE),
        .BranchTarget(BranchTarget),
        .BTB_hit(BTB_hit),
        .BTB_NPC(BTB_NPC),
        .BTB_fail(BTB_fail),
        .BTB_hit_EX(BTB_hit_EX),
        .BrInstr_EX(BrInstr_EX)
    );
    
endmodule
