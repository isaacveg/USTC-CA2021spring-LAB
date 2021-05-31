`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC CS
// Engineer: Zhu Ying
// 
// Design Name: RISCV-Pipline CPU
// Module Name: BranchDecisionMaking
// Target Devices: Nexys4
// Description: Decide whether to branch 
//////////////////////////////////////////////////////////////////////////////////

`include "Parameters.v"   
module BranchDecisionMaking(
    input wire [2:0] BranchTypeE,
    input wire [31:0] Operand1,Operand2,
    output reg BranchE
    );
    
    //Already Completed
    always@(*)
    case(BranchTypeE)
        `BEQ:    //Branch On Equal
            if(Operand1 == Operand2)  BranchE <= 1;  
                else    BranchE <= 0;
        `BNE:    //Branch On Not Equal
            if(Operand1 != Operand2)  BranchE <= 1;  
                else    BranchE <= 0; 
        `BLT:    //Less Than
            if($signed(Operand1) < $signed(Operand2)) BranchE <= 1;  
                else    BranchE <= 0;
        `BLTU:   //Unsigned Less Than
            if(Operand1 < Operand2)   BranchE <= 1;  
                else    BranchE <= 0;
        `BGE:    //Greater Than Or Equal
            if($signed(Operand1) >= $signed(Operand2))  BranchE <= 1;  
                else    BranchE<= 0;
        `BGEU:   //Unsigned Greater Then
            if(Operand1 >= Operand2)    BranchE <= 1;  //BGEU
                else    BranchE <= 0;
        default:    BranchE <= 0;  //Do Nothing                
    endcase


endmodule

