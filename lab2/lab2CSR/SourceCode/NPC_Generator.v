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
    output reg [31:0] PC_In
    );
    
    // EX jumps are prior than others because they are earlier
    always@(*) 
    begin
        if(JalrE) PC_In <= JalrTarget;
        else if(BranchE) PC_In <= BranchTarget;
        else if(JalD) PC_In <= JalTarget;
        else PC_In <= PCF + 4; 
    end
    
endmodule
