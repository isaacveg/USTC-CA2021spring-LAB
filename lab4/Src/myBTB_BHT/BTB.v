`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/05/20 19:50:51
// Design Name: 
// Module Name: BTB
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


module BTB(
    input wire clk, rst,
    input wire Branch, BrInstr_EX, StallF,
    input wire [31:0] BranchTarget, PCE, PC,
    input wire BTB_hit_EX, jump_EX,
    output reg BTB_hit,
    output reg [31:0] BTB_NPC
    );
    
    // Buffer 
    localparam ADDR_LEN = 10;
    localparam BUFFER_SIZE = 1 << ADDR_LEN; // Buffer大小
    wire [ADDR_LEN-1:0] PC_ADDR, BranchPC_ADDR;
    reg [31-ADDR_LEN:0] BTBTAG [BUFFER_SIZE-1:0];  // Tag
    reg [31:0] BTBNPC [BUFFER_SIZE-1:0];      // 产生的预�? PC
    reg BTBvalid [BUFFER_SIZE-1:0];       // 是否有效
    wire BHT_jump;
    
    // 初始�?
    integer k;
    initial begin
        for (k = 0;k < BUFFER_SIZE;k = k + 1) begin
            BTBTAG[k] <= 0;
            BTBNPC[k] <= 0;
            BTBvalid[k] <= 0;
        end
    end
        
    assign PC_ADDR = PC[ADDR_LEN+1:2];
    assign BranchPC_ADDR = PCE[ADDR_LEN+1:2];

    // 产生hit和读出内�?   
    integer i;
    always@(*) begin 
        if (!rst && BTBvalid[PC_ADDR] && BTBTAG[PC_ADDR] == PC[31:ADDR_LEN]) begin
            BTB_hit <= 1;
            BTB_NPC <= BTBNPC[PC_ADDR];
        end 
        else begin
            BTB_hit <= 0;
            BTB_NPC <= 0;
        end
    end

    // 更新内容
    reg BTB_Del,BTB_Wr;
    always@(*) begin
        if (rst) begin
            BTB_Wr <= 0;
            BTB_Del <= 0;
        end
        else begin
            if (!BTB_hit_EX && BrInstr_EX && Branch) BTB_Wr <= 1;
            else BTB_Wr <= 0;
            if (BTB_hit_EX && BrInstr_EX && Branch) BTB_Del <= 1;
            else BTB_Del <= 0; 
        end
   end

    integer j;
    always@(posedge clk) begin
        if (!StallF) begin
            if (rst) begin       // reset
                for (j = 0;j < BUFFER_SIZE;j = j + 1) begin
                    BTBTAG[j] <= 0;
                    BTBNPC[j] <= 0;
                    BTBvalid[j] <= 0;
                end
            end
            else begin      // 写入未预测的跳转指令
                if (BTB_Wr && Branch) begin
                    BTBTAG[BranchPC_ADDR] <= PCE[31:ADDR_LEN];
                    BTBNPC[BranchPC_ADDR] <= BranchTarget;
                    BTBvalid[BranchPC_ADDR] <= 1;
                end
            end
        end
    end
endmodule
