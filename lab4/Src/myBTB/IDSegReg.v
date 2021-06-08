`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC CS
// Engineer: Zhu Ying
// 
// Design Name: RISCV-Pipline CPU
// Module Name: IDSegReg
// Target Devices: Nexys4
// Description: IF-ID Segment Register
//////////////////////////////////////////////////////////////////////////////////

//Already Completed

module IDSegReg(
    input wire clk,
    input wire clear,
    input wire en,
    //Instrution Memory Access
    input wire [31:0] A,
    output wire [31:0] RD,
    //Instruction Memory Debug
    input wire [31:0] A2,
    input wire [31:0] WD2,
    input wire [3:0] WE2,
    output wire [31:0] RD2,
    //
    input wire [31:0] PCF,
    output reg [31:0] PCD,
    // BTB
    input wire BTB_hit_IF,
    output reg BTB_hit_ID
    );
    
    initial PCD = 0;
    always@(posedge clk)
        if(en) begin
            PCD <= clear ? 0: PCF;
            BTB_hit_ID <= clear ? 0: BTB_hit_IF;
        end

    
    wire [31:0] RD_raw;
    // InstructionRam InstructionRamInst (
    //      .clk    ( clk        ),             
    //      .addra  ( A[31:2]    ),    //Use Word Addr, lower 2 bits used in BytesSelected                 
    //      .douta  ( RD_raw     ),
    //      .web    ( |WE2       ),
    //      .addrb  ( A2[31:2]   ),
    //      .dinb   ( WD2        ),
    //      .doutb  ( RD2        )
    //  );
    InstructionCache InstructionCacheInst (
        .clk    ( clk        ),             
        .addr   ( A[31:2]    ),    //Use Word Addr, lower 2 bits used in BytesSelected                 
        .data  ( RD_raw     ),
        .debug_input   ( WD2        ),
        .debug_data  ( RD2        ),
        .write_en( |WE2 ),
        .debug_addr( A2[31:2]   )
     );
    // Add clear and stall support
    // if chip not enabled, output output last read result
    // else if chip clear, output 0
    // else output values from bram
    // 以下部分无需修改
    reg stall_ff= 1'b0;
    reg clear_ff= 1'b0;
    reg [31:0] RD_old=32'b0;
    always @ (posedge clk)
    begin
        stall_ff<=~en;
        clear_ff<=clear;
        RD_old<=RD;
    end    
    assign RD = stall_ff ? RD_old : (clear_ff ? 32'b0 : RD_raw );

endmodule