`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC CS
// Engineer: Zhu Ying
// 
// Design Name: RISCV-Pipline CPU
// Module Name: HarzardUnit
// Target Devices: Nexys4
// Description: Deal with harzards in pipline
//////////////////////////////////////////////////////////////////////////////////

//Already completed
    
    
module HarzardUnit(
    input wire CpuRst, ICacheMiss, DCacheMiss, 
    input wire BranchE, JalrE, JalD, 
    input wire [4:0] Rs1D, Rs2D, Rs1E, Rs2E, RdE,RdM, RdW,    input wire [1:0] RegReadE,
    input wire MemToRegE,
    input wire [2:0] RegWriteM, RegWriteW,
    output reg StallF, FlushF, StallD, FlushD, StallE, FlushE, StallM, FlushM, StallW, FlushW,
    output reg [1:0] Forward1E, Forward2E,
    // BTB
    input wire jump
    );
    
    //forward unit     
    //Source 1
    always@(*)
    begin
        //MEM prior
        if( RegWriteM && RegReadE[1] && RdM==Rs1E && RdM )
        Forward1E<=2'b10;
        else if( RegWriteW && RegReadE[1] && (RdW==Rs1E) && RdW )
            Forward1E<=2'b01;
        else
            Forward1E<=2'b00;
    end
    //Source 2
    always@(*)
    begin
        if( RegWriteM && RegReadE[0] && RdM==Rs2E && RdM )
        Forward2E<=2'b10;
        else if( RegWriteW && RegReadE[0] && (RdW==Rs2E) && RdW )
            Forward2E<=2'b01;
        else
            Forward2E<=2'b00;
    end      

    //harzard unit
    always @ (*)
    begin
        {StallF,FlushF,StallD,FlushD,StallE,FlushE,StallM,FlushM,StallW,FlushW} <= 0;
        if(CpuRst)
            {FlushF,FlushD,FlushE,FlushM,FlushW} <= 5'b11111;
        else if(DCacheMiss | ICacheMiss)
            {StallF,StallD,StallE,StallM,StallW} <= 5'b11111;
        else if( BranchE != jump || JalrE)
            {FlushD,FlushE} <= 2'b11;
        else if(MemToRegE & ((RdE==Rs1D)||(RdE==Rs2D)) )
            {StallF,StallD,FlushE} <= 3'b111;
        else if(JalD)
            FlushD <= 1;  
    end
    
endmodule

  