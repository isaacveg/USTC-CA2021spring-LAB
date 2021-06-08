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
    input wire Branch,JalD,JalrE,
    output reg [31:0] PC_In,
    // BTB
    input clk,rst,
    input wire BrInstr_EX,
    input wire BTB_hit_EX,
    input wire StallF,
    input [31:0] PCE,
    output wire BTB_hit,jump,
    input wire jump_EX
    );
    
    // signals
    wire [31:0] BTB_NPC;
    wire BTB_fail, BHT_jump;

    // EX jumps are prior than others because they are earlier
    always@(*) 
    begin
        if(JalrE) PC_In <= JalrTarget;
        else if(!Branch && BTB_fail) PC_In <= PCE + 4;
        else if(Branch && BTB_fail) PC_In <= BranchTarget;
        else if(JalD) PC_In <= JalTarget;
        else if(jump) PC_In <= BTB_NPC;
        else PC_In <= PCF + 4; 
    end

    BTB BTBinst(
        .clk(clk),
        .rst(rst),
        .PCE(PCE),
        .PC(PCF),
        .StallF(StallF),
        .Branch(Branch),
        .BranchTarget(BranchTarget),
        .BTB_hit(BTB_hit),
        .BTB_NPC(BTB_NPC),
        .BTB_hit_EX(BTB_hit_EX),
        .BrInstr_EX(BrInstr_EX),
        .jump_EX(jump_EX)
    );

    // 连接 BHT
    BHT BHTinst(
        .clk(clk),
        .rst(rst),
        .StallF(StallF),
        .PC(PCF),
        .PCE(PCE),
        .Branch(Branch),
        .BrInstr_EX(BrInstr_EX),
        .BHT_jump(BHT_jump)
    );

    assign jump = BHT_jump && BTB_hit;

    /////////////////////
    ///////COUNTER//////
    /////////////////////
    assign BTB_fail = (jump_EX == 1 && BrInstr_EX == 1 && Branch == 0) ||
                    (jump_EX == 0 && BrInstr_EX == 1 && Branch == 1);

    reg [31:0] BranchCount, PredictCount, WrongCount, NotPredictedCount, TotalCycle;
    initial begin
        TotalCycle <= 0;
        BranchCount <= 0;
        PredictCount <= 0;
        WrongCount <= 0;
        NotPredictedCount <= 0;
    end

    always@(posedge clk)begin
        if (!rst) TotalCycle <= TotalCycle + 1;
        if (BrInstr_EX && !StallF) BranchCount = BranchCount + 1;
        if (jump_EX) PredictCount = PredictCount + 1;
        if (BTB_fail) WrongCount = WrongCount + 1;
        if (BTB_fail && Branch) NotPredictedCount = NotPredictedCount + 1;
    end

    
endmodule
