`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC CS
// Engineer: Zhu Ying
// 
// Design Name: RISCV-Pipline CPU
// Module Name: WBSegReg
// Target Devices: Nexys4
// Description: Write Back Segment Register
//////////////////////////////////////////////////////////////////////////////////
//Already completed


module WBSegReg(
    input wire clk,
    input wire en,
    input wire clear,
    input wire rst,
    output wire CacheMiss,
    //Data Memory Access
    input wire [31:0] A,
    input wire [31:0] WD,
    input wire [3:0] WE,
    output wire [31:0] RD,
    output reg [1:0] LoadedBytesSelect,
    //Data Memory Debug
    input wire [31:0] A2,
    input wire [31:0] WD2,
    input wire [3:0] WE2,
    output wire [31:0] RD2,
    //input control signals
    input wire [31:0] ResultM,
    output reg [31:0] ResultW, 
    input wire [4:0] RdM,
    output reg [4:0] RdW,
    //output constrol signals
    input wire [2:0] RegWriteM,
    output reg [2:0] RegWriteW,
    input wire MemToRegM,
    output reg MemToRegW
    );
    
    //
    initial begin
        LoadedBytesSelect = 2'b00;
        RegWriteW         =  1'b0;
        MemToRegW         =  1'b0;
        ResultW           =     0;
        RdW               =  5'b0;
    end
    //
    always@(posedge clk)
        if(en) begin
            LoadedBytesSelect <= clear ? 2'b00 : A[1:0];
            RegWriteW         <= clear ?  1'b0 : RegWriteM;
            MemToRegW         <= clear ?  1'b0 : MemToRegM;
            ResultW           <= clear ?     0 : ResultM;
            RdW               <= clear ?  5'b0 : RdM;
        end

    wire [31:0] RD_raw;
    cache CacheInst (
        .clk            ( clk           ),  
        .rst            ( rst           ),                    
        .miss           ( CacheMiss     ),
        .addr           ( A             ),
        .rd_req         ( MemToRegM     ),
        .rd_data        ( RD_raw        ),
        .wr_req         ( |WE           ),
        .wr_data        ( WD            )
    ); 
    

/////////////////
/// COUNTER /////
/////////////////
    reg [31:0] hit_count, miss_count, prev_addr;
    wire RD_WR = (|WE) | MemToRegM;
    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            prev_addr  <= 0;
            hit_count  <= 0;
            miss_count <= 0;
        end else begin
            if( RD_WR ) begin
                prev_addr <= A;
                if (prev_addr != A) begin
                    if(CacheMiss) miss_count <= miss_count+1;
                    else hit_count  <= hit_count +1;
                end
            end
        end
    end

    // Add clear and stall support
    // if chip not enabled, output output last read result
    // else if chip clear, output 0
    // else output values from bram
    // ????????????????????????
    reg stall_ff= 1'b0;
    reg clear_ff= 1'b0;
    reg [31:0] RD_old=32'b0;
    always @ (posedge clk)
    begin
        stall_ff<=~en;
        clear_ff<=clear;
        RD_old<=RD_raw;
    end    
    assign RD = stall_ff ? RD_old : (clear_ff ? 32'b0 : RD_raw );

endmodule