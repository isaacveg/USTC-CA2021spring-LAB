`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC CS
// Engineer: Zhu Ying
// 
// Design Name: RISCV-Pipline CPU
// Module Name: DataExt 
// Target Devices: Nexys4
// Description: Data Extension module
//////////////////////////////////////////////////////////////////////////////////

`include "Parameters.v"   
module DataExt(
    input wire [31:0] IN,
    input wire [1:0] LoadedBytesSelect,
    input wire [2:0] RegWriteW,
    output reg [31:0] OUT
    );    
        
    // Already Completed
    wire [31:0] LoadByte;
    wire [31:0] LoadHlfWd;
    assign LoadByte = (IN >> (LoadedBytesSelect * 8)) & 32'h000000ff;
    assign LoadHlfWd = (IN >> (LoadedBytesSelect * 8)) & 32'h0000ffff;
    
    always @(*)
    begin
        case(RegWriteW)
            `LW:    OUT <= IN;
            `LBU:   OUT <= LoadByte;
            `LHU:   OUT <= LoadHlfWd;
            `LB:	OUT <= {{24{LoadByte[7]}},LoadByte[7:0]};
            `LH:    OUT <= {{16{LoadHlfWd[15]}},LoadHlfWd[15:0]};
            default:OUT = 32'hxxxxxxxx;
        endcase
    end

endmodule

