`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC CS
// Engineer: Zhu Ying
// 
// Design Name: RISCV-Pipline CPU
// Module Name: ImmOperandUnit
// Target Devices: Nexys4
// Description: Generate different type of Immediate Operand
//////////////////////////////////////////////////////////////////////////////////

//Already Completed

`include "Parameters.v"   
module ImmOperandUnit(
    input wire [31:7] In,
    input wire [2:0] Type,
    output reg [31:0] Out
    );
    //Use Code From Lab 1
    always@(*)
    begin
        case(Type)
            `UTYPE: Out<={ In[31:12], 12'b0 };
            `ITYPE: Out<={ {20{In[31]}}, In[31:20] };
            `STYPE: Out<={ {20{In[31]}}, In[31:25], In[11:7] };
            `BTYPE: Out<={ {20{In[31]}}, In[7], In[30:25], In[11:8], 1'b0 };
            `JTYPE: Out<={ {12{In[31]}}, In[19:12], In[20], In[30:21], 1'b0 };
            default:Out<=32'hxxxxxxxx;
        endcase
    end
    
endmodule

