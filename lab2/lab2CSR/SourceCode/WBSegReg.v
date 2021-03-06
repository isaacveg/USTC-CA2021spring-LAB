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
    input wire [1:0] MemToRegM,
    output reg [1:0] MemToRegW,
    //CSR signals
    input wire [11:0] CSRaddrM,
    output reg [11:0] CSRaddrW,
    input wire [31:0] CSROutM,
    output reg [31:0] CSROutW,
    input wire CSRwrenM,
    output reg CSRwrenW
    );
    
    //
    initial begin
        LoadedBytesSelect = 2'b00;
        RegWriteW         =  1'b0;
        MemToRegW         =  2'b0;
        ResultW           =     0;
        RdW               =  5'b0;
        CSRaddrW = 0;
        CSROutW = 0;
        CSRwrenW = 0;
    end
    //
    always@(posedge clk)
        if(en) begin
            LoadedBytesSelect <= clear ? 2'b00 : A[1:0];
            RegWriteW         <= clear ?  1'b0 : RegWriteM;
            MemToRegW         <= clear ?  2'b0 : MemToRegM;
            ResultW           <= clear ?     0 : ResultM;
            RdW               <= clear ?  5'b0 : RdM;
            CSRaddrW <= clear ?  5'b0 : CSRaddrM;
            CSROutW <= clear ?  5'b0 : CSROutM;
            CSRwrenW <= clear ?  5'b0 : CSRwrenM;
        end

    wire [31:0] RD_raw;
    DataRam DataRamInst (
        .clk    ( clk            ),                      
        .wea    ( WE << A[1:0]   ),                      
        .addra  ( A[31:2]        ),                      
        .dina   ( WD << (8 * A[1:0]) ),                      
        .douta  ( RD_raw         ),
        .web    ( WE2            ),
        .addrb  ( A2[31:2]       ),
        .dinb   ( WD2            ),
        .doutb  ( RD2            )
    );   
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