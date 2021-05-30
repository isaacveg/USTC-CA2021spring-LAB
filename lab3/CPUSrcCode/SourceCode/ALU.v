`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC CS
// Engineer: Zhu Ying
// 
// Design Name: RISCV-Pipline CPU
// Module Name: ALU
// Target Devices: Nexys4
// Description: ALU unit of RISCV CPU
//////////////////////////////////////////////////////////////////////////////////


`include "Parameters.v"   
module ALU(
    input wire [31:0] Operand1,
    input wire [31:0] Operand2,
    input wire [3:0] AluContrl,
    output reg [31:0] AluOut
    );    
    
    // Already Completed
    always@(*)
    case(AluContrl)
        `ADD: AluOut <= Operand1 + Operand2;
        `SUB: AluOut <= Operand1 - Operand2;
        `SLL: AluOut <= Operand1 << (Operand2[4:0]);
        `SRL: AluOut <= Operand1 >> (Operand2[4:0]);
        `SRA: AluOut <= $signed(Operand1) >>> (Operand2[4:0]);
        `XOR: AluOut <= Operand1 ^ Operand2;
        `OR : AluOut <= Operand1 | Operand2;
        `AND: AluOut <= Operand1 & Operand2;
        `SLT: AluOut <= $signed(Operand1) < $signed(Operand2) ? 32'b1:32'b0;
        `SLTU:AluOut <= Operand1 < Operand2 ? 32'b1:32'b0;
        `LUI: AluOut <= {Operand2[31:12],12'b0};
        default: AluOut <= 32'hxxxxxxxx;    //Unkown 32 bits
    endcase

endmodule

