`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/05/21 10:17:43
// Design Name: 
// Module Name: StateBuf
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


module BHT(
    input clk, rst, StallF,
    input [31:0]PC,PCE,
    input Branch, BrInstr_EX,
    output reg BHT_jump
    );
    
    // local parameters
    localparam ADDR_LEN = 10;
    localparam BUFFER_SIZE = 1 << ADDR_LEN;
    reg [1:0] StateBuf[BUFFER_SIZE-1:0];
    wire [ADDR_LEN-1:0] PC_ADDR;
    wire [ADDR_LEN-1:0] BranchPC_ADDR;
    // Buffer Addr
    assign PC_ADDR = PC[ADDR_LEN+1:2];
    assign BranchPC_ADDR = PCE[ADDR_LEN+1:2];
    // initialize
    integer i;
    initial begin
        for (i = 0;i < BUFFER_SIZE;i = i+1) begin
            StateBuf[i] <= 0;
        end
    end
    // State Machine
    always @ (posedge clk) begin
        if ( !rst && !StallF && BrInstr_EX) begin
            if (StateBuf[BranchPC_ADDR]!=2'b11 || StateBuf[BranchPC_ADDR]!=2'b00 )
                StateBuf[BranchPC_ADDR] <= Branch? StateBuf[BranchPC_ADDR]+1 : StateBuf[BranchPC_ADDR]-1;
            else if (StateBuf[BranchPC_ADDR]==2'b11) 
                StateBuf[BranchPC_ADDR] <= Branch? StateBuf[BranchPC_ADDR] : StateBuf[BranchPC_ADDR]-1;
            else StateBuf[BranchPC_ADDR] <= Branch? StateBuf[BranchPC_ADDR]+1 : StateBuf[BranchPC_ADDR];
        end
    end
    // BHT signal
    always @ (*) begin
        if (!StallF) begin
            if (!rst && StateBuf[PC_ADDR][1]) BHT_jump <= 1;
            else BHT_jump <= 0;
        end        
    end

endmodule
