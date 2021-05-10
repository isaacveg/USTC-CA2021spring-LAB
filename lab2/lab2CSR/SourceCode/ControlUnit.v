`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC CS
// Engineer: Zhu Ying
//
// Design Name: RISCV-Pipline CPU
// Module Name: ControlUnit
// Target Devices: Nexys4
// Description: RISC-V Instruction Decoder
//////////////////////////////////////////////////////////////////////////////////

//Already completed

`include "Parameters.v"   
module ControlUnit(
    input wire [6:0] Op,
    input wire [2:0] Fn3,
    input wire [6:0] Fn7,
    output wire JalD,
    output wire JalrD,
    output reg [2:0] RegWriteD,
    output wire [1:0] MemToRegD,
    output reg [3:0] MemWriteD,
    output wire LoadNpcD,
    output reg [1:0] RegReadD,
    output reg [2:0] BranchTypeD,
    output reg [3:0] AluContrlD,
    output wire [1:0] AluSrc2D,
    output wire [1:0] AluSrc1D,
    output reg [2:0] ImmType,
    //CSR
    input [4:0] Rs1E,//其实没用
    output reg CSRwrenD,
    output reg CSRReadD
    );

    //local parameters
    localparam BRAN = 7'b1100011; 
    localparam SHIF = 7'b0010011;   //偏移立即数
    localparam CALC = 7'b0110011;
    localparam LUIN = 7'b0110111;
    localparam LUIP = 7'b0010111;
    localparam JALR = 7'b1100111;
    localparam JALN = 7'b1101111;
    localparam LOAD = 7'b0000011;
    localparam STOR = 7'b0100011;
    localparam CSRR = 7'b1110011;

    //Alu srcs
    assign AluSrc1D = (Op==CSRR && Fn3[2]==1)?2'b10:((Op==LUIP)?2'b01:2'b00);
    //  确定是不是立即数偏移，是的话选Rs2E；不是的话确认是不是算数和分支；都不是的话检查是否是CSR指令
    assign AluSrc2D = ((Op==SHIF)&&(Fn3[1:0]==2'b01))?(2'b01):(((Op==CALC)||(Op==BRAN))?2'b00:((Op==CSRR)?2'b11:2'b10));

    //jump signal
    assign LoadNpcD = JalD | JalrD;
    assign JalD = (Op==JALN)?1:0;
    assign JalrD = (Op==JALR)?1:0;
    assign MemToRegD = (Op==LOAD)?2'b01:((Op==CSRR)?2'b10:2'b00);

    //Immediate type
    always@(*)
    begin
        case(ImmType)
        `RTYPE,`STYPE,`BTYPE: RegReadD = 2'b11;
        `UTYPE,`JTYPE:RegReadD = 2'b00;
        `ITYPE: RegReadD = 2'b10;  
        default: RegReadD = 2'b00;                               
        endcase
    end   

    //Branch type
    always@(*)
    begin
        if(Op==BRAN)      
        begin    
            case(Fn3)
            3'b000:BranchTypeD<=`BEQ;   
            3'b001:BranchTypeD<=`BNE;    
            3'b100:BranchTypeD<=`BLT;    
            3'b101:BranchTypeD<=`BGE;    
            3'b110:BranchTypeD<=`BLTU;   
            default:BranchTypeD<=`BGEU;                                                       
            endcase
        end
        else BranchTypeD <= `NOBRANCH;
    end

    //CSRRead and CSRwrite enable
    always @(*) 
    begin
        if (Op == CSRR)
        begin
            CSRReadD <= 1;
            CSRwrenD <= 1;
        end
        else 
        begin
            CSRReadD <= 0;
            CSRwrenD <= 0;
        end
    end

    //MemWrite,RegWrite and AluControl
    always@(*)
    begin //set default values
    MemWriteD <= 0;
    RegWriteD <=`NOREGWRITE;
    AluContrlD <=`ADD;
    case(Op)
        CSRR:
        begin
            ImmType<=`ITYPE;  
            RegWriteD<=`LW;
            case (Fn3)
                3'b001:AluContrlD<=`REG1;  
                3'b010:AluContrlD<=`OR; 
                3'b011:AluContrlD<=`CLR;
                3'b101:AluContrlD<=`REG1;  
                3'b110:AluContrlD<=`OR;   
                default: AluContrlD<=`CLR;   
            endcase
        end
        BRAN: ImmType<=`BTYPE;    
        SHIF:
        begin   
            RegWriteD<=`LW;
            ImmType<=`ITYPE;
            case(Fn3)
                3'b000:AluContrlD<=`ADD;  
                3'b001:AluContrlD<=`SLL;  
                3'b010:AluContrlD<=`SLT;  
                3'b011:AluContrlD<=`SLTU;   
                3'b101:begin
                    if(Fn7[5])
                        AluContrlD<=`SRA;   
                    else
                        AluContrlD<=`SRL; 
                        end
                3'b100:AluContrlD<=`XOR;   
                3'b110:AluContrlD<=`OR;   
                default:AluContrlD<=`AND; 
                endcase
        end
        CALC:
        begin   
            RegWriteD<=`LW;
            ImmType<=`RTYPE;
            case(Fn3)
                3'b000:begin
                    if(Fn7[5])
                        AluContrlD<=`SUB;   
                    else
                        AluContrlD<=`ADD;   
                end
                3'b001:AluContrlD<=`SLL;    
                3'b010:AluContrlD<=`SLT;    
                3'b011:AluContrlD<=`SLTU;   
                3'b100:AluContrlD<=`XOR;    
                3'b101:begin
                    if(Fn7[5])
                        AluContrlD<=`SRA;   
                    else
                        AluContrlD<=`SRL;   
                end  
                3'b110:AluContrlD<=`OR;    
                default:AluContrlD<=`AND;                                          
            endcase
        end
        LUIN:
        begin    //LUI
            RegWriteD<=`LW;
            AluContrlD<=`LUI;
            ImmType<=`UTYPE;     
        end 
        LUIP:
        begin    //AUIPC
            RegWriteD<=`LW;
            ImmType<=`UTYPE;
        end
        JALN:
        begin    //Normal jal
            RegWriteD<=`LW;
            ImmType<=`JTYPE;       
        end
        JALR:
        begin    //Jalr 
            RegWriteD<=`LW;
            ImmType<=`ITYPE;     // Check the manul for detailed information    
        end
        LOAD:
        begin    //load
            ImmType<=`ITYPE;
            case(Fn3)
                3'b000:RegWriteD<=`LB;    //byte
                3'b001:RegWriteD<=`LH;    //half word
                3'b010:RegWriteD<=`LW;    //word
                3'b100:RegWriteD<=`LBU;    //unsigned byte
                default:RegWriteD<=`LHU;    //unsigned half word                                                          
            endcase
        end
        STOR:
        begin    //store
            ImmType<=`STYPE; 
            case(Fn3)
                3'b000:MemWriteD<=4'b0001;    //byte
                3'b001:MemWriteD<=4'b0011;    //half word
                default:MemWriteD<=4'b1111;   //word                                                   
            endcase
        end       
        default: ImmType<=`ITYPE;
    endcase
    end
    
endmodule